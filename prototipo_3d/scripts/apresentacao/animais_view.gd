extends Node3D
## Desenho dos animais do MVP (lobo, coruja, cão, cobra). Só lê o estado de Fauna.Animal.
## Frente dos modelos = +Z local. Formas provisórias, sem olhos brilhando (Direção de Arte, 1.6).

var mundo                       # Mundo do MVP
var ver_tudo := false
var _corpos := {}               # id do animal -> {no, tipo, pernas, cabeca, rabo, ...}
var _t := 0.0


func montar() -> void:
	for a in mundo.fauna.animais:
		var c := {}
		match a.tipo:
			"lobo":
				c = _quadrupede(Color(0.36, 0.35, 0.33), 1.0, true)
			"cao":
				c = _quadrupede(Color(0.62, 0.42, 0.22), 0.7, false)
			"coruja":
				c = _coruja()
			"cobra":
				c = _cobra()
		c["tipo"] = a.tipo
		c["ultima"] = a.pos
		c["fase"] = randf() * TAU
		c["no"].name = "%s_%d" % [a.tipo, a.id]
		add_child(c["no"])
		_corpos[a.id] = c


func _process(dt: float) -> void:
	_t += dt
	var j = mundo.jogador()
	for a in mundo.fauna.animais:
		var c: Dictionary = _corpos[a.id]
		var no: Node3D = c["no"]
		var visivel: bool = ver_tudo or mundo.fauna.visivel_para_jogador(a)
		var mov: Vector2 = a.pos - c["ultima"]
		var vel := mov.length() / maxf(dt, 0.0001)
		c["ultima"] = a.pos
		match a.tipo:
			"lobo", "cao":
				no.visible = visivel
				no.position = Vector3(a.pos.x, 0, a.pos.y)
				var alvo_dir := mov
				if a.estado in ["rosnando", "perseguindo"] and a.alvo >= 0:
					alvo_dir = mundo.personagens[a.alvo].pos - a.pos
				if alvo_dir.length() > 0.001:
					no.rotation.y = lerp_angle(no.rotation.y, atan2(alvo_dir.x, alvo_dir.y), minf(1.0, dt * 8.0))
				_animar_quadrupede(c, a, vel, dt)
			"coruja":
				no.visible = visivel
				no.position = Vector3(a.pos.x, 0, a.pos.y)
				_animar_coruja(c, a, dt)
			"cobra":
				# folhas mexendo: quem ouviu o chacoalhar sabe de onde vem; a cobra só aparece para quem a nota
				no.position = Vector3(a.pos.x, 0, a.pos.y)
				var ouviu: bool = a.avisado.has(j.id) or ver_tudo
				var vista: bool = ver_tudo or mundo.fauna.cobra_vista(a)
				no.visible = ouviu or vista
				c["corpo"].visible = vista
				for k in c["folhas"].size():
					var f: Node3D = c["folhas"][k]
					f.visible = ouviu
					f.position.y = 0.04 + absf(sin(_t * 18.0 + k * 1.7)) * 0.06
					f.rotation.y = sin(_t * 11.0 + k) * 0.6
				c["cabeca"].position.y = 0.16 + sin(_t * 3.0) * 0.02


# ---------------- modelos ----------------

func _mat(cor: Color, aspereza: float = 0.95) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = aspereza
	return m


func _peca(malha: Mesh, mat: Material, pos: Vector3, pai: Node3D, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	mi.layers = 2
	pai.add_child(mi)
	return mi


func _capsula(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 10
	c.rings = 3
	return c


func _esf(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


func _cx(t: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = t
	return b


## Lobo ou cão: corpo, peito, cabeça com focinho e orelhas, quatro pernas e rabo.
func _quadrupede(cor: Color, escala: float, lobo: bool) -> Dictionary:
	var raiz := Node3D.new()
	var corpo := Node3D.new()
	corpo.scale = Vector3.ONE * escala
	raiz.add_child(corpo)
	var pelo := _mat(cor)
	var escuro := _mat(cor.darkened(0.35))
	_peca(_capsula(0.22, 1.05), pelo, Vector3(0, 0.72, 0), corpo, Vector3(PI / 2, 0, 0))
	_peca(_esf(0.25), pelo, Vector3(0, 0.78, 0.36), corpo)
	var cabeca := Node3D.new()
	cabeca.position = Vector3(0, 0.95, 0.6)
	corpo.add_child(cabeca)
	_peca(_esf(0.16), pelo, Vector3.ZERO, cabeca)
	_peca(_cx(Vector3(0.12, 0.11, 0.24)), pelo, Vector3(0, -0.04, 0.17), cabeca)
	_peca(_esf(0.03), _mat(Color(0.05, 0.05, 0.05)), Vector3(0, -0.01, 0.3), cabeca)
	for lado in [-1, 1]:
		var orelha := PrismMesh.new()
		orelha.size = Vector3(0.09, 0.16 if lobo else 0.11, 0.04)
		var o := _peca(orelha, escuro, Vector3(lado * 0.08, 0.16, -0.02), cabeca, Vector3(0, 0, lado * 0.25 if lobo else lado * 0.7))
		o.name = "orelha"
	var pernas: Array[Node3D] = []
	for z in [0.32, -0.32]:
		for lado in [-1, 1]:
			var quadril := Node3D.new()
			quadril.position = Vector3(lado * 0.12, 0.62, z)
			corpo.add_child(quadril)
			_peca(_capsula(0.05, 0.62), pelo, Vector3(0, -0.3, 0), quadril)
			pernas.append(quadril)
	var rabo := Node3D.new()
	rabo.position = Vector3(0, 0.78, -0.55)
	corpo.add_child(rabo)
	_peca(_capsula(0.06 if lobo else 0.04, 0.5), escuro if lobo else pelo, Vector3(0, -0.05, -0.22), rabo, Vector3(PI / 2 + 0.6, 0, 0))
	return {"no": raiz, "corpo": corpo, "cabeca": cabeca, "pernas": pernas, "rabo": rabo}


func _animar_quadrupede(c: Dictionary, a, vel: float, dt: float) -> void:
	var andando := vel > 0.2
	c["fase"] += dt * clampf(vel, 0.0, 8.0) * 4.0
	var s := sin(c["fase"])
	var pernas: Array = c["pernas"]
	var amp := clampf(vel / 3.0, 0.0, 1.0) * 0.6 if andando else 0.0
	for k in 4:
		var sinal := 1.0 if k in [0, 3] else -1.0
		pernas[k].rotation.x = s * amp * sinal
	if a.tipo == "lobo" and a.ferido:
		pernas[1].rotation.x = -0.9   # manca: a pata dianteira não toca o chão
	var cabeca: Node3D = c["cabeca"]
	var rabo: Node3D = c["rabo"]
	match a.estado:
		"rosnando", "porta":
			cabeca.position.y = lerp(cabeca.position.y, 0.78, dt * 6.0)   # cabeça baixa, orelhas para trás
			cabeca.rotation.x = 0.25
			rabo.rotation.x = 0.5
		"esperando", "guiando":
			cabeca.position.y = lerp(cabeca.position.y, 1.0, dt * 6.0)
			cabeca.rotation.x = -0.1
			rabo.rotation.y = sin(_t * 14.0) * 0.7   # abana o rabo
			rabo.rotation.x = -0.6
		_:
			cabeca.position.y = lerp(cabeca.position.y, 0.95, dt * 6.0)
			cabeca.rotation.x = 0.0
			rabo.rotation.y = sin(_t * 2.0) * 0.1
			rabo.rotation.x = 0.0
	c["corpo"].position.y = absf(cos(c["fase"])) * 0.03 if andando else 0.0


## Coruja num mourão de pouso: corpo, cabeça com disco facial, que gira para quem ela notou.
func _coruja() -> Dictionary:
	var raiz := Node3D.new()
	var mourao := _mat(Color(0.3, 0.25, 0.2))
	var c := CylinderMesh.new()
	c.top_radius = 0.11
	c.bottom_radius = 0.14
	c.height = 2.4
	_peca(c, mourao, Vector3(0, 1.2, 0), raiz)
	var ave := Node3D.new()
	ave.position = Vector3(0, 2.4, 0)
	raiz.add_child(ave)
	var pena := _mat(Color(0.42, 0.33, 0.24))
	var corpo := _peca(_esf(0.16), pena, Vector3(0, 0.18, 0), ave)
	corpo.scale = Vector3(0.95, 1.35, 0.85)
	var cabeca := Node3D.new()
	cabeca.position = Vector3(0, 0.42, 0)
	ave.add_child(cabeca)
	_peca(_esf(0.12), pena, Vector3.ZERO, cabeca)
	var disco := _peca(_esf(0.1), _mat(Color(0.72, 0.64, 0.52)), Vector3(0, -0.01, 0.06), cabeca)
	disco.scale = Vector3(1.0, 0.9, 0.35)
	for lado in [-1, 1]:
		_peca(_esf(0.025), _mat(Color(0.04, 0.03, 0.02), 0.3), Vector3(lado * 0.04, 0.01, 0.1), cabeca)
	_peca(_cx(Vector3(0.025, 0.04, 0.04)), _mat(Color(0.3, 0.26, 0.2)), Vector3(0, -0.04, 0.12), cabeca, Vector3(0.4, 0, 0))
	return {"no": raiz, "ave": ave, "cabeca": cabeca}


func _animar_coruja(c: Dictionary, a, dt: float) -> void:
	var ave: Node3D = c["ave"]
	var cabeca: Node3D = c["cabeca"]
	ave.visible = a.estado != "voando"
	var alvo_ang := sin(_t * 0.4 + c["fase"]) * 1.2   # olha em volta devagar
	if a.alvo >= 0 and mundo.tempo < a.sinal_ate:
		var d: Vector2 = mundo.personagens[a.alvo].pos - a.pos
		if a.sinal.begins_with("olhou") and mundo.personagens.size() > 1:
			# avisou: vira a cabeça para outro personagem perto
			for o in mundo.personagens:
				if o.id != a.alvo and o.pos.distance_to(a.pos) < 60.0:
					d = o.pos - a.pos
					break
		alvo_ang = atan2(d.x, d.y)
	cabeca.rotation.y = lerp_angle(cabeca.rotation.y, alvo_ang, minf(1.0, dt * 5.0))


## Cobra enrolada (jararaca) e as folhas secas que mexem quando ela chacoalha.
func _cobra() -> Dictionary:
	var raiz := Node3D.new()
	var corpo := Node3D.new()
	raiz.add_child(corpo)
	var pele := _mat(Color(0.36, 0.29, 0.2), 0.6)
	var escura := _mat(Color(0.2, 0.15, 0.1), 0.6)
	for k in 3:
		var t := TorusMesh.new()
		t.inner_radius = 0.16 - k * 0.04
		t.outer_radius = 0.22 - k * 0.04
		t.rings = 18
		t.ring_segments = 8
		_peca(t, pele if k % 2 == 0 else escura, Vector3(0, 0.05 + k * 0.06, 0), corpo)
	var cabeca := _peca(_esf(0.05), pele, Vector3(0.08, 0.16, 0.05), corpo)
	cabeca.scale = Vector3(1.0, 0.6, 1.5)
	var folhas: Array[Node3D] = []
	var seca := _mat(Color(0.46, 0.33, 0.16))
	for k in 9:
		var ang := TAU * k / 9.0
		var f := _peca(_cx(Vector3(0.12, 0.01, 0.2)), seca, Vector3(cos(ang) * 0.45, 0.04, sin(ang) * 0.45), raiz, Vector3(0, ang, 0.3))
		folhas.append(f)
	return {"no": raiz, "corpo": corpo, "cabeca": cabeca, "folhas": folhas}
