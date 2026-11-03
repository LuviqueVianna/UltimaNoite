extends Node3D
## Desenha a mata a partir das listas de árvores e plantas do mundo.
## Cada espécie vira um MultiMesh: milhares de árvores em poucas chamadas de desenho.
## As formas são provisórias (primitivas combinadas), só para testar densidade, luz e leitura.

const SHADER := preload("res://shaders/mata.gdshader")

const QUADRA := 32.0

var total_instancias := 0


func montar(arvores: Array, plantas: Array) -> void:
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
			var tom := rng.randf_range(0.75, 1.2)
			mm.set_instance_color(k, Color(tom * rng.randf_range(0.92, 1.05), tom, tom * rng.randf_range(0.9, 1.08)))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Mata_" + chave.replace("|", "_")
		mmi.multimesh = mm
		var grande: bool = tipo in ["comum", "jequitiba", "embauba", "palmeira", "bambu"]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if grande else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		total_instancias += lista.size()


# ---------------- materiais ----------------

func _mat(cor: Color, vento: float = 1.0, translucidez: float = 0.25, rugosidade: float = 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("rugosidade", rugosidade)
	m.set_shader_parameter("cor", cor)
	m.set_shader_parameter("vento", vento)
	m.set_shader_parameter("translucidez", translucidez)
	return m


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
	var tronco := [[_cilindro(0.22, 0.12, 9.0), _em(Vector3(0, 4.5, 0))]]
	var copa := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 8
	for k in 7:
		var g := rng.randf() * TAU
		var r := 0.0 if k == 0 else rng.randf_range(1.0, 2.2)
		copa.append([_esfera(rng.randf_range(1.5, 2.2), 0.75), _em(Vector3(cos(g) * r, rng.randf_range(8.0, 10.2), sin(g) * r))])
	return _juntar([[_mat(Color(0.3, 0.26, 0.22), 0.2), tronco], [_mat(Color(0.11, 0.19, 0.13), 1.0, 0.25, 1.1), copa]])


func _jequitiba() -> ArrayMesh:
	var tronco := [[_cilindro(0.75, 0.4, 19.0, 8), _em(Vector3(0, 9.5, 0))]]
	for k in 3:
		var g := TAU * k / 3.0
		tronco.append([_cilindro(0.3, 0.15, 6.0), _em(Vector3(cos(g) * 1.6, 19.5, sin(g) * 1.6), Vector3(0, -g, 0.7))])
	var copa := []
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for k in 7:
		var g := TAU * k / 7.0
		var r := 0.0 if k == 0 else rng.randf_range(3.0, 4.5)
		copa.append([_esfera(rng.randf_range(3.2, 4.2), 0.55), _em(Vector3(cos(g) * r, 21.5 + rng.randf_range(-0.8, 1.0), sin(g) * r))])
	for k in 6:
		var g := rng.randf() * TAU
		copa.append([_esfera(rng.randf_range(1.8, 2.6), 0.7), _em(Vector3(cos(g) * 4.8, 20.0 + rng.randf_range(-1.0, 1.5), sin(g) * 4.8))])
	return _juntar([[_mat(Color(0.33, 0.29, 0.25), 0.1), tronco], [_mat(Color(0.09, 0.16, 0.1), 1.0, 0.25, 1.6), copa]])


func _embauba() -> ArrayMesh:
	var tronco := [[_cilindro(0.13, 0.09, 11.0), _em(Vector3(0, 5.5, 0))]]
	var folhas := []
	for k in 7:
		var g := TAU * k / 7.0
		var b := Basis(Vector3.UP, g) * Basis(Vector3.RIGHT, 0.35)
		folhas.append([_esfera(1.0, 0.18), Transform3D(b.scaled(Vector3(0.7, 1, 1.5)), Vector3(0, 11.0, 0) + Basis(Vector3.UP, g) * Vector3(0, -0.3, 1.2))])
	# folhas prateadas por baixo: refletem a lua
	return _juntar([[_mat(Color(0.58, 0.58, 0.54), 0.3), tronco], [_mat(Color(0.36, 0.44, 0.4), 1.2, 0.4), folhas]])


func _palmeira() -> ArrayMesh:
	var tronco := [[_cilindro(0.09, 0.07, 9.0, 5), _em(Vector3(0, 4.5, 0))]]
	return _juntar([[_mat(Color(0.4, 0.38, 0.32), 0.4), tronco], [_mat(Color(0.12, 0.22, 0.12), 1.4), _roseta(9, 0.35, 2.8, -0.35, 9.0, 5)]])


func _bambu() -> ArrayMesh:
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
		folhas.append([_esfera(1.1, 0.5), Transform3D(b, base + b * Vector3(0, h * 0.9, 0))])
	return _juntar([[_mat(Color(0.42, 0.45, 0.28), 0.6), hastes], [_mat(Color(0.2, 0.27, 0.13), 1.5, 0.25, 0.6), folhas]])


func _samambaia() -> ArrayMesh:
	return _juntar([[_mat(Color(0.12, 0.23, 0.13), 0.5, 0.35), _roseta(8, 0.32, 1.2, 0.55, 0.05, 1)]])


func _bromelia() -> ArrayMesh:
	var folhas := _roseta(11, 0.12, 0.7, 0.85, 0.05, 2)
	return _juntar([[_mat(Color(0.2, 0.26, 0.12), 0.3, 0.3), folhas]])


func _moita() -> ArrayMesh:
	var partes := []
	for c in [Vector3(0, 0.5, 0), Vector3(0.5, 0.4, 0.3), Vector3(-0.4, 0.45, 0.2)]:
		partes.append([_esfera(0.75, 0.8), _em(c)])
	return _juntar([[_mat(Color(0.1, 0.18, 0.12), 0.4, 0.25, 0.35), partes]])
