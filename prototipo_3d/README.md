# Protótipo técnico 3D — A Última Noite

Passo 3 da `ANALISE_3D_v1.md` (decisões de 03/11/2026: Godot, PC, protótipo técnico).
Projeto **separado** do MVP (`../godot`): não muda nada no jogo atual.

## Abrir

1. Instale o **Godot 4.7.1** ou mais novo, versão padrão (não precisa da .NET): https://godotengine.org/download
   O MVP continua no 4.3; os dois podem conviver no mesmo computador.
2. No Godot, **Importar** e escolha `prototipo_3d/project.godot`.
3. Aperte **F5**. A primeira abertura demora alguns segundos (compila os shaders).

## Versão para navegador

Para testar em computador sem Godot. Exporte com o preset **Web** (`export_presets.cfg`); o Godot troca sozinho para o renderizador Compatibility. Diferenças: névoa rasteira simples em vez da volumétrica e pegadas como planos no chão (no navegador não há decalques). Fica bem mais lento (7 a 9 FPS no teste de 03/11/2026, contra 39 no PC).

## Controles

| Tecla | O que faz |
|---|---|
| W A S D / setas | Andar livre pelas trilhas e clareiras (a mata e as casas são parede). Diante do lobo e da cobra, quem fica parado se sai melhor |
| Roda do mouse | Aproximar e afastar (nas duas câmeras) |
| Q / E | Girar a câmera 90° (isométrica) |
| C | Alterna entre a câmera isométrica e a **terceira pessoa** |
| Mouse | Olhar em volta (terceira pessoa); clique para prender o mouse, Esc para soltar |
| F | Liga e desliga a mata transparente perto do jogador |
| N | Liga e desliga a neblina rasteira |
| L | Liga e desliga a luz de visão do jogador |
| P | Tamanho das pegadas: 1x (real), 1,5x, 2x |
| V | Ver tudo (mostra animais, pegadas, armadilhas e personagens fora do alcance; para depurar) |
| H | Esconde os textos da tela |

O canto superior esquerdo mostra FPS, chamadas de desenho e triângulos: **é o número que interessa medir no seu PC**.

## O que tem na cena

Desde 04/11/2026 o protótipo roda **a noite inteira do MVP**, com a lógica do jogo 2D (cópia em `scripts/mvp/`):

- **Mapa sorteado de 450 × 450 m** (o mesmo gerador do MVP), com cerca de 34 mil árvores e 84 mil plantas de sub-bosque, para testar desempenho.
- **As seis bases** montadas pela Direção de Arte v1: Cabana do Caçador (Bento), Casa da Curandeira (Iara), Capela dos Segredos (Anselmo), Torre do Vigia (Marta), Moinho Abandonado (Quincas) e a Tapera vazia. Cada uma com sua luz e seus pontos de interesse.
- **Três personagens do computador** andando, visitando bases e deixando pegadas, com a mesma inteligência do MVP.
- **Animais com as regras do MVP** (`docs/sistemas/animais_v1.md`): lobo que rosna, persegue quem corre e derruba; corujas que pousam em mourões, piam ou viram a cabeça para avisar; cão que guia ou late; cobras escondidas na trilha que chacoalham as folhas e picam quem continua andando.
- **Armadilhas** escondidas na trilha (aparecem para quem nota, ou depois de disparadas), veneno, desmaio, chegada à saída e amanhecer.
- **Vida** (barra no canto inferior esquerdo, regra nova pedida em 06/11/2026): armadilha tira 20, lobo derrubando tira 30, picada de cobra tira 20; a primeira chegada a cada casa devolve 35; vida zero desmaia. Preso, lento, derrubado, veneno e desmaio continuam como no MVP.
- **Saída**: porteira aberta com dois lampiões no lado oposto do mapa (com uma luz alta para dar rumo de longe). O canto da tela mostra a distância e a direção; chegar nela registra a chegada.
- **Folhagem**: copas, samambaias, palmeiras e embaúbas feitas de cartões com folhas recortadas (texturas desenhadas na montagem, sem arquivo de imagem); relevo na casca e no chão.
- **Ainda sem as conversas com os guardiões**: chegar a uma base não abre o diálogo.
- Sons do MVP em 3D (uivo, rosnado, pio, latido, folhas, armadilha), grilos e vagalumes.

Formas, cores e figuras são **provisórias** (primitivas do Godot). O protótipo testa técnica, não arte.

## Organização (mesma regra do MVP)

| Pasta | Camada | O que tem |
|---|---|---|
| `scripts/mvp/` | Regras do jogo (sem desenho) | Cópia da lógica do MVP 2D: mapa, personagens, inteligência, animais, armadilhas, visitas |
| `scripts/logica/` | Terreno (sem desenho) | Trilhas e clareiras abertas na mata a partir do mapa do MVP, a mata em volta e a **visão por linha de visada** |
| `scripts/apresentacao/` | Apresentação | Mata (MultiMesh por quadra de 32 m), cabana, pegadas em decalque, personagens, câmera e luz |
| `shaders/` | Apresentação | Mata (vento, tufos, transparência perto do jogador) e chão (barro e folhas) |
| `testes/` | — | Teste da lógica sem tela |

## Testes sem tela

```
godot --headless --path prototipo_3d --import
godot --headless --path prototipo_3d -s res://testes/teste_mundo.gd
```

Capturas automáticas (precisa de tela ou de um servidor X virtual):

```
godot --path prototipo_3d -- --captura <pasta>
```
