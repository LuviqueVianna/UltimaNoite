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
var voltando := false               # computador já decidiu ir para a saída (não volta atrás)
var acelerado := false              # computador acelerado depois que o jogador chegou
var concluiu := -1.0                # instante em que registrou a chegada; -1 se ainda não
var fatos_noite := {}               # premissas e fatos dos animais (ex.: "lobo_avancou", "lobo_reacao")
var lento_s := 0.0                  # anda pela metade da velocidade (lobo, armadilha)
var doses_veneno := 0               # doses que o corpo não aguentou (a 3ª desmaia)
var turvo_s := 0.0                  # visão turva pelo veneno (INF = até o amanhecer)
var desmaiado := false              # caiu de veneno: não anda nem registra a chegada
var ferido_s := 0.0                 # derrubado pelo lobo há pouco (os guardiões percebem)
var oculto_s := 0.0                 # o que resta do "sumir na mata" em uso
var sumir_usados := 0
var escondido := ""                 # base em cuja moita está escondido
var tentou_fundos := false          # computador: já tentou sair pelos fundos com o lobo à porta
var _andando_s := 0.0               # segundos seguidos andando (gasto crescente do "sumir")
var _parado_s := 0.0
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
	var r: float = Regras.nivel(Regras.ALCANCE_VISTA, nivel("inteligencia"))
	return r * Regras.VENENO_VISAO if turvo_s > 0.0 else r


## Oculto: usando o "sumir na mata" ou escondido numa moita. Ninguém o vê.
func oculto() -> bool:
	return oculto_s > 0.0 or escondido != ""


func usos_sumir() -> int:
	return maxi(0, Regras.nivel(Regras.USOS_SUMIR, nivel("furtividade")) - sumir_usados)


## Usa o "sumir na mata". Devolve false se já não tem usos, se já está oculto ou se não pode.
func sumir() -> bool:
	if usos_sumir() <= 0 or oculto() or desmaiado or registrou():
		return false
	sumir_usados += 1
	oculto_s = Regras.SUMIR_S
	_andando_s = 0.0
	_parado_s = 0.0
	return true


func envenenado() -> bool:
	return turvo_s > 0.0


func ferido() -> bool:
	return ferido_s > 0.0


## Velocidade sem a lentidão (o lobo segue o faro numa fração dela).
func velocidade_normal() -> float:
	return Regras.VEL_TRILHA if eh_jogador else Regras.VEL_COMPUTADOR * (Regras.ACELERA_COMPUTADOR if acelerado else 1.0)


func lembranca() -> float:
	return Regras.nivel(Regras.LEMBRANCA_S, nivel("inteligencia"))


func vida_pegada() -> float:
	return Regras.nivel(Regras.VIDA_PEGADA_S, nivel("furtividade"))


func leitura_pegadas() -> int:
	return nivel("furtividade")


func velocidade() -> float:
	return velocidade_normal() * (0.5 if lento_s > 0.0 else 1.0)


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


## Veneno (panela ruim ou cobra): tira 1 ponto da maior habilidade (empate: sorteio; mínimo 1)
## e acumula: 1ª dose turva a visão por um tempo, 2ª até o amanhecer, 3ª desmaia.
## Devolve o atributo perdido, "resistiu" ou "" se não havia habilidade a tirar.
func envenenar(rng: RandomNumberGenerator) -> String:
	if rng.randf() < Regras.nivel(Regras.RESISTIR_VENENO, nivel("resistencia")):
		return "resistiu"
	doses_veneno += 1
	turvo_s = Regras.VENENO_TURVO_S if doses_veneno == 1 else INF
	if doses_veneno >= Regras.VENENO_DESMAIO:
		desmaiado = true
		rota = []
		oculto_s = 0.0
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


## Gasto do "sumir na mata" (MVP, seção 8): parado, 1 s por segundo; andando, o gasto começa em 1
## e cresce 1,1x a cada segundo seguido de movimento. Volta a 1 só depois de 1 s parado.
func _gastar_oculto(dt: float, andando: bool) -> void:
	if oculto_s <= 0.0:
		return
	if andando:
		_andando_s += dt
		_parado_s = 0.0
	else:
		_parado_s += dt
		if _parado_s >= 1.0:
			_andando_s = 0.0
	var taxa := pow(Regras.SUMIR_FATOR, _andando_s) if andando else 1.0
	oculto_s = maxf(0.0, oculto_s - dt * taxa)


## Avança no tempo. Devolve eventos: {"tipo": "pegada"|"chegou", ...}
func passo(dt: float, mapa: Mapa) -> Array:
	var eventos := []
	if turvo_s > 0.0 and turvo_s != INF:
		turvo_s = maxf(0.0, turvo_s - dt)
	if ferido_s > 0.0:
		ferido_s = maxf(0.0, ferido_s - dt)
	if desmaiado:
		return eventos
	var antes := pos
	if espera > 0.0:
		espera -= dt
		_gastar_oculto(dt, false)
		return eventos
	if lento_s > 0.0:
		lento_s -= dt
	if pausado and no_atual < 0:
		_gastar_oculto(dt, false)
		return eventos
	if no_atual >= 0:
		if rota.is_empty():
			_gastar_oculto(dt, false)
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
		eventos.append({"tipo": "pegada", "pos": pos + dir.orthogonal() * 0.7 * lado, "dir": dir, "fraca": oculto_s > 0.0})
	_gastar_oculto(dt, pos.distance_to(antes) > 0.001)
	if chegou:
		no_atual = para
		de = -1
		para = -1
		progresso = 0.0
		eventos.append({"tipo": "chegou", "no": no_atual})
	return eventos
