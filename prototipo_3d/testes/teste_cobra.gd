extends SceneTree
## Teste com a cena inteira (sem tela): o jogador anda livre até cada cobra e passa por ela.
## Pega erros de script da lógica e da apresentação no caminho.
func _init() -> void:
	var cena = load("res://cenas/prototipo.tscn").instantiate()
	root.add_child(cena)
	await process_frame
	cena.pausado = true
	var m = cena.mundo
	var j = m.jogador()
	var avisos := []
	m.aviso.connect(func(t): avisos.append(t))
	for a in m.fauna.animais:
		if a.tipo != "cobra":
			continue
		# leva o jogador para perto da cobra pela trilha mais próxima e anda na direção dela
		var achou := false
		for r in range(12, 6, -1):
			for k in 36:
				var q: Vector2 = a.pos + Vector2(r, 0).rotated(TAU * k / 36.0)
				if cena.terreno.andavel(q) and cena.terreno.ve(q, a.pos):
					j.pos = q
					achou = true
					break
			if achou:
				break
		for k in 240:
			m.mover_jogador_livre(a.pos - j.pos if j.pos.distance_to(a.pos) > 0.5 else Vector2(1, 0), 1.0 / 30.0, cena.terreno.andavel)
			m.tick(1.0 / 30.0)
			await process_frame
		print("cobra %d: jogador terminou a %.1f m · avisado=%s" % [a.id, j.pos.distance_to(a.pos), a.avisado.has(j.id)])
	print("avisos: ", avisos)
	print("doses de veneno: ", j.doses_veneno)
	quit()
