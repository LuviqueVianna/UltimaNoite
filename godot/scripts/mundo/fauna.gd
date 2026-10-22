class_name Fauna
extends RefCounted
## Lobo, coruja, cão sem dono e cobra (docs/sistemas/animais_v1.md).
## Os animais valem igual para o jogador e para os personagens do computador.
## Regra comum: quem fica parado diante do perigo se sai melhor que quem corre.


class Animal extends RefCounted:
	var id := 0
	var tipo := ""              # lobo | coruja | cao | cobra
	var pos := Vector2.ZERO
	var estado := ""
	var caminho: Array = []     # pontos (m) a percorrer, em linha reta de um a outro
	var relogio := 0.0          # tempo restante do estado atual
	var alvo := -1              # id do personagem com quem está lidando
	var ref := Vector2.ZERO     # onde o alvo estava quando o encontro começou
	var mexeu := 0.0            # quanto o alvo andou desde o começo do encontro
	var parado_s := 0.0         # há quanto tempo o alvo está parado (cobra)
	var ferido := false
	var casa := -1              # nó da base que o lobo ronda; pouso da coruja
	var proximo_evento := 0.0   # uivo do lobo, troca de pouso da coruja
	var troca_casa := 0.0
	var base_guia := ""         # cão: base para onde está levando o alvo
	var ignora := {}            # id do personagem -> até quando o animal o ignora
	var ouviu := {}             # cobra: quem já ouviu o chacoalhar nesta passagem
	var sinal := ""             # o que o animal está fazendo agora, para o desenho ("piou", "latiu"...)
	var sinal_ate := 0.0


var mundo: Mundo
var animais: Array = []
var _pos_antes := {}            # id do personagem -> posição no tick anterior


func _init(m: Mundo) -> void:
	mundo = m


func preparar() -> void:
	var rng := mundo.rng
	var mapa := mundo.mapa
	var bases: Dictionary = mapa.bases()
	var ids_bases := bases.keys().filter(func(b): return b != "vazia")
	var n := 0
	for tipo in Regras.ANIMAIS_QTD:
		for i in Regras.ANIMAIS_QTD[tipo]:
			var a := Animal.new()
			a.id = n
			a.tipo = tipo
			n += 1
			match tipo:
				"lobo":
					a.casa = bases[ids_bases[rng.randi() % ids_bases.size()]]
					a.pos = mapa.pos(a.casa) + Vector2.from_angle(rng.randf() * TAU) * 20.0
					a.ferido = rng.randf() < Regras.LOBO_CHANCE_FERIDO
					a.estado = "ronda"
					a.proximo_evento = rng.randf_range(Regras.LOBO_UIVO_S.x, Regras.LOBO_UIVO_S.y)
					a.troca_casa = rng.randf_range(Regras.LOBO_TROCA_BASE_S.x, Regras.LOBO_TROCA_BASE_S.y)
				"coruja":
					a.casa = _pouso_livre()
					a.pos = _ponto_do_pouso(a.casa)
					a.estado = "pousada"
					a.proximo_evento = rng.randf_range(Regras.CORUJA_POUSO_S.x, Regras.CORUJA_POUSO_S.y)
				"cao":
					a.pos = mapa.pos(_no_ao_acaso())
					a.estado = "ronda"
				"cobra":
					a.pos = _lugar_da_cobra()
					a.estado = "escondida"
			animais.append(a)
	for p in mundo.personagens:
		_pos_antes[p.id] = p.pos


func tick(dt: float) -> void:
	var andou := {}
	for p in mundo.personagens:
		andou[p.id] = p.pos.distance_to(_pos_antes.get(p.id, p.pos))
		_pos_antes[p.id] = p.pos
	for a in animais:
		match a.tipo:
			"lobo":
				_lobo(a, dt, andou)
			"coruja":
				_coruja(a, dt)
			"cao":
				_cao(a, dt)
			"cobra":
				_cobra(a, dt, andou)


## O jogador enxerga este animal agora?
func visivel_para_jogador(a: Animal) -> bool:
	if Regras.MAPA_ABERTO:
		return true
	var j := mundo.jogador()
	var d := j.pos.distance_to(a.pos)
	if a.tipo == "cobra":
		return d <= Regras.nivel(Regras.NOTAR_ARMADILHA, j.nivel("inteligencia"))
	return d <= j.alcance()


# ---------------- Lobo ----------------

func _lobo(a: Animal, dt: float, andou: Dictionary) -> void:
	var vel := Regras.LOBO_VEL_FERIDO if a.ferido else Regras.LOBO_VEL
	a.proximo_evento -= dt
	if a.proximo_evento <= 0.0:
		a.proximo_evento = mundo.rng.randf_range(Regras.LOBO_UIVO_S.x, Regras.LOBO_UIVO_S.y)
		_ouvir("lobo_uivou", a.pos, -1, INF)
		_sinal(a, "uivou", 4.0)
	match a.estado:
		"ronda":
			a.troca_casa -= dt
			if a.troca_casa <= 0.0 and not a.ferido:
				var bases: Dictionary = mundo.mapa.bases()
				var outras := bases.keys().filter(func(b): return b != "vazia" and bases[b] != a.casa)
				a.casa = bases[outras[mundo.rng.randi() % outras.size()]]
				a.troca_casa = mundo.rng.randf_range(Regras.LOBO_TROCA_BASE_S.x, Regras.LOBO_TROCA_BASE_S.y)
				a.caminho = _caminho_ate(a.pos, a.casa)
			if a.caminho.is_empty():
				a.caminho = _caminho_ate(a.pos, _no_perto_de(a.casa, Regras.LOBO_RONDA_M))
			_andar(a, dt, vel)
			var p := _quem_esta_perto(a, Regras.LOBO_VE_M)
			if p == null:
				return
			if _protegido(p):
				a.ignora[p.id] = mundo.tempo + 5.0
				return
			p.fatos_noite["encontrou_lobo"] = true
			if a.ferido:
				if not p.fatos_noite.has("encontrou_lobo_ferido"):
					p.fatos_noite["encontrou_lobo_ferido"] = true
					_falar(p, "lobo_ferido")
				a.ignora[p.id] = mundo.tempo + 60.0
				return
			a.estado = "rosnando"
			a.alvo = p.id
			a.ref = p.pos
			a.mexeu = 0.0
			a.relogio = Regras.LOBO_ROSNA_S
			p.fatos_noite["lobo_avancou"] = true
			_falar(p, "lobo_rosna")
			mundo.som.emit("lobo_rosna", a.pos)
			if not p.eh_jogador and _computador_para(p, p.perfil == "cauteloso"):
				p.espera = maxf(p.espera, Regras.LOBO_ROSNA_S + 0.4)
		"rosnando":
			var p: Personagem = mundo.personagens[a.alvo]
			a.mexeu += andou.get(p.id, 0.0)
			# Avança devagar até uns 5 m enquanto rosna
			if a.pos.distance_to(p.pos) > 5.0:
				a.pos = a.pos.move_toward(p.pos, Regras.LOBO_VEL * dt)
			a.relogio -= dt
			if a.mexeu > 1.0 and not _protegido(p):
				p.fatos_noite["lobo_reacao"] = "correu"
				a.estado = "perseguindo"
				a.relogio = Regras.LOBO_PERSEGUE_S
				a.caminho = []
				_ouvir("lobo_atacou", a.pos, p.id, Regras.OUVE_M)
			elif a.relogio <= 0.0 or _protegido(p):
				if not p.fatos_noite.has("lobo_reacao"):
					p.fatos_noite["lobo_reacao"] = "ficou"
				_falar(p, "lobo_desiste")
				_voltar_a_rondar(a, 45.0)
		"perseguindo":
			var p: Personagem = mundo.personagens[a.alvo]
			a.relogio -= dt
			if _protegido(p) or a.relogio <= 0.0:
				if _protegido(p) and not p.registrou():
					_falar(p, "lobo_escapou")
				_voltar_a_rondar(a, 45.0)
				return
			a.pos = a.pos.move_toward(p.pos, Regras.LOBO_VEL_ATAQUE * dt)
			if a.pos.distance_to(p.pos) <= 1.5:
				p.espera = maxf(p.espera, Regras.nivel(Regras.PRESO_S, p.nivel("forca")))
				p.lento_s = Regras.LENTO_S * (1.0 - Regras.nivel(Regras.REDUZ_LENTIDAO, p.nivel("resistencia")))
				p.fatos_noite["lobo_derrubou"] = true
				_falar(p, "lobo_derruba")
				_voltar_a_rondar(a, 60.0)


func _voltar_a_rondar(a: Animal, ignora_s: float) -> void:
	if a.alvo >= 0:
		a.ignora[a.alvo] = mundo.tempo + ignora_s
	a.alvo = -1
	a.estado = "ronda"
	a.caminho = []


## Dentro de uma base (ou já fora da noite) ninguém é atacado.
func _protegido(p: Personagem) -> bool:
	if p.registrou():
		return true
	var no := mundo.mapa.no_mais_proximo(p.pos, 6.0, func(n): return mundo.mapa.nos[n]["base"] != "")
	return no >= 0


# ---------------- Coruja ----------------

func _coruja(a: Animal, dt: float) -> void:
	if a.estado == "voando":
		if _andar(a, dt, Regras.CORUJA_VOO):
			a.estado = "pousada"
		return
	a.proximo_evento -= dt
	if a.proximo_evento <= 0.0:
		a.proximo_evento = mundo.rng.randf_range(Regras.CORUJA_POUSO_S.x, Regras.CORUJA_POUSO_S.y)
		a.casa = _pouso_livre()
		a.caminho = [_ponto_do_pouso(a.casa)]
		a.estado = "voando"
		return
	var p := _quem_esta_perto(a, Regras.CORUJA_VE_M)
	if p == null:
		return
	a.ignora[p.id] = mundo.tempo + 40.0
	p.fatos_noite["coruja_notou"] = true
	# Outro personagem perto dela: avisa quem ela notou, virando a cabeça na direção dele.
	var outro: Personagem = null
	var melhor := Regras.CORUJA_AVISA_M
	for o in mundo.personagens:
		if o.id != p.id and not o.registrou() and o.pos.distance_to(a.pos) <= melhor:
			melhor = o.pos.distance_to(a.pos)
			outro = o
	if outro != null:
		p.fatos_noite["coruja_avisou"] = true
		_falar(p, "coruja_avisa", {"direcao": Textos.direcao(p.pos, outro.pos)})
		_sinal(a, "olhou para " + ("você" if p.eh_jogador else "alguém"), 3.0)
		return
	_falar(p, "coruja_olha")
	_ouvir("coruja_piou", a.pos, p.id, Regras.OUVE_M)
	_sinal(a, "piou", 3.0)


# ---------------- Cão sem dono ----------------

func _cao(a: Animal, dt: float) -> void:
	match a.estado:
		"ronda":
			if a.caminho.is_empty():
				a.caminho = _caminho_ate(a.pos, _no_perto_de(_no_mais_perto(a.pos), 60.0))
			_andar(a, dt, Regras.CAO_VEL)
			var p := _quem_esta_perto(a, Regras.CAO_VE_M)
			if p == null:
				return
			a.alvo = p.id
			if mundo.rng.randf() < Regras.CAO_CHANCE_GUIA:
				p.fatos_noite["cao_ofereceu_guia"] = true
				a.estado = "esperando"
				a.relogio = Regras.CAO_ESPERA_S
				a.caminho = []
				_falar(p, "cao_guia")
				if not p.eh_jogador:
					if p.perfil != "cauteloso":
						_guiar(a, p)
						var base := a.base_guia
						if base != "":
							p.luzes[base] = mundo.mapa.pos(mundo.mapa.bases()[base])   # aprendeu onde fica
						p.fatos_noite["seguiu_cao"] = true
					else:
						p.fatos_noite["seguiu_cao"] = false
					_soltar_cao(a, 90.0)
			else:
				_falar(p, "cao_late")
				_ouvir("cao_latiu", a.pos, p.id, Regras.OUVE_M)
				_sinal(a, "latiu", 3.0)
				_soltar_cao(a, 60.0)
		"esperando":
			var p: Personagem = mundo.personagens[a.alvo]
			a.relogio -= dt
			if p.pos.distance_to(a.pos) <= 5.0:
				p.fatos_noite["seguiu_cao"] = true
				_guiar(a, p)
				if a.base_guia == "":
					_soltar_cao(a, 90.0)
				else:
					a.estado = "guiando"
					_falar(p, "cao_seguindo")
			elif a.relogio <= 0.0:
				p.fatos_noite["seguiu_cao"] = false
				_soltar_cao(a, 60.0)
		"guiando":
			var p: Personagem = mundo.personagens[a.alvo]
			if p.registrou():
				_soltar_cao(a, 90.0)
				return
			if p.pos.distance_to(a.pos) > Regras.CAO_LONGE_M:
				return   # espera a pessoa alcançar
			if _andar(a, dt, Regras.CAO_VEL_GUIA):
				_falar(p, "cao_chegou")
				_soltar_cao(a, 90.0)


## Base mais próxima que a pessoa ainda não visitou (pelas trilhas, a partir do cão).
func _guiar(a: Animal, p: Personagem) -> void:
	var mapa := mundo.mapa
	var de := _no_mais_perto(a.pos)
	var melhor := ""
	var melhor_d := INF
	var bases: Dictionary = mapa.bases()
	for b in bases:
		if b == "vazia" or p.bases_visitadas.has(b):
			continue
		var d := mapa.distancia_grafo(de, bases[b])
		if d < melhor_d:
			melhor_d = d
			melhor = b
	a.base_guia = melhor
	a.caminho = [] if melhor == "" else _caminho_ate(a.pos, bases[melhor])


func _soltar_cao(a: Animal, ignora_s: float) -> void:
	if a.alvo >= 0:
		a.ignora[a.alvo] = mundo.tempo + ignora_s
	a.alvo = -1
	a.base_guia = ""
	a.estado = "ronda"
	a.caminho = []


# ---------------- Cobra ----------------

func _cobra(a: Animal, dt: float, andou: Dictionary) -> void:
	for p in mundo.personagens:
		if p.registrou():
			continue
		var d: float = p.pos.distance_to(a.pos)
		if d > Regras.COBRA_AVISO_M:
			a.ouviu.erase(p.id)
			continue
		if not a.ouviu.has(p.id):
			a.ouviu[p.id] = 0.0
			p.fatos_noite["cobra_avisou"] = true
			var ve: bool = d <= Regras.nivel(Regras.NOTAR_ARMADILHA, p.nivel("inteligencia"))
			_falar(p, "cobra_ve" if ve else "cobra_som")
			if p.eh_jogador:
				mundo.som.emit("cobra_folhas", a.pos)
			if not p.eh_jogador and _computador_para(p, false):
				p.espera = maxf(p.espera, Regras.COBRA_DESISTE_S + 0.3)
		var mexeu: bool = andou.get(p.id, 0.0) > 0.01
		if mexeu:
			a.ouviu[p.id] = 0.0
			if d <= Regras.COBRA_PICA_M:
				var r: String = p.envenenar(mundo.rng)
				p.fatos_noite["cobra_picou"] = true
				_falar(p, "cobra_resistiu" if r == "resistiu" else "cobra_pica")
				if p.eh_jogador and r != "" and r != "resistiu":
					mundo.aviso.emit("Você perdeu 1 ponto de %s." % Dialogo.NOMES_ATRIBUTO.get(r, r))
				_mudar_cobra(a)
				return
		else:
			a.ouviu[p.id] += dt
			if a.ouviu[p.id] >= Regras.COBRA_DESISTE_S:
				_falar(p, "cobra_some")
				_mudar_cobra(a)
				return


func _mudar_cobra(a: Animal) -> void:
	a.pos = _lugar_da_cobra()
	a.ouviu = {}


func _lugar_da_cobra() -> Vector2:
	var mapa := mundo.mapa
	var proibidos := []
	for n in mapa.nos:
		if n["base"] != "" or n["partida"]:
			proibidos.append(n["pos"])
	for tentativa in 200:
		var p: Vector2 = mapa.amostras[mundo.rng.randi() % mapa.amostras.size()]
		var ok := true
		for q in proibidos:
			if p.distance_to(q) < Regras.COBRA_LONGE_M:
				ok = false
				break
		for o in mundo.personagens:
			if p.distance_to(o.pos) < 30.0:
				ok = false
				break
		for b in animais:
			if b.tipo == "cobra" and p.distance_to(b.pos) < 30.0:
				ok = false
				break
		if ok:
			return p
	return mapa.amostras[mundo.rng.randi() % mapa.amostras.size()]


# ---------------- Comum ----------------

## Personagem mais próximo dentro do alcance que o animal ainda não está ignorando.
func _quem_esta_perto(a: Animal, alcance: float) -> Personagem:
	var melhor: Personagem = null
	var melhor_d := alcance
	for p in mundo.personagens:
		if p.registrou() or mundo.tempo < a.ignora.get(p.id, -1.0):
			continue
		var d: float = p.pos.distance_to(a.pos)
		if d <= melhor_d:
			melhor_d = d
			melhor = p
	return melhor


func _computador_para(p: Personagem, sempre: bool) -> bool:
	return sempre or mundo.rng.randf() < Regras.ANIMAL_PARA.x + Regras.ANIMAL_PARA.y * p.nivel("inteligencia")


## Anda pelo caminho; devolve true quando chegou ao fim.
func _andar(a: Animal, dt: float, vel: float) -> bool:
	var resta := vel * dt
	while resta > 0.0 and not a.caminho.is_empty():
		var alvo: Vector2 = a.caminho[0]
		var d := a.pos.distance_to(alvo)
		if d <= resta:
			a.pos = alvo
			resta -= d
			a.caminho.pop_front()
		else:
			a.pos = a.pos.move_toward(alvo, resta)
			resta = 0.0
	return a.caminho.is_empty()


func _no_mais_perto(p: Vector2) -> int:
	return mundo.mapa.no_mais_proximo(p, INF)


func _caminho_ate(de: Vector2, no_destino: int) -> Array:
	var mapa := mundo.mapa
	var origem := _no_mais_perto(de)
	var pts: Array = [mapa.pos(origem)]
	if origem != no_destino:
		for n in mapa.caminho(origem, no_destino):
			pts.append(mapa.pos(n))
	return pts


## Um nó ao acaso a até `raio` metros do nó dado (sem ser base).
func _no_perto_de(no: int, raio: float) -> int:
	var mapa := mundo.mapa
	var centro := mapa.pos(no)
	var opcoes := mapa.nos.filter(func(n): return n["base"] == "" and n["pos"].distance_to(centro) <= raio)
	if opcoes.is_empty():
		return no
	return opcoes[mundo.rng.randi() % opcoes.size()]["id"]


func _no_ao_acaso() -> int:
	var opcoes := mundo.mapa.nos.filter(func(n): return n["base"] == "" and not n["partida"])
	return opcoes[mundo.rng.randi() % opcoes.size()]["id"]


func _pouso_livre() -> int:
	var opcoes := mundo.mapa.nos.filter(func(n): return n["tipo"] == "clareira" and n["base"] == "")
	if opcoes.is_empty():
		return _no_ao_acaso()
	return opcoes[mundo.rng.randi() % opcoes.size()]["id"]


## A coruja pousa numa árvore na beira da clareira, não no meio dela.
func _ponto_do_pouso(no: int) -> Vector2:
	return mundo.mapa.pos(no) + Vector2.from_angle(mundo.rng.randf() * TAU) * mundo.rng.randf_range(5.0, 8.0)


## Mensagem do animal para quem passou por ele (só o jogador lê).
func _falar(p: Personagem, chave: String, valores := {}) -> void:
	if p.eh_jogador:
		mundo.aviso.emit(Textos.preencher(Regras.FALAS_ANIMAIS[chave], valores))


func _sinal(a: Animal, texto: String, duracao: float) -> void:
	a.sinal = texto
	a.sinal_ate = mundo.tempo + duracao


## Evento à distância: toca o som e, se o jogador estiver perto o bastante (e não for quem causou), avisa por texto.
func _ouvir(gatilho: String, origem: Vector2, causador: int, alcance: float) -> void:
	mundo.som.emit(gatilho, origem)
	var j := mundo.jogador()
	if j.id == causador or j.registrou() or j.pos.distance_to(origem) > alcance:
		return
	var lista: Array = Dados.ler_json("textos/eventos_distancia.json").get("eventos", [])
	var texto := Textos.sortear(lista, {"gatilho": gatilho}, mundo.rng)
	if texto != "":
		mundo.aviso.emit(Textos.preencher(texto, {"direcao": Textos.direcao(j.pos, origem)}))
