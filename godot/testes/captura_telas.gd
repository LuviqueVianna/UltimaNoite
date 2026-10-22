extends SceneTree
## Imagens das telas de tutorial e configurações (precisa de tela; use xvfb-run).
##   xvfb-run godot --path godot -s res://testes/captura_telas.gd -- pasta_de_saida
func _init() -> void:
	var pasta: String = OS.get_cmdline_user_args()[0]
	var main = load("res://cenas/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	for n in Tutorial.PAGINAS.size():
		main._abrir(main.tutorial)
		main.tutorial._mostrar(n)
		await _salvar("%s/tutorial_%d.png" % [pasta, n + 1])
	main._abrir(main.configuracoes)
	await _salvar(pasta + "/configuracoes.png")
	main.sobreposicao.visible = false
	await _salvar(pasta + "/inicio.png")
	quit()


func _salvar(caminho: String) -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(caminho)
	print("salvo ", caminho)
