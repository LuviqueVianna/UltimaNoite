class_name Tutorial
extends PanelContainer
## Como jogar: aparece na primeira vez e pode ser aberto de novo na tela inicial.
## Explica as regras e as dicas, sem contar a personalidade de cada guardião.

signal fechado

const COR_PAPEL := Color("#e8d9b5")
const COR_AMBAR := Color("#e89a3c")

const PAGINAS := [
	{
		"titulo": "A última noite",
		"texto": """Você tem uma noite, [b]12 minutos[/b], para atravessar a mata.

• Entre as árvores há casas com uma luz âmbar: são as [b]bases[/b]. Em cada uma, um guardião conversa com você e serve [b]duas panelas[/b]. Só uma é boa.
• [b]Panela boa: +3 pontos.[/b] [b]Panela ruim: −3 pontos e veneno.[/b] Na dúvida, você pode ir embora sem comer.
• A [b]saída[/b] fica do lado oposto do mapa ao ponto onde você começou. O alto da tela mostra para que lado ela está e a que distância.
• Só pontua quem [b]registrar a chegada[/b] na saída antes do amanhecer. Ganha quem tiver mais pontos.
• Outros três viajantes fazem o mesmo nesta noite."""
	},
	{
		"titulo": "Como andar",
		"texto": """• [b]Setas ou WASD:[/b] você segue a trilha que mais aponta para aquele lado. Soltou, parou.
• [b]Clique[/b] numa clareira ou num trecho de trilha que você conhece: o personagem vai até lá sozinho.
• [b]Espaço:[/b] para onde está. Faz diferença diante do lobo e da cobra.
• [b]F (ou o botão no alto):[/b] some na mata por uns segundos. Ninguém vê você, e o lobo que ronda não percebe. Parado dura 5 s; andando, acaba mais rápido. Poucos usos por noite.
• [b]Roda do mouse:[/b] aproxima e afasta o mapa. [b]N:[/b] liga e desliga a névoa. [b]Esc:[/b] configurações.

O mapa se desenha conforme você anda e enxerga. Suas pegadas são vazadas; as dos outros são cheias e mostram o calçado de quem passou. O nome de alguém só aparece quando você o vê."""
	},
	{
		"titulo": "Seus atributos",
		"texto": """Você distribui [b]12 pontos[/b], de 1 a 5 em cada atributo:

• [b]Força:[/b] você fica menos tempo caído quando o lobo te derruba ou preso numa armadilha.
• [b]Inteligência:[/b] enxerga mais longe e lembra por mais tempo do que viu; vê a cobra e as armadilhas antes de chegar perto; percebe mais vezes o gesto de um guardião.
• [b]Carisma:[/b] libera respostas extras nas conversas.
• [b]Furtividade:[/b] mais usos do "sumir na mata"; suas pegadas somem mais rápido, e você lê melhor as dos outros; sai pelos fundos de uma base sem o lobo perceber.
• [b]Resistência:[/b] chance de aguentar o veneno; você se recupera mais rápido de uma queda.

O [b]veneno[/b] (panela ruim ou picada de cobra) tira 1 ponto da sua maior habilidade, pela noite toda, e [b]acumula[/b]:
• 1ª dose: a vista escurece e você enxerga menos por um minuto.
• 2ª dose: a vista não clareia mais até o amanhecer.
• [b]3ª dose: você desmaia na mata e não registra a chegada. A noite está perdida.[/b]"""
	},
	{
		"titulo": "Animais e armadilhas",
		"texto": """Diante do perigo, [b]quem para se sai melhor do que quem corre[/b].

• [b]Lobo:[/b] ronda perto das bases. Se rosnar para você, fique parado (ou suma na mata) até ele ir embora. Se você se mexer, ele ataca: te derruba, e depois você anda devagar por um tempo. [b]Depois de derrubar, ele segue o seu faro[/b]: esconder-se não adianta. O jeito é chegar a uma base: ele não entra, mas fica esperando à porta. Esperar gasta a noite; sair pelos fundos pode enganá-lo; sair pela frente, ele ataca de novo. Às vezes aparece ferido e não ataca.
• [b]Cobra:[/b] fica escondida nas trilhas. Ouviu folhas secas chacoalhando? Pare e espere: ela vai embora. Se continuar andando até perto dela, leva uma picada com veneno.
• [b]Cão sem dono:[/b] se abanar o rabo e esperar, chegue perto e ele leva você até uma base que você ainda não visitou. Se ficar inquieto, ele late, e todos por perto ouvem onde você está.
• [b]Coruja:[/b] quando nota você, pia, e quem estiver por perto sabe de onde veio o pio. Às vezes, em vez de piar, ela vira a cabeça para onde há outra pessoa.
• [b]Armadilhas:[/b] laços e molas escondidos nas trilhas, mais ainda no fim dos caminhos sem saída. Quem tem Inteligência nota antes e passa por elas; quem pisa fica preso (menos tempo com Força) e depois anda devagar. Uma armadilha disparada fica à vista de todos.

Uivos, pios, latidos e o estalo de uma armadilha soam do lado de onde aconteceram."""
	},
	{
		"titulo": "Os guardiões",
		"texto": """• Antes de entrar, você pode [b]olhar pela janela[/b]. Às vezes há outro viajante lá dentro, e dá para ver como o guardião o trata.
• Entre pela [b]frente ou pelos fundos[/b]. O guardião repara. Ou fique [b]na moita[/b] ao lado da casa, vendo quem chega sem ser visto.
• Chegar [b]ferido ou envenenado[/b] muda como você é recebido: uns se compadecem, outros desconfiam.
• Ele faz perguntas. Escolha a resposta e o [b]tom[/b]: firme, gentil ou evasivo. Se você demorar, conta como silêncio.
• Ele sabe parte do que aconteceu na sua noite. [b]Mentir sobre o que ele pode conferir custa caro[/b], e contradizer o que você disse em outra base também.
• Cada guardião valoriza coisas diferentes: o que agrada um pode irritar outro. E o que você faz numa base chega às outras.
• No fim, ele aponta uma panela, ou se recusa. [b]Ele pode mentir.[/b] Cada guardião tem um jeito próprio de se trair quando mente, mas nem sempre você percebe.
• Um deles pode pedir algo em troca da dica. Se não confiar, não coma."""
	},
]

var titulo: Label
var texto: RichTextLabel
var contador: Label
var voltar: Button
var proximo: Button
var pagina := 0


func _ready() -> void:
	custom_minimum_size = Vector2(700, 0)
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

	titulo = Label.new()
	titulo.add_theme_font_size_override("font_size", 26)
	titulo.add_theme_color_override("font_color", COR_AMBAR)
	caixa.add_child(titulo)

	texto = RichTextLabel.new()
	texto.bbcode_enabled = true
	texto.fit_content = true
	texto.scroll_active = false
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size = Vector2(650, 0)
	texto.add_theme_color_override("default_color", COR_PAPEL)
	texto.add_theme_font_size_override("normal_font_size", 17)
	texto.add_theme_font_size_override("bold_font_size", 17)
	caixa.add_child(texto)

	var rodape := HBoxContainer.new()
	rodape.add_theme_constant_override("separation", 12)
	caixa.add_child(rodape)
	var pular := Button.new()
	pular.text = "Pular"
	pular.pressed.connect(_fechar)
	rodape.add_child(pular)
	var meio := Control.new()
	meio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rodape.add_child(meio)
	contador = Label.new()
	contador.add_theme_color_override("font_color", Color(COR_PAPEL, 0.6))
	rodape.add_child(contador)
	voltar = Button.new()
	voltar.text = "Voltar"
	voltar.pressed.connect(func(): _mostrar(pagina - 1))
	rodape.add_child(voltar)
	proximo = Button.new()
	proximo.custom_minimum_size = Vector2(110, 0)
	proximo.pressed.connect(func():
		if pagina >= PAGINAS.size() - 1:
			_fechar()
		else:
			_mostrar(pagina + 1))
	rodape.add_child(proximo)
	visible = false


func abrir() -> void:
	visible = true
	_mostrar(0)


func _mostrar(n: int) -> void:
	pagina = clampi(n, 0, PAGINAS.size() - 1)
	titulo.text = PAGINAS[pagina]["titulo"]
	texto.text = PAGINAS[pagina]["texto"]
	contador.text = "%d de %d" % [pagina + 1, PAGINAS.size()]
	voltar.disabled = pagina == 0
	proximo.text = "Entendi" if pagina == PAGINAS.size() - 1 else "Próximo"


func _fechar() -> void:
	visible = false
	Configuracoes.tutorial_visto = true
	Configuracoes.salvar()
	fechado.emit()
