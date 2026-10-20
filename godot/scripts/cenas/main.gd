extends Node
## Tela inicial (nome e atributos) e a noite.

const COR_PAPEL := Color("#e8d9b5")
const COR_AMBAR := Color("#e89a3c")

var mundo: Mundo
var vista: MapaView
var camera: Camera2D
var hud: CanvasLayer
var rotulo_relogio: Label
var rotulo_avisos: Label
var painel_base: PanelContainer
var rotulo_base: Label
var dialogo: Dialogo
var centro: CenterContainer
var avisos: Array = []
var acelerar := false
var usando_teclado := false

# Tela inicial
var inicio: Control
var campo_nome: LineEdit
var seletores := {}
var rotulo_pontos: Label
var botao_comecar: Button


func _ready() -> void:
	_montar_inicio()


# ---------- Tela inicial ----------

func _montar_inicio() -> void:
	inicio = CenterContainer.new()
	inicio.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(inicio)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 12)
	inicio.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "A Última Noite"
	titulo.add_theme_font_size_override("font_size", 40)
	titulo.add_theme_color_override("font_color", COR_PAPEL)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(titulo)

	campo_nome = LineEdit.new()
	campo_nome.placeholder_text = "Seu nome"
	campo_nome.max_length = 12
	campo_nome.custom_minimum_size = Vector2(320, 0)
	campo_nome.text_changed.connect(func(_t): _validar_inicio())
	caixa.add_child(campo_nome)

	var grade := GridContainer.new()
	grade.columns = 2
	caixa.add_child(grade)
	var nomes_atributos := {"forca": "Força", "inteligencia": "Inteligência", "carisma": "Carisma", "furtividade": "Furtividade", "resistencia": "Resistência"}
	var iniciais := {"forca": 2, "inteligencia": 3, "carisma": 2, "furtividade": 3, "resistencia": 2}
	for k in Regras.ATRIBUTOS:
		var l := Label.new()
		l.text = nomes_atributos[k]
		l.custom_minimum_size = Vector2(200, 0)
		grade.add_child(l)
		var s := SpinBox.new()
		s.min_value = 1
		s.max_value = 5
		s.value = iniciais[k]
		s.value_changed.connect(func(_v): _validar_inicio())
		grade.add_child(s)
		seletores[k] = s

	rotulo_pontos = Label.new()
	caixa.add_child(rotulo_pontos)

	botao_comecar = Button.new()
	botao_comecar.text = "Começar a noite"
	botao_comecar.pressed.connect(_comecar)
	caixa.add_child(botao_comecar)
	_validar_inicio()


func _atributos_escolhidos() -> Dictionary:
	var a := {}
	for k in seletores:
		a[k] = int(seletores[k].value)
	return a


func _validar_inicio() -> void:
	var soma := 0
	for v in _atributos_escolhidos().values():
		soma += v
	var restantes := Regras.PONTOS_TOTAIS - soma
	rotulo_pontos.text = "Pontos restantes: %d" % restantes
	var nome := campo_nome.text.strip_edges()
	var nome_ok := nome != "" and not Dados.nomes_computador().has(nome)
	botao_comecar.disabled = not (nome_ok and restantes == 0)


func _comecar() -> void:
	var semente := int(Time.get_unix_time_from_system()) % 1000000
	mundo = Mundo.new()
	mundo.iniciar(semente, {"nome": campo_nome.text.strip_edges(), "atributos": _atributos_escolhidos()})
	inicio.queue_free()
	_montar_noite()


# ---------- A noite ----------

func _montar_noite() -> void:
	vista = MapaView.new()
	vista.mundo = mundo
	vista.toque.connect(_ao_tocar)
	add_child(vista)

	camera = Camera2D.new()
	camera.zoom = Vector2(1.6, 1.6)
	camera.position_smoothing_enabled = true
	vista.add_child(camera)
	camera.make_current()

	hud = CanvasLayer.new()
	add_child(hud)
	rotulo_relogio = Label.new()
	rotulo_relogio.position = Vector2(16, 12)
	rotulo_relogio.add_theme_color_override("font_color", COR_PAPEL)
	hud.add_child(rotulo_relogio)

	rotulo_avisos = Label.new()
	rotulo_avisos.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	rotulo_avisos.position = Vector2(16, -140)
	rotulo_avisos.add_theme_color_override("font_color", COR_PAPEL)
	hud.add_child(rotulo_avisos)

	painel_base = PanelContainer.new()
	painel_base.set_anchors_preset(Control.PRESET_CENTER)
	painel_base.visible = false
	hud.add_child(painel_base)
	var caixa := VBoxContainer.new()
	painel_base.add_child(caixa)
	rotulo_base = Label.new()
	rotulo_base.autowrap_mode = TextServer.AUTOWRAP_WORD
	rotulo_base.custom_minimum_size = Vector2(420, 0)
	caixa.add_child(rotulo_base)
	var sair := Button.new()
	sair.text = "Voltar para a trilha"
	sair.pressed.connect(func(): painel_base.visible = false)
	caixa.add_child(sair)

	centro = CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(centro)
	dialogo = Dialogo.new()
	centro.add_child(dialogo)
	dialogo.fechado.connect(_ao_fechar_dialogo)
	dialogo.registrou.connect(_ao_registrar)

	mundo.aviso.connect(_ao_aviso)
	mundo.chegou_base.connect(_ao_chegar_base)
	mundo.chegou_saida.connect(func(p):
		p.rota = []
		dialogo.abrir_saida(mundo))
	mundo.amanheceu.connect(_ao_amanhecer)
	var j := mundo.jogador()
	_ao_aviso("Noite começa. Você usa %s." % Regras.CALCADOS[j.calcado])
	_ao_aviso("Ande com as setas, WASD ou clicando numa trilha visível.")
	_ao_aviso("Chegue à saída, %s, antes do amanhecer para registrar seus pontos." % Textos.direcao(j.pos, mundo.mapa.pos(j.saida)))


func _process(dt: float) -> void:
	if mundo == null:
		return
	var j := mundo.jogador()
	_ler_teclado()
	for i in (40 if acelerar else 1):
		mundo.tick(dt)
	camera.position = j.pos * MapaView.ESCALA
	var r := int(mundo.tempo_restante())
	var saida := "chegada registrada" if j.registrou() else "saída %s, %d m" % [Textos.direcao(j.pos, mundo.mapa.pos(j.saida)), int(j.pos.distance_to(mundo.mapa.pos(j.saida)))]
	rotulo_relogio.text = "%s   ·   %d pontos   ·   %s   ·   faltam %d:%02d para o amanhecer" % [j.nome, j.pontos(), saida, r / 60, r % 60]


func _unhandled_input(event: InputEvent) -> void:
	if camera == null:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = (camera.zoom * 1.1).clamp(Vector2(0.6, 0.6), Vector2(4, 4))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = (camera.zoom / 1.1).clamp(Vector2(0.6, 0.6), Vector2(4, 4))


## Setas ou WASD movem pelas trilhas. Soltar a tecla para o personagem onde está.
func _ler_teclado() -> void:
	if dialogo.visible or painel_base.visible or mundo.terminou:
		return
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_UP) or Input.is_physical_key_pressed(KEY_W):
		dir.y -= 1
	if Input.is_physical_key_pressed(KEY_DOWN) or Input.is_physical_key_pressed(KEY_S):
		dir.y += 1
	if Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_A):
		dir.x -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_physical_key_pressed(KEY_D):
		dir.x += 1
	if dir != Vector2.ZERO:
		usando_teclado = true
		mundo.dirigir_jogador(dir)
	elif usando_teclado:
		usando_teclado = false
		mundo.dirigir_jogador(Vector2.ZERO)


func _ao_registrar() -> void:
	_ao_aviso("Chegada registrada com %d pontos. A noite segue sem você." % mundo.jogador().pontos())
	acelerar = true


func _ao_tocar(ponto: Vector2) -> void:
	if painel_base.visible or dialogo.visible or mundo.terminou or mundo.jogador().registrou():
		return
	if not mundo.mover_jogador_para(ponto):
		_ao_aviso("Você não conhece um caminho até lá.")


func _ao_aviso(texto: String) -> void:
	avisos.append(texto)
	if avisos.size() > 5:
		avisos.pop_front()
	rotulo_avisos.text = "\n".join(avisos)


func _ao_chegar_base(p: Personagem, base: String) -> void:
	p.rota = []
	dialogo.abrir(mundo, base)


func _ao_fechar_dialogo() -> void:
	var j := mundo.jogador()
	var atrib := []
	for k in Regras.ATRIBUTOS:
		atrib.append("%s %d" % [k.substr(0, 3).capitalize(), j.atributos[k]])
	_ao_aviso("Panelas boas: %d   ·   %s" % [j.panelas_boas(), "  ".join(atrib)])


func _ao_amanhecer() -> void:
	dialogo.visible = false
	acelerar = false
	var linhas := ["Amanheceu.", ""]
	var pos := 1
	for p in mundo.classificacao():
		var detalhe := "%d panela(s) boa(s), %d ruim(ns)" % [p.panelas_boas(), p.refeicoes.size() - p.panelas_boas()]
		if p.registrou():
			linhas.append("%dº  %s — %d pontos (%s)" % [pos, p.nome, p.pontos(), detalhe])
			pos += 1
		else:
			linhas.append("—   %s — não chegou à saída (%s)" % [p.nome, detalhe])
	linhas.append("")
	linhas.append("Pontos provisórios: panela boa +%d, panela ruim %d." % [Regras.PONTOS["panela_boa"], Regras.PONTOS["panela_ruim"]])
	rotulo_base.text = "\n".join(linhas)
	painel_base.visible = true
