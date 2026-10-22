# Status do projeto

**Atualizado em:** 22/10/2026, pelo Claude.

## Agora

| Quem | Está com | Arquivo |
|---|---|---|
| **ChatGPT** | **Demanda 4**: sinais dos animais, cobra nos textos do mapa, sons sugeridos, perguntas dos guardiões sobre cobra e lobo, falas de indicação e resultado das panelas | [docs/briefings/DEMANDA_4_animais_e_guardioes.md](docs/briefings/DEMANDA_4_animais_e_guardioes.md) |
| **Claude** | Código do MVP em Godot: etapas 1 e 2 prontas, animais prontos (modo de teste ligado); segue a etapa 3 (armadilhas, itens, sumir na mata) | [godot/README.md](godot/README.md) |
| **Usuário** | Aprovar os valores dos pontos; testar os animais; mandar a demanda 4 ao ChatGPT | [docs/sistemas/pontuacao_v1.md](docs/sistemas/pontuacao_v1.md) |

## Fila do ChatGPT

Leia antes: [docs/briefings/BRIEFING_GPT_v0.4.md](docs/briefings/BRIEFING_GPT_v0.4.md).

| Ordem | Demanda | Referência | Estado |
|---|---|---|---|
| 1 | Correções do banco de guardiões (formato v3) | `docs/correcoes/CORRECOES_guardioes_v3.md` | Entregue em 20/10 e revisada |
| 1b | Ajustes da revisão: itens 1, 2, 3 e 4 | `revisoes/2026-10-20_guardioes_v3.md` | Entregue em 20/10 e revisada, sem ajustes |
| 2 | Textos do mapa: janelas, eventos à distância, becos e clareiras, frases prontas, nomes | Briefing v0.4, seção 4 | Entregue em 20/10 e revisada |
| 3 | Quadro de estilo do pergaminho | Briefing v0.4, seção 5 | **Em pausa, provavelmente será descontinuada** (visual definido pelo usuário em 20/10; ver `docs/MVP_v0.4.md`, seção 3). Não fazer |
| 4 | Animais e diálogos dos guardiões | `docs/briefings/DEMANDA_4_animais_e_guardioes.md` | **Fazer agora** |

Ao terminar uma demanda: entregar em `entregas/AAAA-MM-DD_<nome>/` e parar.

**Demanda 4:** seis partes (A a F) descritas no arquivo da demanda, entregues juntas em `entregas/AAAA-MM-DD_demanda4/`, com um `LEIAME.md`. Pare depois da entrega e aguarde a revisão.

**Marcadores de texto:** daqui em diante, vale a tabela de `revisoes/2026-10-20_textos_mapa.md`.

## Histórico

| Data | O que aconteceu |
|---|---|
| 22/10/2026 | Demanda 4 criada para o ChatGPT (animais e diálogos dos guardiões). Demanda 3 continua em pausa e deve ser descontinuada |
| 21/10/2026 | Animais no jogo: lobo, coruja, cão e cobra, com sons livres (CC0) e regras em `docs/sistemas/animais_v1.md`. Câmera presa ao mapa, placar do amanhecer centralizado, versão para navegador. **Modo de teste ligado** (`regras.gd`): mapa sem névoa, jogador a 10 m/s e alcance dos animais desenhado |
| 21/10/2026 | Caminho para o 3D aprovado: lógica separada da apresentação no código, etapa intermediária em 3D com câmera isométrica ortográfica, 3D completo no futuro ([docs/caminho_3D_v1.md](docs/caminho_3D_v1.md)) |
| 20/10/2026 | Segunda rodada de ajustes: jogador a 5 m/s, computador acelera até a saída depois da chegada do jogador, caixas de resposta do diálogo corrigidas |
| 20/10/2026 | Rodada de ajustes do usuário: 50 s para responder, jogador 2x mais rápido, mensagens somem em 6 s, mapa 450 × 450 m, computador mais lento, mata fechada, trilha tracejada e contraste para daltonismo |
| 20/10/2026 | Mata desenhada no mapa: copas e embaúbas em tinta, reveladas com a névoa. Conversa entre jogadores fica para depois (decisão do usuário) |
| 20/10/2026 | Pegadas com mais contraste (borda clara, trilha discreta) e duração de 15 a 20 s, a pedido do usuário |
| 20/10/2026 | Visual do mapa definido pelo usuário e implementado: pergaminho manchado sob a névoa, trilhas em tinta, pegadas de sola e salto. Movimento por setas e WASD |
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
- [ ] **Conversa entre jogadores** (frases prontas): só de perto ou também de longe? Adiada pelo usuário em 20/10/2026.
- [ ] **Valores dos pontos.** Proposta em `docs/sistemas/pontuacao_v1.md`.
- [x] **Catálogo de itens do inventário.** Aprovado: `docs/sistemas/itens_v1.md` e `conteudo/itens.json`.
