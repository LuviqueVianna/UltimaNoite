extends SceneTree
## Desenha os 5 calçados lado a lado sobre o pergaminho (precisa de tela; use xvfb-run).

class Amostra extends MapaView:
	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), COR_PAPEL)
		var j: Personagem = mundo.jogador()
		var calcados := Regras.CALCADOS.keys()
		for i in calcados.size():
			for k in 4:
				var lado := -1.0 if k % 2 == 0 else 1.0
				var g := {"pos": Vector2(8 + i * 15 + lado * 1.2, 34 - k * 5), "dir": Vector2.UP, "dono": 99, "id": k, "calcado": calcados[i], "t": mundo.tempo, "vida": 100.0}
				_desenhar_pegada(g, j)

func _init() -> void:
	var saida: String = OS.get_cmdline_user_args()[0]
	var m := Mundo.new()
	m.iniciar(7, {"nome": "A", "atributos": {"forca": 2, "inteligencia": 3, "carisma": 2, "furtividade": 5, "resistencia": 2}})
	var a := Amostra.new()
	a.mundo = m
	a.fonte = ThemeDB.fallback_font
	a.scale = Vector2(4, 4)
	print(Regras.CALCADOS.keys())
	root.add_child(a)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(saida)
	quit()
