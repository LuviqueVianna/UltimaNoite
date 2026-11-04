# Lógica do MVP (cópia)

Cópia da lógica do jogo 2D (`../../../godot/scripts/`: regras, dados, textos, `mapa/` e `mundo/`), do commit `d4376ec`.
O protótipo 3D roda **as mesmas regras**: mapa sorteado de 450 × 450 m, personagens do computador, pegadas, animais e armadilhas.
Só a apresentação é nova (`../apresentacao/`).

Diferenças: `VEL_TRILHA` = 4 m/s, a velocidade do primeiro protótipo 3D, aprovada pelo usuário (no MVP 2D está em 10 m/s para testes).

Quando o 3D for adiante, as duas cópias devem virar uma só (um módulo de lógica usado pelos dois projetos).

Outra diferença: `mundo/fauna.gd` lia `Dialogo.NOMES_ATRIBUTO` da tela de diálogo do MVP (a lógica dependia da interface). Na cópia, a tabela está no próprio `fauna.gd`.
