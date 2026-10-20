# Status do projeto

**Atualizado em:** 20/10/2026, pelo Claude.

## Agora

| Quem | Está com | Arquivo |
|---|---|---|
| **ChatGPT** | Demanda 3: quadro de estilo do pergaminho | [docs/briefings/BRIEFING_GPT_v0.4.md](docs/briefings/BRIEFING_GPT_v0.4.md), seção 5 |
| **Claude** | Código do MVP em Godot: etapas 1 e 2 prontas (mapa, pegadas, visão, bases, diálogo, panelas); fazendo a etapa 3 (perigos, itens, habilidades) | [godot/README.md](godot/README.md) |
| **Usuário** | Aprovar os valores dos pontos; jogar as etapas 1 e 2; escolher o estilo do pergaminho quando o ChatGPT entregar | [docs/sistemas/pontuacao_v1.md](docs/sistemas/pontuacao_v1.md) |

## Fila do ChatGPT

Leia antes: [docs/briefings/BRIEFING_GPT_v0.4.md](docs/briefings/BRIEFING_GPT_v0.4.md).

| Ordem | Demanda | Referência | Estado |
|---|---|---|---|
| 1 | Correções do banco de guardiões (formato v3) | `docs/correcoes/CORRECOES_guardioes_v3.md` | Entregue em 20/10 e revisada |
| 1b | Ajustes da revisão: itens 1, 2, 3 e 4 | `revisoes/2026-10-20_guardioes_v3.md` | Entregue em 20/10 e revisada, sem ajustes |
| 2 | Textos do mapa: janelas, eventos à distância, becos e clareiras, frases prontas, nomes | Briefing v0.4, seção 4 | Entregue em 20/10 e revisada |
| 3 | Quadro de estilo do pergaminho | Briefing v0.4, seção 5 | **Próxima** |

Ao terminar uma demanda: entregar em `entregas/AAAA-MM-DD_<nome>/` e parar.

**Demanda 3:** as 3 imagens de estilo da seção 5.1 do briefing, cada uma com o prompt usado e o ponto mais fraco, em `entregas/AAAA-MM-DD_quadro_pergaminho/`. Pare depois das 3 e aguarde a escolha do usuário. Referência do que o jogo já desenha hoje: `godot/README.md`.

**Marcadores de texto:** daqui em diante, vale a tabela de `revisoes/2026-10-20_textos_mapa.md`.

## Histórico

| Data | O que aconteceu |
|---|---|
| 20/10/2026 | Regra de vitória decidida e implementada: chegada ao ponto oposto do mapa, classificação no amanhecer |
| 20/10/2026 | Etapa 2 do jogo publicada: visitas às bases, perguntas com tom e silêncio, verificação de mentiras, indicação da panela e veneno |
| 20/10/2026 | Usuário aprovou os textos do mapa; o Claude aplicou 15 ajustes de concordância (agora em `conteudo/textos/`) |
| 20/10/2026 | ChatGPT entregou os textos do mapa. Revisão: aprovado com ajustes de concordância |
| 20/10/2026 | Etapa 1 do jogo publicada em `godot/`: mapa sorteado, movimento, pegadas com calçado, visão noturna, personagens do computador |
| 20/10/2026 | Usuário aprovou o banco de guardiões v3.1 (agora em `conteudo/guardioes/`) e o catálogo de itens |
| 20/10/2026 | ChatGPT entregou os ajustes v3.1. Revisão: aprovado pelo Claude, sem novos ajustes |
| 20/10/2026 | ChatGPT entregou o banco de guardiões v3. Revisão: aprovado com 4 ajustes pequenos |
| 20/10/2026 | MVP v0.4 aprovado: mapa de pegadas visto de cima, single-player, 5 guardiões. Revisão da entrega v2 gerou as correções v3 |
| 19/10/2026 | ChatGPT entregou o banco de guardiões no formato v2 e o quadro de estilo isométrico do Bento (arquivado: o isométrico ficou para depois do MVP) |

## Pendências de decisão

- [x] **Nomes dos personagens.** O jogador escolhe o seu; os do computador são sorteados de uma lista (briefing v0.4, seção 4.5).
- [x] **Regra de vitória.** Ganha quem fizer mais pontos e chegar ao ponto oposto do mapa antes do amanhecer.
- [ ] **Valores dos pontos.** Proposta em `docs/sistemas/pontuacao_v1.md`.
- [x] **Catálogo de itens do inventário.** Aprovado: `docs/sistemas/itens_v1.md` e `conteudo/itens.json`.
