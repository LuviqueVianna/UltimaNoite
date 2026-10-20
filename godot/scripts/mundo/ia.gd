class_name IA
extends RefCounted
## Decisões dos personagens do computador (docs/MVP_v0.4.md, seção 9).
## Eles só usam o que a própria memória sabe: luzes vistas, trilhas vistas, pegadas vistas.


static func decidir(p: Personagem, mundo: Mundo) -> void:
	var mapa := mundo.mapa
	var no := p.no_atual
	if no < 0 or not p.rota.is_empty() or p.espera > 0.0:
		return

	# Hesita em bifurcações e clareiras com várias saídas.
	if mapa.grau(no) >= 3 and p.hesitou_no != no:
		p.hesitou_no = no
		p.espera = mundo.rng.randf_range(Regras.HESITACAO.x, Regras.HESITACAO.y)
		return

	var alvo := _base_alvo(p, mapa)
	if alvo != "":
		var no_base: int = mapa.bases()[alvo]
		if p.no_visto[no_base] == 1 and p.ir_para(mapa, no_base):
			return
		_um_passo(p, mundo, p.luzes[alvo])
		return
	_um_passo(p, mundo, Vector2.INF)


## Base mais próxima, ainda não visitada, cuja luz já foi vista.
static func _base_alvo(p: Personagem, mapa: Mapa) -> String:
	var melhor := ""
	var melhor_d := INF
	for b in p.luzes:
		if p.bases_visitadas.has(b):
			continue
		var d: float = p.pos.distance_to(p.luzes[b])
		if d < melhor_d:
			melhor_d = d
			melhor = b
	return melhor


## Escolhe a próxima trilha a partir do nó atual, conforme o perfil.
static func _um_passo(p: Personagem, mundo: Mundo, destino: Vector2) -> void:
	var mapa := mundo.mapa
	var no := p.no_atual
	var melhor := -1
	var melhor_nota := -INF
	for v in mapa.adj[no]:
		var viz: int = v.x
		var aresta: int = v.y
		var nota := mundo.rng.randf_range(0.0, 0.6)
		var dir := (mapa.pos(viz) - mapa.pos(no)).normalized()
		if destino != Vector2.INF:
			nota += 2.0 * dir.dot((destino - mapa.pos(no)).normalized())
		var nova := not p.aresta_percorrida(mapa, aresta)
		match p.perfil:
			"ousado":
				nota += 1.5 if nova else 0.0
			"cauteloso":
				nota += 0.5 if nova else 0.4
			_:
				nota += 1.0 if nova else 0.0
		nota -= 0.8 * p.vezes_aresta.get(aresta, 0)
		if viz == p.no_anterior and mapa.grau(no) > 1:
			nota -= 1.2
		if p.no_visto[viz] == 1 and mapa.nos[viz]["tipo"] == "beco":
			nota -= 3.0 if p.perfil == "cauteloso" else (0.0 if p.perfil == "ousado" and nova else 1.5)
		if nota > melhor_nota:
			melhor_nota = nota
			melhor = viz
	if melhor >= 0:
		p.rota = [melhor]
