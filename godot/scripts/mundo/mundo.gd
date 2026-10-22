class_name Mundo
extends RefCounted
## Estado da noite: mapa, personagens, pegadas e relógio. Sem nada de desenho,
## para poder ser testado sem tela.

signal chegou_base(personagem: Personagem, base: String)
signal aviso(texto: String)
signal amanheceu
signal guardiao_mentiu_para(personagem: Personagem, base: String)
signal chegou_saida(personagem: Personagem)
signal som(evento: String, origem: Vector2)   # barulho no mapa (Regras.SONS); a cena decide se o jogador ouve

var mapa: Mapa
var personagens: Array = []
var pegadas: Array = []      # {id, pos, dir, dono, calcado, t, vida}
var tempo := 0.0
var terminou := false
var rng := RandomNumberGenerator.new()
var panela_boa := {}         # base -> "esquerda" | "direita"
## Fatos guardados em fatos_noite que o jogo já registra: ausência quer dizer "não aconteceu".
const FATOS_DA_NOITE := ["lobo_reacao", "seguiu_cao", "cobra_reacao"]

var fauna: Fauna
var visitante := {}          # base -> {"id": personagem, "mente": bool} enquanto um personagem do computador está lá
var _verificacao := {}
var _proxima_pegada := 0
var _acumulado_percepcao := 0.0


## jogador: {"nome": String, "atributos": Dictionary}
func iniciar(semente: int, jogador: Dictionary) -> void:
	rng.seed = semente
	mapa = GeradorMapa.new().gerar(semente)

	var calcados := Regras.CALCADOS.keys()
	_embaralhar(calcados)
	var nomes := Dados.nomes_computador().filter(func(n): return n != jogador["nome"])
	_embaralhar(nomes)
	var partidas := mapa.partidas()
	_embaralhar(partidas)
	for b in Regras.BASES:
		panela_boa[b] = "esquerda" if rng.randf() < 0.5 else "direita"
	var v = Dados.ler_json("guardioes/verificacao.json")
	_verificacao = v.get("condicoes", {}) if v is Dictionary else {}
	var comuns := (Dados.itens().get("itens", []) as Array).filter(func(i): return i["raridade"] == "comum").map(func(i): return i["id"])

	for i in 4:
		var p := Personagem.new()
		p.id = i
		p.calcado = calcados[i]
		if i == 0:
			p.eh_jogador = true
			p.nome = jogador["nome"]
			p.atributos = jogador["atributos"]
		else:
			p.nome = nomes[i - 1]
			p.perfil = Regras.PERFIS[rng.randi() % Regras.PERFIS.size()]
			p.atributos = Regras.sortear_atributos(rng)
		p.preparar(mapa, partidas[i])
		p.saida = mapa.saidas[partidas[i]]
		if not comuns.is_empty():
			p.inventario.append(comuns[rng.randi() % comuns.size()])
		personagens.append(p)
	fauna = Fauna.new(self)
	fauna.preparar()
	for p in personagens:
		_perceber(p)


func jogador() -> Personagem:
	return personagens[0]


func tempo_restante() -> float:
	return maxf(0.0, Regras.NOITE_S - tempo)


func tick(dt: float) -> void:
	if terminou:
		return
	tempo += dt
	for p in personagens:
		if not p.eh_jogador:
			IA.decidir(p, self)
		for ev in p.passo(dt, mapa):
			match ev["tipo"]:
				"pegada":
					pegadas.append({
						"id": _proxima_pegada, "pos": ev["pos"], "dir": ev["dir"], "dono": p.id,
						"calcado": p.calcado, "t": tempo, "vida": p.vida_pegada(),
					})
					_proxima_pegada += 1
				"chegou":
					_chegou(p, ev["no"])
	fauna.tick(dt)
	_acumulado_percepcao += dt
	if _acumulado_percepcao >= Regras.PERCEPCAO_INTERVALO:
		_acumulado_percepcao = 0.0
		pegadas = pegadas.filter(func(g): return tempo - g["t"] <= g["vida"])
		for p in personagens:
			_perceber(p)
	if tempo >= Regras.NOITE_S:
		terminou = true
		amanheceu.emit()


func _chegou(p: Personagem, no: int) -> void:
	if no == p.saida and not p.registrou():
		if p.eh_jogador:
			chegou_saida.emit(p)
			return
		if IA.hora_de_ir(p, self):
			p.concluiu = tempo
			return
	var base: String = mapa.nos[no]["base"]
	p.na_base = base
	if base == "":
		return
	if p.eh_jogador:
		if not p.bases_visitadas.has(base):
			chegou_base.emit(p, base)
	elif not p.bases_visitadas.has(base) and not p.acelerado:
		if base == "vazia":
			p.bases_visitadas[base] = tempo
			return
		var res := IA.visitar(p, self, base)
		var duracao := Regras.VISITA_BASE_S / (Regras.ACELERA_COMPUTADOR if p.acelerado else 1.0)
		visitante[base] = {"id": p.id, "mente": res["mente"], "ate": tempo + duracao}
		p.espera = duracao


func registrar_chegada(p: Personagem) -> void:
	if not p.registrou():
		p.concluiu = tempo
		p.rota = []
	if p.eh_jogador:
		# Para a comparação final: os outros apressam o passo e encurtam as visitas.
		for o in personagens:
			if not o.eh_jogador:
				o.acelerado = true
				o.espera = minf(o.espera, 3.0)
				o.rota = o.rota.slice(0, 1)   # termina o trecho atual e recalcula rumo à saída


## Classificação no amanhecer: só pontua quem registrou a chegada.
func classificacao() -> Array:
	var ordem := personagens.duplicate()
	ordem.sort_custom(func(a, b):
		if a.registrou() != b.registrou():
			return a.registrou()
		return a.pontos() > b.pontos())
	return ordem


func item(id: String) -> Dictionary:
	for i in Dados.itens().get("itens", []):
		if i["id"] == id:
			return i
	return {}


func embaralhar(a: Array) -> void:
	_embaralhar(a)


## O que se vê pela janela de uma base agora.
func texto_janela(base: String) -> String:
	var lista: Array = Dados.ler_json("textos/janelas.json").get("janelas", [])
	if base == "vazia":
		return Textos.sortear(lista, {"base": base, "situacao": "sem_ninguem"}, rng)
	var v: Dictionary = visitante.get(base, {})
	if v.is_empty() or tempo > v["ate"]:
		return Textos.sortear(lista, {"base": base, "situacao": "sozinho"}, rng)
	var o: Personagem = personagens[v["id"]]
	var sit := "sinal_mentira" if v["mente"] else "com_visitante"
	return Textos.preencher(Textos.sortear(lista, {"base": base, "situacao": sit}, rng),
		{"calcado": Regras.CALCADOS[o.calcado], "calcado_par": Regras.CALCADOS_PAR[o.calcado]})


## Fatos da noite que as perguntas verificáveis consultam (conteudo/guardioes/verificacao.json).
func fato(p: Personagem, base: String, nome: String) -> Variant:
	match nome:
		"aproximacao":
			return p.aproximacao.get(base, "frente")
		"bases_antes":
			return p.bases_visitadas.keys().filter(func(b): return b != base).size()
		"esconderijos":
			return p.esconderijos
		"jogadores_vistos":
			return p.vistos.size()
		"jogadores_perto":
			var c := 0
			for o in personagens:
				if o.id != p.id and o.pos.distance_to(mapa.pos(mapa.bases()[base])) <= Regras.JOGADORES_PERTO_M:
					c += 1
			return c
		"itens":
			return p.inventario.size()
		"reconhece_calcado":
			return p.ultima_pegada_vista >= 0 and p.vistos.has(p.ultima_pegada_vista)
		"mentiu_antes":
			return p.mentiras > 0
		"mentiu_inventario":
			return p.mentiu_inventario
		"usou_silencio":
			return p.silencios
		"armadilhas_acionadas":
			return p.armadilhas_acionadas
		"avisou_armadilha":
			return p.avisou_armadilha
		"escondeu_rastro":
			return p.escondeu_rastro
	# Fatos dos animais e outros guardados na noite (ex.: "lobo_reacao", "seguiu_cao")
	return p.fatos_noite.get(nome)


func resposta_verdadeira(p: Personagem, base: String, id_pergunta: String, chave: String) -> bool:
	var conds: Array = _verificacao.get(id_pergunta, {}).get(chave, [])
	for c in conds:
		var valor = fato(p, base, c["fato"])
		if c["op"] == "ausente":
			if valor != null:
				return false
			continue
		if valor == null:
			if FATOS_DA_NOITE.has(c["fato"]):
				return false   # o fato existe no jogo e ainda não aconteceu: a resposta não confere
			continue
		var alvo = c["valor"]
		match c["op"]:
			"==":
				if valor != alvo:
					return false
			">=":
				if valor < alvo:
					return false
			"<=":
				if valor > alvo:
					return false
	return true


## Premissas do formato v3: a pergunta só é sorteada se o fato aconteceu.
func premissa(p: Personagem, base: String, nome: String) -> bool:
	if nome.begins_with("marca:"):
		return p.tem_marca(nome.substr(6))
	match nome:
		"viu_pegadas_alheias":
			return p.ultima_pegada_vista >= 0
		"reconhece_calcado":
			return fato(p, base, "reconhece_calcado")
		"viu_jogador":
			return not p.vistos.is_empty()
		"visitou_outra_base":
			return fato(p, base, "bases_antes") > 0
		"tem_item":
			return not p.inventario.is_empty()
		"usou_esconderijo":
			return p.esconderijos > 0
		"acionou_armadilha":
			return p.armadilhas_acionadas > 0
	return p.fatos_noite.has(nome)


## Toque do jogador no mapa: anda até o nó conhecido mais próximo do ponto tocado.
## Toque ou clique: num ponto conhecido, anda até ele; numa trilha visível, segue por ela.
func mover_jogador_para(ponto: Vector2) -> bool:
	var j := jogador()
	var aberto := Regras.sem_nevoa
	var alvo := mapa.no_mais_proximo(ponto, Regras.CLIQUE_RAIO * 0.6, func(n): return aberto or j.no_visto[n] == 1)
	if alvo >= 0 and alvo != j.no_atual:
		return j.ir_para(mapa, alvo, not aberto)
	# Trilha visível (percorrida ou ainda lembrada) perto do clique
	var melhor := -1
	var melhor_d := Regras.CLIQUE_RAIO
	for i in mapa.amostras.size():
		if not aberto and j.amostra_percorrida[i] == 0 and tempo - j.amostra_vista[i] > j.lembranca():
			continue
		var d := mapa.amostras[i].distance_to(ponto)
		if d < melhor_d:
			melhor_d = d
			melhor = i
	if melhor < 0:
		return false
	var e: Dictionary = mapa.arestas[mapa.amostra_aresta[melhor]]
	var a: int = e["a"]
	var b: int = e["b"]
	var destino := a if mapa.pos(a).distance_to(ponto) < mapa.pos(b).distance_to(ponto) else b
	if j.no_atual == a or j.no_atual == b:
		destino = b if j.no_atual == a else a
	return j.ir_para(mapa, destino, not aberto)


## Teclado: segue a trilha que mais aponta para a direção pedida. Direção zero = para onde está.
func dirigir_jogador(dir: Vector2) -> void:
	var j := jogador()
	if j.registrou():
		return
	if dir == Vector2.ZERO:
		j.rota = []
		j.pausado = true
		return
	j.pausado = false
	dir = dir.normalized()
	if j.no_atual >= 0:
		var melhor := -1
		var melhor_dot := 0.35
		for v in mapa.adj[j.no_atual]:
			var d := (mapa.pos(v.x) - mapa.pos(j.no_atual)).normalized().dot(dir)
			if d > melhor_dot:
				melhor_dot = d
				melhor = v.x
		j.rota = [melhor] if melhor >= 0 else []
		return
	var sentido := (mapa.pos(j.para) - mapa.pos(j.de)).normalized()
	if sentido.dot(dir) < -0.35:
		var comp: float = mapa.arestas[mapa.aresta_entre(j.de, j.para)]["comp"]
		var t := j.de
		j.de = j.para
		j.para = t
		j.progresso = comp - j.progresso
	j.rota = []


func _perceber(p: Personagem) -> void:
	var r := p.alcance()
	var r2 := r * r
	var perto2 := Regras.RAIO_PERCORRIDO * Regras.RAIO_PERCORRIDO
	for i in mapa.amostras.size():
		var d2 := p.pos.distance_squared_to(mapa.amostras[i])
		if d2 <= r2:
			p.amostra_vista[i] = tempo
			p.aresta_conhecida[mapa.amostra_aresta[i]] = 1
			if d2 <= perto2:
				p.amostra_percorrida[i] = 1
	for n in mapa.nos:
		var d: float = p.pos.distance_to(n["pos"])
		if d <= r:
			p.no_visto[n["id"]] = 1
		var base: String = n["base"]
		if base != "" and base != "vazia" and d <= Regras.LUZ_BASE_M and not p.luzes.has(base):
			p.luzes[base] = n["pos"]
			if p.eh_jogador:
				aviso.emit("Uma luz âmbar aparece entre as árvores.")
	var mais_nova := -1.0
	for g in pegadas:
		if g["dono"] != p.id and p.pos.distance_squared_to(g["pos"]) <= r2:
			p.pegadas_vistas[g["id"]] = tempo
			if g["t"] > mais_nova:
				mais_nova = g["t"]
				p.ultima_pegada_vista = g["dono"]
	for o in personagens:
		if o.id == p.id or p.pos.distance_squared_to(o.pos) > r2:
			continue
		var primeira: bool = not p.vistos.has(o.id)
		p.vistos[o.id] = tempo
		p.dono_do_calcado[o.calcado] = o.id
		if primeira and p.eh_jogador:
			aviso.emit("Você viu %s, de %s." % [o.nome, Regras.CALCADOS[o.calcado]])


func pegada_visivel_para(p: Personagem, g: Dictionary) -> bool:
	if g["dono"] == p.id:
		return true
	return tempo - p.pegadas_vistas.get(g["id"], -1.0e9) <= p.lembranca()


func _embaralhar(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t
