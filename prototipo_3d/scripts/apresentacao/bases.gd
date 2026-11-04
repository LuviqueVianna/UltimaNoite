extends Node3D
## As bases dos guardiões e a tapera, montadas com primitivas pela Direção de Arte v1 (seção 3).
## Frente (porta principal) voltada para +z local; o nó do mapa fica alguns metros à frente.
## A Cabana do Bento tem o próprio arquivo (cabana_bento.gd).

const CabanaBento := preload("res://scripts/apresentacao/cabana_bento.gd")
const SHADER_MATA := preload("res://shaders/mata.gdshader")

const AMBAR := Color("#E89A3C")
const FOGO := Color("#F2C26B")
const MADEIRA := Color("#4A3F36")
const CAL := Color(0.74, 0.71, 0.64)
const BARRO := Color(0.42, 0.3, 0.22)
const PEDRA := Color(0.36, 0.36, 0.34)

var tipo := "bento"
var _luzes: Array[OmniLight3D] = []
var _base_energia: Array[float] = []
var _t := 0.0
var _ruido := FastNoiseLite.new()
var _grao: NoiseTexture2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = hash(tipo)
	_grao = NoiseTexture2D.new()
	_grao.width = 128
	_grao.height = 128
	_grao.seamless = true
	var nz := FastNoiseLite.new()
	nz.frequency = 0.08
	_grao.noise = nz
	match tipo:
		"bento":
			var c := CabanaBento.new()
			add_child(c)
		"iara":
			_iara()
		"anselmo":
			_anselmo()
		"marta":
			_marta()
		"quincas":
			_quincas()
		"vazia":
			_tapera()


func _process(dt: float) -> void:
	_t += dt
	for k in _luzes.size():
		var tremor := 0.84 + 0.16 * _ruido.get_noise_1d(_t * 8.0 + k * 40.0)
		_luzes[k].light_energy = _base_energia[k] * tremor


# ---------------- ajudantes ----------------

func _mat(cor: Color, aspereza: float = 0.9, escala_uv: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.albedo_texture = _grao
	m.roughness = aspereza
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * escala_uv
	return m


func _brilho(cor: Color, energia: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = energia
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


func _p(malha: Mesh, mat: Material, pos: Vector3, rot: Vector3 = Vector3.ZERO, pai: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.layers = 2
	pai.add_child(mi)
	return mi


func _cx(tam: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tam
	return b


func _cil(r_base: float, altura: float, r_topo: float = -1.0, lados: int = 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.bottom_radius = r_base
	c.top_radius = r_base if r_topo < 0.0 else r_topo
	c.height = altura
	c.radial_segments = lados
	return c


func _esf(r: float, achatar: float = 1.0) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 * achatar
	s.radial_segments = 10
	s.rings = 5
	return s


func _prisma(tam: Vector3) -> PrismMesh:
	var p := PrismMesh.new()
	p.size = tam
	return p


func _luz(pos: Vector3, cor: Color, energia: float, alcance: float, sombra: bool = true) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = cor
	l.light_energy = energia
	l.omni_range = alcance
	l.omni_attenuation = 1.6
	l.shadow_enabled = sombra
	l.light_volumetric_fog_energy = 2.0
	l.distance_fade_enabled = true
	l.distance_fade_begin = 70.0
	l.distance_fade_length = 20.0
	l.distance_fade_shadow = 35.0
	add_child(l)
	_luzes.append(l)
	_base_energia.append(energia)


## Telhado de duas águas: cumeeira ao longo de x, caindo para +z e -z.
func _telhado(largura: float, fundo: float, altura_parede: float, subida: float, mat: Material, beiral: float = 0.5) -> void:
	var meia := fundo / 2.0 + beiral
	var inclinacao := atan(subida / meia)
	var comp := sqrt(subida * subida + meia * meia)
	for lado in [-1, 1]:
		_p(_cx(Vector3(largura + beiral * 2.0, 0.18, comp)), mat, Vector3(0, altura_parede + subida / 2.0, lado * meia / 2.0), Vector3(lado * inclinacao, 0, 0))
	for lado in [-1, 1]:
		_p(_prisma(Vector3(fundo, subida, 0.2)), _mat(CAL.darkened(0.1)), Vector3(lado * (largura / 2.0 - 0.1), altura_parede + subida / 2.0, 0), Vector3(0, PI / 2, 0))


func _janela_luz(pos: Vector3, tam: Vector2, cor: Color, rot_y: float = 0.0, tabuas: int = 0) -> void:
	var j := Node3D.new()
	j.position = pos
	j.rotation.y = rot_y
	add_child(j)
	_p(_cx(Vector3(tam.x, tam.y, 0.02)), _brilho(cor, 2.4), Vector3.ZERO, Vector3.ZERO, j)
	var moldura := _mat(MADEIRA.darkened(0.2))
	for dx in [-1, 1]:
		_p(_cx(Vector3(0.08, tam.y + 0.12, 0.08)), moldura, Vector3(dx * tam.x / 2.0, 0, 0.03), Vector3.ZERO, j)
	for dy in [-1, 1]:
		_p(_cx(Vector3(tam.x + 0.12, 0.08, 0.08)), moldura, Vector3(0, dy * tam.y / 2.0, 0.03), Vector3.ZERO, j)
	for k in tabuas:
		var y := -tam.y / 2.0 + (k + 0.5) * tam.y / tabuas
		_p(_cx(Vector3(tam.x, 0.05, 0.03)), _mat(MADEIRA.darkened(0.4)), Vector3(0, y, 0.05), Vector3(-0.5, 0, 0), j)


func _porta(pos: Vector3, tam: Vector2, cor: Color, aberta: float = 0.0, luz: Color = AMBAR) -> void:
	var dobra := Node3D.new()
	dobra.position = pos + Vector3(-tam.x / 2.0, 0, 0)
	dobra.rotation.y = aberta
	add_child(dobra)
	_p(_cx(Vector3(tam.x, tam.y, 0.07)), _mat(cor, 0.9, 3.0), Vector3(tam.x / 2.0, tam.y / 2.0, 0), Vector3.ZERO, dobra)
	# luz por baixo e pela fresta
	_p(_cx(Vector3(tam.x, 0.03, 0.02)), _brilho(FOGO, 2.0), pos + Vector3(0, 0.015, 0.04))
	if aberta > 0.01:
		_p(_cx(Vector3(tam.x * 0.9, tam.y, 0.02)), _brilho(luz, 1.4), pos + Vector3(0, tam.y / 2.0, -0.04))


func _moita(centro: Vector3, n: int = 6, raio: float = 1.0) -> void:
	var folha := ShaderMaterial.new()
	folha.shader = SHADER_MATA
	folha.set_shader_parameter("cor", Color(0.1, 0.19, 0.12))
	folha.set_shader_parameter("vento", 0.4)
	folha.set_shader_parameter("altura_copa", 1.3)
	folha.set_shader_parameter("raio_copa", 1.0)
	for k in n:
		var r := _rng.randf_range(0.6, 0.95) * raio
		_p(_esf(r, 0.8), folha, centro + Vector3(_rng.randf_range(-1.0, 1.0) * raio, r * 0.6, _rng.randf_range(-0.8, 0.8) * raio))


func _caixote(pos: Vector3, lado: float = 0.6) -> void:
	_p(_cx(Vector3.ONE * lado), _mat(Color(0.45, 0.36, 0.25), 0.95, 4.0), pos + Vector3(0, lado / 2.0, 0), Vector3(0, _rng.randf_range(-0.4, 0.4), 0))


# ---------------- Dona Iara: Casa da Curandeira (acento verde-erva) ----------------

func _iara() -> void:
	var verde := Color("#5E8C4A")
	var w := 7.0
	var f := 5.0
	var h := 2.6
	# pau a pique caiado, com o barro aparecendo onde a cal descascou
	_p(_cx(Vector3(w, h, f)), _mat(CAL, 0.95, 1.5), Vector3(0, h / 2.0, 0))
	for k in 14:
		var lado := 1 if _rng.randf() < 0.6 else -1
		var x := _rng.randf_range(-w / 2.0 + 0.4, w / 2.0 - 0.4)
		var y := _rng.randf_range(0.3, h - 0.3)
		_p(_cx(Vector3(_rng.randf_range(0.3, 0.8), _rng.randf_range(0.2, 0.5), 0.03)), _mat(BARRO), Vector3(x, y, lado * (f / 2.0 + 0.01)))
	_telhado(w, f, h, 1.5, _mat(Color(0.45, 0.24, 0.17), 0.85, 5.0))
	# musgo nas telhas
	for k in 6:
		_p(_cx(Vector3(_rng.randf_range(0.6, 1.4), 0.04, 0.5)), _mat(Color(0.22, 0.3, 0.15)), Vector3(_rng.randf_range(-3, 3), h + 0.8, 1.4), Vector3(0.6, 0, 0))
	# alpendre na frente, com banco
	var alp := 2.4
	_p(_cx(Vector3(w + 0.6, 0.12, alp)), _mat(Color(0.45, 0.24, 0.17), 0.85, 5.0), Vector3(0, h + 0.05, f / 2.0 + alp / 2.0), Vector3(-0.18, 0, 0))
	for x in [-w / 2.0, -1.0, 1.4, w / 2.0]:
		_p(_cil(0.08, h), _mat(MADEIRA), Vector3(x, h / 2.0, f / 2.0 + alp - 0.15))
	_p(_cx(Vector3(1.6, 0.08, 0.4)), _mat(MADEIRA.lightened(0.1)), Vector3(-2.2, 0.45, f / 2.0 + 0.4))
	for x in [-2.8, -1.6]:
		_p(_cx(Vector3(0.08, 0.45, 0.35)), _mat(MADEIRA), Vector3(x, 0.22, f / 2.0 + 0.4))
	# ervas secando no alpendre
	for k in 7:
		var x := -3.0 + k * 0.55
		_p(_cil(0.07, 0.4, 0.02, 6), _mat(verde.darkened(0.25 if k % 2 == 0 else 0.0)), Vector3(x, h - 0.35, f / 2.0 + 1.6))
	# janela da cozinha com cortina de renda (luz âmbar)
	_janela_luz(Vector3(1.9, 1.4, f / 2.0 + 0.03), Vector2(1.1, 0.9), AMBAR)
	_p(_cx(Vector3(1.05, 0.25, 0.02)), _mat(Color(0.9, 0.88, 0.82)), Vector3(1.9, 1.72, f / 2.0 + 0.06))
	_porta(Vector3(-0.4, 0, f / 2.0 + 0.04), Vector2(0.95, 2.0), MADEIRA)
	# porta dos fundos entreaberta
	_porta(Vector3(1.6, 0, -f / 2.0 - 0.04), Vector2(0.9, 1.9), MADEIRA, -1.0)
	# oratório com vela na parede de fora
	_p(_cx(Vector3(0.4, 0.5, 0.25)), _mat(MADEIRA.lightened(0.15)), Vector3(-w / 2.0 - 0.13, 1.6, 0.8))
	_p(_cil(0.03, 0.12), _brilho(FOGO, 3.0), Vector3(-w / 2.0 - 0.2, 1.5, 0.8))
	_luz(Vector3(1.9, 1.4, f / 2.0 + 1.2), AMBAR, 2.6, 8.0)
	_luz(Vector3(-w / 2.0 - 0.6, 1.6, 0.8), FOGO, 0.5, 3.0, false)
	# horta de ervas cercada de bambu
	var hx := w / 2.0 + 2.6
	for i in 12:
		var t := float(i) / 11.0
		_p(_cil(0.04, 0.9), _mat(Color(0.5, 0.52, 0.3)), Vector3(hx - 1.6 + t * 3.2, 0.45, f / 2.0 + 0.5))
		_p(_cil(0.04, 0.9), _mat(Color(0.5, 0.52, 0.3)), Vector3(hx - 1.6 + t * 3.2, 0.45, -f / 2.0 + 0.5))
	for fila in 4:
		for k in 6:
			_p(_esf(0.18, 0.8), _mat(verde.lightened(_rng.randf_range(-0.2, 0.15))), Vector3(hx - 1.3 + k * 0.52, 0.14, -1.4 + fila * 0.9))
	# galinheiro de bambu (esconderijo)
	var g := Vector3(-w / 2.0 - 3.0, 0, -1.5)
	for i in 5:
		for j in 2:
			_p(_cil(0.04, 1.2), _mat(Color(0.48, 0.5, 0.3)), g + Vector3(-1.0 + i * 0.5, 0.6, -0.6 + j * 1.2))
	_p(_cx(Vector3(2.3, 0.08, 1.5)), _mat(Color(0.4, 0.34, 0.22)), g + Vector3(0, 1.22, 0))


# ---------------- Frei Anselmo: Capela dos Segredos (acento dourado-velho) ----------------

func _anselmo() -> void:
	var ouro := Color("#B8963E")
	var w := 5.0
	var f := 8.0
	var h := 3.8
	var capela := Node3D.new()
	capela.rotation.y = PI / 2   # a nave corre ao longo de z: o telhado é montado em x e girado
	add_child(capela)
	_p(_cx(Vector3(f, h, w)), _mat(CAL, 0.95, 1.5), Vector3(0, h / 2.0, 0), Vector3.ZERO, capela)
	var telha := _mat(Color(0.32, 0.28, 0.25), 0.85, 5.0)
	var meia := w / 2.0 + 0.4
	var sub := 1.8
	var inc := atan(sub / meia)
	var comp := sqrt(sub * sub + meia * meia)
	for lado in [-1, 1]:
		_p(_cx(Vector3(f + 0.6, 0.18, comp)), telha, Vector3(0, h + sub / 2.0, lado * meia / 2.0), Vector3(lado * inc, 0, 0), capela)
	# frontão triangular na fachada (+z depois do giro)
	_p(_prisma(Vector3(w + 0.2, 2.2, 0.3)), _mat(CAL.lightened(0.05)), Vector3(0, h + 1.1, f / 2.0 + 0.05))
	_p(_cx(Vector3(0.14, 0.9, 0.1)), _mat(MADEIRA), Vector3(0, h + 1.7, f / 2.0 + 0.25))
	_p(_cx(Vector3(0.55, 0.14, 0.1)), _mat(MADEIRA), Vector3(0, h + 1.85, f / 2.0 + 0.25))
	# porta dupla pesada
	_p(_cx(Vector3(0.85, 2.5, 0.12)), _mat(MADEIRA.darkened(0.2), 0.9, 3.0), Vector3(-0.44, 1.25, f / 2.0 + 0.06))
	_p(_cx(Vector3(0.85, 2.5, 0.12)), _mat(MADEIRA.darkened(0.2), 0.9, 3.0), Vector3(0.44, 1.25, f / 2.0 + 0.06))
	_p(_cx(Vector3(1.8, 0.03, 0.02)), _brilho(ouro, 1.6), Vector3(0, 0.02, f / 2.0 + 0.13))
	# vitral lateral com luz de velas
	for z in [-1.8, 1.0]:
		_janela_luz(Vector3(w / 2.0 + 0.03, 2.2, z), Vector2(0.8, 1.6), ouro.lightened(0.1), PI / 2)
		_p(_cx(Vector3(0.04, 1.6, 0.06)), _mat(PEDRA.darkened(0.4)), Vector3(w / 2.0 + 0.08, 2.2, z))
		_p(_cx(Vector3(0.04, 0.06, 0.8)), _mat(PEDRA.darkened(0.4)), Vector3(w / 2.0 + 0.08, 2.4, z))
	_luz(Vector3(w / 2.0 + 1.2, 2.2, -0.4), ouro, 2.2, 9.0)
	# porta lateral da sacristia
	_porta(Vector3(-w / 2.0 - 0.04, 0, -2.6), Vector2(0.8, 1.9), MADEIRA)
	# sineira de madeira com o sino, ao lado da fachada
	var s := Vector3(-w / 2.0 - 1.6, 0, f / 2.0 - 0.6)
	for dx in [-0.6, 0.6]:
		_p(_cx(Vector3(0.16, 4.2, 0.16)), _mat(MADEIRA), s + Vector3(dx, 2.1, 0))
	_p(_cx(Vector3(1.5, 0.16, 0.2)), _mat(MADEIRA), s + Vector3(0, 4.1, 0))
	_p(_cil(0.34, 0.55, 0.16, 14), _mat(Color(0.5, 0.38, 0.2), 0.35), s + Vector3(0, 3.65, 0))
	_p(_cil(0.012, 2.8), _mat(Color(0.55, 0.5, 0.4)), s + Vector3(0.1, 2.1, 0.05))
	# cemitério: cruzes de madeira tortas, muro baixo de pedra solta
	var c0 := Vector3(w / 2.0 + 3.0, 0, -1.0)
	for k in 7:
		var p := c0 + Vector3((k % 3) * 1.4, 0, (k / 3) * 1.6 - 1.6)
		var cruz := Node3D.new()
		cruz.position = p
		cruz.rotation = Vector3(_rng.randf_range(-0.15, 0.15), _rng.randf_range(-0.4, 0.4), _rng.randf_range(-0.2, 0.2))
		add_child(cruz)
		_p(_cx(Vector3(0.1, 1.0, 0.08)), _mat(MADEIRA.darkened(0.1)), Vector3(0, 0.5, 0), Vector3.ZERO, cruz)
		_p(_cx(Vector3(0.5, 0.09, 0.08)), _mat(MADEIRA.darkened(0.1)), Vector3(0, 0.75, 0), Vector3.ZERO, cruz)
		_p(_cx(Vector3(0.5, 0.06, 1.0)), _mat(Color(0.25, 0.22, 0.18)), Vector3(0, 0.03, 0.55), Vector3.ZERO, cruz)
	# lápide maior (esconderijo)
	_p(_cx(Vector3(1.0, 1.3, 0.3)), _mat(PEDRA, 1.0, 3.0), c0 + Vector3(1.4, 0.65, 2.4), Vector3(0, 0.2, 0.05))
	for k in 18:
		var t := float(k) / 17.0
		_p(_cx(Vector3(0.5, 0.45, 0.4)), _mat(PEDRA.darkened(_rng.randf_range(0.0, 0.3)), 1.0, 3.0), c0 + Vector3(-0.9 + t * 4.6, 0.22, -3.0), Vector3(0, _rng.randf(), 0))
	# árvore grande e retorcida
	var a := Vector3(-w / 2.0 - 3.5, 0, -3.0)
	_p(_cil(0.4, 3.0, 0.3), _mat(Color(0.3, 0.26, 0.22)), a + Vector3(0, 1.5, 0), Vector3(0, 0, 0.12))
	_p(_cil(0.25, 3.0, 0.12), _mat(Color(0.3, 0.26, 0.22)), a + Vector3(0.7, 3.8, 0.2), Vector3(0.2, 0, -0.6))
	_p(_cil(0.2, 2.6, 0.1), _mat(Color(0.3, 0.26, 0.22)), a + Vector3(-0.6, 3.6, -0.2), Vector3(-0.2, 0, 0.7))
	_moita(a + Vector3(0.3, 4.2, 0), 5, 1.8)


# ---------------- Marta: Torre do Vigia (acento azul-frio) ----------------

func _marta() -> void:
	var frio := Color("#4A7FA8")
	var lado := 3.0
	var tronco := _mat(Color(0.33, 0.27, 0.22), 0.95, 3.0)
	# pilotis de troncos
	for dx in [-1, 1]:
		for dz in [-1, 1]:
			_p(_cil(0.16, 3.2), tronco, Vector3(dx * lado / 2.0, 1.6, dz * lado / 2.0))
	# andares
	_p(_cx(Vector3(lado + 0.2, 2.4, lado + 0.2)), _mat(MADEIRA, 0.95, 3.0), Vector3(0, 3.2 + 1.2, 0))
	_p(_cx(Vector3(lado, 2.2, lado)), _mat(MADEIRA.darkened(0.1), 0.95, 3.0), Vector3(0, 5.6 + 1.1, 0))
	for y in [3.2, 5.6, 7.8]:
		_p(_cx(Vector3(lado + 0.5, 0.14, lado + 0.5)), tronco, Vector3(0, y, 0))
	# janela do segundo andar com luz fria de lampião
	_janela_luz(Vector3(0.4, 6.7, lado / 2.0 + 0.03), Vector2(0.9, 0.7), frio.lightened(0.25), 0.0, 3)
	_luz(Vector3(0.4, 6.7, lado / 2.0 + 1.0), frio.lightened(0.2), 2.4, 10.0)
	# plataforma do topo com parapeito e lampião
	for k in 4:
		var ang := k * PI / 2.0
		var dir := Vector3(sin(ang), 0, cos(ang))
		var lat := Vector3(cos(ang), 0, -sin(ang))
		_p(_cx(Vector3(lado + 0.5, 0.08, 0.08)), tronco, Vector3(0, 8.7, 0) + dir * (lado / 2.0 + 0.2), Vector3(0, ang, 0))
		for t in [-1, 0, 1]:
			_p(_cx(Vector3(0.08, 0.9, 0.08)), tronco, Vector3(0, 8.25, 0) + dir * (lado / 2.0 + 0.2) + lat * t * (lado / 2.0))
	_p(_cil(2.6, 1.6, 0.05, 4), _mat(Color(0.3, 0.27, 0.22), 0.9, 4.0), Vector3(0, 10.4, 0), Vector3(0, PI / 4, 0))
	for dx in [-1, 1]:
		_p(_cx(Vector3(0.1, 1.9, 0.1)), tronco, Vector3(dx * 1.3, 8.75, dx * 1.3))
	_p(_cil(0.1, 0.25), _brilho(frio.lightened(0.4), 3.0), Vector3(1.1, 8.4, 1.1))
	_luz(Vector3(1.1, 8.6, 1.1), frio.lightened(0.3), 1.6, 14.0, false)
	# escada externa em zigue-zague
	for lance in 3:
		var y0 := lance * 2.6
		var sobe := 1 if lance % 2 == 0 else -1
		var z := lado / 2.0 + 0.6
		for d in 10:
			var t := float(d) / 9.0
			_p(_cx(Vector3(0.7, 0.06, 0.28)), tronco, Vector3(sobe * (-1.3 + t * 2.6), y0 + t * 2.6 + 0.1, z))
		_p(_cx(Vector3(3.0, 0.08, 0.06)), tronco, Vector3(0, y0 + 1.4 + 0.7, z + 0.36), Vector3(0, 0, sobe * -0.78))
	_porta(Vector3(1.0, 3.3, lado / 2.0 + 0.11), Vector2(0.8, 1.8), MADEIRA.darkened(0.25))
	# alçapão nos fundos, sob a torre
	_p(_cx(Vector3(0.9, 0.05, 0.9)), _mat(MADEIRA.darkened(0.3)), Vector3(0, 3.12, -0.8))
	# estacas com sininhos de lata (alarme)
	for k in 8:
		var ang := TAU * k / 8.0 + 0.3
		var p := Vector3(cos(ang) * 9.0, 0, sin(ang) * 9.0)
		_p(_cil(0.05, 1.1), tronco, p + Vector3(0, 0.55, 0))
		_p(_cil(0.06, 0.1, 0.03, 8), _mat(Color(0.6, 0.6, 0.58), 0.4), p + Vector3(0.08, 0.95, 0))
	# barril de água e caixotes no limite da mata
	_p(_cil(0.35, 0.9), _mat(Color(0.36, 0.27, 0.18)), Vector3(-2.4, 0.45, 1.0))
	for k in 4:
		_caixote(Vector3(-7.5 + (k % 2) * 0.65, 0 if k < 2 else 0.6, -5.5), 0.6)


# ---------------- Seu Quincas: Moinho Abandonado (acento amarelo-ouro) ----------------

func _quincas() -> void:
	var ouro := Color("#C9A227")
	var w := 6.0
	var f := 5.0
	_p(_cx(Vector3(w, 2.8, f)), _mat(PEDRA, 1.0, 2.5), Vector3(0, 1.4, 0))
	for k in 20:
		_p(_cx(Vector3(_rng.randf_range(0.3, 0.6), _rng.randf_range(0.2, 0.35), 0.06)), _mat(PEDRA.darkened(_rng.randf_range(0.1, 0.35))), Vector3(_rng.randf_range(-2.7, 2.7), _rng.randf_range(0.2, 2.6), f / 2.0 + 0.02))
	_p(_cx(Vector3(w, 2.0, f)), _mat(MADEIRA, 0.95, 3.0), Vector3(0, 3.8, 0))
	# telhado com buracos: um dos lados quebrado
	var meia := f / 2.0 + 0.4
	var sub := 1.5
	var inc := atan(sub / meia)
	var comp := sqrt(sub * sub + meia * meia)
	var telha := _mat(Color(0.3, 0.26, 0.22), 0.9, 4.0)
	_p(_cx(Vector3(w + 0.6, 0.15, comp)), telha, Vector3(0, 4.8 + sub / 2.0, meia / 2.0), Vector3(inc, 0, 0))
	for x in [-2.6, -1.2, 1.4]:
		_p(_cx(Vector3(1.2, 0.15, comp)), telha, Vector3(x, 4.8 + sub / 2.0, -meia / 2.0), Vector3(-inc, 0, _rng.randf_range(-0.05, 0.05)))
	for lado in [-1, 1]:
		_p(_prisma(Vector3(f, sub, 0.2)), _mat(MADEIRA.darkened(0.1)), Vector3(lado * (w / 2.0 - 0.1), 4.8 + sub / 2.0, 0), Vector3(0, PI / 2, 0))
	# janela com luz de vela e sombra de mercadorias
	_janela_luz(Vector3(-1.4, 3.8, f / 2.0 + 0.03), Vector2(1.0, 0.8), ouro.lightened(0.2))
	for k in 3:
		_p(_cx(Vector3(0.12, 0.25 + k * 0.06, 0.02)), _mat(Color(0.12, 0.09, 0.06)), Vector3(-1.75 + k * 0.32, 3.55 + k * 0.03, f / 2.0 + 0.05))
	_luz(Vector3(-1.4, 3.6, f / 2.0 + 1.2), ouro, 2.4, 9.0)
	# porta de carga larga
	_porta(Vector3(1.2, 0, f / 2.0 + 0.04), Vector2(1.8, 2.3), MADEIRA.darkened(0.15))
	_porta(Vector3(-1.5, 0, -f / 2.0 - 0.04), Vector2(0.9, 1.9), MADEIRA)
	# córrego raso ao lado, com a roda d'água parada e quebrada
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.05, 0.09, 0.11)
	agua.roughness = 0.08
	agua.metallic_specular = 0.9
	_p(_cx(Vector3(2.4, 0.05, 30.0)), agua, Vector3(w / 2.0 + 2.4, 0.02, 0), Vector3(0, 0.12, 0))
	for lado in [-1, 1]:
		for k in 10:
			_p(_esf(_rng.randf_range(0.2, 0.4), 0.6), _mat(PEDRA.darkened(0.2)), Vector3(w / 2.0 + 2.4 + lado * 1.3, 0.05, -13.0 + k * 2.8))
	var roda := Node3D.new()
	roda.position = Vector3(w / 2.0 + 1.2, 2.2, 0.4)
	roda.rotation = Vector3(0, 0, PI / 2)
	add_child(roda)
	var aro := TorusMesh.new()
	aro.inner_radius = 2.0
	aro.outer_radius = 2.25
	aro.rings = 24
	aro.ring_segments = 6
	_p(aro, _mat(Color(0.3, 0.24, 0.18)), Vector3.ZERO, Vector3.ZERO, roda)
	_p(_cil(0.25, 0.6), _mat(Color(0.25, 0.2, 0.15)), Vector3.ZERO, Vector3.ZERO, roda)
	for k in 8:
		if k == 3 or k == 6:
			continue   # raios quebrados
		var ang := TAU * k / 8.0
		_p(_cx(Vector3(0.12, 0.1, 4.1)), _mat(Color(0.3, 0.24, 0.18)), Vector3.ZERO, Vector3(0, ang, 0), roda)
		_p(_cx(Vector3(0.5, 0.06, 0.7)), _mat(Color(0.28, 0.22, 0.17)), Vector3(sin(ang) * 2.1, 0, cos(ang) * 2.1), Vector3(0, ang, 0), roda)
	# pinguela de tábua sobre o córrego
	_p(_cx(Vector3(3.6, 0.08, 0.5)), _mat(MADEIRA.lightened(0.1)), Vector3(w / 2.0 + 2.4, 0.25, 6.5), Vector3(0, 0.12, 0))
	# sacos de farinha, carroça sem cavalo, caixotes e quinquilharias
	for k in 6:
		_p(_cil(0.28, 0.6, 0.22, 8), _mat(Color(0.72, 0.66, 0.52), 1.0), Vector3(-3.6 + (k % 3) * 0.55, 0.3 + (k / 3) * 0.5, 1.6), Vector3(PI / 2, 0, 0.2))
	var carroca := Vector3(-5.0, 0, -2.5)
	_p(_cx(Vector3(1.6, 0.5, 2.6)), _mat(MADEIRA.lightened(0.05), 0.95, 3.0), carroca + Vector3(0, 0.9, 0), Vector3(0, 0.3, 0.06))
	for dz in [-0.7, 0.7]:
		var rd := TorusMesh.new()
		rd.inner_radius = 0.5
		rd.outer_radius = 0.6
		_p(rd, _mat(Color(0.28, 0.22, 0.17)), carroca + Vector3(0.85, 0.6, dz), Vector3(0, 0.3, PI / 2))
	_p(_cx(Vector3(0.1, 0.1, 2.4)), _mat(MADEIRA), carroca + Vector3(-0.4, 0.55, 2.2), Vector3(0.25, 0.3, 0))
	for k in 5:
		_caixote(Vector3(2.4 + (k % 3) * 0.7, 0 if k < 3 else 0.55, 3.6), 0.55)
	_p(_cil(0.08, 0.3), _mat(Color(0.2, 0.3, 0.25), 0.2), Vector3(2.5, 1.25, 3.6))
	_p(_cil(0.1, 0.25), _mat(Color(0.5, 0.42, 0.2), 0.3), Vector3(3.1, 0.68, 3.6))


# ---------------- Tapera (base vazia): casa abandonada, sem luz ----------------

func _tapera() -> void:
	var w := 5.5
	var f := 4.5
	var pau := _mat(Color(0.32, 0.27, 0.22), 0.95, 3.0)
	# esqueleto de pau a pique: esteios e ripas, com pedaços de barro ainda presos
	for x in [-w / 2.0, 0.0, w / 2.0]:
		for z in [-f / 2.0, f / 2.0]:
			_p(_cil(0.09, 2.4 - abs(x) * 0.15), pau, Vector3(x, 1.2, z), Vector3(_rng.randf_range(-0.08, 0.08), 0, _rng.randf_range(-0.08, 0.08)))
	for k in 5:
		var y := 0.4 + k * 0.42
		_p(_cx(Vector3(w, 0.05, 0.05)), pau, Vector3(0, y, -f / 2.0))
		if k < 3:
			_p(_cx(Vector3(0.05, 0.05, f)), pau, Vector3(-w / 2.0, y, 0))
	_p(_cx(Vector3(2.6, 1.6, 0.18)), _mat(BARRO.darkened(0.1), 1.0), Vector3(-1.4, 0.8, -f / 2.0))
	_p(_cx(Vector3(0.18, 1.1, 2.0)), _mat(BARRO.darkened(0.15), 1.0), Vector3(w / 2.0, 0.55, 0.6))
	_p(_cx(Vector3(1.4, 0.9, 0.18)), _mat(BARRO.darkened(0.05), 1.0), Vector3(1.6, 0.45, f / 2.0))
	# telhado afundado: metade caída no chão
	_p(_cx(Vector3(w + 0.6, 0.12, 2.8)), _mat(Color(0.34, 0.29, 0.2), 1.0, 5.0), Vector3(0, 2.4, -1.0), Vector3(-0.35, 0, 0.08))
	_p(_cx(Vector3(3.0, 0.12, 2.4)), _mat(Color(0.3, 0.26, 0.18), 1.0, 5.0), Vector3(0.8, 0.5, 1.8), Vector3(0.5, 0.3, 0.2))
	# o mato tomando conta
	_moita(Vector3(-1.0, 0, 0.3), 5, 1.0)
	_moita(Vector3(w / 2.0 + 1.0, 0, -1.5), 4, 0.9)
	_moita(Vector3(-w / 2.0 - 1.2, 0, 1.2), 4, 0.8)
