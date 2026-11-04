extends SceneTree
## Teste sem tela: o mundo do MVP e o terreno 3D sobem juntos; mede o tempo de cada parte.
func _init() -> void:
	var t0 := Time.get_ticks_msec()
	var m := Mundo.new()
	m.iniciar(7, {"nome": "Teste", "atributos": {"forca": 2, "inteligencia": 3, "carisma": 2, "furtividade": 3, "resistencia": 2}})
	var t1 := Time.get_ticks_msec()
	print("mundo ok ", t1 - t0)
	var T = load("res://scripts/logica/terreno.gd")
	var ter = T.new(m.mapa, 7)
	var t2 := Time.get_ticks_msec()
	print("mapa %s m · %d nós · %d trilhas · bases %s" % [m.mapa.tamanho, m.mapa.nos.size(), m.mapa.arestas.size(), m.mapa.bases().keys()])
	print("mata: %d árvores · %d plantas" % [ter.arvores.size(), ter.plantas.size()])
	print("animais: %s" % [m.fauna.animais.map(func(a): return a.tipo)])
	print("armadilhas: %d" % m.armadilhas.lista.size())
	print("tempo: mundo %d ms · terreno %d ms" % [t1 - t0, t2 - t1])
	var falhas := 0
	for b in ter.casas:
		var c: Vector2 = ter.casas[b]["centro"]
		if ter.tipo_em(c) == ter.MATA: falhas += 1; print("casa no mato: ", b)
	for k in 600:
		m.dirigir_jogador(Vector2(1, 0.3))
		m.tick(0.1)
	print("jogador andou até ", m.jogador().pos, " · pegadas no mundo: ", m.pegadas.size())
	print("FALHAS=", falhas)
	quit(falhas)
