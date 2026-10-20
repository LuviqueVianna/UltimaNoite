class_name MapaView
extends Node2D
## Desenha a noite do ponto de vista do jogador: só o que ele percorreu, vê agora ou ainda lembra.
## Visual provisório até a escolha do estilo de pergaminho (demanda 3 do ChatGPT).

signal toque(ponto_m: Vector2)

const ESCALA := 4.0          # px por metro
const COR_NOITE := Color("#0e1a2b")
const COR_PAPEL := Color("#e8d9b5")
const COR_TINTA := Color("#d9c79a")
const COR_AMBAR := Color("#e89a3c")
const COR_MATA := Color("#1f3328")
const LARGURA_TRILHA := 1.6  # m
const GLIFO := 1.8           # pegadas desenhadas maiores que o real, para leitura

var mundo: Mundo
var fonte: Font


func _ready() -> void:
	fonte = ThemeDB.fallback_font


func _process(_dt: float) -> void:
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var pressionou: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if pressionou:
		toque.emit(get_global_mouse_position() / ESCALA)


func _draw() -> void:
	if mundo == null:
		return
	var j := mundo.jogador()
	var m := mundo.mapa
	var agora := mundo.tempo
	var lembra := j.lembranca()

	draw_rect(Rect2(Vector2(-200, -200), (m.tamanho + Vector2(400, 400)) * ESCALA), COR_NOITE)
	draw_circle(j.pos * ESCALA, j.alcance() * ESCALA, Color(COR_MATA, 0.55))

	# Trilhas: percorridas ficam; vistas de longe somem com o tempo.
	for e in m.arestas:
		var pa := m.pos(e["a"])
		var pb := m.pos(e["b"])
		var n: int = e["amostra_fim"] - e["amostra_ini"]
		for k in n:
			var i: int = e["amostra_ini"] + k
			var alfa := 0.0
			if j.amostra_percorrida[i] == 1:
				alfa = 0.9
			else:
				var idade := agora - j.amostra_vista[i]
				if idade <= lembra:
					alfa = 0.75 * (1.0 - idade / lembra)
			if alfa <= 0.01:
				continue
			var a := pa.lerp(pb, float(k) / n)
			var b := pa.lerp(pb, float(k + 1) / n)
			draw_line(a * ESCALA, b * ESCALA, Color(COR_TINTA, alfa), LARGURA_TRILHA * ESCALA)

	# Clareiras e bases conhecidas
	for no in m.nos:
		if j.no_visto[no["id"]] == 0:
			continue
		var p: Vector2 = no["pos"] * ESCALA
		match no["tipo"]:
			"clareira":
				draw_circle(p, 8.0 * ESCALA, Color(COR_PAPEL, 0.12))
				draw_arc(p, 8.0 * ESCALA, 0, TAU, 32, Color(COR_PAPEL, 0.5), 1.5)
			"beco":
				draw_line(p + Vector2(-6, -6), p + Vector2(6, 6), Color(COR_PAPEL, 0.6), 2)
				draw_line(p + Vector2(-6, 6), p + Vector2(6, -6), Color(COR_PAPEL, 0.6), 2)
		if no["base"] != "":
			_desenhar_base(no["pos"], no["base"])

	# Luzes vistas de longe (sem a trilha até elas)
	for b in j.luzes:
		var no_base: int = m.bases()[b]
		if j.no_visto[no_base] == 1:
			continue
		var p: Vector2 = j.luzes[b] * ESCALA
		draw_circle(p, 9, Color(COR_AMBAR, 0.18))
		draw_circle(p, 4, COR_AMBAR)

	# Saída do jogador: ele sabe para onde precisa ir, não o caminho.
	_desenhar_saida(m.pos(j.saida))

	# Pegadas
	for g in mundo.pegadas:
		if mundo.pegada_visivel_para(j, g):
			_desenhar_pegada(g, j)

	# Personagens
	for o in mundo.personagens:
		if o.eh_jogador:
			continue
		if agora - j.vistos.get(o.id, -1.0e9) > Regras.PERCEPCAO_INTERVALO * 1.5:
			continue
		draw_circle(o.pos * ESCALA, 1.2 * ESCALA, Color(COR_PAPEL, 0.9))
		draw_string(fonte, o.pos * ESCALA + Vector2(8, -8), o.nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, COR_PAPEL)
	draw_circle(j.pos * ESCALA, 1.4 * ESCALA, COR_AMBAR)
	draw_arc(j.pos * ESCALA, 1.4 * ESCALA, 0, TAU, 24, COR_NOITE, 2)
	if not j.rota.is_empty():
		var alvo := m.pos(j.rota[-1]) * ESCALA
		draw_arc(alvo, 10, 0, TAU, 24, Color(COR_AMBAR, 0.7), 2)


## Planta baixa provisória: casa, porta da frente (baixo), fundos (cima), janela (lado) e esconderijo.
func _desenhar_base(pos_m: Vector2, base: String) -> void:
	var c := pos_m * ESCALA
	var tam := Vector2(10, 7) * ESCALA
	var r := Rect2(c - tam / 2, tam)
	var luz := base != "vazia"
	draw_rect(r, Color(COR_PAPEL, 0.18))
	draw_rect(r, COR_PAPEL, false, 2)
	draw_rect(Rect2(c + Vector2(-1.2, tam.y / 2 / ESCALA - 0.4) * ESCALA, Vector2(2.4, 0.8) * ESCALA), COR_PAPEL)        # frente
	draw_rect(Rect2(c + Vector2(-1.0, -tam.y / 2 / ESCALA - 0.4) * ESCALA, Vector2(2.0, 0.8) * ESCALA), COR_PAPEL)       # fundos
	draw_rect(Rect2(c + Vector2(tam.x / 2 / ESCALA - 0.4, -1.2) * ESCALA, Vector2(0.8, 2.4) * ESCALA), COR_AMBAR if luz else COR_PAPEL)  # janela
	draw_circle(c + Vector2(-9, -6) * ESCALA, 2.2 * ESCALA, Color(COR_MATA, 0.9))                                         # esconderijo
	draw_string(fonte, c + Vector2(-tam.x / 2, -tam.y / 2 - 3.5 * ESCALA), Regras.BASES[base], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_PAPEL)


## Porteira de duas estacas com travessa: o ponto oposto do mapa, onde se registra a chegada.
func _desenhar_saida(pos_m: Vector2) -> void:
	var c := pos_m * ESCALA
	var cor := Color(COR_AMBAR, 0.9)
	draw_circle(c, 7.0 * ESCALA, Color(COR_AMBAR, 0.08))
	draw_line(c + Vector2(-3, -2) * ESCALA, c + Vector2(-3, 2.5) * ESCALA, cor, 3)
	draw_line(c + Vector2(3, -2) * ESCALA, c + Vector2(3, 2.5) * ESCALA, cor, 3)
	draw_line(c + Vector2(-3, -1) * ESCALA, c + Vector2(3, -1) * ESCALA, cor, 2)
	draw_line(c + Vector2(-3, 1) * ESCALA, c + Vector2(3, 1) * ESCALA, cor, 2)
	draw_string(fonte, c + Vector2(-14, -4 * ESCALA), "Saída", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_AMBAR)


func _desenhar_pegada(g: Dictionary, j: Personagem) -> void:
	var minha: bool = g["dono"] == j.id
	var leitura := 5 if minha else j.leitura_pegadas()
	var cor := COR_AMBAR if minha else COR_PAPEL
	var alfa := 0.85
	if leitura >= 3 or minha:
		alfa = clampf(1.0 - (mundo.tempo - g["t"]) / g["vida"], 0.15, 0.9)
	if minha:
		alfa *= 0.55
	var angulo: float = g["dir"].angle() + PI / 2 if leitura >= 2 else 0.0
	draw_set_transform(g["pos"] * ESCALA, angulo, Vector2.ONE * ESCALA * GLIFO)
	var c := Color(cor, alfa)
	match g["calcado"]:
		"bota":
			_elipse(Vector2.ZERO, Vector2(0.38, 0.8), c)
		"botina":
			_elipse(Vector2(0, -0.12), Vector2(0.32, 0.55), c)
			draw_rect(Rect2(Vector2(-0.26, 0.45), Vector2(0.52, 0.3)), c)
		"alpercata":
			_elipse(Vector2.ZERO, Vector2(0.2, 0.75), c)
		"tamanco":
			draw_rect(Rect2(Vector2(-0.34, -0.7), Vector2(0.68, 1.4)), c)
		"descalco":
			_elipse(Vector2(0, 0.1), Vector2(0.26, 0.5), c)
			for k in 3:
				draw_circle(Vector2(-0.18 + 0.18 * k, -0.55), 0.09, c)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _elipse(centro: Vector2, raio: Vector2, cor: Color) -> void:
	var pts := PackedVector2Array()
	for k in 12:
		var a := TAU * k / 12.0
		pts.append(centro + Vector2(cos(a) * raio.x, sin(a) * raio.y))
	draw_colored_polygon(pts, cor)
