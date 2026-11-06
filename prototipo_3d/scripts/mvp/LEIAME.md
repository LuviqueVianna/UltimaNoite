# Lógica do MVP (cópia)

Cópia da lógica do jogo 2D (`../../../godot/scripts/`: regras, dados, textos, `mapa/` e `mundo/`), do commit `d4376ec`.
O protótipo 3D roda **as mesmas regras**: mapa sorteado de 450 × 450 m, personagens do computador, pegadas, animais e armadilhas.
Só a apresentação é nova (`../apresentacao/`).

Diferenças: `VEL_TRILHA` = 4 m/s, a velocidade do primeiro protótipo 3D, aprovada pelo usuário (no MVP 2D está em 10 m/s para testes).

Quando o 3D for adiante, as duas cópias devem virar uma só (um módulo de lógica usado pelos dois projetos).

Outra diferença: `mundo/fauna.gd` lia `Dialogo.NOMES_ATRIBUTO` da tela de diálogo do MVP (a lógica dependia da interface). Na cópia, a tabela está no próprio `fauna.gd`.

Terceira diferença: `mundo/mundo.gd` ganhou `mover_jogador_livre()`, para o jogador andar livre pelas trilhas e clareiras do 3D (pedido do usuário em 06/11/2026), com as mesmas regras de velocidade, pegadas, "sumir" e chegada às bases e à saída. Os personagens do computador continuam no grafo.

Quarta diferença: **vida** (pedido do usuário em 06/11/2026). Cada personagem tem 100 de vida: armadilha tira 20, lobo derrubando tira 30, picada de cobra tira 20; a primeira chegada a cada casa devolve 35; vida zero desmaia. Constantes em `regras.gd` (VIDA_MAX, DANO_*, CURA_CASA); código em `mundo.ferir()` e `mundo._curar_na_casa()`. As consequências do MVP (preso, lento, derrubado, veneno, desmaio) continuam iguais.
