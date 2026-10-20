extends SceneTree
## Testes da etapa 1, sem tela:
##   godot --headless --path godot -s res://testes/teste_etapa1.gd

var falhas := 0


func _init() -> void:
	_testar_gerador(300)
	_testar_noite(3)
	print("RESULTADO: %s" % ("OK" if falhas == 0 else "%d falha(s)" % falhas))
	quit(1 if falhas > 0 else 0)


func _checar(cond: bool, msg: String) -> void:
	if not cond:
		falhas += 1
		printerr("FALHA: " + msg)


func _testar_gerador(n: int) -> void:
	var stats := {"clareiras": [], "becos": [], "arestas_max": 0.0, "comp_total": []}
	var g := GeradorMapa.new()
	for semente in n:
		var m := g.gerar(semente)
		_checar(m != null, "semente %d sem mapa" % semente)
		if m == null:
			continue
		var clareiras := m.nos.filter(func(x): return x["tipo"] == "clareira").size()
		var becos := m.nos.filter(func(x): return x["tipo"] == "beco").size()
		stats["clareiras"].append(clareiras)
		stats["becos"].append(becos)
		stats["comp_total"].append(m.comprimento_total())
		_checar(clareiras >= 10 and clareiras <= 12, "semente %d: %d clareiras" % [semente, clareiras])
		_checar(m.bases().size() == 6, "semente %d: %d bases" % [semente, m.bases().size()])
		_checar(m.partidas().size() == 4, "semente %d: %d partidas" % [semente, m.partidas().size()])
		_checar(m.saidas.size() == 4, "semente %d: %d saídas" % [semente, m.saidas.size()])
		for pa in m.saidas:
			stats.get_or_add("dist_saida", []).append(m.distancia_grafo(pa, m.saidas[pa]))
		for e in m.arestas:
			stats["arestas_max"] = maxf(stats["arestas_max"], e["comp"])
		# Tudo ligado
		for b in m.bases().values():
			_checar(not m.caminho(m.partidas()[0], b).is_empty(), "semente %d: base inalcançável" % semente)
		# Nenhuma trilha cruza outra
		for i in m.arestas.size():
			for j in range(i + 1, m.arestas.size()):
				var a: Dictionary = m.arestas[i]
				var b: Dictionary = m.arestas[j]
				if a["a"] in [b["a"], b["b"]] or a["b"] in [b["a"], b["b"]]:
					continue
				if Geometry2D.segment_intersects_segment(m.pos(a["a"]), m.pos(a["b"]), m.pos(b["a"]), m.pos(b["b"])) != null:
					_checar(false, "semente %d: trilhas %d e %d se cruzam" % [semente, i, j])
	print("Saídas: caminho até a saída %.0f-%.0f m (%.0f-%.0f s andando)" % [stats["dist_saida"].min(), stats["dist_saida"].max(), stats["dist_saida"].min() / Regras.VEL_TRILHA, stats["dist_saida"].max() / Regras.VEL_TRILHA])
	_checar(stats["arestas_max"] <= 41.0, "trecho de trilha com %.1f m" % stats["arestas_max"])
	print("Gerador: %d mapas | clareiras %d-%d | becos %d-%d | trilhas %.0f-%.0f m | maior trecho %.1f m" % [
		n, stats["clareiras"].min(), stats["clareiras"].max(), stats["becos"].min(), stats["becos"].max(),
		stats["comp_total"].min(), stats["comp_total"].max(), stats["arestas_max"]])


func _testar_noite(n: int) -> void:
	for semente in n:
		var mundo := Mundo.new()
		mundo.iniciar(1000 + semente, {"nome": "Teste", "atributos": {"forca": 2, "inteligencia": 3, "carisma": 2, "furtividade": 3, "resistencia": 2}})
		mundo.jogador().eh_jogador = false   # o jogador também anda sozinho no teste
		mundo.jogador().perfil = "ousado"
		var pico_pegadas := 0
		var dt := 1.0 / 30.0
		var passos := 0
		while not mundo.terminou and passos < 40000:
			passos += 1
			mundo.tick(dt)
			pico_pegadas = maxi(pico_pegadas, mundo.pegadas.size())
		var visitas := []
		var vistos := []
		for p in mundo.personagens:
			visitas.append(p.bases_visitadas.size())
			vistos.append(p.vistos.size())
			var percorrido := 0
			for b in p.amostra_percorrida:
				percorrido += b
			_checar(percorrido > 50, "noite %d: %s quase não andou (%d amostras)" % [semente, p.nome, percorrido])
		_checar(visitas.max() >= 2, "noite %d: ninguém visitou 2 bases %s" % [semente, visitas])
		print("Noite %d: bases visitadas %s | personagens vistos %s | pico de pegadas %d" % [semente, visitas, vistos, pico_pegadas])
