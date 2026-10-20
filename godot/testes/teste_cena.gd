extends SceneTree
## Abre a cena principal, preenche a tela inicial e roda alguns segundos de noite.
##   godot --headless --path godot -s res://testes/teste_cena.gd

func _init() -> void:
	var main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.campo_nome.text = "Luvique"
	main._validar_inicio()
	assert(not main.botao_comecar.disabled)
	main._comecar()
	for i in 240:
		await process_frame
	var j: Personagem = main.mundo.jogador()
	var inicio := j.pos
	var alvo := -1
	for v in main.mundo.mapa.adj[j.no_atual]:
		alvo = v.x
	main.mundo.jogador().no_visto[alvo] = 1
	main.mundo.jogador().aresta_conhecida[main.mundo.mapa.aresta_entre(j.no_atual, alvo)] = 1
	var ok: bool = main.mundo.mover_jogador_para(main.mundo.mapa.pos(alvo))
	for i in 600:
		await process_frame
	print("Cena: tempo %.1f s | jogador andou: %s | rota aceita: %s | avisos: %s" % [main.mundo.tempo, j.pos.distance_to(inicio) > 1.0, ok, main.avisos])
	quit()
