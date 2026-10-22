class_name IA
extends RefCounted
## Decisões dos personagens do computador (docs/MVP_v0.4.md, seção 9).
## Eles só usam o que a própria memória sabe: luzes vistas, trilhas vistas, pegadas vistas.


static func decidir(p: Personagem, mundo: Mundo) -> void:
	var mapa := mundo.mapa
	var no := p.no_atual
	if p.registrou() or no < 0 or not p.rota.is_empty() or p.espera > 0.0:
		return

	if hora_de_ir(p, mundo):
		_rumo(p, mundo, mapa.pos(p.saida), p.saida)
		return

	# Hesita em bifurcações e clareiras com várias saídas.
	if mapa.grau(no) >= 3 and p.hesitou_no != no:
		p.hesitou_no = no
		p.espera = mundo.rng.randf_range(Regras.HESITACAO.x, Regras.HESITACAO.y)
		return

	var alvo := _base_alvo(p, mundo)
	if alvo != "":
		_rumo(p, mundo, p.luzes[alvo], mapa.bases()[alvo])
		return
	_um_passo(p, mundo, Vector2.INF)


## Vai até um destino usando o que já conhece: caminho conhecido até ele, ou até o ponto
## conhecido mais próximo dele, e de lá explora na direção certa.
static func _rumo(p: Personagem, mundo: Mundo, destino: Vector2, no_destino: int) -> void:
	var mapa := mundo.mapa
	if p.no_visto[no_destino] == 1 and p.ir_para(mapa, no_destino) and not p.rota.is_empty():
		return
	var aqui := p.no_atual
	var melhor := aqui
	var melhor_d := mapa.pos(aqui).distance_to(destino)
	for n in mapa.nos:
		if p.no_visto[n["id"]] == 0:
			continue
		var d: float = n["pos"].distance_to(destino)
		if d < melhor_d - 5.0 and _tem_saida_nova(p, mapa, n["id"]):
			melhor_d = d
			melhor = n["id"]
	if melhor != aqui and p.ir_para(mapa, melhor) and not p.rota.is_empty():
		return
	_um_passo(p, mundo, destino, true)


static func _tem_saida_nova(p: Personagem, mapa: Mapa, no: int) -> bool:
	for v in mapa.adj[no]:
		if not p.aresta_percorrida(mapa, v.y):
			return true
	return false


## Vai para a saída quando já visitou todos os guardiões ou quando o tempo aperta.
static func hora_de_ir(p: Personagem, mundo: Mundo) -> bool:
	if p.acelerado or p.voltando:
		return true   # já decidiu ir (ou o jogador já chegou): não volta atrás para visitar outra base
	var guardioes := Regras.BASES.keys().filter(func(b): return b != "vazia")
	if guardioes.all(func(b): return p.bases_visitadas.has(b)):
		return true
	var distancia: float = p.pos.distance_to(mundo.mapa.pos(p.saida)) * Regras.FOLGA_VOLTA
	if p.no_visto[p.saida] == 1 and p.no_atual >= 0:
		var conhecido := mundo.mapa.caminho(p.no_atual, p.saida, Callable(p, "conhece_aresta"))
		if not conhecido.is_empty():
			distancia = p._comprimento(mundo.mapa, p.no_atual, conhecido)
	var estimativa: float = distancia / p.velocidade()
	if mundo.tempo_restante() < estimativa + Regras.MARGEM_VOLTA_S:
		p.voltando = true
	return p.voltando


## Base mais próxima, ainda não visitada, cuja luz já foi vista, e que dá tempo de visitar
## e ainda chegar à saída (ida, visita e dali até a saída, com folga).
static func _base_alvo(p: Personagem, mundo: Mundo) -> String:
	var melhor := ""
	var melhor_d := INF
	var saida: Vector2 = mundo.mapa.pos(p.saida)
	for b in p.luzes:
		if p.bases_visitadas.has(b):
			continue
		var d: float = p.pos.distance_to(p.luzes[b])
		var volta: float = (d + p.luzes[b].distance_to(saida)) * Regras.FOLGA_BASE / p.velocidade()
		if volta + Regras.VISITA_BASE_S + Regras.MARGEM_VOLTA_S > mundo.tempo_restante():
			continue
		if d < melhor_d:
			melhor_d = d
			melhor = b
	return melhor


## Escolhe a próxima trilha a partir do nó atual, conforme o perfil.
## so_novas: quando há trilhas ainda não percorridas aqui, escolhe só entre elas (evita ir e voltar).
static func _um_passo(p: Personagem, mundo: Mundo, destino: Vector2, so_novas := false) -> void:
	var mapa := mundo.mapa
	var no := p.no_atual
	var melhor := -1
	var melhor_nota := -INF
	var ha_novas := so_novas and _tem_saida_nova(p, mapa, no)
	for v in mapa.adj[no]:
		if ha_novas and p.aresta_percorrida(mapa, v.y):
			continue
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
		# Sem indicação: só o ousado arrisca no chute
		if p.perfil != "ousado":
			v.recusar()
			return {"mente": ind["mente"], "afinidade": v.afinidade}
		lado = "esquerda" if mundo.rng.randf() < 0.5 else "direita"
	else:
		var percebeu: bool = ind["mente"] and mundo.rng.randf() < 0.1 * p.nivel("inteligencia")
		var desconfia: bool = p.perfil == "trapaceiro" and v.afinidade < 0
		if percebeu or desconfia:
			lado = "direita" if lado == "esquerda" else "esquerda"
	v.comer(lado)
	return {"mente": ind["mente"], "afinidade": v.afinidade}
