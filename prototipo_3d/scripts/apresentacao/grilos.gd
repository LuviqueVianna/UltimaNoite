extends Node3D
## Grilos da mata. Os sons são gerados aqui mesmo (sem arquivo), em laço:
## - grilos espalhados pela mata, com som posicional, que se calam quando o jogador chega perto;
## - um coro baixinho de fundo, de muitos grilos longe.

const TAXA := 32000
const QUANTOS := 18
const CALA_A := 5.0        # m: perto assim, o grilo para de cantar
const VOLTA_A := 9.0       # m: longe assim, ele volta

var mundo
var jogador
var _grilos: Array = []    # {player, volume, calado}
var _rng := RandomNumberGenerator.new()


func montar() -> void:
	_rng.seed = 41
	var cantos := [_canto(4300.0, 3, 0.62), _canto(4800.0, 4, 0.74), _canto(5200.0, 3, 0.5)]
	# lugares: plantas do sub-bosque perto das trilhas
	var lugares: Array = []
	for p in mundo.plantas:
		if mundo.distancia_ao_aberto(p["pos"], 3.0) < 3.0:
			lugares.append(p["pos"])
	for k in QUANTOS:
		if lugares.is_empty():
			break
		var pos: Vector2 = lugares[_rng.randi() % lugares.size()]
		var a := AudioStreamPlayer3D.new()
		a.stream = cantos[k % cantos.size()]
		a.position = Vector3(pos.x, 0.3, pos.y)
		a.unit_size = 7.0
		a.max_distance = 40.0
		a.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		a.pitch_scale = _rng.randf_range(0.94, 1.06)
		a.volume_db = -8.0
		a.panning_strength = 1.0
		add_child(a)
		a.play(_rng.randf() * 5.0)
		_grilos.append({"player": a, "volume": -8.0, "calado": false})
	var coro := AudioStreamPlayer.new()
	coro.stream = _coro()
	coro.volume_db = -19.0
	add_child(coro)
	coro.play()


func _process(dt: float) -> void:
	if jogador == null:
		return
	var eu := Vector3(jogador.pos.x, 0.3, jogador.pos.y)
	for g in _grilos:
		var a: AudioStreamPlayer3D = g["player"]
		var d := a.position.distance_to(eu)
		if d < CALA_A:
			g["calado"] = true
		elif d > VOLTA_A:
			g["calado"] = false
		var alvo := -60.0 if g["calado"] else float(g["volume"])
		# cala rápido (assustado) e volta devagar
		var vel := 30.0 if g["calado"] else 4.0
		a.volume_db = move_toward(a.volume_db, alvo, vel * dt)


# ---------------- síntese ----------------

## Um grilo: trilos de 3 ou 4 sílabas curtas, repetidos com pequena variação de ritmo. 6 s em laço.
func _canto(freq: float, silabas: int, intervalo: float) -> AudioStreamWAV:
	var dur := 6.0
	var n := int(dur * TAXA)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var t0 := 0.05
	while t0 < dur - 0.3:
		for k in silabas:
			_silaba(buf, t0 + k * 0.032, 0.019, freq * _rng.randf_range(0.995, 1.005), 0.5)
		t0 += intervalo * _rng.randf_range(0.9, 1.1)
	return _wav(buf)


## Muitos grilos longe, somados e mais baixos, com um leve chiado de insetos.
func _coro() -> AudioStreamWAV:
	var dur := 8.0
	var n := int(dur * TAXA)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for g in 10:
		var freq := _rng.randf_range(3900.0, 5600.0)
		var silabas := 3 + _rng.randi() % 2
		var intervalo := _rng.randf_range(0.45, 0.9)
		var t0 := _rng.randf() * intervalo
		var amp := _rng.randf_range(0.08, 0.18)
		while t0 < dur - 0.3:
			for k in silabas:
				_silaba(buf, t0 + k * 0.032, 0.018, freq, amp)
			t0 += intervalo * _rng.randf_range(0.92, 1.08)
	var ant := 0.0
	for i in n:
		ant = ant * 0.7 + _rng.randf_range(-1.0, 1.0) * 0.3   # chiado suave
		buf[i] += ant * 0.012
	return _wav(buf)


func _silaba(buf: PackedFloat32Array, inicio: float, dur: float, freq: float, amp: float) -> void:
	var i0 := int(inicio * TAXA)
	var m := int(dur * TAXA)
	for j in m:
		var i := i0 + j
		if i >= buf.size():
			return
		var t := float(j) / TAXA
		var env := sin(PI * float(j) / m)
		env *= env
		# leve vibrato dentro da sílaba, como o atrito da asa
		buf[i] += sin(TAU * freq * t + 0.6 * sin(TAU * 180.0 * t)) * env * amp


func _wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = TAXA
	w.stereo = false
	w.data = bytes
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = buf.size()
	return w
