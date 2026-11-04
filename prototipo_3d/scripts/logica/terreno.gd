extends RefCounted
## Terreno 3D tirado do mapa do MVP: trilhas e clareiras abertas na mata, a mata em volta,
## e a regra de visão por linha de visada. Sem nenhum nó visual. Metros; Vector2 = (x, z).

const MATA := 0
const TRILHA := 1
const CLAREIRA := 2

const LARGURA_TRILHA := 2.6
const RAIO_BASE := 19.0
const RAIO_CLAREIRA := 9.0
const RAIO_BECO := 4.0
const MATA_QUE_TAPA := 2.5        # m de mata atravessados pela linha de visada até tapar

var mapa                          # Mapa do MVP
var n := 0                        # lado da grade em células de 1 m
var tamanho := 0.0
var celulas := PackedByteArray()
var dist_aberto := PackedFloat32Array()   # distância (m) de cada célula de mata até o aberto mais próximo
var arvores: Array = []           # {pos, tipo, escala, giro}
var plantas: Array = []
var casas := {}                   # base -> {centro: Vector2, frente: Vector2 (unitário, da casa para o nó), no}

var _rng := RandomNumberGenerator.new()
var _ruido := FastNoiseLite.new()


func _init(m, semente: int) -> void:
	mapa = m
	_rng.seed = semente
	_ruido.seed = semente
	_ruido.frequency = 0.08
	tamanho = m.tamanho.x
	n = int(ceil(tamanho))
	celulas.resize(n * n)
	celulas.fill(MATA)
	_abrir_trilhas()
	_posicionar_casas()
	_abrir_clareiras()
	_calcular_distancias()
	_gerar_vegetacao()


# ---------------- consulta ----------------

func indice(p: Vector2) -> int:
	var i := int(floor(p.x))
	var j := int(floor(p.y))
	if i < 0 or j < 0 or i >= n or j >= n:
		return -1
	return j * n + i


func tipo_em(p: Vector2) -> int:
	var k := indice(p)
	return MATA if k < 0 else celulas[k]


func distancia_ao_aberto(p: Vector2) -> float:
	var k := indice(p)
	return 0.0 if k < 0 else dist_aberto[k]


## Visível quando a linha de visada atravessa pouca mata.
func ve(de: Vector2, para: Vector2, alcance: float = 1.0e9) -> bool:
	var d := de.distance_to(para)
	if d > alcance:
		return false
	var passos := int(d / 0.5)
	var mata := 0.0
	for s in range(1, passos):
		if tipo_em(de.lerp(para, float(s) / passos)) == MATA:
			mata += 0.5
			if mata > MATA_QUE_TAPA:
				return false
	return true


# ---------------- construção ----------------

func _marcar(p: Vector2, raio: float, tipo: int) -> void:
	var r := int(ceil(raio))
	var ci := int(floor(p.x))
	var cj := int(floor(p.y))
	for dj in range(-r, r + 1):
		for di in range(-r, r + 1):
			var i := ci + di
			var j := cj + dj
			if i < 0 or j < 0 or i >= n or j >= n:
				continue
			if Vector2(i + 0.5, j + 0.5).distance_to(p) <= raio and celulas[j * n + i] < tipo:
				celulas[j * n + i] = tipo


func _abrir_trilhas() -> void:
	# cada aresta do grafo vira uma trilha; um leve serpentear fica dentro da largura
	for e in mapa.arestas:
		var a: Vector2 = mapa.pos(e["a"])
		var b: Vector2 = mapa.pos(e["b"])
		var comp := a.distance_to(b)
		var passos := int(comp / 0.5) + 1
		var largura := LARGURA_TRILHA * _rng.randf_range(0.85, 1.15)
		for k in passos + 1:
			var t := float(k) / passos
			var p := a.lerp(b, t)
			var l := largura * (1.0 + 0.25 * _ruido.get_noise_2d(p.x * 3.0, p.y * 3.0))
			_marcar(p, l / 2.0, TRILHA)


## A casa fica do lado oposto às trilhas que chegam, com a porta da frente voltada para o nó.
func _posicionar_casas() -> void:
	var bases: Dictionary = mapa.bases()
	for b in bases:
		var no: int = bases[b]
		var centro_no: Vector2 = mapa.pos(no)
		var media := Vector2.ZERO
		for v in mapa.adj[no]:
			media += (mapa.pos(v.x) - centro_no).normalized()
		var fora := -media.normalized() if media.length() > 0.1 else Vector2(0, -1)
		casas[b] = {"centro": centro_no + fora * 8.0, "frente": -fora, "no": no}


func _abrir_clareiras() -> void:
	for nd in mapa.nos:
		var raio := 0.0
		var centro: Vector2 = nd["pos"]
		if nd["base"] != "":
			raio = RAIO_BASE
			centro = casas[nd["base"]]["centro"].lerp(centro, 0.35)
		elif nd["tipo"] == "clareira":
			raio = RAIO_CLAREIRA
		elif nd["tipo"] == "beco":
			raio = RAIO_BECO
		elif nd["partida"] or nd["saida"]:
			raio = 6.0
		if raio <= 0.0:
			continue
		var r := int(ceil(raio * 1.25))
		var ci := int(floor(centro.x))
		var cj := int(floor(centro.y))
		var fase := _rng.randf() * 100.0
		for dj in range(-r, r + 1):
			for di in range(-r, r + 1):
				var i := ci + di
				var j := cj + dj
				if i < 0 or j < 0 or i >= n or j >= n:
					continue
				var q := Vector2(i + 0.5, j + 0.5)
				var ang := (q - centro).angle()
				var borda := raio * (1.0 + 0.18 * _ruido.get_noise_2d(cos(ang) * 30.0 + fase, sin(ang) * 30.0))
				if q.distance_to(centro) <= borda:
					celulas[j * n + i] = CLAREIRA


## Distância de cada célula até o aberto: duas passadas (chanfro 3-4), muito mais rápido que procurar em volta.
func _calcular_distancias() -> void:
	dist_aberto.resize(n * n)
	var grande := 1.0e6
	for k in n * n:
		dist_aberto[k] = 0.0 if celulas[k] != MATA else grande
	var d1 := 1.0
	var d2 := 1.4142
	for j in n:
		for i in n:
			var k := j * n + i
			var v := dist_aberto[k]
			if v == 0.0:
				continue
			if i > 0: v = minf(v, dist_aberto[k - 1] + d1)
			if j > 0:
				v = minf(v, dist_aberto[k - n] + d1)
				if i > 0: v = minf(v, dist_aberto[k - n - 1] + d2)
				if i < n - 1: v = minf(v, dist_aberto[k - n + 1] + d2)
			dist_aberto[k] = v
	for j in range(n - 1, -1, -1):
		for i in range(n - 1, -1, -1):
			var k := j * n + i
			var v := dist_aberto[k]
			if v == 0.0:
				continue
			if i < n - 1: v = minf(v, dist_aberto[k + 1] + d1)
			if j < n - 1:
				v = minf(v, dist_aberto[k + n] + d1)
				if i < n - 1: v = minf(v, dist_aberto[k + n + 1] + d2)
				if i > 0: v = minf(v, dist_aberto[k + n - 1] + d2)
			dist_aberto[k] = v


func _gerar_vegetacao() -> void:
	# Árvores: grade com sorteio, a partir de 1,6 m do aberto. Mata bem fechada.
	var esp := 2.3
	var y := 1.0
	while y < tamanho - 1.0:
		var x := 1.0
		while x < tamanho - 1.0:
			var p := Vector2(x, y) + Vector2(_rng.randf_range(-0.9, 0.9), _rng.randf_range(-0.9, 0.9))
			x += esp
			if tipo_em(p) != MATA:
				continue
			var aberto := distancia_ao_aberto(p)
			if aberto < 1.6:
				continue
			# copas largas longe do aberto; na beira, só copas estreitas
			var r := _rng.randf()
			var tipo := "comum"
			if r < 0.14 and aberto > 5.5:
				tipo = "jequitiba"
			elif r < 0.36 or (aberto < 3.0 and r < 0.6):
				tipo = "embauba"
			elif r < 0.46 or aberto < 3.0:
				tipo = "palmeira" if _rng.randf() < 0.7 else "bambu"
			elif r < 0.51:
				tipo = "bambu"
			arvores.append({"pos": p, "tipo": tipo, "escala": _rng.randf_range(0.8, 1.25), "giro": _rng.randf() * TAU})
		y += esp
	# Sub-bosque: samambaias e moitas em toda a mata, bromélias na beira das trilhas.
	y = 0.5
	while y < tamanho:
		var x := 0.5
		while x < tamanho:
			var p := Vector2(x, y) + Vector2(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, 0.6))
			x += 1.5
			if tipo_em(p) != MATA:
				continue
			var aberto := distancia_ao_aberto(p)
			var tipo := "samambaia"
			if aberto < 1.3 and _rng.randf() < 0.35:
				tipo = "bromelia"
			elif _rng.randf() < 0.3:
				tipo = "moita"
			plantas.append({"pos": p, "tipo": tipo, "escala": _rng.randf_range(0.7, 1.4), "giro": _rng.randf() * TAU})
		y += 1.5
