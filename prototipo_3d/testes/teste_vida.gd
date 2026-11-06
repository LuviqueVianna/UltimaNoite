extends SceneTree
## Teste sem tela: vida (armadilha, lobo, cobra, cura na casa) e os personagens do computador andando.
func _init() -> void:
	var cena = load("res://cenas/prototipo.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	cena.pausado = true
	var m = cena.mundo
	var j = m.jogador()
	var falhas := 0
	# armadilha: põe o jogador em cima de uma
	var a = m.armadilhas.lista[0]
	j.pos = a.pos + Vector2(0.2, 0)
	m.tick(0.1)
	print("depois da armadilha: vida %.0f · preso %.1f s · lento %.1f s" % [j.vida, j.espera, j.lento_s])
	if j.vida != 80.0: falhas += 1
	# casa nova: chega no nó de uma base
	var bases: Dictionary = m.mapa.bases()
	var no: int = bases[bases.keys()[0]]
	j.espera = 0.0
	j.pos = m.mapa.pos(no) + Vector2(5, 0)
	for k in 30:
		m.mover_jogador_livre(m.mapa.pos(no) - j.pos, 0.1, func(_p): return true)
		m.tick(0.1)
	print("depois da casa %s: vida %.0f" % [bases.keys()[0], j.vida])
	if j.vida != 100.0: falhas += 1
	# na mesma casa de novo: não cura de novo
	m.ferir(j, 50.0)
	m._curar_na_casa(j, bases.keys()[0])
	if j.vida != 50.0: falhas += 1
	# vida zero desmaia
	m.ferir(j, 60.0)
	print("vida zero: desmaiado=%s" % j.desmaiado)
	if not j.desmaiado: falhas += 1
	# personagens do computador: quanto andam em 8 minutos de noite
	var inicio := {}
	for p in m.personagens:
		inicio[p.id] = p.pos
	var andado := {}
	for k in 4800:
		var antes := {}
		for p in m.personagens:
			antes[p.id] = p.pos
		m.tick(0.1)
		for p in m.personagens:
			andado[p.id] = andado.get(p.id, 0.0) + p.pos.distance_to(antes[p.id])
	for p in m.personagens:
		if p.eh_jogador:
			continue
		print("%s: andou %d m · bases visitadas %s · vida %.0f" % [p.nome, int(andado[p.id]), p.bases_visitadas.keys(), p.vida])
		if andado[p.id] < 200.0: falhas += 1
	print("FALHAS=", falhas)
	quit(falhas)
