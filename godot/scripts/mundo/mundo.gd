class_name Mundo
extends RefCounted
## Estado da noite: mapa, personagens, pegadas e relógio. Sem nada de desenho,
## para poder ser testado sem tela.

signal chegou_base(personagem: Personagem, base: String)
signal aviso(texto: String)
signal amanheceu

var mapa: Mapa
var personagens: Array = []
var pegadas: Array = []      # {id, pos, dir, dono, calcado, t, vida}
var tempo := 0.0
var terminou := false
var rng := RandomNumberGenerator.new()
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
		personagens.append(p)
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
	var base: String = mapa.nos[no]["base"]
	p.na_base = base
	if base == "":
		return
	if p.eh_jogador:
		chegou_base.emit(p, base)
	elif not p.bases_visitadas.has(base):
		p.bases_visitadas[base] = tempo
		p.espera = Regras.VISITA_BASE_S


## Toque do jogador no mapa: anda até o nó conhecido mais próximo do ponto tocado.
func mover_jogador_para(ponto: Vector2) -> bool:
	var j := jogador()
	var alvo := mapa.no_mais_proximo(ponto, Regras.CLIQUE_RAIO, func(n): return j.no_visto[n] == 1)
	if alvo < 0:
		return false
	return j.ir_para(mapa, alvo)


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
	for g in pegadas:
		if g["dono"] != p.id and p.pos.distance_squared_to(g["pos"]) <= r2:
			p.pegadas_vistas[g["id"]] = tempo
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
