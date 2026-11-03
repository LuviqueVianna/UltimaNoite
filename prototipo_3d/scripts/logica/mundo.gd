extends RefCounted
## Lógica do protótipo 3D: terreno, trilhas, mata, personagens, pegadas e visão.
## Sem nenhum nó visual. Coordenadas em metros no plano do chão (Vector2 = x, z).

signal pegada_criada(pegada: Dictionary)

const TAMANHO := 160.0            # lado do trecho, em metros (de -80 a 80)
const N := 160                    # células de 1 m
const MATA := 0
const TRILHA := 1
const CLAREIRA := 2

const VIDA_PEGADA := 40.0         # s (o MVP usa 15 a 20; maior aqui para avaliar leitura)
const PASSO := 0.8                # m entre pegadas
const ALCANCE_VISAO := 22.0       # m
const MATA_QUE_TAPA := 2.5        # m de mata atravessados pela linha de visada até tapar

var celulas := PackedByteArray()
var base_pos := Vector2(4, -6)
var base_raio := 18.0
var clareira_vazia := Vector2.ZERO
var obstaculos: Array[Rect2] = []   # construções (a cabana), em metros
var trilhas: Array = []           # Array[PackedVector2Array]
var arvores: Array = []           # {pos, tipo, escala, giro}
var plantas: Array = []           # {pos, tipo, escala, giro}
var pegadas: Array = []           # {pos, angulo, calcado, lado, nasceu, dono}
var personagens: Array = []
var tempo := 0.0

var _rng := RandomNumberGenerator.new()
var _ruido := FastNoiseLite.new()


class Personagem:
	var nome := ""
	var calcado := "bota"
	var pos := Vector2.ZERO
	var direcao := Vector2(0, 1)
	var velocidade := 4.0
	var andando := false
	var _acumulado := 0.0
	var _lado := 0
	var rota: PackedVector2Array = PackedVector2Array()
	var _alvo := 0
	var _sentido := 1


func _init(semente: int = 7) -> void:
	_rng.seed = semente
	_ruido.seed = semente
	_ruido.frequency = 0.08
	celulas.resize(N * N)
	celulas.fill(MATA)
	_gerar_trilhas()
	_gerar_clareiras()
	_gerar_vegetacao()
	# cabana (6 x 4,4 m) com chaminé, centrada na base
	obstaculos.append(Rect2(base_pos + Vector2(-4.1, -2.6), Vector2(7.5, 5.2)))


# ---------------- terreno ----------------

func indice(p: Vector2) -> int:
	var i := int(floor(p.x + TAMANHO / 2.0))
	var j := int(floor(p.y + TAMANHO / 2.0))
	if i < 0 or j < 0 or i >= N or j >= N:
		return -1
	return j * N + i


func tipo_em(p: Vector2) -> int:
	var k := indice(p)
	return MATA if k < 0 else celulas[k]


func andavel(p: Vector2) -> bool:
	if tipo_em(p) == MATA:
		return false
	for r in obstaculos:
		if r.has_point(p):
			return false
	return true


func _marcar(p: Vector2, raio: float, tipo: int) -> void:
	var r := int(ceil(raio))
	for dj in range(-r, r + 1):
		for di in range(-r, r + 1):
			var q := p + Vector2(di, dj)
			if q.distance_to(p) <= raio:
				var k := indice(q)
				if k >= 0 and celulas[k] < tipo:
					celulas[k] = tipo


func _curva(de: Vector2, para: Vector2, tremor: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var total := de.distance_to(para)
	var n := int(total / 2.0)
	var normal := (para - de).normalized().orthogonal()
	var fase := _rng.randf() * 100.0
	for s in n + 1:
		var t := float(s) / n
		var desvio := sin(t * PI) * _ruido.get_noise_1d(fase + t * total * 0.6) * tremor
		pts.append(de.lerp(para, t) + normal * desvio)
	return pts


func _tracar(pts: PackedVector2Array, largura: float) -> void:
	for s in pts.size() - 1:
		var a := pts[s]
		var b := pts[s + 1]
		var d := a.distance_to(b)
		var passos := int(d / 0.5) + 1
		for k in passos + 1:
			_marcar(a.lerp(b, float(k) / passos), largura / 2.0, TRILHA)
	trilhas.append(pts)


func _gerar_trilhas() -> void:
	var b := base_pos
	# oeste até a borda, com bifurcação que morre num beco
	var oeste := _curva(b + Vector2(-12, 2), Vector2(-80, 10), 14.0)
	_tracar(oeste, 2.4)
	var meio := oeste[int(oeste.size() * 0.45)]
	_tracar(_curva(meio, meio + Vector2(-6, -28), 6.0), 2.0)            # beco
	# sudeste até a borda, passando por uma clareira vazia
	clareira_vazia = b + Vector2(34, 36)
	_tracar(_curva(b + Vector2(9, 10), clareira_vazia, 10.0), 2.4)
	_tracar(_curva(clareira_vazia, Vector2(80, 70), 12.0), 2.4)
	# norte até a borda
	_tracar(_curva(b + Vector2(2, -13), Vector2(-10, -80), 16.0), 2.4)
	# trilha que cruza a do sudeste
	_tracar(_curva(Vector2(20, 80), Vector2(70, -20), 12.0), 2.2)


func _gerar_clareiras() -> void:
	for centro in [base_pos, clareira_vazia]:
		var raio: float = base_raio if centro == base_pos else 7.0
		for j in N:
			for i in N:
				var p := Vector2(i - TAMANHO / 2.0 + 0.5, j - TAMANHO / 2.0 + 0.5)
				var ang: float = (p - centro).angle()
				var borda: float = raio * (1.0 + 0.18 * _ruido.get_noise_2d(cos(ang) * 30.0 + centro.x, sin(ang) * 30.0))
				if p.distance_to(centro) <= borda:
					celulas[j * N + i] = CLAREIRA


func distancia_ao_aberto(p: Vector2, limite: float = 4.0) -> float:
	var r := int(ceil(limite))
	var melhor := limite
	for dj in range(-r, r + 1):
		for di in range(-r, r + 1):
			var q := p + Vector2(di, dj)
			if tipo_em(q) != MATA:
				melhor = min(melhor, Vector2(di, dj).length())
	return melhor


func _gerar_vegetacao() -> void:
	# Árvores: grade com sorteio, a partir de 1,6 m do aberto. Mata bem fechada.
	var esp := 2.3
	var y := -TAMANHO / 2.0 + 1.0
	while y < TAMANHO / 2.0 - 1.0:
		var x := -TAMANHO / 2.0 + 1.0
		while x < TAMANHO / 2.0 - 1.0:
			var p := Vector2(x, y) + Vector2(_rng.randf_range(-0.9, 0.9), _rng.randf_range(-0.9, 0.9))
			x += esp
			if tipo_em(p) != MATA:
				continue
			var aberto := distancia_ao_aberto(p, 6.0)
			if aberto < 1.6:
				continue
			# copas largas ficam longe do aberto, para a lua alcançar trilhas e clareiras;
			# na beira, só espécies de copa estreita (embaúba, palmeira, bambu)
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
	y = -TAMANHO / 2.0
	while y < TAMANHO / 2.0:
		var x := -TAMANHO / 2.0
		while x < TAMANHO / 2.0:
			var p := Vector2(x, y) + Vector2(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, 0.6))
			x += 1.5
			if tipo_em(p) != MATA:
				continue
			var aberto := distancia_ao_aberto(p, 2.0)
			var tipo := "samambaia"
			if aberto < 1.3 and _rng.randf() < 0.35:
				tipo = "bromelia"
			elif _rng.randf() < 0.3:
				tipo = "moita"
			plantas.append({"pos": p, "tipo": tipo, "escala": _rng.randf_range(0.7, 1.4), "giro": _rng.randf() * TAU})
		y += 1.5


# ---------------- personagens ----------------

func criar_personagem(nome: String, calcado: String, pos: Vector2) -> Personagem:
	var p := Personagem.new()
	p.nome = nome
	p.calcado = calcado
	p.pos = pos
	personagens.append(p)
	return p


func mover(p: Personagem, entrada: Vector2, dt: float) -> void:
	p.andando = entrada.length() > 0.1
	if not p.andando:
		return
	var dir := entrada.normalized()
	var passo := dir * p.velocidade * dt
	var novo := p.pos + passo
	if not andavel(novo):
		# desliza pela parede de mata
		if andavel(p.pos + Vector2(passo.x, 0)):
			novo = p.pos + Vector2(passo.x, 0)
		elif andavel(p.pos + Vector2(0, passo.y)):
			novo = p.pos + Vector2(0, passo.y)
		else:
			p.andando = false
			return
	var andou := p.pos.distance_to(novo)
	p.direcao = (novo - p.pos).normalized() if andou > 0.0001 else p.direcao
	p.pos = novo
	p._acumulado += andou
	while p._acumulado >= PASSO:
		p._acumulado -= PASSO
		_deixar_pegada(p)


func seguir_rota(p: Personagem, dt: float) -> void:
	if p.rota.size() < 2:
		return
	var alvo := p.rota[p._alvo]
	if p.pos.distance_to(alvo) < 0.6:
		p._alvo += p._sentido
		if p._alvo >= p.rota.size() or p._alvo < 0:
			p._sentido = -p._sentido
			p._alvo += 2 * p._sentido
		alvo = p.rota[p._alvo]
	mover(p, alvo - p.pos, dt)


func _deixar_pegada(p: Personagem) -> void:
	p._lado = 1 - p._lado
	var lateral := p.direcao.orthogonal() * (0.13 if p._lado == 0 else -0.13)
	var peg := {
		"pos": p.pos + lateral,
		"angulo": p.direcao.angle(),
		"calcado": p.calcado,
		"lado": p._lado,
		"nasceu": tempo,
		"dono": p.nome,
	}
	pegadas.append(peg)
	pegada_criada.emit(peg)


func atualizar(dt: float) -> void:
	tempo += dt
	while not pegadas.is_empty() and tempo - pegadas[0]["nasceu"] > VIDA_PEGADA:
		pegadas.pop_front()


func idade(peg: Dictionary) -> float:
	return tempo - float(peg["nasceu"])


# ---------------- visão ----------------

## Visível quando está no alcance e a linha de visada atravessa pouca mata.
func ve(de: Vector2, para: Vector2, alcance: float = ALCANCE_VISAO) -> bool:
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


## Ponto ao longo das trilhas, útil para posicionar câmera e testes.
func ponto_da_trilha(indice_trilha: int, fracao: float) -> Vector2:
	var t: PackedVector2Array = trilhas[indice_trilha]
	return t[clampi(int(fracao * (t.size() - 1)), 0, t.size() - 1)]
