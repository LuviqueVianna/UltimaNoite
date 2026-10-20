extends SceneTree
## Gera uma imagem do jogo depois de alguns minutos de noite (precisa de tela; use xvfb-run).
##   xvfb-run godot --path godot -s res://testes/captura.gd -- saida.png 150

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var saida: String = args[0] if args.size() > 0 else "user://captura.png"
	var segundos: float = float(args[1]) if args.size() > 1 else 150.0
	var main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.campo_nome.text = "Luvique"
	main._validar_inicio()
	main._comecar()
	var j: Personagem = main.mundo.jogador()
	j.eh_jogador = false
	j.perfil = "ousado"
	var t := 0.0
	var passo := 0
	while t < segundos:
		main.mundo.tick(1.0 / 30.0)
		t += 1.0 / 30.0
		passo += 1
		if passo % 6 == 0:
			main.vista._revelar()
	j.eh_jogador = true
	if args.size() > 2 and args[2] == "dialogo_longo":
		# Procura uma pergunta com resposta longa ou opção extra, para conferir o layout
		main.dialogo.abrir(main.mundo, "iara")
		main.dialogo._entrar("frente")
		var v: Visita = main.dialogo.visita
		for e in Dados.guardiao("iara")["entradas"]:
			if e["id"] == "iara_09":
				v.perguntas = [e]
		v.indice = 0
		j.atributos = {"forca": 1, "inteligencia": 4, "carisma": 4, "furtividade": 2, "resistencia": 1}
		main.dialogo._mostrar_pergunta("")
	if args.size() > 2 and args[2] == "dialogo":
		var b: String = main.mundo.mapa.bases().keys().filter(func(x): return x != "vazia" and not j.bases_visitadas.has(x))[0]
		main.dialogo.abrir(main.mundo, b)
		main.dialogo._olhar_janela()
		main.dialogo._entrar("frente")
		main.dialogo._responder("1")
	if args.size() > 2 and args[2] == "longe":
		main.camera.zoom = Vector2(0.75, 0.75)
	if args.size() > 2 and args[2] == "media":
		main.camera.zoom = Vector2(1.3, 1.3)
	if args.size() > 2 and args[2] == "perto":
		main.camera.zoom = Vector2(3.2, 3.2)
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(saida)
	print("Captura salva em ", saida)
	quit()
