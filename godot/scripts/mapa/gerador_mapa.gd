class_name GeradorMapa
extends RefCounted
## Sorteia o mapa da partida: clareiras ligadas por trilhas, com voltas, bifurcações e becos.
## Regras: docs/MVP_v0.4.md, seção 2.

const AREA := Vector2(450, 450)            # aumentado a pedido do usuário em 20/10/2026 (era 300)
const MARGEM := 20.0
const DIST_MIN_CLAREIRAS := 82.0
const LIGACAO_MAX := 195.0
const CHANCE_VOLTA := 0.45
const TRECHO_MAX := 40.0
const DESVIO := 4.0
const BECO_TRECHO := Vector2(22.0, 34.0)
const BECO_FOLGA := 18.0
const BASES_COM_VOLTA_MIN := 4

var rng := RandomNumberGenerator.new()


func gerar(semente: int) -> Mapa:
	rng.seed = semente
	for tentativa in 80:
		var m := _tentar()
		if m != null:
			m.semente = semente
			return m
	push_error("Não consegui gerar um mapa válido com a semente %d" % semente)
	return null


func _tentar() -> Mapa:
	var pontos := _sortear_clareiras(rng.randi_range(10, 12))
	if pontos.size() < 10:
		return null
	var ligacoes := _ligar(pontos)
	if ligacoes.is_empty():
		return null

	var m := Mapa.new()
	m.tamanho = AREA
	for p in pontos:
		m.adicionar_no(p, "clareira")
	for l in ligacoes:
		_criar_trilha(m, l.x, l.y)
	_criar_becos(m)
	if not _escolher_bases_e_partidas(m):
		return null
	if _bases_com_volta(m) < BASES_COM_VOLTA_MIN:
		return null
	if not _escolher_saidas(m):
		return null
	m.finalizar()
	return m


func _sortear_clareiras(n: int) -> Array:
	var pts := []
	var tentativas := 0
	while pts.size() < n and tentativas < 3000:
		tentativas += 1
		var p := Vector2(rng.randf_range(MARGEM, AREA.x - MARGEM), rng.randf_range(MARGEM, AREA.y - MARGEM))
		var ok := true
		for q in pts:
			if p.distance_to(q) < DIST_MIN_CLAREIRAS:
				ok = false
				break
		if ok:
			pts.append(p)
	return pts


## Árvore mínima (garante que tudo se liga, sem cruzamentos) + algumas ligações extras (voltas).
func _ligar(pts: Array) -> Array:
	var candidatas := []
	for i in pts.size():
		for j in range(i + 1, pts.size()):
			var d: float = pts[i].distance_to(pts[j])
			if d <= LIGACAO_MAX:
				candidatas.append([d, i, j])
	candidatas.sort_custom(func(a, b): return a[0] < b[0])

	var pai := range(pts.size())
	var achar := func(x: int) -> int:
		while pai[x] != x:
			x = pai[x]
		return x
	var escolhidas := []
	var sobra := []
	for c in candidatas:
		var ra: int = achar.call(c[1])
		var rb: int = achar.call(c[2])
		if ra != rb:
			pai[ra] = rb
			escolhidas.append(Vector2i(c[1], c[2]))
		else:
			sobra.append(c)
	# Se a árvore não fechou (pontos muito distantes), a tentativa falha.
	var raiz: int = achar.call(0)
	for i in pts.size():
		if achar.call(i) != raiz:
			return []

	var grau := {}
	for e in escolhidas:
		grau[e.x] = grau.get(e.x, 0) + 1
		grau[e.y] = grau.get(e.y, 0) + 1
	for c in sobra:
		if rng.randf() > CHANCE_VOLTA:
			continue
		var a: int = c[1]
		var b: int = c[2]
		if grau.get(a, 0) >= 4 or grau.get(b, 0) >= 4:
			continue
		if _cruza(pts[a], pts[b], escolhidas.map(func(e): return [pts[e.x], pts[e.y]])):
			continue
		if not _angulo_ok(pts, escolhidas, a, b) or not _angulo_ok(pts, escolhidas, b, a):
			continue
		escolhidas.append(Vector2i(a, b))
		grau[a] = grau.get(a, 0) + 1
		grau[b] = grau.get(b, 0) + 1
	return escolhidas


func _angulo_ok(pts: Array, ligs: Array, de: int, para: int) -> bool:
	var dir: Vector2 = (pts[para] - pts[de]).normalized()
	for e in ligs:
		var outro := -1
		if e.x == de:
			outro = e.y
		elif e.y == de:
			outro = e.x
		if outro >= 0 and absf(dir.angle_to((pts[outro] - pts[de]).normalized())) < deg_to_rad(30):
			return false
	return true


func _cruza(a: Vector2, b: Vector2, segmentos: Array) -> bool:
	for s in segmentos:
		var c: Vector2 = s[0]
		var d: Vector2 = s[1]
		if a.is_equal_approx(c) or a.is_equal_approx(d) or b.is_equal_approx(c) or b.is_equal_approx(d):
			continue
		if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
			return true
	return false


func _criar_trilha(m: Mapa, a: int, b: int) -> void:
	var pa := m.pos(a)
	var pb := m.pos(b)
	var n := ceili(pa.distance_to(pb) / TRECHO_MAX)
	var normal := (pb - pa).normalized().orthogonal()
	var anterior := a
	for i in range(1, n):
		var p := pa.lerp(pb, float(i) / n) + normal * rng.randf_range(-DESVIO, DESVIO)
		var novo := m.adicionar_no(p, "trilha")
		m.adicionar_aresta(anterior, novo)
		anterior = novo
	m.adicionar_aresta(anterior, b)


func _segmentos(m: Mapa) -> Array:
	return m.arestas.map(func(e): return [m.pos(e["a"]), m.pos(e["b"])])


func _criar_becos(m: Mapa) -> void:
	var trechos := m.nos.filter(func(n): return n["tipo"] == "trilha").map(func(n): return n["id"])
	trechos.shuffle()
	var meta := rng.randi_range(3, 5)
	var feitos := 0
	for origem in trechos:
		if feitos >= meta:
			break
		if _tentar_beco(m, origem):
			feitos += 1


func _tentar_beco(m: Mapa, origem: int) -> bool:
	var v: Vector2i = m.adj[origem][0]
	var ao_longo := (m.pos(v.x) - m.pos(origem)).normalized()
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var dir := ao_longo.orthogonal().rotated(lado * rng.randf_range(-0.5, 0.5)) * lado
	var pontos := [m.pos(origem)]
	for i in rng.randi_range(1, 2):
		dir = dir.rotated(rng.randf_range(-0.4, 0.4))
		pontos.append(pontos[-1] + dir * rng.randf_range(BECO_TRECHO.x, BECO_TRECHO.y))
	var segs := _segmentos(m)
	for i in range(1, pontos.size()):
		var p: Vector2 = pontos[i]
		if p.x < MARGEM or p.y < MARGEM or p.x > AREA.x - MARGEM or p.y > AREA.y - MARGEM:
			return false
		for n in m.nos:
			if n["id"] != origem and n["pos"].distance_to(p) < BECO_FOLGA:
				return false
		if _cruza(pontos[i - 1], p, segs):
			return false
		for s in segs:
			if Geometry2D.get_closest_point_to_segment(p, s[0], s[1]).distance_to(p) < BECO_FOLGA:
				return false
	m.nos[origem]["tipo"] = "bifurcacao"
	var anterior := origem
	for i in range(1, pontos.size()):
		var tipo := "beco" if i == pontos.size() - 1 else "trilha"
		var novo := m.adicionar_no(pontos[i], tipo)
		m.adicionar_aresta(anterior, novo)
		anterior = novo
	return true


func _escolher_bases_e_partidas(m: Mapa) -> bool:
	var clareiras := m.nos.filter(func(n): return n["tipo"] == "clareira").map(func(n): return n["id"])
	if clareiras.size() < 10:
		return false
	var ids_bases := Regras.BASES.keys()
	var melhor_espalho := INF
	var melhor_bases := []
	var melhor_partidas := []
	for tentativa in 30:
		var ordem := clareiras.duplicate()
		_embaralhar(ordem)
		var bases := ordem.slice(0, ids_bases.size())
		var livres := ordem.slice(ids_bases.size())
		var medias := {}
		for l in livres:
			var soma := 0.0
			for b in bases:
				soma += m.distancia_grafo(l, b)
			medias[l] = soma / bases.size()
		livres.sort_custom(func(a, b): return medias[a] < medias[b])
		for i in range(0, livres.size() - 3):
			var grupo := livres.slice(i, i + 4)
			var espalho: float = medias[grupo[3]] - medias[grupo[0]]
			if espalho < melhor_espalho:
				melhor_espalho = espalho
				melhor_bases = bases
				melhor_partidas = grupo
	if melhor_bases.is_empty():
		return false
	for i in ids_bases.size():
		m.nos[melhor_bases[i]]["base"] = ids_bases[i]
	for p in melhor_partidas:
		m.nos[p]["partida"] = true
	return true


## A saída de cada personagem fica no ponto oposto do mapa ao da sua partida (espelhado pelo centro).
func _escolher_saidas(m: Mapa) -> bool:
	var centro := AREA / 2.0
	for partida in m.partidas():
		var alvo: Vector2 = centro * 2.0 - m.pos(partida)
		var melhor := -1
		var melhor_d := INF
		for n in m.nos:
			if n["base"] != "" or n["partida"] or n["saida"] or n["tipo"] == "beco":
				continue
			var d: float = n["pos"].distance_to(alvo)
			if d < melhor_d:
				melhor_d = d
				melhor = n["id"]
		if melhor < 0 or m.pos(melhor).distance_to(m.pos(partida)) < AREA.x * 0.5:
			return false
		m.nos[melhor]["saida"] = true
		m.saidas[partida] = melhor
	return true


func _embaralhar(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


## Quantas bases estão numa volta (têm mais de um caminho até elas).
func _bases_com_volta(m: Mapa) -> int:
	var pontes := _pontes(m)
	var total := 0
	for n in m.nos:
		if n["base"] == "":
			continue
		var fora_de_ponte := 0
		for v in m.adj[n["id"]]:
			if not pontes.has(v.y):
				fora_de_ponte += 1
		if fora_de_ponte >= 2:
			total += 1
	return total


func _pontes(m: Mapa) -> Dictionary:
	var tin := {}
	var low := {}
	var pontes := {}
	var tempo := [0]
	var visitar := func(proprio: Callable, u: int, aresta_pai: int) -> void:
		tin[u] = tempo[0]
		low[u] = tempo[0]
		tempo[0] += 1
		for v in m.adj[u]:
			if v.y == aresta_pai:
				continue
			if tin.has(v.x):
				low[u] = mini(low[u], tin[v.x])
			else:
				proprio.call(proprio, v.x, v.y)
				low[u] = mini(low[u], low[v.x])
				if low[v.x] > tin[u]:
					pontes[v.y] = true
	visitar.call(visitar, 0, -1)
	return pontes
