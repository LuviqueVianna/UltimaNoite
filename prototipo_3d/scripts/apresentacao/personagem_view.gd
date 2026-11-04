extends Node3D
## Figura provisória de um personagem, montada com primitivas, com juntas de joelho e cotovelo.
## Só lê o estado do personagem da lógica. O visual vem de um "estilo" (roupa, cabeça, acessórios).
## Frente do modelo = +Z local.

var personagem
var estilo := "jovem"            # "jovem" (boné, óculos, camiseta) ou "roceiro" (chapéu de palha, camisa)

var _coxas: Array[Node3D] = []
var _canelas: Array[Node3D] = []
var _bracos: Array[Node3D] = []
var _antebracos: Array[Node3D] = []
var _corpo: Node3D
var _fase := 0.0

const ESTILOS := {
	"jovem": {
		"pele": Color(0.27, 0.17, 0.12),
		"camisa": Color(0.05, 0.05, 0.06),
		"calca": Color(0.25, 0.32, 0.45),
		"sapato": Color(0.12, 0.12, 0.13),
		"sola": Color(0.75, 0.74, 0.7),
		"manga_curta": true,
		"cabeca": "bone",
		"cor_cabeca": Color(0.1, 0.12, 0.24),
		"oculos": true,
		"relogio": true,
		"estampa": Color(0.82, 0.92, 0.12),
	},
	"roceiro": {
		"pele": Color(0.5, 0.36, 0.27),
		"camisa": Color(0.42, 0.36, 0.27),
		"calca": Color(0.22, 0.2, 0.18),
		"sapato": Color(0.2, 0.14, 0.1),
		"sola": Color(0.15, 0.11, 0.08),
		"manga_curta": false,
		"cabeca": "palha",
		"cor_cabeca": Color(0.62, 0.52, 0.32),
		"oculos": false,
		"relogio": false,
		"estampa": null,
	},
}


func _ready() -> void:
	var e: Dictionary = ESTILOS[estilo]
	var pele := _mat(e["pele"], 0.6)
	var camisa := _mat(e["camisa"], 0.95)
	var calca := _mat(e["calca"], 0.9)
	var sapato := _mat(e["sapato"], 0.7)
	var sola := _mat(e["sola"], 0.8)
	_corpo = Node3D.new()
	add_child(_corpo)

	# pernas: quadril -> coxa -> joelho -> canela -> pé
	for lado in [-1, 1]:
		var quadril := _pivo(Vector3(lado * 0.1, 0.93, 0), _corpo)
		_parte(_capsula(0.075, 0.5), calca, Vector3(0, -0.23, 0), quadril)
		var joelho := _pivo(Vector3(0, -0.46, 0), quadril)
		_parte(_capsula(0.06, 0.48), calca, Vector3(0, -0.22, 0), joelho)
		_parte(_caixa(Vector3(0.11, 0.08, 0.27)), sapato, Vector3(0, -0.43, 0.045), joelho)
		_parte(_caixa(Vector3(0.115, 0.025, 0.28)), sola, Vector3(0, -0.47, 0.045), joelho)
		_coxas.append(quadril)
		_canelas.append(joelho)

	# quadril e tronco (mais largo nos ombros)
	_parte(_caixa(Vector3(0.34, 0.16, 0.2)), calca, Vector3(0, 0.98, 0))
	var tronco := _parte(_capsula(0.17, 0.62), camisa, Vector3(0, 1.3, 0))
	tronco.scale = Vector3(1.25, 1.0, 0.72)
	if e["estampa"] != null:
		# estampas pequenas no peito, como a camiseta da referência
		var neon := _brilho(e["estampa"], 0.6)
		for x in [-0.1, 0.0, 0.1]:
			_parte(_caixa(Vector3(0.06, 0.018, 0.01)), neon, Vector3(x, 1.43, 0.125))
	_parte(_cilindro(0.052, 0.12), pele, Vector3(0, 1.6, 0))

	# braços: ombro -> braço -> cotovelo -> antebraço -> mão
	for lado in [-1, 1]:
		var ombro := _pivo(Vector3(lado * 0.24, 1.52, 0), _corpo)
		if e["manga_curta"]:
			_parte(_capsula(0.068, 0.22), camisa, Vector3(0, -0.08, 0), ombro)
			_parte(_capsula(0.046, 0.3), pele, Vector3(0, -0.16, 0), ombro)
		else:
			_parte(_capsula(0.056, 0.32), camisa, Vector3(0, -0.15, 0), ombro)
		var cotovelo := _pivo(Vector3(0, -0.3, 0), ombro)
		if e["manga_curta"]:
			_parte(_capsula(0.04, 0.28), pele, Vector3(0, -0.13, 0), cotovelo)
		else:
			_parte(_capsula(0.048, 0.28), camisa, Vector3(0, -0.13, 0), cotovelo)
		var mao := _parte(_esfera(0.045), pele, Vector3(0, -0.3, 0.01), cotovelo)
		mao.scale = Vector3(0.75, 1.15, 1.0)
		if e["relogio"] and lado == -1:
			_parte(_cilindro(0.045, 0.03), _mat(Color(0.05, 0.05, 0.05), 0.4), Vector3(0, -0.24, 0), cotovelo)
		_bracos.append(ombro)
		_antebracos.append(cotovelo)

	# cabeça: crânio, orelhas, nariz
	var cabeca := _parte(_esfera(0.115), pele, Vector3(0, 1.74, 0))
	cabeca.scale = Vector3(0.88, 1.05, 0.95)
	for lado in [-1, 1]:
		var orelha := _parte(_esfera(0.03), pele, Vector3(lado * 0.1, 1.735, -0.005))
		orelha.scale = Vector3(0.5, 1.0, 0.8)
	_parte(_caixa(Vector3(0.03, 0.045, 0.035)), pele, Vector3(0, 1.725, 0.11))
	if e["oculos"]:
		var aro := _mat(Color(0.06, 0.06, 0.07), 0.3)
		for lado in [-1, 1]:
			var t := TorusMesh.new()
			t.inner_radius = 0.022
			t.outer_radius = 0.03
			t.rings = 12
			t.ring_segments = 6
			_parte(t, aro, Vector3(lado * 0.042, 1.752, 0.103), _corpo, Vector3(PI / 2, 0, 0))
			_parte(_caixa(Vector3(0.006, 0.006, 0.1)), aro, Vector3(lado * 0.085, 1.755, 0.055))
		_parte(_caixa(Vector3(0.025, 0.006, 0.006)), aro, Vector3(0, 1.756, 0.105))
	match e["cabeca"]:
		"bone":
			var copa := SphereMesh.new()
			copa.radius = 0.122
			copa.height = 0.122
			copa.is_hemisphere = true
			copa.radial_segments = 16
			copa.rings = 6
			var cor := _mat(e["cor_cabeca"], 0.9)
			var c := _parte(copa, cor, Vector3(0, 1.78, -0.005))
			c.scale = Vector3(0.95, 0.95, 1.02)
			var aba := _parte(_cilindro(0.085, 0.014), cor, Vector3(0, 1.79, 0.13), _corpo, Vector3(-0.12, 0, 0))
			aba.scale = Vector3(1.0, 1.0, 1.15)
			_parte(_esfera(0.014), cor, Vector3(0, 1.9, -0.005))
		"palha":
			var palha := _mat(e["cor_cabeca"], 1.0)
			_parte(_cilindro(0.26, 0.018), palha, Vector3(0, 1.84, 0))
			_parte(_cilindro(0.115, 0.13), palha, Vector3(0, 1.9, 0))
			_parte(_cilindro(0.118, 0.025), _mat(Color(0.25, 0.18, 0.12), 0.9), Vector3(0, 1.86, 0))


func _process(dt: float) -> void:
	if personagem == null:
		return
	position = Vector3(personagem.pos.x, 0, personagem.pos.y)
	var alvo: float = -personagem.direcao.angle() + PI / 2.0
	rotation.y = lerp_angle(rotation.y, alvo, min(1.0, dt * 10.0))
	var andando: bool = personagem.andando
	if andando:
		_fase += dt * personagem.velocidade * 2.0
	else:
		_fase = lerp(_fase, round(_fase / PI) * PI, min(1.0, dt * 8.0))
	var s := sin(_fase)
	var amp := 1.0 if andando else 0.0
	for k in 2:
		var lado := 1.0 if k == 0 else -1.0
		var balanco := s * lado
		_coxas[k].rotation.x = -balanco * 0.55 * amp
		# o joelho dobra quando a perna volta para a frente
		_canelas[k].rotation.x = maxf(0.0, cos(_fase) * lado) * 0.9 * amp + 0.05
		_bracos[k].rotation.x = balanco * 0.45 * amp
		_bracos[k].rotation.z = (0.08 if k == 0 else -0.08)
		_antebracos[k].rotation.x = -0.3 - maxf(0.0, balanco) * 0.35 * amp
	_corpo.position.y = absf(cos(_fase)) * 0.035 * amp
	_corpo.rotation.y = s * 0.06 * amp


func _mat(c: Color, aspereza: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = aspereza
	return m


func _brilho(c: Color, energia: float) -> StandardMaterial3D:
	var m := _mat(c, 0.6)
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = energia
	return m


func _pivo(pos: Vector3, pai: Node3D) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	pai.add_child(n)
	return n


func _parte(malha: Mesh, mat: Material, pos: Vector3, pai: Node3D = null, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.layers = 2
	(pai if pai else _corpo).add_child(mi)
	return mi


func _capsula(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 12
	c.rings = 4
	return c


func _esfera(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 16
	s.rings = 8
	return s


func _caixa(tam: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tam
	return b


func _cilindro(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 16
	return c
