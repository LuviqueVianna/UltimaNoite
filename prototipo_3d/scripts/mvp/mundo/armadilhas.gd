class_name Armadilhas
extends RefCounted
## Armadilhas escondidas nas trilhas (docs/MVP_v0.4.md, seção 6).
## Ficam ocultas até alguém pisar nelas ou percebê-las. Ao chegar à distância de notar, cada um tem
## uma chance só, pela Inteligência (0% a 70%); quem não notou pisa (decidido em 23/10/2026).
## Quem pisa fica preso (tempo pela Força) e depois lento (duração reduzida pela Resistência).
## Quem já viu uma armadilha passa por ela sem disparar. Disparada, ela fica à vista de todos.


class Armadilha extends RefCounted:
	var id := 0
	var pos := Vector2.ZERO
	var local := "trilha"        # trilha | beco (escolhe o texto de descoberta)
	var disparada := false
	var vista_por := {}          # id do personagem -> true
	var falhou := {}             # id do personagem -> true: chegou perto e não notou nesta passagem


var mundo: Mundo
var lista: Array = []


func _init(m: Mundo) -> void:
	mundo = m


func preparar() -> void:
	var mapa := mundo.mapa
	var becos := mapa.nos.filter(func(n): return n["tipo"] == "beco").map(func(n): return n["id"])
	mundo.embaralhar(becos)
	var n := 0
	# Parte delas no fim dos becos: quem entra num caminho sem saída arrisca mais
	for b in becos.slice(0, Regras.ARMADILHAS_BECO):
		_criar(mapa.pos(b), "beco", n)
		n += 1
	var tentativas := 0
	while n < Regras.ARMADILHAS_QTD and tentativas < 500:
		tentativas += 1
		var p: Vector2 = mapa.amostras[mundo.rng.randi() % mapa.amostras.size()]
		if _lugar_ok(p):
			_criar(p, "trilha", n)
			n += 1


func _criar(p: Vector2, local: String, id: int) -> void:
	var a := Armadilha.new()
	a.id = id
	a.pos = p
	a.local = local
	lista.append(a)


func _lugar_ok(p: Vector2) -> bool:
	for no in mundo.mapa.nos:
		if (no["partida"] or no["base"] != "" or no["saida"]) and p.distance_to(no["pos"]) < Regras.ARMADILHA_LONGE_M:
			return false
	for a in lista:
		if p.distance_to(a.pos) < 40.0:
			return false
	return true


func tick() -> void:
	for p in mundo.personagens:
		if p.registrou():
			continue
		var notar: float = Regras.nivel(Regras.NOTAR_ARMADILHA, p.nivel("inteligencia"))
		var chance: float = Regras.nivel(Regras.CHANCE_NOTAR, p.nivel("inteligencia"))
		for a in lista:
			if a.disparada or a.vista_por.has(p.id):
				continue
			var d: float = p.pos.distance_to(a.pos)
			if d > notar + 4.0:
				a.falhou.erase(p.id)   # afastou-se: na próxima passagem tem nova chance
			if d <= notar and not a.falhou.has(p.id) and mundo.rng.randf() >= chance:
				a.falhou[p.id] = true
			if d <= notar and not a.falhou.has(p.id):
				a.vista_por[p.id] = true
				p.fatos_noite["notou_armadilha"] = true
				_falar(p, a, "armadilha_notada", "Você nota uma armadilha escondida na trilha e passa por ela com cuidado.")
			elif d <= Regras.ARMADILHA_PISA_M and p.espera <= 0.0:
				_disparar(a, p)


func _disparar(a: Armadilha, p: Personagem) -> void:
	a.disparada = true
	p.armadilhas_acionadas += 1
	p.espera = maxf(p.espera, Regras.nivel(Regras.PRESO_S, p.nivel("forca")))
	p.lento_s = maxf(p.lento_s, Regras.LENTO_S * (1.0 - Regras.nivel(Regras.REDUZ_LENTIDAO, p.nivel("resistencia"))))
	mundo.som.emit("armadilha", a.pos)
	_falar(p, a, "armadilha_acionada", "")
	if p.eh_jogador:
		mundo.aviso.emit("Você fica preso por %.0f s e depois anda devagar." % Regras.nivel(Regras.PRESO_S, p.nivel("forca")))
	# Os outros ouvem de longe
	var j := mundo.jogador()
	if j.id != p.id and not j.registrou() and j.pos.distance_to(a.pos) <= Regras.OUVE_M:
		var eventos: Array = Dados.ler_json("textos/eventos_distancia.json").get("eventos", [])
		var t := Textos.sortear(eventos, {"gatilho": "armadilha_acionada"}, mundo.rng)
		if t != "":
			mundo.aviso.emit(Textos.preencher(t, {"direcao": Textos.direcao(j.pos, a.pos)}))


## O jogador vê esta armadilha? (já a notou, ela foi disparada, ou a névoa está desligada)
func visivel_para_jogador(a: Armadilha) -> bool:
	if a.disparada or Regras.sem_nevoa:
		return true
	return a.vista_por.has(mundo.jogador().id)


func _falar(p: Personagem, a: Armadilha, conteudo: String, reserva: String) -> void:
	if not p.eh_jogador:
		return
	var lista_textos: Array = Dados.ler_json("textos/clareiras.json").get("descobertas", [])
	var t := Textos.sortear(lista_textos, {"local": a.local, "conteudo": conteudo}, mundo.rng)
	if t == "" and a.local == "trilha":
		# Enquanto não houver textos próprios de trilha (demanda 5), usa os de clareira
		t = Textos.sortear(lista_textos, {"local": "clareira_vazia", "conteudo": conteudo}, mundo.rng)
	mundo.aviso.emit(t if t != "" else reserva)
