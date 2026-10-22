class_name Visita
extends RefCounted
## Uma visita a uma base: perguntas sorteadas, afinidade, mentira, contradição, reputação,
## e no fim a indicação da panela. Serve igual para o jogador e para o computador.
## Regras: formato v3 (docs/correcoes/CORRECOES_guardioes_v3.md) e conteudo/guardioes/verificacao.json.

var mundo: Mundo
var p: Personagem
var base := ""
var dados := {}
var afinidade := 0
var ma := 0
var boa_intencao := 0
var abertura: Array = []     # narração e uma fala
var perguntas: Array = []
var indice := 0
var registro: Array = []     # {id, escolha, delta, mentiu, contradisse}
var indicacao := {}          # preenchida por indicar()


func _init(m: Mundo, personagem: Personagem, id_base: String) -> void:
	mundo = m
	p = personagem
	base = id_base
	dados = Dados.guardiao(base)
	afinidade = _reputacao()
	var entradas: Array = dados.get("entradas", [])
	var narracoes := entradas.filter(func(e): return e["tipo"] == "narracao")
	var falas := entradas.filter(func(e): return e["tipo"] == "fala")
	if not narracoes.is_empty():
		abertura.append(narracoes[0])
	if not falas.is_empty():
		abertura.append(falas[mundo.rng.randi() % falas.size()])
	var possiveis := entradas.filter(func(e): return e["tipo"] == "pergunta" and _pode_perguntar(e))
	mundo.embaralhar(possiveis)
	var n := mundo.rng.randi_range(Regras.PERGUNTAS_POR_VISITA.x, Regras.PERGUNTAS_POR_VISITA.y)
	perguntas = possiveis.slice(0, n)


func terminou_perguntas() -> bool:
	return indice >= perguntas.size()


func pergunta_atual() -> Dictionary:
	return perguntas[indice] if indice < perguntas.size() else {}


## Opções que o personagem pode escolher na pergunta atual: as respostas e, se tiver o atributo, a extra.
func opcoes() -> Array:
	var e := pergunta_atual()
	var r := []
	for i in e.get("respostas", []).size():
		r.append({"chave": str(i), "texto": e["respostas"][i]["texto"]})
	var extra: Dictionary = e.get("opcao_extra", {})
	if not extra.is_empty() and p.nivel(extra["atributo"]) >= int(extra["minimo"]):
		r.append({"chave": "extra", "texto": extra["texto"], "atributo": extra["atributo"]})
	return r


## chave: "0", "1", "2", "extra" ou "silencio". tom: "firme", "gentil" ou "evasivo".
func responder(chave: String, tom: String) -> Dictionary:
	var e := pergunta_atual()
	var res := {"id": e["id"], "escolha": chave, "delta": 0, "mentiu": false, "contradisse": false}
	if chave == "silencio":
		res["delta"] = int(e.get("silencio", {}).get("afinidade", 0))
		p.silencios += 1
	else:
		var r: Dictionary = e["opcao_extra"] if chave == "extra" else e["respostas"][int(chave)]
		var delta := int(r["afinidade"])
		var intencao = r.get("intencao")
		if e.get("verificavel", false) and not mundo.resposta_verdadeira(p, base, e["id"], chave):
			res["mentiu"] = true
			p.mentiras += 1
			if "inventario" in _lista(e, "requer"):
				p.mentiu_inventario = true
			delta = int(e.get("mentira", {}).get("afinidade", -4))
			intencao = e.get("mentira", {}).get("intencao")
		delta += _modificador_tom(r, tom)
		for marca in _lista(r, "contradiz"):
			if p.tem_marca(marca):
				res["contradisse"] = true
		if res["contradisse"]:
			delta += int(e.get("contradicao", {}).get("afinidade", 0))
		for marca in _lista(r, "registra"):
			p.marcas.append({"marca": marca, "base": base})
		if intencao == "ma":
			ma += 1
		elif intencao == "boa":
			boa_intencao += 1
		res["delta"] = delta
	afinidade = clampi(afinidade + res["delta"], -Regras.AFINIDADE_LIMITE, Regras.AFINIDADE_LIMITE)
	registro.append(res)
	indice += 1
	return res


func _modificador_tom(r: Dictionary, tom: String) -> int:
	var proprio = r.get("tom")
	if proprio is Dictionary and proprio.has(tom):
		return int(proprio[tom])
	return int(dados.get("modificadores_tom", {}).get(tom, 0))


func situacao() -> String:
	if ma >= Regras.MA_INTENCAO_MIN:
		return "ma"
	if afinidade >= Regras.AFINIDADE_ALTA:
		return "alta"
	if afinidade <= Regras.AFINIDADE_BAIXA:
		return "baixa"
	return "neutra"


## Decide o que o guardião diz sobre as panelas.
## Devolve {acao, lado ("esquerda"|"direita"|""), mente, fala, gesto, pede_item}.
func indicar() -> Dictionary:
	var acao: String = Regras.COMPORTAMENTO[base][situacao()]
	indicacao = {"acao": acao, "lado": "", "mente": false, "pede_item": acao == "preco" and not p.inventario.is_empty()}
	match acao:
		"boa":
			_apontar(false)
		"ruim":
			_apontar(true)
		"sorteio":
			_apontar(mundo.rng.randf() < 0.5)
		"preco":
			if indicacao["pede_item"]:
				indicacao["fala"] = Textos.indicacao(base, "preco", mundo.rng)
				return indicacao
			_apontar(true)
		_:
			indicacao["fala"] = Textos.indicacao(base, "nada", mundo.rng)
	return indicacao


## Resposta ao pedido do Quincas: item dado (ou "" se recusou).
func pagar(item: String) -> Dictionary:
	if item != "" and p.inventario.has(item):
		p.inventario.erase(item)
		var raridade: String = mundo.item(item).get("raridade", "comum")
		afinidade += int(Dados.itens().get("valor_quincas", {}).get(raridade, 1))
		_apontar(false)
	else:
		_apontar(true)
	indicacao["pede_item"] = false
	return indicacao


func _apontar(mentindo: bool) -> void:
	var boa: String = mundo.panela_boa[base]
	var lado := boa if not mentindo else ("direita" if boa == "esquerda" else "esquerda")
	indicacao["lado"] = lado
	indicacao["mente"] = mentindo
	indicacao["fala"] = Textos.preencher(Textos.indicacao(base, "fala", mundo.rng), {"lado": lado})
	indicacao["gesto"] = Textos.indicacao(base, "mentira" if mentindo else "verdade", mundo.rng)


## O personagem come da panela do lado escolhido.
func comer(lado: String) -> Dictionary:
	var boa: bool = lado == mundo.panela_boa[base]
	p.refeicoes[base] = "boa" if boa else "ruim"
	p.bases_visitadas[base] = mundo.tempo
	var r := {"boa": boa, "veneno": ""}
	if not boa:
		r["veneno"] = p.envenenar(mundo.rng)
	return r


func _pode_perguntar(e: Dictionary) -> bool:
	for m in _lista(e, "requer"):
		if not Regras.MECANICAS_MVP.has(m):
			return false
	for premissa in _lista(e, "premissa"):
		if not mundo.premissa(p, base, premissa):
			return false
	return true


## Marcas deixadas em outras bases que este guardião valoriza ou despreza.
func _reputacao() -> int:
	var total := 0
	var rep: Dictionary = dados.get("reputacao", {})
	for m in p.marcas:
		if m["base"] != base and rep.has(m["marca"]):
			total += int(rep[m["marca"]])
	return total


static func _lista(d: Dictionary, campo: String) -> Array:
	var v = d.get(campo)
	return v if v is Array else []
