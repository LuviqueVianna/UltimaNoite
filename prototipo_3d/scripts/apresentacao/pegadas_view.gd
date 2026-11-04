extends Node3D
## Pegadas como decalques projetados no chão. Uma textura por calçado e por pé.
## No navegador (renderizador Compatibility) não existe Decal: lá cada pegada é um plano rente ao chão.
## Cada pegada só aparece se o jogador a enxerga (alcance + linha de visada) e some com a idade.

const COMPRIMENTO := {"bota": 0.31, "botina": 0.29, "descalco": 0.26}
const LARGURA := {"bota": 0.12, "botina": 0.11, "descalco": 0.11}

var mundo
var escala := 1.5              # 1 = tamanho real; o jogo pode exagerar para ler melhor
var brilho_borda := 0.35       # emissão da borda úmida (ajuda a ler no escuro)
var _texturas := {}
var _vivas: Array = []         # [{peg, decal}]
var _fixas: Array[Node3D] = []
var _plano := RenderingServer.get_current_rendering_method() == "gl_compatibility"
var _relogio := 0.0


func _ready() -> void:
	for calcado in ["bota", "botina", "descalco"]:
		for lado in [0, 1]:
			_texturas[calcado + str(lado)] = _gerar(calcado, lado)


func ao_criar(peg: Dictionary) -> void:
	var d := _decal(peg)
	add_child(d)
	_vivas.append({"peg": peg, "decal": d})


## Pegadas antigas, que não somem (ex.: as do dono da casa, levando à porta).
func fixar(pos: Vector2, angulo: float, calcado: String, lado: int) -> void:
	var d := _decal({"pos": pos, "angulo": angulo, "calcado": calcado, "lado": lado})
	add_child(d)
	_fixas.append(d)


func _decal(peg: Dictionary) -> Node3D:
	var calcado: String = peg["calcado"]
	var t: Array = _texturas[calcado + str(peg["lado"])]
	var p: Vector2 = peg["pos"]
	if _plano:
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		mi.mesh = pm
		var m := StandardMaterial3D.new()
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_texture = t[0]
		m.emission_enabled = true
		m.emission_texture = t[1]
		m.emission_energy_multiplier = brilho_borda
		m.roughness = 1.0
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(p.x, 0.02, p.y)
		mi.rotation.y = -float(peg["angulo"]) - PI / 2.0
		mi.set_meta("calcado", calcado)
		_tamanho(mi, calcado)
		return mi
	var d := Decal.new()
	d.texture_albedo = t[0]
	d.texture_emission = t[1]
	d.emission_energy = brilho_borda
	d.set_meta("calcado", calcado)
	_tamanho(d, calcado)
	d.albedo_mix = 1.0
	d.upper_fade = 0.2
	d.lower_fade = 0.2
	d.position = Vector3(p.x, 0.0, p.y)
	d.rotation.y = -float(peg["angulo"]) - PI / 2.0
	d.cull_mask = 1   # só o chão (camada 1); mata e personagens ficam na camada 2
	return d


func atualizar(dt: float, olho: Vector2, ver_tudo: bool) -> int:
	_relogio += dt
	var checar := _relogio > 0.2
	if checar:
		_relogio = 0.0
	var visiveis := 0
	var restantes: Array = []
	for item in _vivas:
		var peg: Dictionary = item["peg"]
		var d: Node3D = item["decal"]
		var idade: float = mundo.idade(peg)
		if idade > mundo.VIDA_PEGADA:
			d.queue_free()
			continue
		restantes.append(item)
		if checar:
			d.visible = ver_tudo or mundo.ve(olho, peg["pos"])
		var vida := 1.0 - smoothstep(mundo.VIDA_PEGADA * 0.5, mundo.VIDA_PEGADA, idade)
		_vida(d, vida)
		if d.visible:
			visiveis += 1
	_vivas = restantes
	if checar:
		for d in _fixas:
			d.visible = ver_tudo or mundo.ve(olho, Vector2(d.position.x, d.position.z))
	return visiveis


func reaplicar_escala() -> void:
	for item in _vivas:
		_tamanho(item["decal"], item["decal"].get_meta("calcado"))
	for d in _fixas:
		_tamanho(d, d.get_meta("calcado"))


func _tamanho(n: Node3D, calcado: String) -> void:
	var w: float = LARGURA[calcado] * escala
	var l: float = COMPRIMENTO[calcado] * escala
	if n is Decal:
		n.size = Vector3(w, 0.8, l)
	else:
		(n as MeshInstance3D).mesh.size = Vector2(w, l)


func _vida(n: Node3D, vida: float) -> void:
	if n is Decal:
		n.modulate.a = vida
		n.emission_energy = brilho_borda * vida
	else:
		var m: StandardMaterial3D = (n as MeshInstance3D).material_override
		m.albedo_color.a = vida
		m.emission_energy_multiplier = brilho_borda * vida


# ---------------- texturas (geradas, provisórias) ----------------
# 64 x 160 px; y = 0 é a ponta do pé. Miolo escuro (barro afundado) e borda clara (água na lama).

func _dentro(calcado: String, x: float, y: float) -> int:
	# 0 = fora, 1 = sola, 2 = ranhura (só calçado)
	match calcado:
		"bota", "botina":
			var salto_ini := 112.0 if calcado == "bota" else 118.0
			if y >= 4 and y <= 104:
				var t := (y - 52.0) / 48.0
				var cx := 32.0 + 3.0 * t
				var meia := 25.0 * sqrt(max(0.0, 1.0 - t * t * (0.9 if t < 0 else 0.55)))
				if abs(x - cx) <= meia:
					return 2 if int(y) % 9 < 3 and y > 14 and y < 98 else 1
			if y >= salto_ini and y <= 156:
				var mx: float = 19.0 if y < 150 else 19.0 - (y - 150.0) * 1.5
				if abs(x - 33.0) <= mx:
					return 2 if int(y) % 9 < 3 else 1
			return 0
		_:
			# pé descalço: dedos, planta, arco e calcanhar
			var dedos := [[21.0, 13.0, 9.0], [34.0, 11.0, 6.5], [43.0, 14.0, 5.5], [50.0, 19.0, 5.0], [55.0, 26.0, 4.5]]
			for d in dedos:
				if Vector2(x - d[0], y - d[1]).length() <= d[2]:
					return 1
			if y >= 30 and y <= 92:
				var t := (y - 60.0) / 32.0
				var meia := 23.0 * sqrt(max(0.0, 1.0 - t * t))
				if abs(x - (34.0 + 2.0 * t)) <= meia:
					return 1
			if y > 92 and y < 112:
				# arco: só a borda externa toca o chão
				if x > 34.0 and x < 50.0:
					return 1
			if y >= 108 and y <= 156:
				var t := (y - 132.0) / 24.0
				var meia := 16.0 * sqrt(max(0.0, 1.0 - t * t))
				if abs(x - 38.0) <= meia:
					return 1
			return 0


func _gerar(calcado: String, lado: int) -> Array:
	var w := 64
	var h := 160
	var mapa := PackedByteArray()
	mapa.resize(w * h)
	for y in h:
		for x in w:
			mapa[y * w + x] = _dentro(calcado, x, y)
	var alb := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var emi := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var miolo := Color(0.06, 0.035, 0.025, 0.92)
	var ranhura := Color(0.16, 0.1, 0.07, 0.9)
	var borda := Color(0.8, 0.74, 0.64, 0.6)
	for y in h:
		for x in w:
			var v := mapa[y * w + x]
			if v == 1:
				alb.set_pixel(x, y, miolo)
			elif v == 2:
				alb.set_pixel(x, y, ranhura)
			else:
				var perto := false
				for dy in range(-3, 4):
					for dx in range(-3, 4):
						var xx := x + dx
						var yy := y + dy
						if xx >= 0 and yy >= 0 and xx < w and yy < h and mapa[yy * w + xx] != 0 and dx * dx + dy * dy <= 10:
							perto = true
							break
					if perto:
						break
				if perto:
					alb.set_pixel(x, y, borda)
					emi.set_pixel(x, y, Color(0.55, 0.6, 0.62, 1.0))
	if lado == 1:
		alb.flip_x()
		emi.flip_x()
	alb.generate_mipmaps()
	emi.generate_mipmaps()
	return [ImageTexture.create_from_image(alb), ImageTexture.create_from_image(emi)]
