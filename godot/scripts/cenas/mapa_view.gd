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
# Textos e marcadores: contraste por claro/escuro e por formato, não por matiz (pensado para daltonismo).
const COR_TEXTO := Color("#fff4dc")
const COR_CONTORNO := Color("#120c06")
const LARGURA_TRILHA := 0.25  # m (tracejado fino, como caminho de mapa antigo)
const GLIFO := 6.0            # pegadas desenhadas maiores que o real, para leitura

var mundo: Mundo
var fonte: Font
var fundo: ColorRect
var mascara: Image
var textura_mascara: ImageTexture
var _acumulado := 0.0
var arvores: Array = []        # {pos, raio, tipo, visivel}; só desenho, a mata já é parede nas regras
const BLOCO_ARVORES := 40.0   # m: a mata é dividida em blocos para redesenhar só o pedaço que mudou
var blocos := {}               # Vector2i -> CamadaArvores
var _ultimo_revelado := Vector2.INF
var _alvo: CanvasItem = self    # onde os desenhos caem: o próprio mapa ou a camada viva
var camada_viva: CamadaViva


## Camada por cima do mapa com o que se mexe; redesenhada a cada quadro.
class CamadaViva extends Node2D:
	var vista: MapaView
	func _draw() -> void:
		vista._alvo = self
		vista._desenhar_vivo()
		vista._alvo = vista


## Um bloco da mata: o Godot guarda o desenho e só refaz quando aparecem árvores novas nele.
class CamadaArvores extends Node2D:
	var vista: MapaView
	var lista: Array = []
	func _draw() -> void:
		# Todas as copas do bloco num só lote de triângulos: uma chamada de desenho por bloco.
		var pontos := PackedVector2Array()
		var cores := PackedColorArray()
		var indices := PackedInt32Array()
		for a in lista:
			if a["visivel"] or Regras.sem_nevoa:
				vista._triangulos_arvore(a, pontos, cores, indices)
		if not indices.is_empty():
			RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, pontos, cores)


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
	camada_viva = CamadaViva.new()
	camada_viva.vista = self
	camada_viva.z_index = 1
	add_child(camada_viva)
	_plantar_arvores()
	for a in arvores:
		var chave := Vector2i((a["pos"] / BLOCO_ARVORES).floor())
		if not blocos.has(chave):
			var bloco := CamadaArvores.new()
			bloco.vista = self
			bloco.show_behind_parent = true
			add_child(bloco)
			blocos[chave] = bloco
		blocos[chave].lista.append(a)
	_revelar()


func _process(dt: float) -> void:
	if mundo == null:
		return
	_acumulado += dt
	if _acumulado >= Regras.PERCEPCAO_INTERVALO:
		_acumulado = 0.0
		_revelar()
		queue_redraw()   # trilhas, clareiras e bases: 5 vezes por segundo bastam
	var j := mundo.jogador()
	var mat := fundo.material as ShaderMaterial
	mat.set_shader_parameter("jogador_m", j.pos + Vector2.ONE * MARGEM)
	mat.set_shader_parameter("alcance", j.alcance())
	mat.set_shader_parameter("sem_nevoa", Regras.sem_nevoa)
	camada_viva.queue_redraw()


## Abre a névoa em volta do jogador, de forma permanente (borda suave).
func _revelar() -> void:
	var j := mundo.jogador()
	# Parado no mesmo lugar, não há nada novo para abrir
	if j.pos.distance_to(_ultimo_revelado) < 0.5:
		return
	_ultimo_revelado = j.pos
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
	# Só os blocos de mata em volta do jogador
	var de := Vector2i(((j.pos - Vector2.ONE * r) / BLOCO_ARVORES).floor())
	var ate := Vector2i(((j.pos + Vector2.ONE * r) / BLOCO_ARVORES).floor())
	for bx in range(de.x, ate.x + 1):
		for by in range(de.y, ate.y + 1):
			var bloco: CamadaArvores = blocos.get(Vector2i(bx, by))
			if bloco == null:
				continue
			var novas := false
			for a in bloco.lista:
				if not a["visivel"] and a["pos"].distance_to(j.pos) <= r * 0.78:
					a["visivel"] = true
					novas = true
			if novas:
				bloco.queue_redraw()


## Espalha a mata em volta das trilhas: copas vistas de cima, fora das trilhas e das clareiras.
## Sorteio fixo pela semente do mapa, para a mata ser a mesma a noite toda.
func _plantar_arvores() -> void:
	var m := mundo.mapa
	var rng := RandomNumberGenerator.new()
	rng.seed = m.semente * 7 + 3
	var segs := m.arestas.map(func(e): return [m.pos(e["a"]), m.pos(e["b"])])
	var clareiras := m.nos.filter(func(n): return n["tipo"] == "clareira").map(func(n): return n["pos"])
	var densidade := FastNoiseLite.new()
	densidade.seed = m.semente * 13 + 5
	densidade.frequency = 0.03
	var passo := 3.1
	var y := -MARGEM * 0.5
	while y < m.tamanho.y + MARGEM * 0.5:
		var x := -MARGEM * 0.5
		while x < m.tamanho.x + MARGEM * 0.5:
			var p := Vector2(x, y) + Vector2(rng.randf_range(-1.6, 1.6), rng.randf_range(-1.6, 1.6))
			x += passo
			# Densidade variável: grupos fechados, vãos e uma ou outra árvore bem maior.
			var d := (densidade.get_noise_2dv(p) + 1.0) * 0.5
			# Mata fechada: quase todo ponto vira árvore; onde a densidade é menor, nasce sub-bosque.
			var sub_bosque := rng.randf() > smoothstep(0.15, 0.5, d) * 0.6 + 0.4
			var raio := rng.randf_range(1.4, 2.4) * (0.85 + 0.45 * d)
			if sub_bosque:
				raio = rng.randf_range(0.8, 1.3)
			elif rng.randf() < 0.08:
				raio = rng.randf_range(3.2, 4.4)
			var ok := true
			for c in clareiras:
				if p.distance_to(c) < 9.0 + raio:
					ok = false
					break
			if ok:
				var mais_perto := INF
				for sg in segs:
					mais_perto = minf(mais_perto, p.distance_to(Geometry2D.get_closest_point_to_segment(p, sg[0], sg[1])))
					if mais_perto < 2.2 + raio:
						break
				# Longe das trilhas a névoa nunca se abre: não precisa plantar.
				ok = mais_perto >= 1.8 + raio and mais_perto <= 30.0
			if ok:
				arvores.append({"pos": p, "raio": raio, "tipo": "copa", "tom": rng.randf_range(-1.0, 1.0),
					"giro": rng.randf() * TAU, "visivel": false})
		y += passo * 0.87


## Liga ou desliga a névoa durante a noite (tecla N).
func alternar_nevoa() -> void:
	Regras.sem_nevoa = not Regras.sem_nevoa
	atualizar()


## Redesenha tudo depois de mudar uma configuração.
func atualizar() -> void:
	for bloco in blocos.values():
		bloco.queue_redraw()
	queue_redraw()


func revelado(p_m: Vector2) -> float:
	if Regras.sem_nevoa:
		return 1.0
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
	# Todos os tracinhos vão num só comando de desenho (bem mais leve no navegador).
	# Configuração: sem o tracejado, a trilha aparece só pelo vão entre as árvores.
	var pontos := PackedVector2Array()
	var cores := PackedColorArray()
	for e in (m.arestas if Regras.mostrar_trilhas else []):
		var pa := m.pos(e["a"])
		var pb := m.pos(e["b"])
		var n: int = e["amostra_fim"] - e["amostra_ini"]
		for k in n:
			var i: int = e["amostra_ini"] + k
			var alfa := 0.0
			if j.amostra_percorrida[i] == 1 or Regras.sem_nevoa:
				alfa = 0.6
			else:
				var idade := agora - j.amostra_vista[i]
				if idade <= lembra:
					alfa = 0.6 * (1.0 - idade / lembra)
			if alfa <= 0.01:
				continue
			# Tracejado: em cada trecho de 2 m, desenha só pouco mais da metade.
			var a := pa.lerp(pb, float(k) / n)
			var b := pa.lerp(pb, (k + 0.55) / n)
			var cor := COR_TINTA_CLARA if revelado(m.amostras[i]) > 0.5 else COR_MEMORIA
			pontos.append(a * ESCALA)
			pontos.append(b * ESCALA)
			cores.append(Color(cor, alfa))
	if not pontos.is_empty():
		_alvo.draw_multiline_colors(pontos, cores, LARGURA_TRILHA * ESCALA)

	# Clareiras e bases conhecidas
	for no in m.nos:
		if j.no_visto[no["id"]] == 0 and not Regras.sem_nevoa:
			continue
		var p: Vector2 = no["pos"] * ESCALA
		match no["tipo"]:
			"clareira":
				_alvo.draw_circle(p, 8.0 * ESCALA, Color(COR_TINTA, 0.08))
				_arco_tracejado(p, 8.0 * ESCALA, Color(COR_TINTA, 0.7))
			"beco":
				var cor := Color(COR_TINTA, 0.8)
				_alvo.draw_line(p + Vector2(-5, -5), p + Vector2(5, 5), cor, 2)
				_alvo.draw_line(p + Vector2(-5, 5), p + Vector2(5, -5), cor, 2)
		if no["base"] != "":
			_desenhar_base(no["pos"], no["base"])

	# Luzes vistas de longe (sem a trilha até elas)
	for b in j.luzes:
		var no_base: int = m.bases()[b]
		if j.no_visto[no_base] == 1 or Regras.sem_nevoa:
			continue
		var p: Vector2 = j.luzes[b] * ESCALA
		_alvo.draw_circle(p, 12, Color(COR_AMBAR, 0.15))
		_alvo.draw_circle(p, 4, COR_AMBAR)

	_desenhar_saida(m.pos(j.saida))


## O que se mexe (pegadas, animais, personagens, você): redesenhado a cada quadro numa camada
## por cima. O resto do mapa é refeito só 5 vezes por segundo.
func _desenhar_vivo() -> void:
	var j := mundo.jogador()
	var m := mundo.mapa
	var agora := mundo.tempo
	for g in mundo.pegadas:
		if mundo.pegada_visivel_para(j, g):
			_desenhar_pegada(g, j)

	# Armadilhas conhecidas (armada: mandíbula aberta; disparada: fechada)
	for a in mundo.armadilhas.lista:
		if mundo.armadilhas.visivel_para_jogador(a):
			_desenhar_armadilha(a)

	# Animais
	for a in mundo.fauna.animais:
		if mundo.fauna.visivel_para_jogador(a):
			_desenhar_animal(a)

	# Personagens
	for o in mundo.personagens:
		if o.eh_jogador:
			continue
		if agora - j.vistos.get(o.id, -1.0e9) > Regras.PERCEPCAO_INTERVALO * 1.5:
			continue
		# Outros personagens: losango escuro com borda clara
		var c: Vector2 = o.pos * ESCALA
		var t := 1.6 * ESCALA
		var losango := PackedVector2Array([c + Vector2(0, -t), c + Vector2(t, 0), c + Vector2(0, t), c + Vector2(-t, 0)])
		_alvo.draw_colored_polygon(losango, COR_CONTORNO)
		losango.append(losango[0])
		_alvo.draw_polyline(losango, COR_TEXTO, 2.0)
		_texto(c + Vector2(t + 6, -t), o.nome, 15)
	# Você: círculo claro com anel escuro grosso e ponto escuro no centro
	_alvo.draw_circle(j.pos * ESCALA, 1.7 * ESCALA, COR_CONTORNO)
	_alvo.draw_circle(j.pos * ESCALA, 1.2 * ESCALA, COR_AMBAR)
	_alvo.draw_circle(j.pos * ESCALA, 0.35 * ESCALA, COR_CONTORNO)
	if not j.rota.is_empty():
		var alvo := m.pos(j.rota[-1]) * ESCALA
		_alvo.draw_arc(alvo, 10, 0, TAU, 24, Color(COR_MINHA, 0.8), 2)


## Animais vistos de cima: silhuetas escuras com borda clara, cada uma com um formato
## (não depende de cor), e o nome do animal ao lado.
func _desenhar_animal(a: Fauna.Animal) -> void:
	var c: Vector2 = a.pos * ESCALA
	if Regras.mostrar_alcance:
		_alcance_animal(a)
	var u := ESCALA * 1.35         # desenhados maiores que o real, para leitura (como as pegadas)
	var borda := Color(COR_TEXTO, 0.9)
	var rotulo: String = {"lobo": "lobo", "coruja": "coruja", "cao": "cão", "cobra": "cobra"}[a.tipo]
	match a.tipo:
		"lobo", "cao":
			# Corpo alongado, cabeça e orelhas; o lobo é maior e tem orelhas pontudas
			var t := 1.0 if a.tipo == "lobo" else 0.75
			var dir := Vector2.RIGHT
			if not a.caminho.is_empty():
				dir = (a.caminho[0] - a.pos).normalized() if a.caminho[0] != a.pos else dir
			elif a.alvo >= 0:
				dir = (mundo.personagens[a.alvo].pos - a.pos).normalized()
			var lado := dir.orthogonal()
			var corpo := PackedVector2Array()
			for k in 14:
				var ang := TAU * k / 14.0
				corpo.append(c + dir * cos(ang) * 2.2 * u * t + lado * sin(ang) * 0.9 * u * t)
			var cabeca := c + dir * 2.4 * u * t
			var orelha := 0.9 if a.tipo == "lobo" else 0.5
			_alvo.draw_colored_polygon(corpo, COR_CONTORNO)
			corpo.append(corpo[0])
			_alvo.draw_polyline(corpo, borda, 1.5)
			_alvo.draw_circle(cabeca, 0.8 * u * t, COR_CONTORNO)
			_alvo.draw_arc(cabeca, 0.8 * u * t, 0, TAU, 12, borda, 1.5)
			for sinal in [-1.0, 1.0]:
				var base_orelha: Vector2 = cabeca + lado * sinal * 0.45 * u * t
				_alvo.draw_colored_polygon(PackedVector2Array([base_orelha - dir * 0.3 * u * t, base_orelha + dir * 0.3 * u * t,
					base_orelha + lado * sinal * orelha * u * t]), COR_CONTORNO)
			# Rabo
			_alvo.draw_line(c - dir * 2.0 * u * t, c - dir * 3.3 * u * t + lado * (0.6 if a.tipo == "cao" else 0.0) * u, borda, 2.0)
			if a.tipo == "lobo" and a.ferido:
				rotulo = "lobo (mancando)"
			elif a.tipo == "lobo" and a.estado in ["rosnando", "perseguindo"]:
				rotulo = "lobo (rosnando)"
			elif a.tipo == "cao" and a.estado in ["esperando", "guiando"]:
				rotulo = "cão (abanando o rabo)"
		"coruja":
			# Corpo redondo com dois olhos claros
			_alvo.draw_circle(c, 1.4 * u, COR_CONTORNO)
			_alvo.draw_arc(c, 1.4 * u, 0, TAU, 16, borda, 1.5)
			_alvo.draw_circle(c + Vector2(-0.5, -0.3) * u, 0.38 * u, COR_TEXTO)
			_alvo.draw_circle(c + Vector2(0.5, -0.3) * u, 0.38 * u, COR_TEXTO)
			_alvo.draw_circle(c + Vector2(-0.5, -0.3) * u, 0.15 * u, COR_CONTORNO)
			_alvo.draw_circle(c + Vector2(0.5, -0.3) * u, 0.15 * u, COR_CONTORNO)
		"cobra" when not mundo.fauna.cobra_vista(a):
			# Só se ouviu: folhas secas se mexendo (três arcos curtos), sem mostrar o bicho
			for k in 3:
				var centro := c + Vector2((k - 1) * 0.9 * u, (k % 2) * 0.5 * u)
				_alvo.draw_arc(centro, 0.6 * u, PI * 1.1, PI * 1.9, 6, COR_CONTORNO, 0.5 * u)
				_alvo.draw_arc(centro, 0.6 * u, PI * 1.1, PI * 1.9, 6, COR_TEXTO, 0.22 * u)
			rotulo = "folhas mexendo"
		"cobra":
			# Linha em zigue-zague grossa, escura com contorno claro
			var pts := PackedVector2Array()
			for k in 9:
				var x := (k - 4) * 0.6 * u
				pts.append(c + Vector2(x, sin(k * 1.4) * 0.7 * u))
			_alvo.draw_polyline(pts, borda, 0.9 * u)
			_alvo.draw_polyline(pts, COR_CONTORNO, 0.55 * u)
			_alvo.draw_circle(pts[pts.size() - 1], 0.45 * u, COR_CONTORNO)
	if mundo.tempo < a.sinal_ate:
		rotulo += " — " + a.sinal
	_texto(c + Vector2(2.6 * u, 0.4 * u), rotulo, 9)


func _desenhar_armadilha(a: Armadilhas.Armadilha) -> void:
	var c: Vector2 = a.pos * ESCALA
	var u := ESCALA * 1.3
	var borda := Color(COR_TEXTO, 0.9)
	if a.disparada:
		# Fechada: duas barras juntas
		_alvo.draw_line(c + Vector2(-1.4, 0) * u, c + Vector2(1.4, 0) * u, COR_CONTORNO, 0.9 * u)
		_alvo.draw_line(c + Vector2(-1.4, 0) * u, c + Vector2(1.4, 0) * u, borda, 0.3 * u)
		_texto(c + Vector2(1.8 * u, 0.4 * u), "armadilha disparada", 9)
		return
	# Armada: aro com dentes em volta
	var dentes := PackedVector2Array()
	for k in 17:
		var ang := TAU * k / 16.0
		dentes.append(c + Vector2(cos(ang), sin(ang)) * u * (1.3 if k % 2 == 0 else 0.9))
	_alvo.draw_polyline(dentes, COR_CONTORNO, 0.6 * u)
	_alvo.draw_polyline(dentes, borda, 0.22 * u)
	_alvo.draw_circle(c, 0.35 * u, COR_CONTORNO)
	_texto(c + Vector2(1.8 * u, 0.4 * u), "armadilha", 9)


## Ajuda de teste: a distância em que o animal percebe alguém (tracejado) e o tempo que falta
## no encontro (arco cheio que vai se fechando).
func _alcance_animal(a: Fauna.Animal) -> void:
	var c: Vector2 = a.pos * ESCALA
	var raio := {"lobo": Regras.LOBO_VE_M, "coruja": Regras.CORUJA_VE_M, "cao": Regras.CAO_VE_M,
		"cobra": mundo.fauna.cobra_aviso_m(mundo.jogador())}[a.tipo] as float
	# Tracejado claro com contorno escuro: aparece tanto no papel quanto sobre a mata
	for k in 32:
		if k % 2 == 0:
			var a0 := TAU * k / 32.0
			var a1 := TAU * (k + 1) / 32.0
			_alvo.draw_arc(c, raio * ESCALA, a0, a1, 4, Color(COR_CONTORNO, 0.8), 3.5)
			_alvo.draw_arc(c, raio * ESCALA, a0, a1, 4, Color(COR_TEXTO, 0.9), 1.5)
	if a.tipo == "cobra":
		_alvo.draw_arc(c, Regras.COBRA_PICA_M * ESCALA, 0, TAU, 20, Color(COR_CONTORNO, 0.9), 3.5)
		_alvo.draw_arc(c, Regras.COBRA_PICA_M * ESCALA, 0, TAU, 20, Color(COR_TEXTO, 0.9), 1.5)
		var j := mundo.jogador()
		var parado: float = a.ouviu.get(j.id, 0.0)
		if a.ouviu.has(j.id) and parado > 0.0:
			_contagem(c, Regras.COBRA_PICA_M * 1.4 * ESCALA, parado / Regras.COBRA_DESISTE_S, "%.1f s parado" % parado)
		elif a.avisado.has(j.id):
			_texto(c + Vector2(-20, -Regras.COBRA_PICA_M * ESCALA - 8), "pare antes do círculo pequeno", 9)
	elif a.tipo == "lobo" and a.estado == "rosnando":
		_contagem(c, 5.0 * ESCALA, 1.0 - a.relogio / Regras.LOBO_ROSNA_S, "fique parado: %.1f s" % maxf(a.relogio, 0.0))
	elif a.tipo == "lobo" and a.estado == "perseguindo":
		_texto(c + Vector2(-20, -5.5 * ESCALA), "atacando! corra para uma base", 9)
	elif a.tipo == "cao" and a.estado == "esperando":
		_contagem(c, 5.0 * ESCALA, 1.0 - a.relogio / Regras.CAO_ESPERA_S, "chegue a 5 m: %.0f s" % maxf(a.relogio, 0.0))


func _contagem(c: Vector2, r: float, fracao: float, texto: String) -> void:
	_alvo.draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * clampf(fracao, 0.0, 1.0), 32, COR_CONTORNO, 5.0)
	_alvo.draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * clampf(fracao, 0.0, 1.0), 32, COR_AMBAR, 2.5)
	_texto(c + Vector2(-r, -r - 6), texto, 9)


## Copa vista de cima em triângulos (leque a partir do centro), para desenhar a mata em lote.
## Folhagem escura com borda recortada e reflexos; pontas e reentrâncias alternadas.
func _triangulos_arvore(a: Dictionary, pontos: PackedVector2Array, cores: PackedColorArray, indices: PackedInt32Array) -> void:
	var c: Vector2 = a["pos"] * ESCALA
	var r: float = a["raio"] * ESCALA
	var giro: float = a["giro"]
	var tom: float = a.get("tom", 0.0)
	var escura := Color("#2a1c10").lerp(Color("#4a3a1e") if tom > 0.0 else Color("#140d06"), absf(tom) * 0.6)
	escura.a = 0.9
	_leque(c, r, 14, giro, 0.84, escura, pontos, cores, indices)
	_leque(c + Vector2(-r * 0.25, -r * 0.25), r * 0.32, 8, 0.0, 1.0, Color(COR_TINTA_CLARA, 0.35), pontos, cores, indices)
	if r > 1.8 * ESCALA:
		# Copas grandes ganham folhagem interna, para a mata parecer viva
		_leque(c + Vector2(r * 0.3, -r * 0.1), r * 0.22, 8, 0.0, 1.0, Color(COR_TINTA_CLARA, 0.22), pontos, cores, indices)
		_leque(c + Vector2(-r * 0.05, r * 0.35), r * 0.18, 8, 0.0, 1.0, Color("#0d0804", 0.35), pontos, cores, indices)


## Polígono em leque: `lados` pontos em volta do centro; `recorte` < 1 alterna pontas e reentrâncias.
func _leque(c: Vector2, r: float, lados: int, giro: float, recorte: float, cor: Color,
		pontos: PackedVector2Array, cores: PackedColorArray, indices: PackedInt32Array) -> void:
	var base := pontos.size()
	pontos.append(c)
	cores.append(cor)
	for k in lados:
		var ang := giro + TAU * k / lados
		pontos.append(c + Vector2(cos(ang), sin(ang)) * r * (1.0 if k % 2 == 0 else recorte))
		cores.append(cor)
	for k in lados:
		indices.append(base)
		indices.append(base + 1 + k)
		indices.append(base + 1 + (k + 1) % lados)


## Texto claro com contorno escuro grosso: legível sobre o papel, as árvores e a névoa.
func _texto(pos: Vector2, texto: String, tamanho: int) -> void:
	_alvo.draw_string_outline(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, 7, COR_CONTORNO)
	_alvo.draw_string(fonte, pos, texto, HORIZONTAL_ALIGNMENT_LEFT, -1, tamanho, COR_TEXTO)


func _arco_tracejado(c: Vector2, r: float, cor: Color) -> void:
	for k in 24:
		if k % 2 == 0:
			_alvo.draw_arc(c, r, TAU * k / 24.0, TAU * (k + 1) / 24.0, 4, cor, 1.5)


## Planta baixa: casa em tinta, porta da frente (baixo), fundos (cima), janela acesa (lado) e moita de esconderijo.
func _desenhar_base(pos_m: Vector2, base: String) -> void:
	var c := pos_m * ESCALA
	var tam := Vector2(10, 7) * ESCALA
	var r := Rect2(c - tam / 2, tam)
	_alvo.draw_rect(r, Color(COR_TINTA, 0.12))
	_alvo.draw_rect(r, COR_TINTA, false, 2.5)
	_alvo.draw_line(c + Vector2(-tam.x / 2, 0), c + Vector2(tam.x / 2 - 3 * ESCALA, 0), Color(COR_TINTA, 0.6), 1.5)
	_alvo.draw_rect(Rect2(c + Vector2(-1.2, tam.y / 2 / ESCALA - 0.4) * ESCALA, Vector2(2.4, 0.8) * ESCALA), COR_PAPEL)
	_alvo.draw_rect(Rect2(c + Vector2(-1.2, tam.y / 2 / ESCALA - 0.4) * ESCALA, Vector2(2.4, 0.8) * ESCALA), COR_TINTA, false, 1.5)
	_alvo.draw_rect(Rect2(c + Vector2(-1.0, -tam.y / 2 / ESCALA - 0.4) * ESCALA, Vector2(2.0, 0.8) * ESCALA), COR_PAPEL)
	_alvo.draw_rect(Rect2(c + Vector2(-1.0, -tam.y / 2 / ESCALA - 0.4) * ESCALA, Vector2(2.0, 0.8) * ESCALA), COR_TINTA, false, 1.5)
	var janela := Rect2(c + Vector2(tam.x / 2 / ESCALA - 0.4, -1.2) * ESCALA, Vector2(0.8, 2.4) * ESCALA)
	_alvo.draw_rect(janela, COR_AMBAR if base != "vazia" else COR_PAPEL)
	_alvo.draw_rect(janela, COR_TINTA, false, 1.5)
	for k in 5:
		var a := TAU * k / 5.0
		_alvo.draw_circle(c + Vector2(-9, -6) * ESCALA + Vector2(cos(a), sin(a)) * 1.1 * ESCALA, 1.1 * ESCALA, Color(COR_TINTA, 0.35))
	_texto(c + Vector2(-tam.x / 2, -tam.y / 2 - 3.5 * ESCALA), Regras.BASES[base], 16)


## Porteira de duas estacas com travessa: o ponto oposto do mapa, onde se registra a chegada.
func _desenhar_saida(pos_m: Vector2) -> void:
	var c := pos_m * ESCALA
	var claro := revelado(pos_m) > 0.5
	var cor := COR_MINHA if claro else COR_AMBAR
	_alvo.draw_circle(c, 7.0 * ESCALA, Color(COR_AMBAR, 0.1))
	_alvo.draw_line(c + Vector2(-3, -2) * ESCALA, c + Vector2(-3, 2.5) * ESCALA, cor, 3)
	_alvo.draw_line(c + Vector2(3, -2) * ESCALA, c + Vector2(3, 2.5) * ESCALA, cor, 3)
	_alvo.draw_line(c + Vector2(-3, -1) * ESCALA, c + Vector2(3, -1) * ESCALA, cor, 2)
	_alvo.draw_line(c + Vector2(-3, 1) * ESCALA, c + Vector2(3, 1) * ESCALA, cor, 2)
	_texto(c + Vector2(-16, -4 * ESCALA), "Saída", 16)


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
	_alvo.draw_set_transform(g["pos"] * ESCALA, angulo, Vector2.ONE * ESCALA * GLIFO * 1.32)
	_forma(g["calcado"], Color(COR_PAPEL, 0.85 * alfa), Color(COR_PAPEL, 0.0))
	_alvo.draw_set_transform(g["pos"] * ESCALA, angulo, Vector2.ONE * ESCALA * GLIFO)
	_forma(g["calcado"], Color(COR_PEGADA, alfa), Color(COR_PAPEL, alfa))
	if minha:
		# As suas ficam vazadas: miolo claro dentro do contorno escuro.
		_alvo.draw_set_transform(g["pos"] * ESCALA, angulo, Vector2.ONE * ESCALA * GLIFO * 0.58)
		_forma(g["calcado"], Color(COR_PAPEL, 1.0), Color(COR_PAPEL, 0.0))
	_alvo.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
				_alvo.draw_line(Vector2(-0.12, 0.0), Vector2(0.12, -0.05), detalhe, 0.025)
		"descalco":
			_elipse(Vector2(0, -0.07), Vector2(0.1, 0.13), c)
			_elipse(Vector2(0, 0.17), Vector2(0.07, 0.08), c)
			_alvo.draw_rect(Rect2(Vector2(-0.04, 0.02), Vector2(0.07, 0.12)), c)
			for k in 5:
				_alvo.draw_circle(Vector2(-0.085 + 0.042 * k, -0.24 + abs(k - 1.5) * 0.012), 0.022, c)


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
	_alvo.draw_colored_polygon(pts, cor)


func _salto(centro: Vector2, meio: Vector2, cor: Color) -> void:
	_elipse(centro + Vector2(0, 0.08), meio, cor)


func _elipse(centro: Vector2, raio: Vector2, cor: Color) -> void:
	var pts := PackedVector2Array()
	for k in 14:
		var a := TAU * k / 14.0
		pts.append(centro + Vector2(cos(a) * raio.x, sin(a) * raio.y))
	_alvo.draw_colored_polygon(pts, cor)
