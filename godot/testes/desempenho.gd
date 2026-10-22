extends SceneTree
## Mede quadros por segundo com a névoa ligada, o jogador andando sozinho pelo mapa.
##   xvfb-run godot --path godot --rendering-driver opengl3 -s res://testes/desempenho.gd
func _init() -> void:
	var main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.campo_nome.text = "Luvique"
	main._validar_inicio()
	main._comecar()
	main.sobreposicao.visible = false   # fecha o tutorial da primeira vez
	var j: Personagem = main.mundo.jogador()
	j.eh_jogador = false   # anda sozinho, como um personagem do computador
	j.perfil = "ousado"
	if OS.get_cmdline_user_args().has("sem_shader"):
		main.vista.fundo.material = null
	var a_ := OS.get_cmdline_user_args()
	if a_.has("sem_vista"):
		main.vista.visible = false
	if a_.has("sem_viva"):
		main.vista.camada_viva.visible = false
	if a_.has("sem_blocos"):
		for b in main.vista.blocos.values(): b.visible = false
	if a_.has("sem_nevoa"):
		main.vista.alternar_nevoa()
	if a_.has("sem_hud"):
		main.hud.visible = false
	var t_tick := 0
	for i in 120:
		var t0 := Time.get_ticks_usec()
		main.mundo.tick(1.0 / 60.0)
		t_tick += Time.get_ticks_usec() - t0
	print("  mundo.tick: %.2f ms" % (t_tick / 120.0 / 1000.0))
	var inicio := Time.get_ticks_usec()
	var quadros := 0
	var pior := 0
	var proc := 0.0
	var chamadas := 0.0
	var prim := 0.0
	var antes := Time.get_ticks_usec()
	while Time.get_ticks_usec() - inicio < 20_000_000:
		await process_frame
		var agora := Time.get_ticks_usec()
		pior = maxi(pior, agora - antes)
		antes = agora
		quadros += 1
		proc += Performance.get_monitor(Performance.TIME_PROCESS)
		chamadas += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		prim += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	var s := (Time.get_ticks_usec() - inicio) / 1_000_000.0
	print("Desempenho: %.1f quadros/s em média, pior quadro %.0f ms, árvores visíveis %d de %d" % [quadros / s, pior / 1000.0, main.vista.arvores.filter(func(a): return a["visivel"]).size(), main.vista.arvores.size()])
	print("  processamento %.1f ms/quadro, %.0f chamadas de desenho, %.0f primitivas por quadro" % [proc / quadros * 1000.0, chamadas / quadros, prim / quadros])
	quit()
