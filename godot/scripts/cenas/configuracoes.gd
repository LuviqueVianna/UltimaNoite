class_name Configuracoes
extends PanelContainer
## Tela de configurações: névoa, tracejado das trilhas e alcance dos animais.
## Fica guardada entre partidas (user://configuracoes.cfg; no navegador, no próprio navegador).

signal fechado
signal mudou

const ARQUIVO := "user://configuracoes.cfg"
const COR_PAPEL := Color("#e8d9b5")
const COR_AMBAR := Color("#e89a3c")

static var tutorial_visto := false

var _chaves := {}


static func carregar() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(ARQUIVO) != OK:
		return
	Regras.sem_nevoa = not bool(cfg.get_value("jogo", "nevoa", true))
	Regras.mostrar_trilhas = bool(cfg.get_value("jogo", "trilhas", false))
	Regras.mostrar_alcance = bool(cfg.get_value("jogo", "alcance_animais", false))
	tutorial_visto = bool(cfg.get_value("jogo", "tutorial_visto", false))


static func salvar() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("jogo", "nevoa", not Regras.sem_nevoa)
	cfg.set_value("jogo", "trilhas", Regras.mostrar_trilhas)
	cfg.set_value("jogo", "alcance_animais", Regras.mostrar_alcance)
	cfg.set_value("jogo", "tutorial_visto", tutorial_visto)
	cfg.save(ARQUIVO)


func _ready() -> void:
	custom_minimum_size = Vector2(560, 0)
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#16212e")
	estilo.border_color = Color(COR_PAPEL, 0.5)
	estilo.set_border_width_all(2)
	estilo.set_corner_radius_all(8)
	estilo.set_content_margin_all(24)
	add_theme_stylebox_override("panel", estilo)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 14)
	add_child(caixa)

	var titulo := Label.new()
	titulo.text = "Configurações"
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.add_theme_color_override("font_color", COR_AMBAR)
	caixa.add_child(titulo)

	_chave(caixa, "nevoa", "Névoa", "O mapa só aparece onde você já andou e enxergou. Tecla N liga e desliga durante a noite.")
	_chave(caixa, "trilhas", "Tracejado das trilhas", "Desenha a linha tracejada no meio das trilhas. Sem ele, a trilha é o vão entre as árvores.")
	_chave(caixa, "alcance", "Alcance dos animais (ajuda de teste)", "Mostra até onde cada animal percebe você e quanto tempo falta num encontro.")

	var fechar := Button.new()
	fechar.text = "Fechar"
	fechar.custom_minimum_size = Vector2(0, 40)
	fechar.pressed.connect(func():
		visible = false
		fechado.emit())
	caixa.add_child(fechar)
	visible = false


func abrir() -> void:
	_chaves["nevoa"].button_pressed = not Regras.sem_nevoa
	_chaves["trilhas"].button_pressed = Regras.mostrar_trilhas
	_chaves["alcance"].button_pressed = Regras.mostrar_alcance
	visible = true


func _chave(caixa: VBoxContainer, id: String, rotulo: String, explicacao: String) -> void:
	var linha := VBoxContainer.new()
	linha.add_theme_constant_override("separation", 2)
	var chave := CheckButton.new()
	chave.text = rotulo
	chave.add_theme_color_override("font_color", COR_PAPEL)
	chave.toggled.connect(func(ligada: bool):
		match id:
			"nevoa":
				Regras.sem_nevoa = not ligada
			"trilhas":
				Regras.mostrar_trilhas = ligada
			"alcance":
				Regras.mostrar_alcance = ligada
		salvar()
		mudou.emit())
	linha.add_child(chave)
	var texto := Label.new()
	texto.text = explicacao
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(500, 0)
	texto.add_theme_color_override("font_color", Color(COR_PAPEL, 0.65))
	texto.add_theme_font_size_override("font_size", 14)
	linha.add_child(texto)
	caixa.add_child(linha)
	_chaves[id] = chave
