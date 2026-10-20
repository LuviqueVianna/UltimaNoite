class_name Personagem
extends RefCounted
## Um dos 4 personagens da noite (o jogador ou um do computador).
## Guarda posição, rota pelo grafo e a memória do que ele viu.

var id := 0
var nome := ""
var eh_jogador := false
var perfil := ""              # só para os do computador
var calcado := ""
var atributos := {}

# Posição no grafo: parado num nó (no_atual >= 0) ou andando numa aresta (de -> para).
var pos := Vector2.ZERO
var no_atual := -1
var de := -1
var para := -1
var progresso := 0.0
var rota: Array = []
var pausado := false          # parado no meio de uma trilha (jogador soltou a tecla)
var espera := 0.0
var desde_pegada := 0.0
var passo_esquerdo := false

# Estado de jogo
var bases_visitadas := {}
var inventario: Array = []          # ids de itens
var marcas: Array = []              # {"marca": String, "base": String}
var mentiras := 0                   # respostas que falharam na verificação
var mentiu_inventario := false
var silencios := 0
var aproximacao := {}               # base -> "rondou" | "frente" | "fundos"
var esconderijos := 0
var armadilhas_acionadas := 0
var avisou_armadilha := false
var escondeu_rastro := false
var refeicoes := {}                 # base -> "boa" | "ruim"
var ultima_pegada_vista := -1       # id de personagem dono das últimas pegadas alheias vistas
var saida := -1                     # nó de chegada (ponto oposto à partida)
var acelerado := false              # computador acelerado depois que o jogador chegou
var concluiu := -1.0                # instante em que registrou a chegada; -1 se ainda não
var fatos_noite := {}               # premissas que aconteceram (ex.: "lobo_avancou"), preenchidas na etapa 3
var na_base := ""
var no_anterior := -1
var hesitou_no := -1
var vezes_aresta := {}

# Memória (o que este personagem viu)
var amostra_vista := PackedFloat32Array()
var amostra_percorrida := PackedByteArray()
var no_visto := PackedByteArray()
var aresta_conhecida := PackedByteArray()
var luzes := {}               # base_id -> posição da luz vista de longe
var vistos := {}              # id de personagem -> último instante em que foi visto
var dono_do_calcado := {}     # calcado -> id de personagem (ligação aprendida por visão)
var pegadas_vistas := {}      # id da pegada -> último instante em que foi vista


func nivel(atributo: String) -> int:
	return clampi(atributos.get(atributo, 1), 1, 5)


func alcance() -> float:
	return Regras.nivel(Regras.ALCANCE_VISTA, nivel("inteligencia"))


func lembranca() -> float:
	return Regras.nivel(Regras.LEMBRANCA_S, nivel("inteligencia"))


func vida_pegada() -> float:
	return Regras.nivel(Regras.VIDA_PEGADA_S, nivel("furtividade"))


func leitura_pegadas() -> int:
	return nivel("furtividade")


func velocidade() -> float:
	if eh_jogador:
		return Regras.VEL_TRILHA
	return Regras.VEL_COMPUTADOR * (Regras.ACELERA_COMPUTADOR if acelerado else 1.0)


func tem_marca(marca: String) -> bool:
	for m in marcas:
		if m["marca"] == marca:
			return true
	return false


func panelas_boas() -> int:
	return refeicoes.values().count("boa")


func pontos() -> int:
	var ruins := refeicoes.size() - panelas_boas()
	return panelas_boas() * Regras.PONTOS["panela_boa"] + ruins * Regras.PONTOS["panela_ruim"]


func registrou() -> bool:
	return concluiu >= 0.0


## Veneno da panela ruim: tira 1 ponto da maior habilidade (empate: sorteio; mínimo 1).
## Devolve o atributo perdido, "resistiu" ou "" se não havia o que tirar.
func envenenar(rng: RandomNumberGenerator) -> String:
	if rng.randf() < Regras.nivel(Regras.RESISTIR_VENENO, nivel("resistencia")):
		return "resistiu"
	var maior := 0
	for k in Regras.ATRIBUTOS:
		maior = maxi(maior, atributos[k])
	if maior <= 1:
		return ""
	var candidatos := Regras.ATRIBUTOS.filter(func(k): return atributos[k] == maior)
	var perdido: String = candidatos[rng.randi() % candidatos.size()]
	atributos[perdido] -= 1
	return perdido


func preparar(mapa: Mapa, no_inicial: int) -> void:
	amostra_vista.resize(mapa.amostras.size())
	amostra_vista.fill(-1.0e9)
	amostra_percorrida.resize(mapa.amostras.size())
	amostra_percorrida.fill(0)
	no_visto.resize(mapa.nos.size())
	no_visto.fill(0)
	aresta_conhecida.resize(mapa.arestas.size())
	aresta_conhecida.fill(0)
	no_atual = no_inicial
	pos = mapa.pos(no_inicial)
	no_visto[no_inicial] = 1


func parado() -> bool:
	return no_atual >= 0 and rota.is_empty()


func conhece_aresta(a: int) -> bool:
	return aresta_conhecida[a] == 1


func aresta_percorrida(mapa: Mapa, a: int) -> bool:
	var e: Dictionary = mapa.arestas[a]
	for i in range(e["amostra_ini"], e["amostra_fim"]):
		if amostra_percorrida[i] == 1:
			return true
	return false


## Define o destino. Se estiver no meio de uma trilha, decide se continua ou dá meia-volta.
## `so_conhecidas`: usa só trilhas que este personagem já viu.
func ir_para(mapa: Mapa, alvo: int, so_conhecidas := true) -> bool:
	pausado = false
	var filtro := Callable(self, "conhece_aresta") if so_conhecidas else Callable()
	if no_atual >= 0:
		if alvo == no_atual:
			rota = []
			return true
		var r := mapa.caminho(no_atual, alvo, filtro)
		if r.is_empty():
			return false
		rota = r
		return true
	var comp: float = mapa.arestas[mapa.aresta_entre(de, para)]["comp"]
	var r_frente: Array = [] if alvo == para else mapa.caminho(para, alvo, filtro)
	var r_volta: Array = [] if alvo == de else mapa.caminho(de, alvo, filtro)
	var custo_frente := INF if (r_frente.is_empty() and alvo != para) else (comp - progresso) + _comprimento(mapa, para, r_frente)
	var custo_volta := INF if (r_volta.is_empty() and alvo != de) else progresso + _comprimento(mapa, de, r_volta)
	if custo_frente == INF and custo_volta == INF:
		return false
	if custo_volta < custo_frente:
		var t := de
		de = para
		para = t
		progresso = comp - progresso
		rota = r_volta
	else:
		rota = r_frente
	return true


func _comprimento(mapa: Mapa, origem: int, r: Array) -> float:
	var total := 0.0
	var anterior := origem
	for n in r:
		total += mapa.arestas[mapa.aresta_entre(anterior, n)]["comp"]
		anterior = n
	return total


## Avança no tempo. Devolve eventos: {"tipo": "pegada"|"chegou", ...}
func passo(dt: float, mapa: Mapa) -> Array:
	var eventos := []
	if espera > 0.0:
		espera -= dt
		return eventos
	if pausado and no_atual < 0:
		return eventos
	if no_atual >= 0:
		if rota.is_empty():
			return eventos
		de = no_atual
		para = rota.pop_front()
		progresso = 0.0
		no_anterior = no_atual
		no_atual = -1
		var a := mapa.aresta_entre(de, para)
		vezes_aresta[a] = vezes_aresta.get(a, 0) + 1
	var aresta := mapa.aresta_entre(de, para)
	var comp: float = mapa.arestas[aresta]["comp"]
	var andar := velocidade() * dt
	var anterior := pos
	progresso += andar
	var chegou := progresso >= comp
	if chegou:
		progresso = comp
	pos = mapa.pos(de).lerp(mapa.pos(para), progresso / comp)
	desde_pegada += anterior.distance_to(pos)
	if desde_pegada >= Regras.ESPACO_PEGADA:
		desde_pegada = 0.0
		passo_esquerdo = not passo_esquerdo
		var dir := (mapa.pos(para) - mapa.pos(de)).normalized()
		var lado := -1.0 if passo_esquerdo else 1.0
		eventos.append({"tipo": "pegada", "pos": pos + dir.orthogonal() * 0.7 * lado, "dir": dir})
	if chegou:
		no_atual = para
		de = -1
		para = -1
		progresso = 0.0
		eventos.append({"tipo": "chegou", "no": no_atual})
	return eventos
