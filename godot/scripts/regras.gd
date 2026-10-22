class_name Regras
extends RefCounted
## Números do MVP v0.4 (docs/MVP_v0.4.md). Unidade de distância: metros.

const NOITE_S := 720.0               # duração da noite no MVP (provisório)
const VEL_TRILHA := 10.0             # m/s do jogador (dobrada de novo a pedido do usuário em 20/10/2026, para testes)
const VEL_COMPUTADOR := 1.5          # m/s dos personagens do computador (mais lentos, a pedido do usuário)
const ACELERA_COMPUTADOR := 3.0      # depois que o jogador registra a chegada, o computador anda 3x mais rápido
const ESPACO_PEGADA := 2.6           # m entre pegadas desenhadas (o desenho é maior que o real)
const AMOSTRA_M := 2.0               # resolução da memória do mapa
const RAIO_PERCORRIDO := 2.0         # amostras a essa distância viram "percorridas"
const LUZ_BASE_M := 180.0            # de quão longe se vê a luz de uma base
const PERCEPCAO_INTERVALO := 0.2     # s entre atualizações de visão
const HESITACAO := Vector2(2.0, 5.0) # pausa dos personagens do computador em bifurcações
const VISITA_BASE_S := 25.0          # tempo de visita do computador (provisório, até a etapa 2)
const CLIQUE_RAIO := 15.0            # m de tolerância ao tocar no mapa
const AVISO_S := 6.0                 # s que cada mensagem fica na tela
## Névoa: ligada no jogo normal. Para testes, o jogador desliga na tela inicial ou com a tecla N
## durante a noite (pedido do usuário em 22/10/2026). Sem névoa, o mapa inteiro aparece, os animais
## ficam visíveis e dá para clicar em qualquer ponto. Ligar de novo volta ao que você explorou.
static var sem_nevoa := false
## Tracejado das trilhas no mapa (desligado por padrão: a trilha aparece pelo vão entre as árvores).
static var mostrar_trilhas := false
## Ajuda de teste: círculo de alcance de cada animal e o tempo que falta no encontro.
static var mostrar_alcance := false

const ATRIBUTOS := ["forca", "inteligencia", "carisma", "furtividade", "resistencia"]
const PONTOS_TOTAIS := 12

const CALCADOS := {
	"bota": "bota de couro",
	"botina": "botina",
	"alpercata": "alpercata",
	"tamanco": "tamanco",
	"descalco": "pé descalço",
}

const CALCADOS_PAR := {
	"bota": "botas de couro",
	"botina": "botinas",
	"alpercata": "alpercatas",
	"tamanco": "tamancos",
	"descalco": "pés descalços",
}

const BASES := {
	"bento": "Cabana do Caçador",
	"iara": "Casa da Curandeira",
	"anselmo": "Capela dos Segredos",
	"marta": "Torre do Vigia",
	"quincas": "Moinho Abandonado",
	"vazia": "Tapera",
}

const PERFIS := ["cauteloso", "ousado", "trapaceiro"]

# ---- Pontuação e chegada (decidido em 20/10/2026: ganha quem fizer mais pontos e chegar à saída) ----
# Valores provisórios, aguardando aprovação (docs/sistemas/pontuacao_v1.md).
const PONTOS := {"panela_boa": 3, "panela_ruim": -3}   # 22/10/2026: ruim era -1; comer no chute deixou de compensar
const FOLGA_VOLTA := 2.5     # sem caminho conhecido, o computador estima 2,5x a distância em linha reta
const MARGEM_VOLTA_S := 90.0       # folga extra desde os animais (lobo derruba, cobra faz parar)
const FOLGA_BASE := 1.8      # o computador só desvia para uma base se der tempo de ir, visitar e chegar à saída

# ---- Visita às bases (etapa 2) ----
const PERGUNTAS_POR_VISITA := Vector2i(4, 5)     # 22/10/2026: era 4 a 6; menos chances de compensar um erro
const SILENCIO_S := 50.0                 # tempo para responder antes de contar como silêncio (ajustado em 20/10/2026)
const AFINIDADE_LIMITE := 10
const AFINIDADE_ALTA := 10              # 22/10/2026: era 8; agora só quem acerta quase tudo chega lá
## Afinidade com que cada guardião começa a visita (GDD: Marta desconfia de todos).
const AFINIDADE_INICIAL := {"marta": -2, "bento": -1}
## Chance de perceber o gesto do guardião ao indicar a panela: base + por nível de Inteligência.
## Sem perceber, o jogador só ouve a fala (que serve tanto para a verdade quanto para a mentira).
const GESTO_CHANCE := Vector2(0.35, 0.1)
const AFINIDADE_BAIXA := 1
const ESCOLHA_TEMPERATURA := 1.5         # quanto o computador hesita entre respostas (maior = mais ao acaso)
const MA_INTENCAO_MIN := 2               # respostas "ma" na visita para o guardião perceber
const JOGADORES_PERTO_M := 40.0
const TONS := ["firme", "gentil", "evasivo"]
const MECANICAS_MVP := ["bases_visitadas", "jogadores_vistos", "esconderijo", "aproximacao", "rastros",
	"armadilhas", "historico_respostas", "frases_prontas", "animais", "inventario"]

## O que cada guardião faz em cada situação (GDD v0.3, seção 2.1 e 2.2).
## boa = indica a boa; ruim = indica a ruim (mentindo); nada = não indica;
## sorteio = indica uma ao acaso; preco = pede um item: dá a boa se receber, senão a ruim.
const COMPORTAMENTO := {
	"bento":   {"alta": "boa", "neutra": "nada",    "baixa": "ruim", "ma": "ruim"},
	"iara":    {"alta": "boa", "neutra": "boa",     "baixa": "ruim", "ma": "ruim"},
	"anselmo": {"alta": "boa", "neutra": "boa",     "baixa": "nada", "ma": "ruim"},
	"marta":   {"alta": "boa", "neutra": "nada",    "baixa": "ruim", "ma": "ruim"},
	"quincas": {"alta": "preco", "neutra": "sorteio", "baixa": "ruim", "ma": "preco"},
}

## Falas e gestos da indicação: reserva, usada só se faltar conteudo/textos/indicacao.json.
const INDICACAO := {
	"bento": {"fala": "A da {lado}. E não volte pra reclamar.", "nada": "Escolha sozinho. Coragem não se empresta.",
		"verdade": "Bento olha você nos olhos enquanto fala.", "mentira": "Bento limpa a faca num pano, sem olhar para você."},
	"iara": {"fala": "Coma da {lado}, meu bem. Faz bem pro corpo.", "nada": "As duas têm o mesmo cheiro, né?",
		"verdade": "Iara oferece a tigela com as duas mãos.", "mentira": "Iara oferece a tigela com uma mão; a outra some no avental."},
	"anselmo": {"fala": "A da {lado}.", "nada": "Não lhe devo essa resposta.",
		"verdade": "Quando ele termina, o sino toca uma vez.", "mentira": "Ele termina de falar. O sino não toca."},
	"marta": {"fala": "{lado}.", "nada": "Descubra. Eu descobri.",
		"verdade": "Marta faz uma pausa antes de responder.", "mentira": "Marta responde antes de você terminar a pergunta."},
	"quincas": {"fala": "Pra você, a da {lado}. Palavra de comerciante.", "nada": "Sem mercadoria, sem conselho.",
		"preco": "Uma indicação dessas tem preço. O que você me dá?",
		"verdade": "Quincas fala com as mãos paradas sobre o balcão.", "mentira": "Quincas esfrega as mãos e solta uma risadinha."},
}

# ---- Animais (docs/sistemas/animais_v1.md, decidido em 21/10/2026). Números provisórios. ----
const ANIMAIS_QTD := {"lobo": 1, "coruja": 2, "cao": 1, "cobra": 4}
const LOBO_VE_M := 16.0
const LOBO_ROSNA_S := 2.5
const LOBO_VEL := 1.4
const LOBO_VEL_FERIDO := 0.6
const LOBO_VEL_ATAQUE := 7.0
const LOBO_PERSEGUE_S := 15.0
const LOBO_CHANCE_FERIDO := 0.3
const LOBO_UIVO_S := Vector2(70.0, 130.0)
const LOBO_TROCA_BASE_S := Vector2(120.0, 200.0)
const LOBO_RONDA_M := 45.0              # anda pelas trilhas até essa distância da base
const LENTO_S := 10.0                   # metade da velocidade depois de derrubado (reduzido pela Resistência)
const CORUJA_VE_M := 20.0
const CORUJA_AVISA_M := 60.0
const CORUJA_POUSO_S := Vector2(70.0, 110.0)
const CORUJA_VOO := 9.0
const CAO_VE_M := 14.0
const CAO_VEL := 1.8
const CAO_VEL_GUIA := 2.5
const CAO_ESPERA_S := 8.0
const CAO_CHANCE_GUIA := 0.55
const CAO_LONGE_M := 18.0
const COBRA_AVISO_M := 6.0              # distância mínima do chacoalhar
const COBRA_PICA_M := 3.0               # o bote alcança até aqui
const COBRA_REACAO_S := 1.2             # o chacoalhar vem cedo o bastante para dar esse tempo de parar, em qualquer velocidade
const COBRA_DESISTE_S := 2.0
const COBRA_LONGE_M := 25.0             # não aparece tão perto de partidas e bases
const ONDA_IMPRECISAO_M := 12.0          # as ondas mostram a região do som, não o ponto exato
const OUVE_M := 250.0                   # distância de que se ouve pio, latido e ataque
const ANIMAL_PARA := Vector2(0.3, 0.12) # chance do computador ficar parado: base + por nível de Inteligência
## Sons de cada evento: arquivos em godot/sons (créditos em sons/CREDITOS.md) e de quão longe se ouvem.
## "onda": desenha ondas no mapa, mesmo sobre a névoa, na região de onde veio o som.
const SONS := {
	"lobo_uivou": {"arquivos": ["lobo_uivo_1", "lobo_uivo_2"], "alcance": 700.0, "onda": true},
	"lobo_rosna": {"arquivos": ["lobo_rosna"], "alcance": 60.0},
	"lobo_atacou": {"arquivos": ["lobo_ataque", "lobo_rosna"], "alcance": 250.0, "onda": true},
	"coruja_piou": {"arquivos": ["coruja_1", "coruja_2", "coruja_3"], "alcance": 250.0, "onda": true},
	"cao_latiu": {"arquivos": ["cao_late_1", "cao_late_2", "cao_late_3"], "alcance": 250.0, "onda": true},
	"cobra_folhas": {"arquivos": ["cobra_folhas"], "alcance": 15.0},
	"armadilha": {"arquivos": ["armadilha"], "alcance": 250.0, "onda": true},
}

# ---- Armadilhas (docs/MVP_v0.4.md, seção 6; implementadas em 22/10/2026). Números provisórios. ----
const ARMADILHAS_QTD := 7
const ARMADILHAS_BECO := 2           # quantas vão no fim de um beco
const ARMADILHA_LONGE_M := 30.0      # longe das partidas, das bases e das saídas
const ARMADILHA_PISA_M := 1.2

## Falas dos animais: reserva, usada só se faltar conteudo/textos/animais.json.
const FALAS_ANIMAIS := {
	"lobo_rosna": "Um lobo rosna para você, orelhas para trás. Fique parado até ele se afastar.",
	"lobo_desiste": "O lobo fareja o ar e se afasta.",
	"lobo_derruba": "O lobo te derruba. Você demora a levantar e segue mancando.",
	"lobo_escapou": "O lobo para na beira da clareira e não entra.",
	"lobo_ferido": "Um lobo passa mancando, sem forças para atacar.",
	"coruja_olha": "Uma coruja olha para você e pia.",
	"coruja_avisa": "Uma coruja olha para você e vira a cabeça {direcao}.",
	"cao_guia": "Um cão sem dono abana o rabo e espera por você. Chegue perto dele.",
	"cao_seguindo": "O cão sai trotando pela trilha. Siga-o.",
	"cao_chegou": "O cão para diante da luz da base e volta para a mata.",
	"cao_late": "Um cão inquieto rosna e late para você.",
	"cobra_som": "Folhas secas chacoalham bem perto. Pare e espere.",
	"cobra_ve": "Uma cobra, enrolada no meio da trilha. Pare e espere.",
	"cobra_some": "A cobra desliza para o mato.",
	"cobra_pica": "Uma picada no tornozelo. Você sente o veneno subir.",
	"cobra_resistiu": "Uma picada no tornozelo, mas seu corpo aguenta o veneno.",
}

# Provisório: substituído por conteudo/nomes.json quando a demanda 2 for aprovada.
const NOMES_PROVISORIOS := ["Zé Tonico", "Cotinha", "Bastião", "Filó", "Nhô Juca", "Sá Rita", "Tonhão", "Dita"]

# Tabela de atributos (seção 7 do MVP). Índice = nível - 1.
const ALCANCE_VISTA := [8.0, 11.0, 14.0, 17.0, 20.0]       # Inteligência
const LEMBRANCA_S := [30.0, 45.0, 60.0, 90.0, 120.0]        # Inteligência
const NOTAR_ARMADILHA := [0.0, 2.0, 3.0, 4.0, 5.0]          # Inteligência
const USOS_SUMIR := [1, 1, 2, 2, 3]                         # Furtividade
const VIDA_PEGADA_S := [20.0, 19.0, 18.0, 16.5, 15.0]      # Furtividade (ajustado pelo usuário em 20/10/2026: 15 a 20 s)
const VEL_MATA := [0.2, 0.3, 0.4, 0.5, 0.6]                 # Força
const PRESO_S := [8.0, 6.5, 5.0, 3.5, 2.0]                  # Força
const RESISTIR_VENENO := [0.0, 0.1, 0.2, 0.3, 0.4]          # Resistência
const REDUZ_LENTIDAO := [0.0, 0.15, 0.3, 0.45, 0.6]         # Resistência


static func nivel(tabela: Array, valor: int):
	return tabela[clampi(valor, 1, 5) - 1]


static func atributos_validos(a: Dictionary) -> bool:
	var soma := 0
	for k in ATRIBUTOS:
		var v: int = a.get(k, 0)
		if v < 1 or v > 5:
			return false
		soma += v
	return soma == PONTOS_TOTAIS


static func sortear_atributos(rng: RandomNumberGenerator) -> Dictionary:
	var a := {}
	for k in ATRIBUTOS:
		a[k] = 1
	var restantes := PONTOS_TOTAIS - ATRIBUTOS.size()
	while restantes > 0:
		var k: String = ATRIBUTOS[rng.randi() % ATRIBUTOS.size()]
		if a[k] < 5:
			a[k] += 1
			restantes -= 1
	return a
