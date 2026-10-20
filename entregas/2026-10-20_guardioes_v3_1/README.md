# Banco de guardiões — formato v3.1

Entrega da demanda 1b do `STATUS.md`, baseada na revisão `revisoes/2026-10-20_guardioes_v3.md`.

Parte da entrega anterior `entregas/2026-10-20_guardioes_v3/`. A pasta `fora_do_mvp/` não foi repetida porque não recebeu alterações.

## Conteúdo

- `bento.json`
- `iara.json`
- `anselmo.json`
- `marta.json`
- `quincas.json`
- `validar.ps1`

Cada guardião mantém 1 narração, 2 falas e 12 perguntas utilizáveis no MVP.

## Ajustes aplicados

### 1. Respostas possíveis no MVP

Foram substituídas quatro respostas que descreviam troca entre jogadores:

| Pergunta | Nova resposta | Afinidade preservada |
|---|---|---:|
| `iara_08` | “Usei a dica primeiro e só depois a repassei.” | 0 |
| `iara_13` | “Esperei a pessoa escolher antes de avisar.” | 0 |
| `anselmo_13` | “Guardei a informação para proteger minha própria rota.” | 1 |
| `marta_14` | “Avisei só a direção, guardando os detalhes.” | 2 |

As substituições mantêm o papel das respostas: escolhas pragmáticas, egoístas ou parcialmente cooperativas, sem usar uma mecânica suspensa.

### 2. Reputação da Iara

`explorou_vulneravel: -2` foi substituída por `confessou_egoismo: -2`. A nova marca é registrada por Anselmo e pode afetar uma visita posterior à Iara.

### 3. Opções extras e Carisma

O critério passou a exigir de 2 a 4 opções extras que igualem ou superem a melhor resposta comum, sem ultrapassar metade das opções extras.

| Guardião | Opções no topo | IDs |
|---|---:|---|
| Bento | 3 | `bento_08`, `bento_10`, `bento_15` |
| Iara | 3 | `iara_08`, `iara_09`, `iara_15` |
| Anselmo | 2 | `anselmo_08`, `anselmo_13` |
| Marta | 2 | `marta_06`, `marta_08` |
| Quincas | 3 | `quincas_05`, `quincas_06`, `quincas_14` |

Nos quatro guardiões ajustados, as opções elevadas são de Carisma sempre que esse atributo já estava disponível. Marta não possuía opções extras de Carisma; foram preservados os atributos existentes.

### 4. Premissas mais específicas

- `iara_08`: `recebeu_frase_panela`
- `iara_13`: `viu_jogador_entrar_base`
- `iara_14`: `recebeu_frase_pedido`

O validador passou a reconhecer as três premissas acrescentadas ao vocabulário oficial.

## Validação

Executar nesta pasta:

```powershell
./validar.ps1
```

Resultado esperado:

```text
VALIDO V3.1: 5 guardiões, 60 perguntas no MVP e ajustes da revisão aprovados.
```

Além das regras v2/v3 anteriores, o validador agora confere:

- de 2 a 4 opções extras no topo por guardião;
- limite máximo de metade das opções extras;
- as três novas premissas da Iara;
- ausência das quatro respostas impossíveis;
- remoção da marca de reputação que nunca disparava.

## Ponto mais fraco

Marta e Anselmo não possuem opções extras de Carisma adequadas para elevar sem reescrever conteúdo já aprovado. Eles cumprem o critério numérico com opções de Furtividade e Inteligência; o efeito específico do Carisma continua mais visível nos outros três guardiões.

## PROPOSTAS

Nenhuma. Os ajustes seguem estritamente a revisão aprovada e não alteram decisões do MVP.
