class_name MapaView
extends Node2D
## Desenha a noite do ponto de vista do jogador. Onde ele andou e enxergou, a névoa se abre
## e aparece o pergaminho bege manchado, com trilhas em tinta marrom e pegadas pretas de sola e salto.
## Direção de arte pedida pelo usuário em 20/10/2026.

signal toque(ponto_m: Vector2)

const ESCALA := 4.0           # px por metro
const MARGEM := 40.0          # m de névoa em volta da área do mapa
const COR_NOITE := Color("#0e1a2b")
const COR_PAPEL := Color("#dcc596")
const COR_TINTA := Color("#4a321c")
const COR_TINTA_CLARA := Color("#7a5a36")
const COR_PEGADA := Color("#1a120b")
const COR_MINHA := Color("#5c2a14")
const COR_AMBAR := Color("#e89a3c")
const COR_MEMORIA := Color("#cdb88c")   # trilha lembrada, vista sobre a névoa
const LARGURA_TRILHA := 0.45  # m (discreta, para não competir com as pegadas)
const GLIFO := 6.0            # pegadas desenhadas maiores que o real, para leitura

var mundo: Mundo
var fonte: Font
var fundo: ColorRect
var mascara: Image
var textura_mascara: ImageTexture
var _acumulado := 0.0
var arvores: Array = []        # {pos, raio, tipo, visivel}; só desenho, a mata já é parede nas regras
var camada_arvores: Node2D     # redesenhada só quando aparecem árvores novas


## Camada separada para a mata: o Godot guarda o desenho e só refaz quando pedimos.
class CamadaArvores extends Node2D:
	var vista: MapaView
	func _draw() -> void:
		for a in vista.arvores:
			if a["visivel"]:
				vista._desenhar_arvore_em(self, a)


func _ready() -> void:
	fonte = ThemeDB.fallback_font


func preparar(m: Mundo) -> void:
	mundo = m
	var area := mundo.mapa.tamanho + Vector2.ONE * MARGEM * 2.0
	mascara = Image.create(int(area.x), int(area.y), false, Image.FORMAT_L8)
	mascara.fill(Color.BLACK)
	textura_mascara = ImageTexture.create_from_image(mascara)

	var ruido := NoiseTexture2D.new()
	ruido.width = 256
	ruido.height = 256
	ruido.seamless = true
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = 0.012
	fn.fractal_octaves = 4
	fn.seed = mundo.mapa.semente
	ruido.noise = fn

	var material := ShaderMaterial.new()
	material.shader = load("res://cenas/pergaminho.gdshader")
	material.set_shader_parameter("mascara", textura_mascara)
	material.set_shader_parameter("ruido", ruido)
	material.set_shader_parameter("tamanho_m", area)

	fundo = ColorRect.new()
	fundo.material = material
	fundo.position = -Vector2.ONE * MARGEM * ESCALA
	fundo.size = area * ESCALA
	fundo.show_behind_parent = true
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fundo)
	camada_arvores = CamadaArvores.new()
	camada_arvores.vista = self
	camada_arvores.show_behind_parent = true
	add_child(camada_arvores)
	_plantar_arvores()
	_revelar()


func _process(dt: float) -> void:
	if mundo == null:
		return
	_acumulado += dt
	if _acumulado >= Regras.PERCEPCAO_INTERVALO:
		_acumulado = 0.0
		_revelar()
	var j := mundo.jogador()
	var mat := fundo.material as ShaderMaterial
	mat.set_shader_parameter("jogador_m", j.pos + Vector2.ONE * MARGEM)
	mat.set_shader_parameter("alcance", j.alcance())
	queue_redraw()


## Abre a névoa em volta do jogador, de forma permanente (borda suave).
func _revelar() -> void:
	var j := mundo.jogador()
	var centro := j.pos + Vector2.ONE * MARGEM
	var r := j.alcance() * 1.2
	var x0 := maxi(0, int(centro.x - r))
	var x1 := mini(mascara.get_width() - 1, int(centro.x + r))
	var y0 := maxi(0, int(centro.y - r))
	var y1 := mini(mascara.get_height() - 1, int(centro.y + r))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var d := centro.distance_to(Vector2(x + 0.5, y + 0.5))
			if d > r:
				continue
			var v := clampf((r - d) / (r * 0.45), 0.0, 1.0)
			if v > mascara.get_pixel(x, y).r:
				mascara.set_pixel(x, y, Color(v, v, v))
	textura_mascara.update(mascara)
	var novas := false
	for a in arvores:
		if not a["visivel"] and a["pos"].distance_to(j.pos) <= r * 0.78:
			a["visivel"] = true
			novas = true
	if novas and camada_arvores != null:
		camada_arvores.queue_redraw()


## Espalha a mata em volta das trilhas: copas vistas de cima, fora das trilhas e das clareiras.
## Sorteio fixo pela semente do mapa, para a mata ser a mesma a noite toda.
func _plantar_arvores() -> void:
	var m := mundo.mapa
	var rng := RandomNumberGenerator.new()
	rng.seed = m.semente * 7 + 3
	var segs := m.arestas.map(func(e): return [m.pos(e["a"]), m.pos(e["b"])])
	var clareiras := m.nos.filter(func(n): return n["tipo"] == "clareira").map(func(n): return n["pos"])
	var passo := 4.2
	var y := -MARGEM * 0.5
	while y < m.tamanho.y + MARGEM * 0.5:
		var x := -MARGEM * 0.5
		while x < m.tamanho.x + MARGEM * 0.5:
			var p := Vector2(x, y) + Vector2(rng.randf_range(-1.6, 1.6), rng.randf_range(-1.6, 1.6))
			x += passo
			var raio := rng.randf_range(1.5, 2.6)
			var ok := true
			for c in clareiras:
				if p.distance_to(c) < 9.0 + raio:
					ok = false
					break
			if ok:
				for sg in segs:
					if p.distance_to(Geometry2D.get_closest_point_to_segment(p, sg[0], sg[1])) < 2.2 + raio:
						ok = false
						break
			if ok:
				arvores.append({"pos": p, "raio": raio, "tipo": "palmeira" if rng.randf() < 0.22 else "copa",
					"giro": rng.randf() * TAU, "visivel": false})
		y += passo * 0.87


func revelado(p_m: Vector2) -> float:
	var q := p_m + Vector2.ONE * MARGEM
	var x := clampi(int(q.x), 0, mascara.get_width() - 1)
	var y := clampi(int(q.y), 0, mascara.get_height() - 1)
	var v := mascara.get_pixel(x, y).r
	if mundo.jogador().pos.distance_to(p_m) <= mundo.jogador().alcance() * 0.8:
		v = 1.0
	return v


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

	# Trilhas em tinta. Percorridas ficam; vistas de longe somem com o tempo.
	for e in m.arestas:
		var pa := m.pos(e["a"])
		var pb := m.pos(e["b"])
		var n: int = e["amostra_fim"] - e["amostra_ini"]
		for k in n:
			var i: int = e["amostra_ini"] + k
			var alfa := 0.0
			if j.amostra_percorrida[i] == 1:
				alfa = 0.32
			else:
				var idade := agora - j.amostra_vista[i]
				if idade <= lembra:
					alfa = 0.32 * (1.0 - idade / lembra)
			if alfa <= 0.01:
				continue
			var a := pa.lerp(pb, float(k) / n)
			var b := pa.lerp(pb, float(k + 1) / n)
			var cor := COR_TINTA_CLARA if revelado(m.amostras[i]) > 0.5 else COR_MEMORIA
			draw_line(a * ESCALA, b * ESCALA, Color(cor, alfa), LARGURA_TRILHA * ESCALA)

	# Clareiras e bases conhecidas
	for no in m.nos:
		if j.no_visto[no["id"]] == 0:
			continue
		var p: Vector2 = no["pos"] * ESCALA
		match no["tipo"]:
			"clareira":
				draw_circle(p, 8.0 * ESCALA, Color(COR_TINTA, 0.08))
				_arco_tracejado(p, 8.0 * ESCALA, Color(COR_TINTA, 0.7))
			"beco":
				var cor := Color(COR_TINTA, 0.8)
				draw_line(p + Vector2(-5, -5), p + Vector2(5, 5), cor, 2)
				draw_line(p + Vector2(-5, 5), p + Vector2(5, -5), cor, 2)
		if no["base"] != "":
			_desenhar_base(no["pos"], no["base"])

	# Luzes vistas de longe (sem a trilha até elas)
	for b in j.luzes:
		var no_base: int = m.bases()[b]
		if j.no_visto[no_base] == 1:
			continue
		var p: Vector2 = j.luzes[b] * ESCALA
		draw_circle(p, 12, Color(COR_AMBAR, 0.15))
		draw_circle(p, 4, COR_AMBAR)

	_desenhar_saida(m.pos(j.saida))

	for g in mundo.pegadas:
		if mundo.pegada_visivel_para(j, g):
			_desenhar_pegada(g, j)

	# Personagens
	for o in mundo.personagens:
		if o.eh_jogador:
			continue
		if agora - j.vistos.get(o.id, -1.0e9) > Regras.PERCEPCAO_INTERVALO * 1.5:
			continue
		draw_circle(o.pos * ESCALA, 1.3 * ESCALA, COR_TINTA)
		draw_string(fonte, o.pos * ESCALA + Vector2(9, -9), o.nome, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, COR_TINTA)
	draw_circle(j.pos * ESCALA, 1.5 * ESCALA, COR_AMBAR)
	draw_arc(j.pos * ESCALA, 1.5 * ESCALA, 0, TAU, 24, COR_TINTA, 2)
	if not j.rota.is_empty():
		var alvo := m.pos(j.rota[-1]) * ESCALA
		draw_arc(alvo, 10, 0, TAU, 24, Color(COR_MINHA, 0.8), 2)


## Copa vista de cima com borda recortada (folhagem), ou embaúba/palmeira em estrela.
func _desenhar_arvore_em(alvo: CanvasItem, a: Dictionary) -> void:
	var c: Vector2 = a["pos"] * ESCALA
	var r: float = a["raio"] * ESCALA
	var giro: float = a["giro"]
	var tinta := Color(COR_TINTA, 0.55)
	if a["tipo"] == "palmeira":
		var linhas := PackedVector2Array()
		for k in 7:
			var ang := giro + TAU * k / 7.0
			var ponta := c + Vector2(cos(ang), sin(ang)) * r
			linhas.append_array([c, ponta, ponta, ponta + Vector2(cos(ang + 0.9), sin(ang + 0.9)) * r * 0.3])
		alvo.draw_multiline(linhas, tinta, 1.3)
		alvo.draw_circle(c, r * 0.14, tinta)
		return
	alvo.draw_circle(c, r, Color(COR_TINTA, 0.09))
	var pts := PackedVector2Array()
	for k in 19:
		var ang := giro + TAU * k / 18.0
		var bico := 1.0 if k % 2 == 0 else 0.84
		pts.append(c + Vector2(cos(ang), sin(ang)) * r * bico)
	alvo.draw_polyline(pts, tinta, 1.3)
	alvo.draw_circle(c + Vector2(r * 0.15, r * 0.12), r * 0.12, Color(COR_TINTA, 0.45))


func _arco_tracejado(c: Vector2, r: float, cor: Color) -> void:
	for k in 24:
		if k % 2 == 0:
			draw_arc(c, r, TAU * k / 24.0, TAU * (k + 1) / 24.0, 4, cor, 1.5)


## Planta baixa: casa em tinta, porta da frente (baixo), fundos (cima), janela acesa (lado) e moita de esconderijo.
func _desenhar_base(pos_m: Vector2, base: String) -> void:
	var c := pos_m * ESCALA
	var tam := Vector2(10, 7) * ESCALA
	var r := Rect2(c - tam / 2, tam)
	draw_rect(r, Color(COR_TINTA, 0.12))
	draw_rect(r, COR_TINTA, false, 2.5)
	draw_line(c + Vector2(-tam.x / 2, 0), c + Vector2(tam.x / 2 - 3 * ESCALA, 0), Color(COR_TINTA, 0.6), 1.5)
	draw_rect(Rect2(c + Vector2(-1.2, tam.y / 2 / ESCALA - 0.4) * ESCALA, Vector2(2.4, 0.8) * ESCALA), COR_PAPEL)
	draw_rect(Rect2(c + Vector2(-1.2, tam.y / 2 / ESCALA - 0.4) * ESCALA, Vector2(2.4, 0.8) * ESCALA), COR_TINTA, false, 1.5)
	draw_rect(Rect2(c + Vector2(-1.0, -tam.y / 2 / ESCALA - 0.4) * ESCALA, Vector2(2.0, 0.8) * ESCALA), COR_PAPEL)
	draw_rect(Rect2(c + Vector2(-1.0, -tam.y / 2 / ESCALA - 0.4) * ESCALA, Vector2(2.0, 0.8) * ESCALA), COR_TINTA, false, 1.5)
	var janela := Rect2(c + Vector2(tam.x / 2 / ESCALA - 0.4, -1.2) * ESCALA, Vector2(0.8, 2.4) * ESCALA)
	draw_rect(janela, COR_AMBAR if base != "vazia" else COR_PAPEL)
	draw_rect(janela, COR_TINTA, false, 1.5)
	for k in 5:
		var a := TAU * k / 5.0
		draw_circle(c + Vector2(-9, -6) * ESCALA + Vector2(cos(a), sin(a)) * 1.1 * ESCALA, 1.1 * ESCALA, Color(COR_TINTA, 0.35))
	draw_string(fonte, c + Vector2(-tam.x / 2, -tam.y / 2 - 3.5 * ESCALA), Regras.BASES[base], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, COR_TINTA)


## Porteira de duas estacas com travessa: o ponto oposto do mapa, onde se registra a chegada.
func _desenhar_saida(pos_m: Vector2) -> void:
	var c := pos_m * ESCALA
	var claro := revelado(pos_m) > 0.5
	var cor := COR_MINHA if claro else COR_AMBAR
	draw_circle(c, 7.0 * ESCALA, Color(COR_AMBAR, 0.1))
	draw_line(c + Vector2(-3, -2) * ESCALA, c + Vector2(-3, 2.5) * ESCALA, cor, 3)
	draw_line(c + Vector2(3, -2) * ESCALA, c + Vector2(3, 2.5) * ESCALA, cor, 3)
	draw_line(c + Vector2(-3, -1) * ESCALA, c + Vector2(3, -1) * ESCALA, cor, 2)
	draw_line(c + Vector2(-3, 1) * ESCALA, c + Vector2(3, 1) * ESCALA, cor, 2)
	draw_string(fonte, c + Vector2(-14, -4 * ESCALA), "Saída", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, cor)


## Pegada em forma de sola e salto (ou pé descalço). Coordenadas em metros, frente para cima.
func _desenhar_pegada(g: Dictionary, j: Personagem) -> void:
	var minha: bool = g["dono"] == j.id
	var leitura := 5 if minha else j.leitura_pegadas()
	var alfa := 0.9
	if leitura >= 3 or minha:
		alfa = clampf(1.0 - (mundo.tempo - g["t"]) / g["vida"], 0.2, 0.92)
	if minha:
		alfa *= 0.85
	var angulo: float = g["dir"].angle() + PI / 2 if leitura >= 2 else 0.0
	var esquerdo: bool = int(g.get("id", 0)) % 2 == 0
	if leitura >= 2:
		angulo += -0.12 if esquerdo else 0.12   # pés esquerdo e direito levemente abertos
	# Borda clara (papel) por baixo, para a pegada saltar sobre a trilha e as manchas.
	draw_set_transform(g["pos"] * ESCALA, angulo, Vector2.ONE * ESCALA * GLIFO * 1.32)
	_forma(g["calcado"], Color(COR_PAPEL, 0.85 * alfa), Color(COR_PAPEL, 0.0))
	draw_set_transform(g["pos"] * ESCALA, angulo, Vector2.ONE * ESCALA * GLIFO)
	_forma(g["calcado"], Color(COR_MINHA if minha else COR_PEGADA, alfa), Color(COR_PAPEL, alfa))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _forma(calcado: String, c: Color, detalhe: Color) -> void:
	match calcado:
		"bota":
			_sola(Vector2(0.15, 0.2), 0.26, c)
			_salto(Vector2(0, 0.2), Vector2(0.11, 0.07), c)
		"botina":
			_sola(Vector2(0.12, 0.16), 0.21, c)
			_salto(Vector2(0, 0.17), Vector2(0.09, 0.06), c)
		"tamanco":
			_sola(Vector2(0.13, 0.0), 0.26, c, true)
		"alpercata":
			_sola(Vector2(0.09, 0.12), 0.24, c)
			if detalhe.a > 0.0:
				draw_line(Vector2(-0.12, 0.0), Vector2(0.12, -0.05), detalhe, 0.025)
		"descalco":
			_elipse(Vector2(0, -0.07), Vector2(0.1, 0.13), c)
			_elipse(Vector2(0, 0.17), Vector2(0.07, 0.08), c)
			draw_rect(Rect2(Vector2(-0.04, 0.02), Vector2(0.07, 0.12)), c)
			for k in 5:
				draw_circle(Vector2(-0.085 + 0.042 * k, -0.24 + abs(k - 1.5) * 0.012), 0.022, c)


## Sola: frente arredondada mais larga, cintura estreita. largura.x = frente, largura.y não usada;
## comprimento = metade do comprimento da sola.
## inteira = true: sola e salto num bloco só (tamanco).
func _sola(largura: Vector2, comprimento: float, cor: Color, inteira := false) -> void:
	var pts := PackedVector2Array()
	var frente := largura.x
	for k in 9:
		var a := PI + PI * k / 8.0
		pts.append(Vector2(cos(a) * frente, -comprimento * 0.45 + sin(a) * comprimento * 0.55))
	var fundo := comprimento * (1.0 if inteira else 0.45)
	var cintura := 0.8 if inteira else 0.55
	pts.append(Vector2(frente * 0.75, comprimento * 0.15))
	pts.append(Vector2(frente * cintura, fundo))
	pts.append(Vector2(-frente * cintura, fundo))
	pts.append(Vector2(-frente * 0.75, comprimento * 0.15))
	draw_colored_polygon(pts, cor)


func _salto(centro: Vector2, meio: Vector2, cor: Color) -> void:
	_elipse(centro + Vector2(0, 0.08), meio, cor)


func _elipse(centro: Vector2, raio: Vector2, cor: Color) -> void:
	var pts := PackedVector2Array()
	for k in 14:
		var a := TAU * k / 14.0
		pts.append(centro + Vector2(cos(a) * raio.x, sin(a) * raio.y))
	draw_colored_polygon(pts, cor)
