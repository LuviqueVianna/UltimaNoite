# Status do projeto

**Atualizado em:** 20/10/2026, pelo Claude.

## Agora

| Quem | Está com | Arquivo |
|---|---|---|
| **ChatGPT** | Demanda 1b: ajustes pequenos no banco de guardiões v3 | [revisoes/2026-10-20_guardioes_v3.md](revisoes/2026-10-20_guardioes_v3.md) |
| **Claude** | Revisão da entrega v3 concluída; vocabulário de premissas ampliado | [docs/correcoes/CORRECOES_guardioes_v3.md](docs/correcoes/CORRECOES_guardioes_v3.md) |
| **Usuário** | Decidir os nomes dos personagens; aprovar o catálogo de itens quando o Claude propuser | — |

## Fila do ChatGPT

Leia antes: [docs/briefings/BRIEFING_GPT_v0.4.md](docs/briefings/BRIEFING_GPT_v0.4.md).

| Ordem | Demanda | Referência | Estado |
|---|---|---|---|
| 1 | Correções do banco de guardiões (formato v3) | `docs/correcoes/CORRECOES_guardioes_v3.md` | Entregue em 20/10 e revisada |
| 1b | Ajustes da revisão: itens 1, 2, 3 e 4 | `revisoes/2026-10-20_guardioes_v3.md` | **Próxima** |
| 2 | Textos do mapa: janelas, eventos à distância, becos e clareiras, frases prontas | Briefing v0.4, seção 4 | Aguardando |
| 3 | Quadro de estilo do pergaminho | Briefing v0.4, seção 5 | Aguardando |

Ao terminar uma demanda: entregar em `entregas/AAAA-MM-DD_<nome>/` e parar.

**Demanda 1b:** partir de `entregas/2026-10-20_guardioes_v3/`, aplicar os ajustes da revisão e entregar em `entregas/AAAA-MM-DD_guardioes_v3_1/` (os 5 JSONs, o validador e um README com o que mudou). A pasta `fora_do_mvp/` não muda; não precisa repetir.

## Histórico

| Data | O que aconteceu |
|---|---|
| 20/10/2026 | ChatGPT entregou o banco de guardiões v3. Revisão: aprovado com 4 ajustes pequenos |
| 20/10/2026 | MVP v0.4 aprovado: mapa de pegadas visto de cima, single-player, 5 guardiões. Revisão da entrega v2 gerou as correções v3 |
| 19/10/2026 | ChatGPT entregou o banco de guardiões no formato v2 e o quadro de estilo isométrico do Bento (arquivado: o isométrico ficou para depois do MVP) |

## Pendências de decisão

- [ ] **Nomes dos personagens.** Frases e respostas como "digo quem era" precisam de um identificador escolhível. Sugestão do Claude: elenco de nomes e aparências sorteado por partida.
- [ ] **Catálogo de itens do inventário** (6 a 8 itens). O Claude vai propor.
