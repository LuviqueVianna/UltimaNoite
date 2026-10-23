# Status do projeto

**Atualizado em:** 23/10/2026, pelo Claude.

## Agora

| Quem | Está com | Arquivo |
|---|---|---|
| **ChatGPT** | Sem demanda aberta. Aguardando a próxima | — |
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
| 4 | Animais e diálogos dos guardiões | `docs/briefings/DEMANDA_4_animais_e_guardioes.md` | Entregue em 22/10 e revisada: A, B, E e F aprovadas; C aguarda o usuário ouvir os sons |
| 4b | Refazer a parte D (perguntas sobre cobra e lobo), pontos D1 a D4 | `revisoes/2026-10-22_demanda4.md` | Entregue em 22/10, aprovada e integrada |
| 5 | Guardiões menos previsíveis e armadilhas | `docs/briefings/DEMANDA_5_guardioes_mais_dificeis.md` | Entregue em 22/10, aprovada e integrada |

Ao terminar uma demanda: entregar em `entregas/AAAA-MM-DD_<nome>/` e parar.

**Ao entregar:** fazer commit e push só da pasta da entrega, para o Claude encontrar no repositório.

**Marcadores de texto:** daqui em diante, vale a tabela de `revisoes/2026-10-20_textos_mapa.md`.

## Histórico

| Data | O que aconteceu |
|---|---|
| 23/10/2026 | Armadilhas: chance de notar pela Inteligência (0%, 10%, 30%, 50%, 70%), decidido pelo usuário; antes, Inteligência 2+ notava sempre. Sons novos (provisórios, sintetizados) para armadilha, picada de cobra e mordida do lobo. Ainda local |
| 23/10/2026 | Consequências mais pesadas (pedido do usuário, testando o jogo): veneno acumula (vista turva, 3ª dose desmaia), lobo segue o faro de quem derrubou, base como refúgio com o lobo esperando à porta (esperar, fundos ou frente), guardiões reagem a quem chega ferido ou envenenado. Sumir na mata (F) e moita das bases implementados. Itens adiados. Ainda local, aguardando o usuário fechar ([regras](docs/sistemas/consequencias_v1.md)) |
| 22/10/2026 | Demanda 5 aprovada e integrada: 20 perguntas por guardião, dilemas em vez de estereótipos, textos de armadilha na trilha. Marta começa com −2. Ondas no mapa mostram de onde vêm os sons |
| 22/10/2026 | Tela de configurações (névoa, tracejado das trilhas, alcance dos animais) e tutorial "Como jogar". Jogo mais difícil: panela ruim −3, opção de não comer, afinidade alta só no máximo, Marta e Bento começam desconfiados, gesto de mentira nem sempre percebido. Armadilhas no mapa. Desempenho no navegador e sons mais altos |
| 22/10/2026 | Demanda 5 criada para o ChatGPT: perguntas dos guardiões menos previsíveis, 6 novas por guardião e textos de armadilha |
| 22/10/2026 | Névoa de volta, com chave para o usuário ligar e desligar (tela inicial e tecla N). Cobra corrigida: o chacoalhar vem com tempo de parar em qualquer velocidade e mostra no mapa de onde vem. Ainda em modo de teste: jogador a 10 m/s e alcance dos animais desenhado |
| 22/10/2026 | Parte D da demanda 4 aprovada e integrada: 10 perguntas sobre cobra e lobo, conferidas contra o que aconteceu na noite |
| 22/10/2026 | Textos aprovados da demanda 4 integrados ao jogo (sinais dos animais, indicação, panelas, cobra ouvida de longe). Computador não desiste da saída depois de decidir ir: chegada voltou a 24 de 24 no teste |
| 22/10/2026 | Demanda 4 entregue e revisada: sinais dos animais, indicação e panelas aprovados; perguntas da parte D voltam para ajuste |
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
