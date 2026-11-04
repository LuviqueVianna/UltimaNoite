class_name Mapa
extends RefCounted
## Grafo do mapa: nós (clareiras, trechos de trilha, bifurcações, becos) ligados por arestas retas.
## Cada aresta é dividida em amostras de 2 m, usadas pela memória do mapa de cada personagem.

var tamanho := Vector2(300, 300)
var nos: Array = []        # {id, pos: Vector2, tipo: String, base: String, partida: bool}
var arestas: Array = []    # {id, a, b, comp, amostra_ini, amostra_fim}
var adj: Array = []        # adj[no] = Array de Vector2i(vizinho, aresta)
var amostras := PackedVector2Array()
var amostra_aresta := PackedInt32Array()
var semente := 0
var saidas := {}            # nó de partida -> nó de saída (o ponto oposto do mapa)


func adicionar_no(pos: Vector2, tipo: String) -> int:
	var id := nos.size()
	nos.append({"id": id, "pos": pos, "tipo": tipo, "base": "", "partida": false, "saida": false})
	adj.append([])
	return id


func adicionar_aresta(a: int, b: int) -> int:
	var id := arestas.size()
	var comp: float = nos[a]["pos"].distance_to(nos[b]["pos"])
	arestas.append({"id": id, "a": a, "b": b, "comp": comp, "amostra_ini": 0, "amostra_fim": 0})
	adj[a].append(Vector2i(b, id))
	adj[b].append(Vector2i(a, id))
	return id


func finalizar() -> void:
	amostras = PackedVector2Array()
	amostra_aresta = PackedInt32Array()
	for e in arestas:
		var pa: Vector2 = nos[e["a"]]["pos"]
		var pb: Vector2 = nos[e["b"]]["pos"]
		var n := maxi(1, ceili(e["comp"] / Regras.AMOSTRA_M))
		e["amostra_ini"] = amostras.size()
		for i in n:
			amostras.append(pa.lerp(pb, (i + 0.5) / n))
			amostra_aresta.append(e["id"])
		e["amostra_fim"] = amostras.size()


func pos(no: int) -> Vector2:
	return nos[no]["pos"]


func grau(no: int) -> int:
	return adj[no].size()


func outra_ponta(aresta: int, no: int) -> int:
	var e: Dictionary = arestas[aresta]
	return e["b"] if e["a"] == no else e["a"]


func aresta_entre(a: int, b: int) -> int:
	for v in adj[a]:
		if v.x == b:
			return v.y
	return -1


## Menor caminho (Dijkstra). Devolve os nós depois da origem, até o destino.
## `aresta_ok` filtra arestas utilizáveis (ex.: só as que o personagem conhece).
func caminho(origem: int, destino: int, aresta_ok: Callable = Callable()) -> Array:
	if origem == destino:
		return []
	var dist := {}
	var ant := {}
	var aberto := {origem: true}
	dist[origem] = 0.0
	while not aberto.is_empty():
		var atual := -1
		var melhor := INF
		for n in aberto:
			if dist[n] < melhor:
				melhor = dist[n]
				atual = n
		aberto.erase(atual)
		if atual == destino:
			break
		for v in adj[atual]:
			if aresta_ok.is_valid() and not aresta_ok.call(v.y):
				continue
			var d: float = melhor + arestas[v.y]["comp"]
			if d < dist.get(v.x, INF):
				dist[v.x] = d
				ant[v.x] = atual
				aberto[v.x] = true
	if not ant.has(destino):
		return []
	var rota := [destino]
	while rota[0] != origem and ant.has(rota[0]):
		rota.push_front(ant[rota[0]])
	rota.pop_front()
	return rota


func distancia_grafo(origem: int, destino: int) -> float:
	var rota := caminho(origem, destino)
	if rota.is_empty():
		return 0.0 if origem == destino else INF
	var total := 0.0
	var anterior := origem
	for n in rota:
		total += arestas[aresta_entre(anterior, n)]["comp"]
		anterior = n
	return total


func no_mais_proximo(p: Vector2, raio: float, filtro: Callable = Callable()) -> int:
	var melhor := -1
	var melhor_d := raio
	for n in nos:
		if filtro.is_valid() and not filtro.call(n["id"]):
			continue
		var d: float = n["pos"].distance_to(p)
		if d <= melhor_d:
			melhor_d = d
			melhor = n["id"]
	return melhor


func bases() -> Dictionary:
	var r := {}
	for n in nos:
		if n["base"] != "":
			r[n["base"]] = n["id"]
	return r


func partidas() -> Array:
	return nos.filter(func(n): return n["partida"]).map(func(n): return n["id"])


func comprimento_total() -> float:
	var t := 0.0
	for e in arestas:
		t += e["comp"]
	return t
