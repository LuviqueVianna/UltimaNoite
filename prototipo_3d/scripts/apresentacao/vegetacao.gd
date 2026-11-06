extends Node3D
## Desenha a mata a partir das listas de árvores e plantas do mundo.
## Cada espécie vira um MultiMesh: milhares de árvores em poucas chamadas de desenho.
## Copas, samambaias e palmeiras são feitas de "cartões": quadrados com uma textura de folhas recortada,
## desenhada aqui mesmo na montagem (sem arquivo de imagem). Um miolo escuro dá corpo às copas.

const SHADER := preload("res://shaders/mata.gdshader")
var _shader_cartao: Shader   # mesmo shader, mas com as duas faces desenhadas
var _tex := {}

const QUADRA := 32.0

var total_instancias := 0


func montar(arvores: Array, plantas: Array) -> void:
	_shader_cartao = Shader.new()
	_shader_cartao.code = SHADER.code.replace("cull_back", "cull_disabled")
	_tex = {
		"folhagem": _textura_folhagem(256, 90, 11),
		"miuda": _textura_folhagem(256, 140, 23, 0.6),
		"fronde": _textura_fronde(64, 256, 0.9, 3),
		"palma": _textura_fronde(64, 256, 0.35, 5),
		"embauba": _textura_embauba(128),
	}
	var especies := {
		"comum": _comum(),
		"jequitiba": _jequitiba(),
		"embauba": _embauba(),
		"palmeira": _palmeira(),
		"bambu": _bambu(),
		"samambaia": _samambaia(),
		"bromelia": _bromelia(),
		"moita": _moita(),
	}
	# agrupa por espécie e por quadra de 32 m: a câmera só desenha as quadras à vista
	var por_tipo := {}
	for item in arvores + plantas:
		var p: Vector2 = item["pos"]
		var chave := "%s|%d|%d" % [item["tipo"], int(floor(p.x / QUADRA)), int(floor(p.y / QUADRA))]
		por_tipo.get_or_add(chave, []).append(item)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for chave in por_tipo:
		var tipo: String = chave.get_slice("|", 0)
		var lista: Array = por_tipo[chave]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = especies[tipo]
		mm.instance_count = lista.size()
		for k in lista.size():
			var it: Dictionary = lista[k]
			var b := Basis(Vector3.UP, it["giro"]).scaled(Vector3.ONE * float(it["escala"]))
			var p: Vector2 = it["pos"]
			mm.set_instance_transform(k, Transform3D(b, Vector3(p.x, 0.0, p.y)))
			var tom := rng.randf_range(0.75, 1.25)
			var c := Color(tom * rng.randf_range(0.92, 1.05), tom, tom * rng.randf_range(0.9, 1.08))
			if tipo in ["samambaia", "moita", "bromelia"]:
				# sub-bosque: verdes variados, algumas folhas secas e algumas avermelhadas (bromélias)
				var r := rng.randf()
				if r < 0.15:
					c = Color(tom * 1.6, tom * 1.25, tom * 0.55)
				elif r < 0.3 and tipo == "bromelia":
					c = Color(tom * 1.9, tom * 0.8, tom * 0.7)
				elif r < 0.5:
					c = Color(tom * 0.8, tom * 1.15, tom * 0.85)
			mm.set_instance_color(k, c)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Mata_" + chave.replace("|", "_")
		mmi.multimesh = mm
		var grande: bool = tipo in ["comum", "jequitiba", "embauba", "palmeira", "bambu"]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if grande else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		total_instancias += lista.size()


# ---------------- materiais ----------------

var _altura := 10.0
var _corta := 1.0
var _copa := 2.5
var _casca := 0.0


func _mat(cor: Color, vento: float = 1.0, translucidez: float = 0.25, rugosidade: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("altura_copa", _altura)
	m.set_shader_parameter("corta", _corta)
	m.set_shader_parameter("raio_copa", _copa)
	m.set_shader_parameter("casca", _casca)
	_casca = 0.0
	m.set_shader_parameter("rugosidade", rugosidade)
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("vento", vento)
	m.set_shader_parameter("translucidez", translucidez)
	return m


## Material de cartão de folhas: duas faces, recorte pela textura, normal da copa.
func _cartao_mat(cor: Color, textura: String, centro: float, vento: float = 1.0, translucidez: float = 0.35) -> ShaderMaterial:
	var m := _mat(cor * 1.3, vento, translucidez)
	m.shader = _shader_cartao
	m.set_shader_parameter("textura", _tex[textura])
	m.set_shader_parameter("usa_textura", 1.0)
	m.set_shader_parameter("centro_copa", centro)
	return m


func _quad(lado: float, alto: float = -1.0) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(lado, lado if alto < 0.0 else alto)
	return q


## Um tufo de copa: cartões espalhados na casca de uma esfera, virados para fora, com giro sorteado.
func _tufo(centro: Vector3, raio: float, n: int, rng: RandomNumberGenerator) -> Array:
	var partes := []
	for k in n:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 1.0), rng.randf_range(-1, 1)).normalized()
		var pos := centro + dir * raio * rng.randf_range(0.55, 0.9)
		var olha := Basis.looking_at(-dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.FORWARD)
		var b := olha * Basis(Vector3.BACK, rng.randf() * TAU)
		partes.append([_quad(raio * rng.randf_range(1.0, 1.35)), Transform3D(b, pos)])
	return partes


## Folha comprida e arqueada (samambaia, palmeira): dois cartões em sequência, o segundo caindo.
func _fronde(giro: float, incl: float, comp: float, larg: float, altura: float, queda: float) -> Array:
	var partes := []
	var b1 := Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, -PI / 2 + incl)
	var meio := comp / 2.0
	var c1 := Vector3(0, altura, 0) + b1 * Vector3(0, meio / 2.0, 0)
	partes.append([_quad_uv(larg, meio, 0.5, 1.0), Transform3D(b1, c1)])
	var b2 := Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, -PI / 2 + incl - queda)
	var ponta := Vector3(0, altura, 0) + b1 * Vector3(0, meio, 0)
	partes.append([_quad_uv(larg * 0.8, meio, 0.0, 0.5), Transform3D(b2, ponta + b2 * Vector3(0, meio / 2.0, 0))])
	return partes


## Quadrado que usa só um pedaço vertical da textura (v0..v1): a base e a ponta da folha.
func _quad_uv(larg: float, alto: float, v0: float, v1: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vs := [Vector3(-larg / 2, -alto / 2, 0), Vector3(larg / 2, -alto / 2, 0), Vector3(larg / 2, alto / 2, 0), Vector3(-larg / 2, alto / 2, 0)]
	var uvs := [Vector2(0, v1), Vector2(1, v1), Vector2(1, v0), Vector2(0, v0)]
	for i in [0, 2, 1, 0, 3, 2]:
		st.set_normal(Vector3(0, 0, 1))
		st.set_uv(uvs[i])
		st.add_vertex(vs[i])
	return st.commit()


func _tronco(cor: Color, vento: float, tipo: float) -> ShaderMaterial:
	_casca = tipo
	return _mat(cor, vento)


func _juntar(grupos: Array) -> ArrayMesh:
	# grupos: [[material, [[PrimitiveMesh, Transform3D], ...]], ...]
	var am := ArrayMesh.new()
	for g in grupos:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for parte in g[1]:
			st.append_from(parte[0], 0, parte[1])
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, st.commit_to_arrays())
		am.surface_set_material(am.get_surface_count() - 1, g[0])
	return am


func _cilindro(r_base: float, r_topo: float, altura: float, lados: int = 6) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = r_base
	c.top_radius = r_topo
	c.height = altura
	c.radial_segments = lados
	c.rings = 1
	c.cap_bottom = false
	return c


func _esfera(raio: float, achatar: float = 1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0 * achatar
	s.radial_segments = 10
	s.rings = 5
	return s


func _lamina(largura: float, comprimento: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(largura, 0.03, comprimento)
	return b


func _em(pos: Vector3, rot: Vector3 = Vector3.ZERO, esc: Vector3 = Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_euler(rot).scaled(esc), pos)


## Roseta presa num ponto qualquer (bromélia no tronco).
func _roseta_em(centro: Vector3, n: int, largura: float, comp: float, inclinacao: float, sorteio: int) -> Array:
	var partes := _roseta(n, largura, comp, inclinacao, 0.0, sorteio)
	for p in partes:
		p[1].origin += centro
	return partes


## Lâminas em roseta (folhas de samambaia, palmeira, bromélia), presas pela base.
func _roseta(n: int, largura: float, comp: float, inclinacao: float, altura: float, sorteio: int) -> Array:
	var partes := []
	var rng := RandomNumberGenerator.new()
	rng.seed = sorteio
	for k in n:
		var giro := TAU * k / n + rng.randf_range(-0.2, 0.2)
		var incl := inclinacao + rng.randf_range(-0.15, 0.15)
		var b := Basis(Vector3.UP, giro) * Basis(Vector3.RIGHT, -incl)
		var centro := b * Vector3(0, 0, comp / 2.0) + Vector3(0, altura, 0)
		partes.append([_lamina(largura, comp), Transform3D(b, centro)])
	return partes


# ---------------- espécies ----------------

func _comum() -> ArrayMesh:
	_copa = 4.0
	_altura = 10.0
	_corta = 1.0
	var tronco := [[_cilindro(0.22, 0.12, 9.0, 8), _em(Vector3(0, 4.5, 0))]]
	var miolo := []
	var cartoes := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	for k in 7:
		var g := rng.randf() * TAU
		var r := 0.0 if k == 0 else rng.randf_range(1.0, 2.2)
		var raio := rng.randf_range(1.5, 2.2)
		var c := Vector3(cos(g) * r, rng.randf_range(8.0, 10.2), sin(g) * r)
		miolo.append([_esfera(raio * 0.62, 0.75), _em(c)])
		cartoes.append_array(_tufo(c, raio, 9, rng))
		if k > 0:
			# galho do tronco até o tufo: a arquitetura da árvore aparece por baixo da copa
			tronco.append(_galho(Vector3(0, rng.randf_range(6.0, 7.5), 0), c - Vector3(0, raio * 0.4, 0), 0.09, 0.04))
	if rng.randf() < 1.0:
		tronco.append_array(_cipo(Vector3(1.2, 8.4, 0.4), Vector3(1.8, 0.0, 1.0), 0.6, rng))
	return _juntar([[_tronco(Color(0.36, 0.3, 0.24), 0.2, 1.0), tronco],
		[_mat(Color(0.06, 0.11, 0.07), 1.0, 0.2, 0.8), miolo],
		[_cartao_mat(Color(0.11, 0.19, 0.12), "folhagem", 9.0), cartoes]])


func _jequitiba() -> ArrayMesh:
	_copa = 8.0
	_altura = 22.0
	_corta = 1.0
	var tronco := [[_cilindro(0.75, 0.4, 19.0, 10), _em(Vector3(0, 9.5, 0))]]
	for k in 3:
		var g := TAU * k / 3.0
		tronco.append([_cilindro(0.3, 0.15, 6.0), _em(Vector3(cos(g) * 1.6, 19.5, sin(g) * 1.6), Vector3(0, -g, 0.7))])
	# sapopemas: raízes em tábua na base do tronco
	for k in 4:
		var g := TAU * k / 4.0 + 0.4
		tronco.append([_lamina_alta(0.12, 1.6, 1.4), _em(Vector3(cos(g) * 0.8, 0.7, sin(g) * 0.8), Vector3(0, -g, 0))])
	var miolo := []
	var cartoes := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 7:
		var g := TAU * k / 7.0
		var r := 0.0 if k == 0 else rng.randf_range(3.0, 4.5)
		var raio := rng.randf_range(3.2, 4.2)
		var c := Vector3(cos(g) * r, 21.5 + rng.randf_range(-0.8, 1.0), sin(g) * r)
		var e := _esfera(raio * 0.6, 0.55)
		miolo.append([e, _em(c)])
		cartoes.append_array(_tufo(c, raio, 12, rng))
		if k > 0:
			tronco.append(_galho(Vector3(0, 17.5, 0), c - Vector3(0, raio * 0.35, 0), 0.3, 0.12, 6))
	for k in 6:
		var g := rng.randf() * TAU
		var raio := rng.randf_range(1.8, 2.6)
		var c := Vector3(cos(g) * 4.8, 20.0 + rng.randf_range(-1.0, 1.5), sin(g) * 4.8)
		miolo.append([_esfera(raio * 0.6, 0.7), _em(c)])
		cartoes.append_array(_tufo(c, raio, 7, rng))
	# cipós descendo da copa e bromélias presas no tronco (epífitas)
	var cipos := []
	for k in 4:
		var g := rng.randf() * TAU
		cipos.append_array(_cipo(Vector3(cos(g) * 3.5, 19.0, sin(g) * 3.5), Vector3(cos(g) * 2.2, 0.0, sin(g) * 2.2), 1.2, rng))
	var epifitas := []
	for k in 3:
		var g := rng.randf() * TAU
		var y := rng.randf_range(6.0, 15.0)
		var r := 0.75 - y * 0.016
		epifitas.append_array(_roseta_em(Vector3(cos(g) * r, y, sin(g) * r), 8, 0.1, 0.5, 0.8, 30 + k))
	return _juntar([[_tronco(Color(0.4, 0.35, 0.29), 0.1, 1.0), tronco],
		[_tronco(Color(0.3, 0.27, 0.2), 0.3, 1.0), cipos],
		[_mat(Color(0.25, 0.3, 0.14), 0.2, 0.3), epifitas],
		[_mat(Color(0.05, 0.09, 0.06), 1.0, 0.2, 1.0), miolo],
		[_cartao_mat(Color(0.09, 0.16, 0.1), "folhagem", 21.0), cartoes]])


func _embauba() -> ArrayMesh:
	_copa = 2.2
	_altura = 11.0
	_corta = 1.0
	var tronco := [[_cilindro(0.13, 0.09, 11.0), _em(Vector3(0, 5.5, 0))]]
	var folhas := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	# folhas palmadas, grandes, em guarda-chuva; um segundo andar menor por baixo
	for andar in 2:
		var n := 7 if andar == 0 else 5
		for k in n:
			var g := TAU * k / n + andar * 0.4
			var incl := 0.35 + andar * 0.25 + rng.randf_range(-0.1, 0.1)
			var b := Basis(Vector3.UP, g) * Basis(Vector3.RIGHT, -PI / 2 + incl)
			var y := 11.0 - andar * 0.9
			var dist := 1.15 - andar * 0.25
			folhas.append([_quad(1.5 - andar * 0.3), Transform3D(b, Vector3(0, y, 0) + Basis(Vector3.UP, g) * Vector3(0, -0.2, dist))])
	# folhas prateadas por baixo: refletem a lua
	return _juntar([[_tronco(Color(0.44, 0.44, 0.4), 0.3, 2.0), tronco], [_cartao_mat(Color(0.34, 0.42, 0.38), "embauba", 10.0, 1.2, 0.45), folhas]])


func _palmeira() -> ArrayMesh:
	_copa = 3.0
	_altura = 9.0
	_corta = 1.0
	var tronco := [[_cilindro(0.09, 0.07, 9.0, 6), _em(Vector3(0, 4.5, 0))]]
	var folhas := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for k in 10:
		var giro := TAU * k / 10.0 + rng.randf_range(-0.15, 0.15)
		folhas.append_array(_fronde(giro, rng.randf_range(0.1, 0.5), 3.2, 0.9, 9.0, 0.6))
	return _juntar([[_tronco(Color(0.34, 0.31, 0.26), 0.4, 2.0), tronco], [_cartao_mat(Color(0.12, 0.22, 0.12), "palma", 9.0, 1.4), folhas]])


func _bambu() -> ArrayMesh:
	_copa = 1.8
	_altura = 12.0
	_corta = 1.0
	var hastes := []
	var folhas := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	for k in 11:
		var g := rng.randf() * TAU
		var incl := rng.randf_range(0.05, 0.28)
		var h := rng.randf_range(9.0, 13.0)
		var b := Basis(Vector3.UP, g) * Basis(Vector3.RIGHT, incl)
		var base := Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5))
		hastes.append([_cilindro(0.06, 0.04, h, 5), Transform3D(b, base + b * Vector3(0, h / 2.0, 0))])
		folhas.append_array(_tufo(base + b * Vector3(0, h * 0.88, 0), 1.2, 5, rng))
	return _juntar([[_tronco(Color(0.28, 0.34, 0.18), 0.6, 2.0), hastes], [_cartao_mat(Color(0.2, 0.27, 0.13), "miuda", 10.5, 1.5), folhas]])


func _samambaia() -> ArrayMesh:
	_copa = 1.0
	_altura = 1.0
	_corta = 0.0
	var folhas := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for k in 8:
		var giro := TAU * k / 8.0 + rng.randf_range(-0.2, 0.2)
		folhas.append_array(_fronde(giro, rng.randf_range(0.7, 1.1), 1.4, 0.45, 0.05, 0.7))
	return _juntar([[_cartao_mat(Color(0.12, 0.23, 0.13), "fronde", 0.2, 0.5, 0.4), folhas]])


func _bromelia() -> ArrayMesh:
	_copa = 0.6
	_altura = 0.7
	_corta = 0.0
	var folhas := _roseta(13, 0.12, 0.7, 0.85, 0.05, 2)
	folhas.append_array(_roseta(7, 0.1, 0.45, 0.35, 0.08, 4))
	return _juntar([[_mat(Color(0.2, 0.26, 0.12), 0.3, 0.3), folhas]])


func _moita() -> ArrayMesh:
	_copa = 1.2
	_altura = 1.3
	_corta = 1.0
	var miolo := []
	var cartoes := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for c in [Vector3(0, 0.5, 0), Vector3(0.5, 0.4, 0.3), Vector3(-0.4, 0.45, 0.2)]:
		miolo.append([_esfera(0.32, 0.8), _em(c)])
		cartoes.append_array(_tufo(c, 0.75, 9, rng))
	return _juntar([[_mat(Color(0.08, 0.15, 0.09), 0.4, 0.2, 0.3), miolo], [_cartao_mat(Color(0.1, 0.18, 0.12), "miuda", 0.5, 0.4), cartoes]])


## Galho de a até b, afinando (cilindro alinhado ao segmento).
func _galho(a: Vector3, b: Vector3, r0: float, r1: float, lados: int = 6) -> Array:
	var d := b - a
	var c := CylinderMesh.new()
	c.bottom_radius = r0
	c.top_radius = r1
	c.height = d.length()
	c.radial_segments = lados
	c.rings = 1
	var y := d.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	return [c, Transform3D(Basis(x, y, z), (a + b) / 2.0)]


## Cipó pendurado: uma corda que desce da copa em curva, em segmentos.
func _cipo(topo: Vector3, base: Vector3, barriga: float, rng: RandomNumberGenerator) -> Array:
	var partes := []
	var lado := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * barriga
	var n := 6
	var ant := topo
	for k in range(1, n + 1):
		var t := float(k) / n
		var p := topo.lerp(base, t) + lado * sin(t * PI)
		partes.append(_galho(ant, p, 0.035, 0.03, 4))
		ant = p
	return partes


func _lamina_alta(esp: float, alto: float, comp: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(esp, alto, comp)
	return b


# ---------------- texturas de folha (geradas na montagem) ----------------
# Cor quase branca com variações: o material dá o verde (e a cor de cada árvore) por cima.

func _folha(img: Image, centro: Vector2, comp: float, larg: float, ang: float, cor: Color) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var n := d.orthogonal()
	var r := int(ceil(comp / 2.0)) + 1
	for y in range(int(centro.y) - r, int(centro.y) + r + 1):
		for x in range(int(centro.x) - r, int(centro.x) + r + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var q := Vector2(x, y) - centro
			var u := q.dot(d) / (comp / 2.0)
			var v := q.dot(n) / (larg / 2.0)
			# folha com ponta: mais larga perto da base
			var forma := (1.0 - u * u) * (1.0 - 0.35 * u)
			if v * v <= forma and absf(u) <= 1.0:
				var nervura := 0.78 if absf(v) < 0.09 else 1.0
				var borda := 0.82 if v * v > forma * 0.7 else 1.0
				img.set_pixel(x, y, Color(cor.r * nervura * borda, cor.g * nervura * borda, cor.b * nervura * borda, 1.0))


func _cor_folha(rng: RandomNumberGenerator) -> Color:
	var l := rng.randf_range(0.55, 1.0)
	var t := rng.randf()
	if t < 0.15:
		return Color(l * 1.0, l * 0.92, l * 0.55)   # folha nova, amarelada
	if t < 0.3:
		return Color(l * 0.75, l * 0.85, l * 0.8)   # folha velha, acinzentada
	return Color(l * 0.85, l, l * 0.8)


## Tufo de folhas ovais em todas as direções, mais denso no meio, para as copas.
func _textura_folhagem(tam: int, n: int, semente: int, escala: float = 1.0) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.4, 0.3, 0.0))
	var c := Vector2(tam / 2.0, tam / 2.0)
	for k in n:
		var r := sqrt(rng.randf()) * tam * 0.4
		var a := rng.randf() * TAU
		var p := c + Vector2(cos(a), sin(a)) * r
		var ang := a + rng.randf_range(-0.7, 0.7)
		_folha(img, p, rng.randf_range(26, 42) * escala * tam / 256.0, rng.randf_range(10, 16) * escala * tam / 256.0, ang, _cor_folha(rng))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Folha pinada (samambaia, palmeira): um talo no meio e folíolos dos dois lados, afinando até a ponta.
## v = 0 é a ponta; v = 1, a base. 'abertura' < 1 deixa os folíolos estreitos e caídos (palmeira).
func _textura_fronde(larg: int, alto: int, abertura: float, semente: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	var img := Image.create(larg, alto, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.4, 0.3, 0.0))
	var cx := larg / 2.0
	for y in alto:
		for dx in range(-1, 2):
			img.set_pixel(int(cx) + dx, y, Color(0.6, 0.7, 0.45, 1.0))
	var passo := 7
	var y := 6
	while y < alto - 4:
		var t := float(y) / alto            # 0 na ponta, 1 na base
		var comp := (larg * 0.48) * (0.25 + 0.75 * sin(t * PI * 0.9 + 0.1))
		for lado in [-1, 1]:
			var dir := Vector2(lado * cos(0.5 + (1.0 - abertura) * 0.7), -sin(0.5 + (1.0 - abertura) * 0.7))
			var centro := Vector2(cx, y) + dir * comp * 0.5
			_folha(img, centro, comp, maxf(4.0, comp * 0.32 * (0.6 + abertura * 0.6)), dir.angle(), _cor_folha(rng))
		y += passo
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Folha palmada da embaúba: sete lobos compridos saindo de um centro, como uma mão aberta.
func _textura_embauba(tam: int) -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var img := Image.create(tam, tam, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.6, 0.65, 0.6, 0.0))
	var c := Vector2(tam / 2.0, tam * 0.55)
	for k in 9:
		var ang := -PI / 2 + (k - 4) * 0.36 + rng.randf_range(-0.05, 0.05)
		var comp := tam * rng.randf_range(0.36, 0.46)
		var dir := Vector2(cos(ang), sin(ang))
		var cor := Color(0.95, 1.0, 0.95) * rng.randf_range(0.8, 1.0)
		_folha(img, c + dir * comp * 0.5, comp, comp * 0.3, ang, cor)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
