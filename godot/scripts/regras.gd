class_name Regras
extends RefCounted
## Números do MVP v0.4 (docs/MVP_v0.4.md). Unidade de distância: metros.

const NOITE_S := 720.0               # duração da noite no MVP (provisório)
const VEL_TRILHA := 1.5              # m/s
const ESPACO_PEGADA := 1.5           # m entre pegadas
const AMOSTRA_M := 2.0               # resolução da memória do mapa
const RAIO_PERCORRIDO := 2.0         # amostras a essa distância viram "percorridas"
const LUZ_BASE_M := 130.0            # de quão longe se vê a luz de uma base
const PERCEPCAO_INTERVALO := 0.2     # s entre atualizações de visão
const HESITACAO := Vector2(2.0, 5.0) # pausa dos personagens do computador em bifurcações
const VISITA_BASE_S := 25.0          # tempo de visita do computador (provisório, até a etapa 2)
const CLIQUE_RAIO := 15.0            # m de tolerância ao tocar no mapa

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
const PONTOS := {"panela_boa": 3, "panela_ruim": -1}
const FOLGA_VOLTA := 2.5     # sem caminho conhecido, o computador estima 2,5x a distância em linha reta
const MARGEM_VOLTA_S := 60.0

# ---- Visita às bases (etapa 2) ----
const PERGUNTAS_POR_VISITA := Vector2i(4, 6)
const SILENCIO_S := 10.0                 # tempo para responder antes de contar como silêncio
const AFINIDADE_LIMITE := 10
const AFINIDADE_ALTA := 8               # calibrado com o banco v3.1 (ver godot/README.md)
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

## Falas e gestos da indicação. Provisório: o banco definitivo será pedido ao ChatGPT.
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

# Provisório: substituído por conteudo/nomes.json quando a demanda 2 for aprovada.
const NOMES_PROVISORIOS := ["Zé Tonico", "Cotinha", "Bastião", "Filó", "Nhô Juca", "Sá Rita", "Tonhão", "Dita"]

# Tabela de atributos (seção 7 do MVP). Índice = nível - 1.
const ALCANCE_VISTA := [8.0, 11.0, 14.0, 17.0, 20.0]       # Inteligência
const LEMBRANCA_S := [30.0, 45.0, 60.0, 90.0, 120.0]        # Inteligência
const NOTAR_ARMADILHA := [0.0, 2.0, 3.0, 4.0, 5.0]          # Inteligência
const USOS_SUMIR := [1, 1, 2, 2, 3]                         # Furtividade
const VIDA_PEGADA_S := [120.0, 100.0, 80.0, 60.0, 40.0]     # Furtividade
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
