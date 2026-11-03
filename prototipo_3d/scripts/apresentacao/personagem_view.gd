extends Node3D
## Figura provisória de um personagem: corpo, cabeça, chapéu e pernas que balançam ao andar.
## Só lê o estado do personagem da lógica.

var personagem
var cor_roupa := Color(0.35, 0.33, 0.3)
var _pernas: Array[Node3D] = []
var _bracos: Array[Node3D] = []
var _corpo: Node3D
var _fase := 0.0


func _ready() -> void:
	var roupa := _mat(cor_roupa)
	var pele := _mat(Color(0.45, 0.33, 0.26))
	var chapeu := _mat(Color(0.25, 0.21, 0.17))
	var calca := _mat(cor_roupa.darkened(0.35))
	_corpo = Node3D.new()
	add_child(_corpo)
	for lado in [-1, 1]:
		var quadril := Node3D.new()
		quadril.position = Vector3(lado * 0.11, 0.9, 0)
		_corpo.add_child(quadril)
		_parte(_capsula(0.08, 0.9), calca, Vector3(0, -0.45, 0), quadril)
		_pernas.append(quadril)
	_parte(_capsula(0.21, 0.75), roupa, Vector3(0, 1.28, 0))
	for lado in [-1, 1]:
		var ombro := Node3D.new()
		ombro.position = Vector3(lado * 0.27, 1.5, 0)
		_corpo.add_child(ombro)
		_parte(_capsula(0.065, 0.68), roupa, Vector3(0, -0.32, 0), ombro)
		_bracos.append(ombro)
	_parte(_esfera(0.12), pele, Vector3(0, 1.78, 0))
	_parte(_cilindro(0.26, 0.02), chapeu, Vector3(0, 1.88, 0))
	_parte(_cilindro(0.13, 0.14), chapeu, Vector3(0, 1.95, 0))


func _process(dt: float) -> void:
	if personagem == null:
		return
	position = Vector3(personagem.pos.x, 0, personagem.pos.y)
	var alvo: float = -personagem.direcao.angle() + PI / 2.0
	rotation.y = lerp_angle(rotation.y, alvo, min(1.0, dt * 12.0))
	if personagem.andando:
		_fase += dt * personagem.velocidade * 2.2
	else:
		_fase = lerp(_fase, round(_fase / PI) * PI, min(1.0, dt * 8.0))
	var s := sin(_fase)
	_pernas[0].rotation.x = s * 0.5
	_pernas[1].rotation.x = -s * 0.5
	_bracos[0].rotation.x = -s * 0.4
	_bracos[1].rotation.x = s * 0.4
	_corpo.position.y = abs(cos(_fase)) * 0.04


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m


func _parte(malha: Mesh, mat: Material, pos: Vector3, pai: Node3D = null) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = mat
	mi.position = pos
	mi.layers = 2
	(pai if pai else _corpo).add_child(mi)


func _capsula(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 10
	c.rings = 3
	return c


func _esfera(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


func _cilindro(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 12
	return c
