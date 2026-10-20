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


## Visita completa de um personagem do computador: responde, recebe a indicação e come.
static func visitar(p: Personagem, mundo: Mundo, base: String) -> Dictionary:
	var v := Visita.new(mundo, p, base)
	var tom: String = {"ousado": "firme", "cauteloso": "gentil", "trapaceiro": "evasivo"}.get(p.perfil, "gentil")
	while not v.terminou_perguntas():
		var e := v.pergunta_atual()
		# Escolhe com hesitação: respostas que agradam são mais prováveis, mas não certas.
		var chaves := []
		var pesos := []
		for o in v.opcoes():
			var r: Dictionary = e["opcao_extra"] if o["chave"] == "extra" else e["respostas"][int(o["chave"])]
			var verdade: bool = not e.get("verificavel", false) or mundo.resposta_verdadeira(p, base, e["id"], o["chave"])
			if not verdade and p.perfil != "trapaceiro":
				continue
			chaves.append(o["chave"])
			pesos.append(exp(float(r["afinidade"]) / Regras.ESCOLHA_TEMPERATURA))
		var escolha := "silencio"
		if not chaves.is_empty():
			var total := 0.0
			for w in pesos:
				total += w
			var sorteio := mundo.rng.randf() * total
			for i in chaves.size():
				sorteio -= pesos[i]
				if sorteio <= 0.0:
					escolha = chaves[i]
					break
			if escolha == "silencio":
				escolha = chaves[-1]
		v.responder(escolha, tom)
	var ind := v.indicar()
	if ind["pede_item"]:
		var dar := ""
		if p.perfil != "trapaceiro" and not p.inventario.is_empty():
			dar = "fumo" if p.inventario.has("fumo") else p.inventario[0]
		ind = v.pagar(dar)
	var lado: String = ind["lado"]
	if lado == "":
		lado = "esquerda" if mundo.rng.randf() < 0.5 else "direita"
	else:
		var percebeu: bool = ind["mente"] and mundo.rng.randf() < 0.1 * p.nivel("inteligencia")
		var desconfia: bool = p.perfil == "trapaceiro" and v.afinidade < 0
		if percebeu or desconfia:
			lado = "direita" if lado == "esquerda" else "esquerda"
	v.comer(lado)
	return {"mente": ind["mente"], "afinidade": v.afinidade}
