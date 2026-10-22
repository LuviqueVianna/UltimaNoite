extends SceneTree
## Noites só com o computador para ver os encontros com os animais.
##   godot --headless --path godot -s res://testes/teste_animais.gd

func _init() -> void:
	var totais := {}
	var avisos: Array = []
	var picadas := 0
	var derrubadas := 0
	for semente in [11, 22, 33, 44, 55, 66]:
		var m := Mundo.new()
		m.iniciar(semente, {"nome": "Teste", "atributos": {"forca": 2, "inteligencia": 3, "carisma": 3, "furtividade": 2, "resistencia": 2}})
		m.aviso.connect(func(t): avisos.append(t))
		# O jogador anda sozinho como se fosse do computador
		var j := m.jogador()
		j.eh_jogador = false
		j.perfil = "ousado"
		while not m.terminou:
			m.tick(0.1)
		j.eh_jogador = true
		for p in m.personagens:
			for f in p.fatos_noite:
				var chave := "%s=%s" % [f, p.fatos_noite[f]]
				totais[chave] = totais.get(chave, 0) + 1
	var chaves := totais.keys()
	chaves.sort()
	for k in chaves:
		print("  ", k, ": ", totais[k])
	print("Avisos ao jogador (amostra): ", avisos.slice(0, 12))
	quit()
