extends Node3D
## Figura de um personagem. Estilo "real": modelo 3D do jogador (MPFB, assets/personagens/jogador.glb),
## animado por código nos ossos. Demais estilos: figura provisória montada com primitivas.
## Só lê o estado do personagem da lógica. O visual vem de um "estilo" (roupa, cabeça, acessórios),
## e o pé mostra o calçado do MVP — o mesmo que marca as pegadas no barro.
## Frente do modelo = +Z local.

var personagem
var estilo := "jovem"          # "real" = modelo 3D do jogador; os demais são figuras provisórias
var calcado := "bota"         # bota, botina, alpercata, tamanco, descalco
var altura := 1.0             # escala do corpo
var pele := Color(0, 0, 0, 0) # alfa > 0 troca a cor da pele do estilo
var hesitando := false        # parado olhando em volta (o MVP faz o computador hesitar nas bifurcações)

var _coxas: Array[Node3D] = []
var _canelas: Array[Node3D] = []
var _bracos: Array[Node3D] = []
var _antebracos: Array[Node3D] = []
var _corpo: Node3D
var _cabeca: Node3D
var _fase := 0.0
var _t := 0.0

const MODELO_REAL := "res://assets/personagens/jogador.glb"
var _skel: Skeleton3D
var _osso := {}              # nome do osso -> índice
var _rest_g := {}            # índice -> Basis global de repouso (espaço do esqueleto)
var _ordem: Array[int] = []  # ossos com o pai sempre antes do filho
var _vel := 0.0              # velocidade suavizada (m/s)
var _amp := 0.0              # 0 parado, 1 andando (transição suave)
var _agacha := 0.0           # 0 em pé, 1 agachado (transição suave)
var _chao_repouso := 0.0     # altura dos pés na pose de repouso (para assentá-los no chão)
var _desce := {}             # nome do osso do braço -> Basis que leva o osso da pose em A para junto do corpo

## Estilos. Chaves que faltam valem o padrão de _padrao().
const ESTILOS := {
	"jovem": {   # o jogador (foto de referência): boné, óculos, camiseta preta com estampa, jeans, relógio
		"pele": Color(0.27, 0.17, 0.12), "camisa": Color(0.05, 0.05, 0.06), "calca": Color(0.25, 0.32, 0.45),
		"manga_curta": true, "cabeca": "bone", "cor_cabeca": Color(0.1, 0.12, 0.24),
		"oculos": true, "relogio": true, "estampa": Color(0.82, 0.92, 0.12),
	},
	"roceiro": {   # chapéu de palha, camisa de algodão cru, calça arregaçada
		"pele": Color(0.5, 0.36, 0.27), "camisa": Color(0.62, 0.56, 0.44), "calca": Color(0.3, 0.27, 0.22),
		"cabeca": "palha", "cor_cabeca": Color(0.66, 0.56, 0.34), "barra": true,
	},
	"vaqueiro": {   # chapéu de couro de aba virada, colete de couro, camisa clara, barba
		"pele": Color(0.42, 0.29, 0.2), "camisa": Color(0.7, 0.66, 0.58), "calca": Color(0.2, 0.18, 0.16),
		"cabeca": "couro", "cor_cabeca": Color(0.35, 0.22, 0.13), "colete": Color(0.4, 0.26, 0.15),
		"barba": Color(0.12, 0.1, 0.09),
	},
	"velho": {   # cabelo e barba brancos, paletó escuro surrado, curvado, bengala
		"pele": Color(0.56, 0.42, 0.33), "camisa": Color(0.22, 0.22, 0.24), "calca": Color(0.25, 0.24, 0.23),
		"cabeca": "cabelo", "cor_cabeca": Color(0.82, 0.82, 0.8), "barba": Color(0.85, 0.85, 0.83),
		"curvado": true, "bengala": true,
	},
	"lavadeira": {   # lenço na cabeça, vestido de chita, avental claro
		"pele": Color(0.33, 0.21, 0.15), "camisa": Color(0.62, 0.3, 0.26), "calca": Color(0.62, 0.3, 0.26),
		"manga_curta": true, "cabeca": "lenco", "cor_cabeca": Color(0.86, 0.8, 0.55),
		"saia": Color(0.62, 0.3, 0.26), "avental": Color(0.82, 0.8, 0.72),
	},
	"senhora": {   # coque, xale sobre os ombros, saia comprida escura
		"pele": Color(0.6, 0.46, 0.36), "camisa": Color(0.32, 0.38, 0.45), "calca": Color(0.18, 0.18, 0.2),
		"cabeca": "coque", "cor_cabeca": Color(0.12, 0.1, 0.09), "saia": Color(0.18, 0.18, 0.2),
		"xale": Color(0.5, 0.42, 0.3), "saia_longa": true,
	},
}


func _padrao() -> Dictionary:
	return {"manga_curta": false, "oculos": false, "relogio": false, "estampa": null, "barra": false,
		"colete": null, "barba": null, "curvado": false, "bengala": false, "saia": null, "avental": null,
		"xale": null, "saia_longa": false}


func _ready() -> void:
	if estilo == "real":
		if _montar_real():
			return
		push_warning("Modelo do jogador não encontrado em %s; usando a figura provisória." % MODELO_REAL)
		estilo = "jovem"
	var e: Dictionary = _padrao()
	e.merge(ESTILOS[estilo], true)
	var cor_pele: Color = pele if pele.a > 0.0 else e["pele"]
	var m_pele := _mat(cor_pele, 0.6)
	var camisa := _mat(e["camisa"], 0.95)
	var calca := _mat(e["calca"], 0.9)
	_corpo = Node3D.new()
	_corpo.scale = Vector3.ONE * altura
	add_child(_corpo)

	# pernas: quadril -> coxa -> joelho -> canela -> pé (o pé mostra o calçado)
	for lado in [-1, 1]:
		var quadril := _pivo(Vector3(lado * 0.1, 0.93, 0), _corpo)
		_parte(_capsula(0.075, 0.5), calca, Vector3(0, -0.23, 0), quadril)
		var joelho := _pivo(Vector3(0, -0.46, 0), quadril)
		if e["barra"] or e["saia"] != null:
			_parte(_capsula(0.05, 0.3), m_pele, Vector3(0, -0.3, 0), joelho)   # canela à mostra
			_parte(_capsula(0.06, 0.24), calca, Vector3(0, -0.1, 0), joelho)
		else:
			_parte(_capsula(0.06, 0.48), calca, Vector3(0, -0.22, 0), joelho)
		_pe(joelho, m_pele)
		_coxas.append(quadril)
		_canelas.append(joelho)

	# quadril e tronco (mais largo nos ombros)
	_parte(_caixa(Vector3(0.34, 0.16, 0.2)), calca, Vector3(0, 0.98, 0))
	var tronco := _parte(_capsula(0.17, 0.62), camisa, Vector3(0, 1.3, 0))
	tronco.scale = Vector3(1.25, 1.0, 0.72)
	if e["saia"] != null:
		var c := CylinderMesh.new()
		c.top_radius = 0.2
		c.bottom_radius = 0.34 if not e["saia_longa"] else 0.3
		c.height = 0.62 if not e["saia_longa"] else 0.82
		c.radial_segments = 14
		_parte(c, _mat(e["saia"], 0.95), Vector3(0, 1.0 - c.height / 2.0 + 0.04, 0))
	if e["avental"] != null:
		_parte(_caixa(Vector3(0.36, 0.55, 0.02)), _mat(e["avental"], 1.0), Vector3(0, 0.82, 0.2), _corpo, Vector3(0.18, 0, 0))
	if e["colete"] != null:
		for lado in [-1, 1]:
			_parte(_caixa(Vector3(0.17, 0.48, 0.3)), _mat(e["colete"], 0.8), Vector3(lado * 0.12, 1.3, 0.0))
	if e["xale"] != null:
		var x := _parte(_esfera(0.28), _mat(e["xale"], 1.0), Vector3(0, 1.47, -0.01))
		x.scale = Vector3(1.05, 0.45, 0.75)
	if e["estampa"] != null:
		# estampas pequenas no peito, como a camiseta da referência
		var neon := _brilho(e["estampa"], 0.6)
		for x in [-0.1, 0.0, 0.1]:
			_parte(_caixa(Vector3(0.06, 0.018, 0.01)), neon, Vector3(x, 1.43, 0.125))
	_parte(_cilindro(0.052, 0.12), m_pele, Vector3(0, 1.6, 0))

	# braços: ombro -> braço -> cotovelo -> antebraço -> mão
	for lado in [-1, 1]:
		var ombro := _pivo(Vector3(lado * 0.24, 1.52, 0), _corpo)
		if e["manga_curta"]:
			_parte(_capsula(0.068, 0.22), camisa, Vector3(0, -0.08, 0), ombro)
			_parte(_capsula(0.046, 0.3), m_pele, Vector3(0, -0.16, 0), ombro)
		else:
			_parte(_capsula(0.056, 0.32), camisa, Vector3(0, -0.15, 0), ombro)
		var cotovelo := _pivo(Vector3(0, -0.3, 0), ombro)
		if e["manga_curta"]:
			_parte(_capsula(0.04, 0.28), m_pele, Vector3(0, -0.13, 0), cotovelo)
		else:
			_parte(_capsula(0.048, 0.28), camisa, Vector3(0, -0.13, 0), cotovelo)
		var mao := _parte(_esfera(0.045), m_pele, Vector3(0, -0.3, 0.01), cotovelo)
		mao.scale = Vector3(0.75, 1.15, 1.0)
		if e["relogio"] and lado == -1:
			_parte(_cilindro(0.045, 0.03), _mat(Color(0.05, 0.05, 0.05), 0.4), Vector3(0, -0.24, 0), cotovelo)
		if e["bengala"] and lado == 1:
			_parte(_cilindro(0.015, 0.92), _mat(Color(0.3, 0.22, 0.15), 0.8), Vector3(0, -0.66, 0.12), cotovelo, Vector3(0.12, 0, 0))
		_bracos.append(ombro)
		_antebracos.append(cotovelo)

	# cabeça num pivô no pescoço, para poder olhar em volta
	_cabeca = _pivo(Vector3(0, 1.62, 0), _corpo)
	var h := _cabeca
	var cranio := _parte(_esfera(0.115), m_pele, Vector3(0, 0.12, 0), h)
	cranio.scale = Vector3(0.88, 1.05, 0.95)
	for lado in [-1, 1]:
		var orelha := _parte(_esfera(0.03), m_pele, Vector3(lado * 0.1, 0.115, -0.005), h)
		orelha.scale = Vector3(0.5, 1.0, 0.8)
	_parte(_caixa(Vector3(0.03, 0.045, 0.035)), m_pele, Vector3(0, 0.105, 0.11), h)
	# rosto: olhos e sobrancelhas escuros, boca, para se saber de que lado está a frente
	var escuro := _mat(Color(0.05, 0.04, 0.04), 0.5)
	for lado in [-1, 1]:
		_parte(_esfera(0.014), escuro, Vector3(lado * 0.04, 0.135, 0.098), h)
		_parte(_caixa(Vector3(0.035, 0.008, 0.01)), escuro, Vector3(lado * 0.042, 0.158, 0.1), h)
	_parte(_caixa(Vector3(0.04, 0.008, 0.01)), _mat(Color(0.25, 0.12, 0.1), 0.6), Vector3(0, 0.068, 0.103), h)
	if e["barba"] != null:
		var b := _parte(_esfera(0.085), _mat(e["barba"], 1.0), Vector3(0, 0.04, 0.05), h)
		b.scale = Vector3(1.0, 0.8, 0.85)
	if e["oculos"]:
		var aro := _mat(Color(0.06, 0.06, 0.07), 0.3)
		for lado in [-1, 1]:
			var t := TorusMesh.new()
			t.inner_radius = 0.022
			t.outer_radius = 0.03
			t.rings = 12
			t.ring_segments = 6
			_parte(t, aro, Vector3(lado * 0.042, 0.132, 0.103), h, Vector3(PI / 2, 0, 0))
			_parte(_caixa(Vector3(0.006, 0.006, 0.1)), aro, Vector3(lado * 0.085, 0.135, 0.055), h)
		_parte(_caixa(Vector3(0.025, 0.006, 0.006)), aro, Vector3(0, 0.136, 0.105), h)
	var cor_cab := _mat(e["cor_cabeca"], 0.9)
	match e["cabeca"]:
		"bone":
			var copa := SphereMesh.new()
			copa.radius = 0.122
			copa.height = 0.122
			copa.is_hemisphere = true
			copa.radial_segments = 16
			copa.rings = 6
			var c := _parte(copa, cor_cab, Vector3(0, 0.16, -0.005), h)
			c.scale = Vector3(0.95, 0.95, 1.02)
			var aba := _parte(_cilindro(0.085, 0.014), cor_cab, Vector3(0, 0.17, 0.13), h, Vector3(-0.12, 0, 0))
			aba.scale = Vector3(1.0, 1.0, 1.15)
		"palha":
			_parte(_cilindro(0.26, 0.018), cor_cab, Vector3(0, 0.22, 0), h)
			_parte(_cilindro(0.115, 0.13), cor_cab, Vector3(0, 0.28, 0), h)
			_parte(_cilindro(0.118, 0.025), _mat(Color(0.25, 0.18, 0.12), 0.9), Vector3(0, 0.24, 0), h)
		"couro":
			# chapéu de couro: aba larga virada para cima nos lados
			_parte(_cilindro(0.2, 0.02), cor_cab, Vector3(0, 0.22, 0), h)
			for lado in [-1, 1]:
				_parte(_caixa(Vector3(0.06, 0.08, 0.32)), cor_cab, Vector3(lado * 0.19, 0.25, 0), h, Vector3(0, 0, lado * 0.6))
			var cop := _parte(_esfera(0.12), cor_cab, Vector3(0, 0.27, 0), h)
			cop.scale = Vector3(1.0, 0.75, 1.1)
		"cabelo":
			var cab := SphereMesh.new()
			cab.radius = 0.118
			cab.height = 0.118
			cab.is_hemisphere = true
			var c2 := _parte(cab, cor_cab, Vector3(0, 0.14, -0.012), h)
			c2.scale = Vector3(0.92, 0.8, 0.98)
		"lenco":
			var len := SphereMesh.new()
			len.radius = 0.125
			len.height = 0.125
			len.is_hemisphere = true
			var c3 := _parte(len, cor_cab, Vector3(0, 0.14, -0.01), h, Vector3(-0.25, 0, 0))
			c3.scale = Vector3(0.95, 1.0, 1.05)
			_parte(_esfera(0.035), cor_cab, Vector3(0, 0.08, -0.11), h)   # nó atrás
		"coque":
			var cab2 := SphereMesh.new()
			cab2.radius = 0.118
			cab2.height = 0.118
			cab2.is_hemisphere = true
			_parte(cab2, cor_cab, Vector3(0, 0.14, -0.012), h)
			_parte(_esfera(0.055), cor_cab, Vector3(0, 0.17, -0.11), h)
	if e["curvado"]:
		_corpo.rotation.x = 0.12


## Pé conforme o calçado do MVP: o mesmo que deixa a marca nas pegadas.
func _pe(joelho: Node3D, m_pele: Material) -> void:
	var couro := _mat(Color(0.2, 0.14, 0.1), 0.7)
	match calcado:
		"descalco":
			var pe := _parte(_esfera(0.06), m_pele, Vector3(0, -0.46, 0.05), joelho)
			pe.scale = Vector3(0.85, 0.45, 2.0)
		"alpercata":
			var pe := _parte(_esfera(0.06), m_pele, Vector3(0, -0.45, 0.05), joelho)
			pe.scale = Vector3(0.85, 0.45, 2.0)
			_parte(_caixa(Vector3(0.11, 0.015, 0.26)), couro, Vector3(0, -0.475, 0.05), joelho)
			_parte(_caixa(Vector3(0.115, 0.02, 0.03)), couro, Vector3(0, -0.44, 0.08), joelho)
		"tamanco":
			_parte(_caixa(Vector3(0.12, 0.07, 0.27)), _mat(Color(0.5, 0.38, 0.24), 0.8), Vector3(0, -0.45, 0.045), joelho)
			_parte(_caixa(Vector3(0.12, 0.05, 0.12)), couro, Vector3(0, -0.4, 0.09), joelho)
		"bota":
			_parte(_caixa(Vector3(0.11, 0.08, 0.27)), couro, Vector3(0, -0.43, 0.045), joelho)
			_parte(_cilindro(0.065, 0.26), couro, Vector3(0, -0.3, 0), joelho)   # cano alto
			_parte(_caixa(Vector3(0.115, 0.025, 0.28)), _mat(Color(0.1, 0.07, 0.05), 0.8), Vector3(0, -0.47, 0.045), joelho)
		_:
			var cor := Color(0.12, 0.12, 0.13) if estilo == "jovem" else Color(0.24, 0.16, 0.11)
			_parte(_caixa(Vector3(0.11, 0.08, 0.27)), _mat(cor, 0.7), Vector3(0, -0.43, 0.045), joelho)
			_parte(_caixa(Vector3(0.115, 0.025, 0.28)), _mat(Color(0.75, 0.74, 0.7) if estilo == "jovem" else Color(0.15, 0.11, 0.08), 0.8), Vector3(0, -0.47, 0.045), joelho)


func _process(dt: float) -> void:
	if personagem == null:
		return
	_t += dt
	if _skel != null:
		_animar_real(dt)
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
	# parado na bifurcação: olha de um lado para o outro, decidindo o caminho
	var olhar := sin(_t * 1.6) * 0.9 if (hesitando and not andando) else 0.0
	_cabeca.rotation.y = lerp_angle(_cabeca.rotation.y, olhar, minf(1.0, dt * 4.0))
	# derrubado pelo lobo ou desmaiado: deitado no chão
	var caido: bool = personagem.get("caido") == true
	var curva := 0.12 if ESTILOS[estilo].get("curvado", false) else 0.0
	_corpo.rotation.x = lerp_angle(_corpo.rotation.x, -1.45 if caido else curva, minf(1.0, dt * 6.0))
	if caido:
		_corpo.position.y = 0.18


# ---------------------------------------------------------------- modelo real

func _montar_real() -> bool:
	if not ResourceLoader.exists(MODELO_REAL):
		return false
	var cena := load(MODELO_REAL) as PackedScene
	if cena == null:
		return false
	_corpo = Node3D.new()
	_corpo.scale = Vector3.ONE * altura
	add_child(_corpo)
	var modelo := cena.instantiate() as Node3D
	_corpo.add_child(modelo)
	var achados := modelo.find_children("*", "Skeleton3D", true, false)
	if achados.is_empty():
		_corpo.queue_free()
		return false
	_skel = achados[0]
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		mi.layers = 2
		_ajustar_materiais(mi)
	var n := _skel.get_bone_count()
	for i in n:
		_osso[_skel.get_bone_name(i)] = i
		_rest_g[i] = _skel.get_bone_global_rest(i).basis.orthonormalized()
	# ordem pai -> filho
	var visto := {}
	while _ordem.size() < n:
		for i in n:
			var p := _skel.get_bone_parent(i)
			if not visto.has(i) and (p < 0 or visto.has(p)):
				visto[i] = true
				_ordem.append(i)
	# o MPFB exporta em pose de A (braços e pernas abertos): cada osso dos membros é
	# levado para baixo, os braços um pouco abertos e as pernas retas sob o quadril
	for lado in ["l", "r"]:
		for par in [["upperarm_", "lowerarm_", 0.12], ["lowerarm_", "hand_", 0.06],
				["thigh_", "calf_", 0.0], ["calf_", "foot_", 0.0]]:
			var b := _osso.get(par[0] + lado, -1) as int
			var c := _osso.get(par[1] + lado, -1) as int
			if b < 0 or c < 0:
				continue
			var d := (_skel.get_bone_global_rest(c).origin - _skel.get_bone_global_rest(b).origin).normalized()
			var alvo := Vector3(signf(d.x) * par[2], -1.0, 0.0).normalized()
			_desce[par[0] + lado] = Basis(Quaternion(d, alvo))
	# altura dos pés com as pernas retas: referência para assentar no chão
	var menor := INF
	for nome_pe in ["foot_l", "foot_r", "ball_l", "ball_r"]:
		var ip: int = _osso.get(nome_pe, -1)
		if ip >= 0:
			menor = minf(menor, _skel.get_bone_global_rest(ip).origin.y)
	_chao_repouso = 0.0 if menor == INF else menor
	return true


## Pele, olhos, roupa: opacos (o MPFB exporta a pele com transparência, o que estraga sombra e ordem de desenho).
## Sobrancelhas e cílios: recorte por alfa, dos dois lados.
func _ajustar_materiais(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for s in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(s) as BaseMaterial3D
		if m == null:
			continue
		m = m.duplicate()
		var pelos := mi.name.contains("eyebrow") or mi.name.contains("eyelash") \
			or m.resource_name.contains("eyebrow") or m.resource_name.contains("eyelash")
		if pelos:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.35
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		else:
			m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
		mi.set_surface_override_material(s, m)


## Ciclo de passada a partir das curvas de marcha humana (quadril, joelho e tornozelo),
## misturando andar e correr pela velocidade, com balanço do quadril, tronco contrário,
## cabeça estável e respiração parado. Por cima: agachar (esconder na mata) e abaixar para
## pegar algo do chão. Os pés são assentados no chão depois da pose.
## Ângulos em graus nas curvas, radianos na aplicação.
func _animar_real(dt: float) -> void:
	position = Vector3(personagem.pos.x, 0, personagem.pos.y)
	var alvo: float = -personagem.direcao.angle() + PI / 2.0
	rotation.y = lerp_angle(rotation.y, alvo, min(1.0, dt * 8.0))
	var andando: bool = personagem.andando
	var v: float = clampf(personagem.velocidade, 0.0, 8.0) if andando else 0.0
	_vel = lerpf(_vel, v, minf(1.0, dt * 6.0))
	_amp = move_toward(_amp, 1.0 if andando else 0.0, dt * 3.5)
	_agacha = move_toward(_agacha, 1.0 if personagem.get("agachado") == true else 0.0, dt * 4.0)
	var pg = personagem.get("pegar")
	var pegar: float = pg if pg != null else -1.0
	var tipo = personagem.get("pegar_tipo")
	# e: abaixar até o chão (desce até 40% do tempo, segura, sobe a partir de 65%)
	# ea: esticar o braço à frente (vai até 35%, segura, volta a partir de 60%)
	var e := 0.0
	var ea := 0.0
	if pegar >= 0.0:
		if tipo == "chao":
			e = smoothstep(0.0, 0.4, pegar) * (1.0 - smoothstep(0.65, 1.0, pegar))
		else:
			ea = smoothstep(0.0, 0.35, pegar) * (1.0 - smoothstep(0.6, 1.0, pegar))
	var ag := _agacha
	# 0 = andar, 1 = correr (agachado nunca corre)
	var c := clampf((_vel - 1.8) / 3.0, 0.0, 1.0) * (1.0 - ag)
	var passada := lerpf(1.4, 3.0, c) * (1.0 - 0.45 * ag)   # metros por ciclo (dois passos)
	var freq := clampf(_vel / passada, 0.75, 2.0) if _vel > 0.05 else 0.75
	_fase = fposmod(_fase + dt * freq * (1.0 if _amp > 0.0 else 0.0), 1.0)
	var a := _amp * (1.0 - 0.55 * ag)
	var X := Vector3.RIGHT
	var giro := {}
	var quadril_l := 0.0
	var quadril_r := 0.0
	for k in 2:
		var lado := "l" if k == 0 else "r"
		var p := fposmod(_fase + (0.0 if k == 0 else 0.5), 1.0)   # 0 = calcanhar toca o chão
		# quadril (flexão +: perna para a frente)
		var q := lerpf(7.0 + 18.0 * cos(TAU * p), 10.0 + 32.0 * cos(TAU * (p - 0.03)), c)
		# joelho: dobra ao receber o peso e, mais, no balanço
		var j := lerpf(15.0 * _sino(p, 0.12, 0.06) + 60.0 * _sino(p, 0.72, 0.11) + 3.0,
			38.0 * _sino(p, 0.15, 0.08) + 90.0 * _sino(p, 0.7, 0.12) + 8.0, c)
		# tornozelo (dorsiflexão +)
		var t := lerpf(8.0 * _sino(p, 0.42, 0.1) - 16.0 * _sino(p, 0.62, 0.05),
			12.0 * _sino(p, 0.28, 0.08) - 22.0 * _sino(p, 0.5, 0.06), c)
		q *= a
		j = j * a + 2.0 * (1.0 - a)
		t *= a
		if k == 0:
			quadril_l = q
		else:
			quadril_r = q
		# agachado: cócoras baixas; pegar: agacha com a perna direita um pouco à frente
		var frente_pegar := 12.0 if k == 1 else -4.0
		# esticar o braço: a perna direita adianta um pouco, como quem se inclina para alcançar
		q += ea * (10.0 if k == 1 else -3.0)
		j += ea * (8.0 if k == 1 else 2.0)
		q += ag * 72.0 + e * (92.0 + frente_pegar - ag * 72.0)
		j += ag * 112.0 + e * (128.0 - frente_pegar - ag * 112.0)
		t += ag * 34.0 + e * (38.0 - ag * 34.0)
		var d_coxa: Basis = _desce.get("thigh_" + lado, Basis.IDENTITY)
		var d_perna: Basis = _desce.get("calf_" + lado, Basis.IDENTITY)
		_girar(giro, "thigh_" + lado, Basis(X, deg_to_rad(-q)) * d_coxa)
		_girar(giro, "calf_" + lado, Basis(X, deg_to_rad(-q + j)) * d_perna)
		_girar(giro, "foot_" + lado, Basis(X, deg_to_rad(-q + j - t)) * d_perna)
	# braços: contrários à perna do mesmo lado; cotovelo mais dobrado correndo
	for k in 2:
		var lado := "l" if k == 0 else "r"
		var q_oposta := quadril_r if k == 0 else quadril_l
		var ombro := (q_oposta - 7.0 * a) * lerpf(0.75, 0.9, c)
		var cotovelo := lerpf(12.0, 75.0, c * _amp) + maxf(0.0, ombro) * 0.5
		# agachado: braços à frente, sobre os joelhos
		ombro += ag * 30.0
		cotovelo += ag * 45.0
		# pegar: o braço direito desce estendido até o chão; o esquerdo apoia no joelho
		if lado == "r":
			ombro = lerpf(ombro, 38.0, e)
			cotovelo = lerpf(cotovelo, 5.0, e)
			# esticar: braço direito à frente, na altura do peito, quase reto
			ombro = lerpf(ombro, 82.0 + ag * 10.0, ea)
			cotovelo = lerpf(cotovelo, 8.0, ea)
		else:
			ombro = lerpf(ombro, 40.0, e)
			cotovelo = lerpf(cotovelo, 60.0, e)
			ombro = lerpf(ombro, -8.0 + ag * 30.0, ea)
			cotovelo = lerpf(cotovelo, 20.0 + ag * 45.0, ea)
		var d_braco: Basis = _desce.get("upperarm_" + lado, Basis.IDENTITY)
		var d_ante: Basis = _desce.get("lowerarm_" + lado, Basis.IDENTITY)
		_girar(giro, "upperarm_" + lado, Basis(X, deg_to_rad(-ombro)) * d_braco)
		_girar(giro, "lowerarm_" + lado, Basis(X, deg_to_rad(-ombro - cotovelo)) * d_ante)
		_girar(giro, "hand_" + lado, Basis(X, deg_to_rad(-ombro - cotovelo * 0.9)) * d_ante)
	# quadril gira e inclina com a passada; tronco gira ao contrário; corrida e agachado inclinam para a frente
	var s := sin(TAU * _fase)
	var giro_quadril := deg_to_rad(lerpf(5.0, 7.0, c)) * s * a
	var queda := deg_to_rad(lerpf(4.0, 3.0, c)) * sin(TAU * _fase * 2.0 + PI / 2.0) * a
	var respira := deg_to_rad(1.2) * sin(_t * 1.5) * (1.0 - _amp)
	_girar(giro, "pelvis", Basis(Vector3.UP, giro_quadril) * Basis(Vector3.BACK, queda * signf(s)))
	var inclina := deg_to_rad(lerpf(3.0, 10.0, c)) * _amp + respira + deg_to_rad(24.0) * ag + deg_to_rad(68.0 - 24.0 * ag) * e + deg_to_rad(12.0) * ea
	_girar(giro, "spine_01", Basis(X, inclina * 0.4) * Basis(Vector3.UP, -giro_quadril * 0.6))
	_girar(giro, "spine_02", Basis(X, inclina * 0.7) * Basis(Vector3.UP, -giro_quadril * 1.4))
	# esticar: o ombro direito vai à frente (tronco gira um pouco)
	var gira_alcance := deg_to_rad(14.0) * ea
	_girar(giro, "spine_03", Basis(X, inclina) * Basis(Vector3.UP, -giro_quadril * 1.8 + gira_alcance))
	var olhar := sin(_t * 1.6) * 0.7 if (hesitando and not andando) else 0.0
	_girar(giro, "neck_01", Basis(X, inclina * 0.5) * Basis(Vector3.UP, olhar * 0.4))
	# cabeça nivelada; ao pegar, olha para o chão
	_girar(giro, "head", Basis(Vector3.UP, olhar) * Basis(X, deg_to_rad(30.0) * e + deg_to_rad(8.0) * ea))
	# aplica: pose local = repouso do pai⁻¹ · giro do pai⁻¹ · giro · repouso do osso
	var absoluto := {}
	for i in _ordem:
		var pai := _skel.get_bone_parent(i)
		var gp: Basis = absoluto[pai] if pai >= 0 else Basis.IDENTITY
		var g: Basis = giro.get(i, gp)
		absoluto[i] = g
		var local: Basis = g * _rest_g[i]
		if pai >= 0:
			local = (gp * _rest_g[pai]).inverse() * local
		_skel.set_bone_pose_rotation(i, local.get_rotation_quaternion())
	var caido: bool = personagem.get("caido") == true
	_corpo.rotation.x = lerp_angle(_corpo.rotation.x, -1.45 if caido else 0.0, minf(1.0, dt * 6.0))
	if caido:
		_corpo.position = Vector3(0, 0.15, 0)
		return
	# assenta o pé mais baixo no chão (dá o sobe e desce da passada e a altura do agachado);
	# o peso vai para o lado da perna de apoio
	var y := _chao_repouso - _pe_mais_baixo()
	_corpo.position = Vector3(0.025 * s * a * (1.0 - c * 0.5), y, 0.0)


## Altura (no espaço do esqueleto) do ponto mais baixo dos pés na pose atual.
func _pe_mais_baixo() -> float:
	var menor := INF
	for n in ["foot_l", "foot_r", "ball_l", "ball_r"]:
		var i: int = _osso.get(n, -1)
		if i >= 0:
			menor = minf(menor, _skel.get_bone_global_pose(i).origin.y)
	return 0.0 if menor == INF else menor


## Curva em sino periódica (0..1) centrada em c, com largura w.
func _sino(p: float, centro: float, w: float) -> float:
	var d := fposmod(p - centro + 0.5, 1.0) - 0.5
	return exp(-(d * d) / (2.0 * w * w))


func _girar(giro: Dictionary, osso: String, b: Basis) -> void:
	var i: int = _osso.get(osso, -1)
	if i >= 0:
		giro[i] = b


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
