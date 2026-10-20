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

const BASES := {
	"bento": "Cabana do Caçador",
	"iara": "Casa da Curandeira",
	"anselmo": "Capela dos Segredos",
	"marta": "Torre do Vigia",
	"quincas": "Moinho Abandonado",
	"vazia": "Tapera",
}

const PERFIS := ["cauteloso", "ousado", "trapaceiro"]

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
