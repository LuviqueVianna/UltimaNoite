extends Node3D
## Cabana do Caçador (Velho Bento), montada com primitivas, seguindo a Direção de Arte v1, seção 3.1:
## cabana baixa de troncos escuros, sapê, chaminé de pedra com fumaça fina, peles no varal,
## armadilhas de laço, lenha, toco com machado, janela lateral com luz âmbar pelas frestas,
## porta dos fundos, porta da frente com degrau e moita (esconderijo).
## Frente voltada para +z; janela na parede +x (as duas ficam de frente para a câmera).

const AMBAR := Color("#E89A3C")
const FOGO := Color("#F2C26B")
const LARGURA := 6.0
const FUNDO := 4.4
const PAREDE := 2.3

var _luzes_fogo: Array[Light3D] = []
var _base_energia: Array[float] = []
var _t := 0.0
var _ruido := FastNoiseLite.new()
var _grao: NoiseTexture2D


func _ready() -> void:
	_grao = NoiseTexture2D.new()
	_grao.width = 128
	_grao.height = 128
	_grao.seamless = true
	var n := FastNoiseLite.new()
	n.frequency = 0.08
	_grao.noise = n
	_montar()


func _process(dt: float) -> void:
	_t += dt
	for k in _luzes_fogo.size():
		var tremor := 0.82 + 0.18 * _ruido.get_noise_1d(_t * 9.0 + k * 50.0) + 0.06 * sin(_t * 23.0 + k)
		_luzes_fogo[k].light_energy = _base_energia[k] * tremor


# ---------------- ajudantes ----------------

func _mat(cor: Color, aspereza: float = 0.9, escala_uv: Vector3 = Vector3(1, 1, 1)) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.albedo_texture = _grao
	m.roughness = aspereza
	m.uv1_triplanar = true
	m.uv1_scale = escala_uv
	return m


func _brilho(cor: Color, energia: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = energia
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _peca(malha: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, pai: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	pai.add_child(mi)
	return mi


func _caixa(tam: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tam
	return b


func _cil(raio: float, altura: float, lados: int = 8) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = raio
	c.bottom_radius = raio
	c.height = altura
	c.radial_segments = lados
	return c


func _luz(pos: Vector3, cor: Color, energia: float, alcance: float, sombra: bool, nevoa: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = cor
	l.light_energy = energia
	l.omni_range = alcance
	l.omni_attenuation = 1.6
	l.shadow_enabled = sombra
	l.light_volumetric_fog_energy = nevoa
	add_child(l)
	_luzes_fogo.append(l)
	_base_energia.append(energia)
	return l


# ---------------- montagem ----------------

func _montar() -> void:
	var madeira := Color("#4A3F36")
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	# paredes de troncos
	var raio := 0.15
	var fileiras := int(PAREDE / (raio * 2.0))
	for f in fileiras:
		var y := raio + f * raio * 2.0
		for lado in [-1, 1]:
			var tom := madeira.darkened(rng.randf_range(0.0, 0.3))
			_peca(_cil(raio, LARGURA + 0.4), _mat(tom, 0.95, Vector3(3, 0.5, 3)), Vector3(0, y, lado * FUNDO / 2.0), Vector3(0, 0, PI / 2))
			_peca(_cil(raio, FUNDO + 0.4), _mat(tom, 0.95, Vector3(3, 0.5, 3)), Vector3(lado * LARGURA / 2.0, y + raio, 0), Vector3(PI / 2, 0, 0))
	# miolo escuro (fecha as frestas entre troncos)
	_peca(_caixa(Vector3(LARGURA - 0.2, PAREDE, FUNDO - 0.2)), _mat(madeira.darkened(0.5)), Vector3(0, PAREDE / 2.0, 0))
	# oitões
	var oitao := PrismMesh.new()
	oitao.size = Vector3(FUNDO, 1.6, 0.25)
	for lado in [-1, 1]:
		_peca(oitao, _mat(madeira.darkened(0.2), 0.95, Vector3(2, 2, 2)), Vector3(lado * (LARGURA / 2.0 - 0.05), PAREDE + 0.8, 0), Vector3(0, PI / 2, 0))
	# telhado de sapê, baixo e com beiral
	var sape := _mat(Color(0.4, 0.33, 0.21), 1.0, Vector3(1, 6, 1))
	var inclinacao := atan(1.6 / (FUNDO / 2.0 + 0.6))
	var comp := sqrt(1.6 * 1.6 + pow(FUNDO / 2.0 + 0.6, 2))
	for lado in [-1, 1]:
		_peca(_caixa(Vector3(LARGURA + 1.2, 0.35, comp)), sape, Vector3(0, PAREDE + 0.75, lado * (FUNDO / 2.0 + 0.6) / 2.0), Vector3(lado * inclinacao, 0, 0))
	_peca(_cil(0.22, LARGURA + 1.2, 6), sape, Vector3(0, PAREDE + 1.6, 0), Vector3(0, 0, PI / 2))
	_chamine()
	_janela()
	_portas()
	_varal()
	_lenha_e_toco()
	_moita()


func _chamine() -> void:
	var pedra := _mat(Color(0.33, 0.32, 0.3), 1.0, Vector3(4, 4, 4))
	var x := -LARGURA / 2.0 - 0.45
	for k in 9:
		var tam := Vector3(0.95 - k * 0.02, 0.55, 0.95 - k * 0.02)
		_peca(_caixa(tam), pedra, Vector3(x + (0.03 if k % 2 == 0 else -0.03), 0.275 + k * 0.53, -0.6), Vector3(0, k * 0.07, 0))
	# fumaça fina
	var fumaca := GPUParticles3D.new()
	fumaca.position = Vector3(x, 4.9, -0.6)
	fumaca.amount = 40
	fumaca.lifetime = 7.0
	fumaca.preprocess = 7.0
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0.25, 1, 0)
	pm.spread = 8.0
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0.12, 0.05, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.0
	var curva := CurveTexture.new()
	var c := Curve.new()
	c.add_point(Vector2(0, 0.3))
	c.add_point(Vector2(1, 2.2))
	curva.curve = c
	pm.scale_curve = curva
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	grad.colors = PackedColorArray([Color(0.55, 0.58, 0.6, 0.0), Color(0.55, 0.58, 0.6, 0.22), Color(0.55, 0.58, 0.6, 0.0)])
	var gt := GradientTexture1D.new()
	gt.gradient = grad
	pm.color_ramp = gt
	fumaca.process_material = pm
	var quad := QuadMesh.new()
	quad.size = Vector2(0.8, 0.8)
	var mq := StandardMaterial3D.new()
	mq.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mq.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mq.vertex_color_use_as_albedo = true
	mq.albedo_texture = _bolinha()
	mq.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = mq
	fumaca.draw_pass_1 = quad
	add_child(fumaca)


func _bolinha() -> ImageTexture:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 15.5
			img.set_pixel(x, y, Color(1, 1, 1, clamp(1.0 - d, 0.0, 1.0) ** 2))
	return ImageTexture.create_from_image(img)


func _janela() -> void:
	var x := LARGURA / 2.0 + 0.14
	# luz de dentro, vista pelas frestas da veneziana
	_peca(_caixa(Vector3(0.02, 0.75, 1.05)), _brilho(AMBAR, 2.2), Vector3(x, 1.35, 0.4))
	var tabua := _mat(Color("#4A3F36").darkened(0.35))
	for k in 6:
		_peca(_caixa(Vector3(0.04, 0.08, 1.15)), tabua, Vector3(x + 0.06, 1.05 + k * 0.12, 0.4), Vector3(0, 0, -0.5))
	var moldura := _mat(Color("#4A3F36").darkened(0.15))
	for dz in [-0.6, 0.6]:
		_peca(_caixa(Vector3(0.1, 0.95, 0.1)), moldura, Vector3(x + 0.04, 1.35, 0.4 + dz))
	for dy in [-0.47, 0.47]:
		_peca(_caixa(Vector3(0.1, 0.1, 1.3)), moldura, Vector3(x + 0.04, 1.35 + dy, 0.4))
	# o calor que sai pela janela e cai no barro
	_luz(Vector3(x + 0.7, 1.35, 0.4), AMBAR, 3.2, 9.0, true, 2.5)


func _portas() -> void:
	var porta := _mat(Color("#4A3F36").darkened(0.25), 0.9, Vector3(1, 4, 1))
	var z := FUNDO / 2.0 + 0.16
	# frente, com degrau de madeira e luz vazando por baixo
	_peca(_caixa(Vector3(1.0, 1.95, 0.08)), porta, Vector3(-0.9, 0.98, z))
	_peca(_caixa(Vector3(1.0, 0.04, 0.02)), _brilho(FOGO, 3.0), Vector3(-0.9, 0.02, z + 0.04))
	_peca(_caixa(Vector3(0.03, 1.9, 0.02)), _brilho(AMBAR, 1.6), Vector3(-0.38, 0.98, z + 0.03))
	_peca(_caixa(Vector3(1.4, 0.18, 0.6)), _mat(Color("#4A3F36").lightened(0.05)), Vector3(-0.9, 0.09, z + 0.35))
	_luz(Vector3(-0.9, 0.25, z + 0.6), AMBAR, 0.8, 3.0, false, 0.6)
	# fundos, dando para o mato
	_peca(_caixa(Vector3(0.9, 1.85, 0.08)), porta, Vector3(1.4, 0.93, -z))
	_peca(_caixa(Vector3(0.9, 0.03, 0.02)), _brilho(FOGO, 2.0), Vector3(1.4, 0.02, -z - 0.04))


func _varal() -> void:
	var pau := _mat(Color("#4A3F36").lightened(0.1))
	var a := Vector3(4.6, 0, -2.2)
	var b := Vector3(6.4, 0, 2.6)
	for p in [a, b]:
		_peca(_cil(0.06, 2.2, 6), pau, p + Vector3(0, 1.1, 0))
	var meio := (a + b) / 2.0 + Vector3(0, 2.05, 0)
	var dir := (b - a).normalized()
	var corda := _peca(_cil(0.012, a.distance_to(b), 4), _mat(Color(0.5, 0.45, 0.35)), meio)
	corda.basis = Basis(Quaternion(Vector3.UP, dir))
	var giro := atan2(dir.x, dir.z)
	var peles := [Color(0.36, 0.26, 0.17), Color(0.45, 0.35, 0.24), Color(0.28, 0.22, 0.17)]
	for k in 3:
		var p := a.lerp(b, 0.25 + k * 0.25) + Vector3(0, 1.55, 0)
		_peca(_caixa(Vector3(0.05, 0.85 - k * 0.1, 0.6)), _mat(peles[k], 1.0, Vector3(6, 6, 6)), p, Vector3(0, giro, 0))
	# armadilhas de laço penduradas
	for f in [0.12, 0.88]:
		var laco := TorusMesh.new()
		laco.inner_radius = 0.13
		laco.outer_radius = 0.16
		_peca(laco, _mat(Color(0.5, 0.45, 0.35)), a.lerp(b, f) + Vector3(0, 1.75, 0), Vector3(PI / 2, giro, 0))


func _lenha_e_toco() -> void:
	var lenha := _mat(Color(0.42, 0.33, 0.25), 1.0, Vector3(4, 4, 4))
	var base := Vector3(-LARGURA / 2.0 - 0.6, 0, 1.6)
	var k := 0
	for fileira in 4:
		for n in 4 - fileira:
			var p := base + Vector3(0, 0.09 + fileira * 0.16, (n - (3 - fileira) / 2.0) * 0.18)
			_peca(_cil(0.085, 0.75, 6), lenha, p, Vector3(0, 0, PI / 2 + (k % 3) * 0.05))
			k += 1
	var toco := Vector3(-5.2, 0, 3.6)
	_peca(_cil(0.36, 0.55, 10), _mat(Color(0.38, 0.3, 0.23)), toco + Vector3(0, 0.275, 0))
	_peca(_cil(0.025, 0.75, 6), _mat(Color(0.45, 0.36, 0.25)), toco + Vector3(0.12, 0.85, 0.05), Vector3(0, 0, -0.45))
	_peca(_caixa(Vector3(0.22, 0.13, 0.03)), _mat(Color(0.3, 0.3, 0.32), 0.5), toco + Vector3(0.0, 0.58, 0.05), Vector3(0, 0, -0.45))


func _moita() -> void:
	var folha := ShaderMaterial.new()
	folha.shader = preload("res://shaders/mata.gdshader")
	folha.set_shader_parameter("cor", Color(0.1, 0.19, 0.12))
	folha.set_shader_parameter("vento", 0.4)
	var centro := Vector3(-8.0, 0, -4.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	for k in 7:
		var s := SphereMesh.new()
		s.radius = rng.randf_range(0.7, 1.0)
		s.height = s.radius * 1.6
		s.radial_segments = 10
		s.rings = 5
		_peca(s, folha, centro + Vector3(rng.randf_range(-1.1, 1.1), s.radius * 0.7, rng.randf_range(-0.9, 0.9)))


## Pontos de interesse em coordenadas locais (para a lógica e para os testes).
func pontos() -> Dictionary:
	return {
		"janela": Vector3(LARGURA / 2.0 + 1.0, 0, 0.4),
		"porta_frente": Vector3(-0.9, 0, FUNDO / 2.0 + 1.0),
		"porta_fundos": Vector3(1.4, 0, -FUNDO / 2.0 - 1.0),
		"moita": Vector3(-8.0, 0, -4.5),
	}
