class_name Dialogo
extends PanelContainer
## Tela da visita: aproximação, perguntas com tom e silêncio cronometrado, indicação e as duas panelas.
## A noite continua correndo enquanto o jogador conversa.

signal fechado
signal registrou

const COR_PAPEL := Color("#e8d9b5")
const COR_AMBAR := Color("#e89a3c")
const NOMES_TOM := {"firme": "Firme", "gentil": "Gentil", "evasivo": "Evasivo"}
const NOMES_GUARDIAO := {"bento": "Velho Bento", "iara": "Dona Iara", "anselmo": "Frei Anselmo", "marta": "Marta", "quincas": "Seu Quincas"}
const NOMES_ATRIBUTO := {"forca": "Força", "inteligencia": "Inteligência", "carisma": "Carisma", "furtividade": "Furtividade", "resistencia": "Resistência"}

var mundo: Mundo
var base := ""
var visita: Visita
var estado := ""
var tom := "gentil"
var relogio := 0.0

var titulo: Label
var texto: Label
var linha_tom: HBoxContainer
var botoes_tom := {}
var caixa_opcoes: VBoxContainer
var rodape: Label


func _ready() -> void:
	custom_minimum_size = Vector2(620, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#16212e")
	estilo.border_color = Color(COR_PAPEL, 0.5)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(20)
	add_theme_stylebox_override("panel", estilo)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 12)
	add_child(caixa)
	titulo = Label.new()
	titulo.add_theme_font_size_override("font_size", 22)
	titulo.add_theme_color_override("font_color", COR_AMBAR)
	caixa.add_child(titulo)
	texto = Label.new()
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD
	texto.custom_minimum_size = Vector2(580, 0)
	texto.add_theme_color_override("font_color", COR_PAPEL)
	caixa.add_child(texto)
	linha_tom = HBoxContainer.new()
	caixa.add_child(linha_tom)
	var rotulo_tom := Label.new()
	rotulo_tom.text = "Tom:"
	linha_tom.add_child(rotulo_tom)
	var grupo := ButtonGroup.new()
	for t in Regras.TONS:
		var b := Button.new()
		b.text = NOMES_TOM[t]
		b.toggle_mode = true
		b.button_group = grupo
		b.button_pressed = t == tom
		b.pressed.connect(func(): tom = t)
		linha_tom.add_child(b)
		botoes_tom[t] = b
	caixa_opcoes = VBoxContainer.new()
	caixa_opcoes.add_theme_constant_override("separation", 6)
	caixa.add_child(caixa_opcoes)
	rodape = Label.new()
	rodape.add_theme_color_override("font_color", Color(COR_PAPEL, 0.6))
	caixa.add_child(rodape)
	visible = false


func abrir(m: Mundo, id_base: String) -> void:
	mundo = m
	base = id_base
	visible = true
	_mostrar_aproximacao()


func _process(dt: float) -> void:
	if not visible or estado != "pergunta":
		return
	relogio -= dt
	rodape.text = "Silêncio em %d s" % ceili(maxf(relogio, 0.0))
	if relogio <= 0.0:
		_responder("silencio")


func _limpar() -> void:
	for c in caixa_opcoes.get_children():
		c.queue_free()
	rodape.text = ""


## Opção clicável que cresce com o texto (respostas longas quebram linha sem vazar).
## Todas com o mesmo visual; a opção extra de atributo só leva a etiqueta entre colchetes.
func _opcao(rotulo: String, acao: Callable) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#1e2a38")
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(8)
	normal.content_margin_left = 12
	var realce := normal.duplicate()
	realce.bg_color = Color("#2e3e52")
	realce.border_color = COR_PAPEL
	realce.set_border_width_all(1)

	var caixa := PanelContainer.new()
	caixa.add_theme_stylebox_override("panel", normal)
	caixa.mouse_filter = Control.MOUSE_FILTER_STOP
	caixa.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var l := Label.new()
	l.text = rotulo
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(550, 0)
	l.add_theme_color_override("font_color", COR_PAPEL)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa.add_child(l)
	caixa.mouse_entered.connect(func(): caixa.add_theme_stylebox_override("panel", realce))
	caixa.mouse_exited.connect(func(): caixa.add_theme_stylebox_override("panel", normal))
	caixa.gui_input.connect(func(ev: InputEvent):
		if (ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT) \
				or (ev is InputEventScreenTouch and ev.pressed):
			acao.call())
	caixa_opcoes.add_child(caixa)


# ---------- Saída ----------

func abrir_saida(m: Mundo) -> void:
	mundo = m
	base = ""
	visible = true
	estado = "saida"
	_limpar()
	linha_tom.visible = false
	var j := mundo.jogador()
	titulo.text = "O outro lado da mata"
	var faltam := Regras.BASES.keys().filter(func(b): return b != "vazia" and not j.bases_visitadas.has(b)).size()
	texto.text = "A mata se abre. Daqui se vê a estrada.\n\nVocê tem %d ponto(s). Registrar a chegada encerra a sua noite: não dá para visitar mais nenhuma base.%s" % [
		j.pontos(), ("\nAinda há %d guardião(ões) que você não visitou." % faltam) if faltam > 0 else ""]
	_opcao("Registrar minha chegada", func():
		mundo.registrar_chegada(j)
		visible = false
		estado = ""
		registrou.emit())
	_opcao("Continuar na mata", _fechar)


# ---------- Aproximação ----------

func _mostrar_aproximacao(extra := "") -> void:
	estado = "aproximacao"
	_limpar()
	linha_tom.visible = false
	titulo.text = Regras.BASES[base]
	var j := mundo.jogador()
	if base == "vazia":
		texto.text = (extra + "\n\n" if extra != "" else "") + "Ninguém mora aqui. A porta range com o vento."
		if not j.aproximacao.has(base):
			_opcao("Olhar pela janela", _olhar_janela)
		_opcao("Voltar para a trilha", _fechar)
		return
	texto.text = extra if extra != "" else "Uma luz âmbar escapa pelas frestas. Por onde você se aproxima?"
	if not j.aproximacao.has(base):
		_opcao("Olhar pela janela", _olhar_janela)
	_opcao("Entrar pela porta da frente", func(): _entrar("frente"))
	_opcao("Entrar pela porta dos fundos", func(): _entrar("fundos"))
	_opcao("Voltar para a trilha", _fechar)


func _olhar_janela() -> void:
	mundo.jogador().aproximacao[base] = "rondou"
	_mostrar_aproximacao("Pela janela: " + mundo.texto_janela(base))


func _entrar(porta: String) -> void:
	var j := mundo.jogador()
	if not j.aproximacao.has(base):
		j.aproximacao[base] = porta
	visita = Visita.new(mundo, j, base)
	var abertura := visita.abertura.map(func(e): return e["texto"])
	titulo.text = NOMES_GUARDIAO.get(base, base)
	_mostrar_pergunta("\n\n".join(abertura))


# ---------- Perguntas ----------

func _mostrar_pergunta(prefixo := "") -> void:
	if visita.terminou_perguntas():
		_mostrar_indicacao()
		return
	estado = "pergunta"
	_limpar()
	linha_tom.visible = true
	var e := visita.pergunta_atual()
	texto.text = (prefixo + "\n\n" if prefixo != "" else "") + "— " + e["texto"]
	for o in visita.opcoes():
		var rotulo: String = o["texto"]
		if o.has("atributo"):
			rotulo = "[%s] %s" % [NOMES_ATRIBUTO.get(o["atributo"], o["atributo"]), rotulo]
		var chave: String = o["chave"]
		_opcao(rotulo, func(): _responder(chave))
	_opcao("(Ficar em silêncio)", func(): _responder("silencio"))
	relogio = Regras.SILENCIO_S


func _responder(chave: String) -> void:
	if estado != "pergunta":
		return
	visita.responder(chave, tom)
	_mostrar_pergunta()


# ---------- Indicação e panelas ----------

func _mostrar_indicacao() -> void:
	estado = "indicacao"
	_limpar()
	linha_tom.visible = false
	var ind := visita.indicar()
	_apresentar(ind)


func _apresentar(ind: Dictionary) -> void:
	_limpar()
	var linhas := ["Duas panelas fumegam diante de você.", "— " + ind["fala"]]
	if ind.has("gesto") and ind["lado"] != "":
		linhas.append(ind["gesto"])
	texto.text = "\n\n".join(linhas)
	if ind["pede_item"]:
		for it in mundo.jogador().inventario:
			var id_item: String = it
			_opcao("Dar %s" % Textos.item(id_item), func(): _apresentar(visita.pagar(id_item)))
		_opcao("Não dar nada", func(): _apresentar(visita.pagar("")))
		return
	_opcao("Comer da panela da esquerda", func(): _comer("esquerda"))
	_opcao("Comer da panela da direita", func(): _comer("direita"))


func _comer(lado: String) -> void:
	estado = "resultado"
	_limpar()
	var r := visita.comer(lado)
	if r["boa"]:
		texto.text = "O caldo esquenta o corpo. Você se sente inteiro."
	else:
		match r["veneno"]:
			"resistiu":
				texto.text = "O gosto é amargo e a cabeça gira, mas seu corpo aguenta."
			"":
				texto.text = "O gosto é amargo. Você já não tinha o que perder."
			_:
				texto.text = "O gosto é amargo e algo se apaga em você.\nVocê perdeu 1 ponto de %s." % NOMES_ATRIBUTO[r["veneno"]]
	_opcao("Voltar para a trilha", _fechar)


func _fechar() -> void:
	visible = false
	estado = ""
	fechado.emit()
