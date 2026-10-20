# Banco de guardiões — formato v3

Entrega da demanda 1 do `STATUS.md`, baseada em:

- `docs/MVP_v0.4.md`
- `docs/briefings/BRIEFING_GPT_v0.4.md`
- `docs/correcoes/CORRECOES_guardioes_v3.md`
- entrega anterior `entregas/2026-10-19_guardioes_v2/`

## Conteúdo

- `bento.json`, `iara.json`, `anselmo.json`, `marta.json` e `quincas.json`: formato v3, cada um com 1 narração, 2 falas e 12 perguntas utilizáveis no MVP.
- `fora_do_mvp/`: cópia das nove perguntas v2 retiradas por dependerem de trocas, prendas, escuta ou alerta de furtividade.
- `validar.ps1`: valida regras estruturais e mensuráveis dos formatos v2 e v3.

## O que mudou

### Formato

- `versao_formato` passou de 2 para 3.
- Todos os guardiões receberam `reputacao`, com pelo menos três marcas produzidas em outras bases e valores entre -2 e +2.
- Perguntas que pressupõem acontecimentos receberam `premissa` usando apenas o vocabulário fechado do formato v3.
- `requer` nos arquivos principais foi limitado às dez mecânicas que entram no MVP.

### Conteúdo

- **Bento:** ganhou premissas para lobo, pegadas, frase enviada e coruja. `bento_05` agora distingue calçado, direção e identidade reconhecida. `bento_11` deixou de depender de escuta e passou a testar franqueza sobre uma frase enviada.
- **Iara:** ganhou premissas para animais, armadilha, frases e jogador visto. `iara_10` não penaliza quem honestamente não acionou armadilha. `iara_12` passou de prenda para uma decisão verificável diante do lobo perto de uma base.
- **Anselmo:** ganhou premissas e dois novos cruzamentos do histórico. `anselmo_09` confere omissão sobre inventário; `anselmo_11` confere silêncio usado para esconder a verdade.
- **Marta:** `marta_05` aplica a regra de identidade por calçado e visão. `marta_06` passou a testar leitura de pegadas; `marta_08` passou de inventário alheio para rota observada. O silêncio positivo foi preservado.
- **Quincas:** quatro perguntas de trocas entre jogadores foram substituídas por perguntas sobre o inventário do próprio jogador e o que ele oferece ao guardião.

## Perguntas preservadas fora do MVP

| Guardião | IDs | Mecânica suspensa |
|---|---|---|
| Bento | `bento_11` | escuta |
| Iara | `iara_12` | prendas |
| Anselmo | `anselmo_09`, `anselmo_11` | trocas, prendas |
| Marta | `marta_06` | alerta de furtividade |
| Quincas | `quincas_06`, `quincas_09`, `quincas_11`, `quincas_14` | trocas |

Os IDs foram mantidos nos arquivos principais para as perguntas substitutas. As versões antigas ficam isoladas em `fora_do_mvp/` e não devem ser carregadas pelo MVP.

## Validação

Executar na raiz desta entrega:

```powershell
./validar.ps1
```

Resultado final:

```text
VALIDO V3: 5 guardiões, 60 perguntas no MVP, 9 arquivadas e regras v2/v3 aprovadas.
```

O validador cobre:

- sintaxe JSON, versão, IDs, tipos e contagens;
- tons, afinidades, intenções, mentira, contradição, silêncio e opções extras;
- mecânicas permitidas e vocabulário de premissas;
- premissas obrigatórias das perguntas factuais revisadas;
- reputação e origem das marcas em outras bases;
- regra de identidade por calçado e visão;
- correção de `iara_10`;
- preservação exata das nove perguntas fora do MVP;
- equilíbrio mensurável herdado do formato v2.

## Ponto mais fraco

As reações de `reputacao` são coerentes com as personalidades, mas seus valores ainda não foram testados em partida. As novas perguntas do Quincas usam descrições genéricas de itens porque o catálogo definitivo do inventário continua como decisão pendente no MVP.

## PROPOSTAS

Nenhuma. A entrega não acrescenta mecânicas nem altera decisões do MVP v0.4.
