# Animais — v1 (proposta para teste)

Decidido pelo usuário em 21/10/2026: entram no MVP **lobo, coruja e cão** (os já definidos) **e a cobra**.
O lobo que alcança alguém **derruba e atrasa**. A picada da cobra é **veneno, como a panela ruim**.

Os números abaixo são ponto de partida para teste (em `godot/scripts/regras.gd`).
Todos os animais seguem as mesmas regras para o jogador e para os personagens do computador.
O jogador só vê um animal dentro do seu alcance de vista (no modo de teste com o mapa aberto, vê todos).

Regra comum: **quem fica parado diante do perigo se sai melhor que quem corre.** O sinal de cada animal avisa antes.

| Animal | Quantos | Onde | Perigo | Aliado | Sinal |
|---|---|---|---|---|---|
| Lobo | 1 | Ronda as trilhas em volta de uma base e troca de base de tempos em tempos | Rosna e avança uns passos. Se a pessoa se mexer, persegue; se alcançar, derruba | Ferido (30% das noites): manca e não ataca | Rosnado, orelhas para trás; mancando = ferido |
| Coruja | 2 | Pousa em clareiras e muda de pouso | Olha para quem passa e pia: todos por perto ouvem de onde veio | Se outro personagem estiver perto dela, em vez de piar ela vira a cabeça para ele | Olhou para você = você foi notado |
| Cão sem dono | 1 | Anda pelas trilhas | Inquieto: late, e todos por perto ouvem de onde veio | Abana o rabo e espera; quem chega perto é guiado até uma base que ainda não visitou | Abana o rabo = guia; inquieto = late |
| Cobra | 4 | Escondida no meio das trilhas, longe das partidas e das bases | Pica quem passa andando por ela: veneno, perde 1 ponto da maior habilidade (Resistência dá chance de aguentar) | — | Folhas secas chacoalham bem perto |

## Lobo
- Percebe quem está a até **16 m**. Nunca ataca dentro de uma base nem quem já registrou a chegada.
- **Rosna por 2,5 s** e avança devagar até uns 5 m. Se a pessoa **ficar parada** o tempo todo, o lobo perde o interesse e se afasta.
- Se a pessoa **se mexer**, ele **persegue a 7 m/s** por até 15 s. Desiste se ela chegar a uma base.
- Ao alcançar: **derruba** (preso pelo tempo da tabela de Força) e depois a pessoa anda **pela metade da velocidade por 10 s** (reduzido pela Resistência, como na armadilha).
- Uiva de tempos em tempos (evento à distância). Um ataque também é ouvido por quem estiver perto.
- Depois de rosnar para alguém, ignora essa pessoa por 45 s; depois de derrubar, por 60 s.
- Ferido: anda devagar e não ataca. Ajudá-lo (ervas, carne seca) fica para quando os itens tiverem uso no mapa.

## Coruja
- Nota quem passa a até **20 m** (uma vez a cada 40 s por pessoa).
- Se outro personagem estiver a até 60 m dela: **avisa** quem ela notou, virando a cabeça na direção dele.
- Senão: **pia**. Todos a até 250 m ouvem "uma coruja piou" e a direção.
- Troca de pouso a cada 70 a 110 s.

## Cão sem dono
- Encontra quem passa a até **14 m**. Sorteia o humor: **55% guia, 45% inquieto**.
- **Guia:** abana o rabo e espera 8 s. Quem chegar a 5 m dele é levado até a base mais próxima que ainda não visitou. Ele anda a 2,5 m/s e espera se a pessoa ficar mais de 18 m para trás.
- **Inquieto:** late. Todos a até 250 m ouvem e sabem a direção. (Quando as armadilhas existirem, o cão inquieto leva até uma.)
- Depois de um encontro, ignora a pessoa por 60 a 90 s.

## Cobra
- Quem passa a até **6 m** ouve as folhas secas chacoalharem.
- Quem tem Inteligência para notar armadilhas (2 a 5 m pela tabela) também **vê** a cobra a essa distância.
- Quem **passar andando** a até 1,6 m dela é picado: veneno. Depois ela some e reaparece em outra trilha.
- Quem **ficar parado** 2 s perto dela faz a cobra ir embora (ela reaparece em outra trilha).

## Personagens do computador
- Diante do rosnado e do chacoalhar: ficam parados com chance de 30% + 12% por nível de Inteligência. Os cautelosos sempre param diante do lobo.
- Cão guia: quem não é cauteloso o segue e aprende onde fica a base.

## Para os guardiões (premissas e verificação)
- Premissas preenchidas: `encontrou_lobo`, `lobo_avancou` (rosnou e avançou), `encontrou_lobo_ferido`, `coruja_notou`, `coruja_avisou`, `cao_ofereceu_guia`.
- Novos fatos verificáveis: `lobo_reacao` ("ficou" ou "correu"), `seguiu_cao` (sim ou não).
- Fatos extras da noite: `cobra_picou`, `cobra_avisou` (ainda sem perguntas).

## Textos
- Uivo, ataque, pio e latido usam `conteudo/textos/eventos_distancia.json`.
- As falas de sinal (rosnado, folhas secas, cão abanando o rabo) são provisórias, em `regras.gd`. Pedir o banco definitivo ao ChatGPT, junto com os eventos da cobra.
