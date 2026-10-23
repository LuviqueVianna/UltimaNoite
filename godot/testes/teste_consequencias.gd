extends SceneTree
## Consequências mais pesadas (docs/sistemas/consequencias_v1.md): veneno acumulado, faro do lobo,
## base como refúgio, sumir na mata, moita e reação dos guardiões.
##   godot --headless --path godot -s res://testes/teste_consequencias.gd

var falhas := 0


func _ok(cond: bool, texto: String) -> void:
	print(("  ok   " if cond else "  FALHA ") + texto)
	if not cond:
		falhas += 1


func _mundo(semente: int, atributos := {}) -> Mundo:
	var a := {"forca": 3, "inteligencia": 3, "carisma": 2, "furtividade": 3, "resistencia": 1}
	a.merge(atributos, true)
	var m := Mundo.new()
	m.iniciar(semente, {"nome": "Teste", "atributos": a})
	return m


## Deixa o jogador sozinho com o lobo: sem cobras, sem armadilhas, sem os outros na mata.
func _so_o_lobo(m: Mundo) -> Fauna.Animal:
	m.fauna.animais = m.fauna.animais.filter(func(a): return a.tipo == "lobo")
	m.armadilhas.lista = []
	for p in m.personagens:
		if not p.eh_jogador:
			p.concluiu = 0.0
	var lobo: Fauna.Animal = m.fauna.animais[0]
	lobo.ferido = false
	return lobo


## Um nó de trilha a uns 25-45 m (pelo caminho) de alguma base.
func _perto_de_base(m: Mundo) -> Vector2i:
	for b in m.mapa.bases().values():
		for n in m.mapa.nos:
			if n["base"] != "" or n["partida"]:
				continue
			var d := m.mapa.distancia_grafo(n["id"], b)
			if d >= 25.0 and d <= 45.0:
				return Vector2i(n["id"], b)
	return Vector2i(-1, -1)


func _por_no(p: Personagem, m: Mundo, no: int) -> void:
	p.no_atual = no
	p.de = -1
	p.para = -1
	p.rota = []
	p.pos = m.mapa.pos(no)


func _init() -> void:
	print("== Veneno acumulado")
	var m := _mundo(5)
	var j := m.jogador()
	var desmaios := []
	m.desmaiou.connect(func(p): desmaios.append(p.id))
	m.envenenar(j)
	# O veneno também tira 1 ponto da maior habilidade (pode ser a Inteligência, que dá o alcance)
	var alcance: float = Regras.nivel(Regras.ALCANCE_VISTA, j.nivel("inteligencia"))
	_ok(j.doses_veneno == 1 and j.turvo_s == Regras.VENENO_TURVO_S, "1ª dose: visão turva por %.0f s" % Regras.VENENO_TURVO_S)
	_ok(is_equal_approx(j.alcance(), alcance * Regras.VENENO_VISAO), "visão cai de %.1f para %.1f m" % [alcance, j.alcance()])
	for i in 700:
		m.tick(0.1)
		if not j.envenenado():
			break
	_ok(not j.envenenado() and is_equal_approx(j.alcance(), alcance), "a vista clareia depois de 1 minuto")
	m.envenenar(j)
	_ok(j.turvo_s == INF, "2ª dose: visão turva até o amanhecer")
	m.envenenar(j)
	_ok(j.desmaiado and desmaios == [0], "3ª dose: desmaia (sinal emitido)")
	var pos := j.pos
	j.rota = [m.mapa.adj[j.no_atual][0].x] if j.no_atual >= 0 else []
	for i in 30:
		m.tick(0.1)
	_ok(j.pos == pos, "desmaiado não anda")
	m.registrar_chegada(j)
	_ok(not j.registrou(), "desmaiado não registra a chegada")

	print("== Sumir na mata")
	m = _mundo(7, {"furtividade": 5})
	j = m.jogador()
	_ok(j.usos_sumir() == 3, "Furtividade 5: 3 usos")
	j.sumir()
	var t := 0.0
	while j.oculto_s > 0.0 and t < 20.0:
		m.tick(0.1)
		t += 0.1
	_ok(absf(t - Regras.SUMIR_S) < 0.3, "parado dura %.1f s" % t)
	var longe := -1
	for n in m.mapa.nos:
		if m.mapa.distancia_grafo(j.no_atual, n["id"]) > 120.0:
			longe = n["id"]
			break
	j.ir_para(m.mapa, longe, false)
	j.sumir()
	t = 0.0
	while j.oculto_s > 0.0 and t < 20.0:
		m.tick(0.1)
		t += 0.1
	_ok(t > 3.8 and t < 4.8, "andando sem parar dura %.1f s (MVP: cerca de 4,3 s)" % t)
	var o: Personagem = m.personagens[1]
	o.pos = j.pos + Vector2(2, 0)
	j.rota = []
	j.sumir()
	o.vistos.erase(j.id)
	m._perceber(o)
	_ok(not o.vistos.has(j.id), "oculto, ninguém vê você")
	j.oculto_s = 0.0
	m._perceber(o)
	_ok(o.vistos.has(j.id), "sem estar oculto, é visto")
	m.pegadas = [{"id": 999, "pos": o.pos, "dir": Vector2.UP, "dono": j.id, "calcado": j.calcado, "t": m.tempo, "vida": 20.0, "fraca": true}]
	o.atributos["furtividade"] = 2
	o.pegadas_vistas.erase(999)
	m._perceber(o)
	_ok(not o.pegadas_vistas.has(999), "pegada de quem andou oculto: Furtividade 2 não vê")
	o.atributos["furtividade"] = 4
	m._perceber(o)
	_ok(o.pegadas_vistas.has(999), "Furtividade 4 vê as pegadas fracas")

	print("== Lobo: oculto passa despercebido")
	m = _mundo(9)
	j = m.jogador()
	var lobo := _so_o_lobo(m)
	var par := _perto_de_base(m)
	_por_no(j, m, par.x)
	lobo.pos = j.pos + Vector2(8, 0)
	lobo.estado = "ronda"
	lobo.caminho = [lobo.pos]
	j.sumir()
	m.tick(0.1)
	_ok(lobo.estado == "ronda", "o lobo que ronda não percebe quem sumiu na mata")
	j.oculto_s = 0.0
	m.tick(0.1)
	_ok(lobo.estado == "rosnando", "visível, ele rosna")

	print("== Lobo: faro, refúgio e porta dos fundos")
	var resultados := {}
	var refugios := 0
	var esperas := []
	for semente in range(20, 60):
		m = _mundo(semente, {"forca": 4})
		j = m.jogador()
		lobo = _so_o_lobo(m)
		par = _perto_de_base(m)
		if par.x < 0:
			continue
		var avisou := [false]
		m.refugio.connect(func(p): avisou[0] = true)
		_por_no(j, m, par.x)
		lobo.pos = j.pos + Vector2(1, 0)
		lobo.alvo = j.id
		m.fauna._derrubar(lobo, j)
		var estado_inicial := lobo.estado
		# Corre para a base
		j.ir_para(m.mapa, par.y, false)
		var fim := "?"
		var t0 := m.tempo
		for i in 900:
			m.tick(0.1)
			if lobo.estado == "porta":
				fim = "chegou à base"
				break
			if lobo.estado == "ronda":
				fim = "derrubado de novo" if j.espera > 0.0 else "o lobo desistiu"
				break
		resultados[fim] = resultados.get(fim, 0) + 1
		if semente == 20:
			_ok(estado_inicial == "farejando", "depois de derrubar, o lobo segue o faro")
		if fim == "chegou à base":
			if avisou[0]:
				refugios += 1
			# Espera lá dentro até ele cansar
			var t_porta := m.tempo
			while m.fauna.lobo_a_porta(j) != null and m.tempo - t_porta < 200.0:
				m.tick(0.1)
			esperas.append(m.tempo - t_porta)
	print("  Correndo para a base depois da mordida: ", resultados)
	_ok(resultados.get("chegou à base", 0) > 0, "dá para chegar a uma base com o lobo no faro")
	_ok(refugios == resultados.get("chegou à base", 0), "a cena é avisada (refúgio) sempre que o lobo fica à porta")
	if not esperas.is_empty():
		_ok(esperas.all(func(e): return absf(e - Regras.LOBO_ESPERA_PORTA_S) < 1.0), "esperar lá dentro custa %.0f s da noite" % esperas[0])

	# Sair pela frente com o lobo à porta: ele persegue
	m = _mundo(31)
	j = m.jogador()
	lobo = _so_o_lobo(m)
	par = _perto_de_base(m)
	_por_no(j, m, par.y)
	lobo.alvo = j.id
	lobo.pos = j.pos + Vector2(12, 0)
	m.fauna._esperar_porta(lobo, j)
	_ok(m.fauna.lobo_a_porta(j) == lobo, "na base, o lobo espera à porta")
	j.ir_para(m.mapa, par.x, false)
	var perseguiu := false
	for i in 40:
		m.tick(0.1)
		if lobo.estado == "perseguindo" or j.fatos_noite.has("lobo_derrubou"):
			perseguiu = true
			break
	_ok(perseguiu, "saiu pela frente: o lobo ataca")

	# Porta dos fundos: Furtividade decide
	for furt in [1, 5]:
		var escapou := 0
		for k in 150:
			m = _mundo(1000 + k, {"furtividade": furt})
			j = m.jogador()
			lobo = _so_o_lobo(m)
			par = _perto_de_base(m)
			_por_no(j, m, par.y)
			lobo.alvo = j.id
			m.fauna._esperar_porta(lobo, j)
			if m.fauna.sair_fundos(j):
				escapou += 1
		var esperado: float = 1.0 - Regras.nivel(Regras.LOBO_PERCEBE_FUNDOS, furt)
		_ok(absf(escapou / 150.0 - esperado) < 0.12, "fundos com Furtividade %d: escapa %d%% (esperado %d%%)" % [furt, roundi(escapou / 1.5), roundi(esperado * 100)])

	print("== Guardiões e o estado de quem chega")
	for base in ["iara", "marta", "bento", "anselmo"]:
		m = _mundo(3)
		j = m.jogador()
		var normal := Visita.new(m, j, base).afinidade
		j.ferido_s = 60.0
		var ferido := Visita.new(m, j, base).afinidade
		_ok(ferido - normal == int(Regras.REACAO_ESTADO.get(base, 0)), "%s: ferido muda a afinidade inicial em %+d" % [base, ferido - normal])
	m = _mundo(3)
	j = m.jogador()
	m.envenenar(j)
	var v := Visita.new(m, j, "iara")
	_ok(v.reagiu_estado == 1 and v.abertura.any(func(e): return e["texto"] == Regras.REACAO_ESTADO_TEXTO["iara"]), "envenenado: Iara reage e a cena mostra a reação")

	print("== Noites completas (todos no computador)")
	var tot := {"noites": 0, "desmaios": 0, "chegaram": 0, "personagens": 0, "porta": 0, "derrubados": 0, "doses": [0, 0, 0, 0]}
	for semente in range(100, 140):
		m = _mundo(semente, {"resistencia": 2, "carisma": 1})
		j = m.jogador()
		j.eh_jogador = false
		j.perfil = ["cauteloso", "ousado", "trapaceiro"][semente % 3]
		while not m.terminou:
			m.tick(0.1)
		tot["noites"] += 1
		for p in m.personagens:
			tot["personagens"] += 1
			if p.desmaiado:
				tot["desmaios"] += 1
			if p.registrou():
				tot["chegaram"] += 1
			if p.fatos_noite.has("lobo_esperou_porta"):
				tot["porta"] += 1
			if p.fatos_noite.has("lobo_derrubou"):
				tot["derrubados"] += 1
			tot["doses"][mini(p.doses_veneno, 3)] += 1
	print("  ", tot)
	_ok(tot["chegaram"] >= tot["personagens"] * 0.75, "a maioria dos personagens do computador ainda chega à saída")

	print("RESULTADO: ", "OK" if falhas == 0 else "%d FALHA(S)" % falhas)
	quit(1 if falhas > 0 else 0)
