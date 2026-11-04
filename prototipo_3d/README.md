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
| W A S D / setas | Andar (só pelas trilhas e clareiras; a mata é parede) |
| Roda do mouse | Aproximar e afastar |
| Q / E | Girar a câmera 90° |
| F | Liga e desliga a mata transparente perto do jogador |
| N | Liga e desliga a neblina rasteira |
| L | Liga e desliga a luz de visão do jogador |
| P | Tamanho das pegadas: 1x (real), 1,5x, 2x |
| V | Ver tudo (ignora a linha de visada; para depurar) |
| H | Esconde os textos da tela |

O canto superior esquerdo mostra FPS, chamadas de desenho e triângulos: **é o número que interessa medir no seu PC**.

## O que tem na cena

- Trecho de 160 × 160 m de Mata Atlântica fechada: cerca de 4.100 árvores (jequitibá, embaúba, palmeira, bambu, árvores comuns) e 10.400 plantas de sub-bosque (samambaia, bromélia, moita).
- Trilhas com bifurcação e beco, uma clareira vazia e a clareira da **Cabana do Bento**, montada pela Direção de Arte v1, seção 3.1.
- Lua cheia vinda do canto superior esquerdo da tela, luz âmbar da janela e da porta, fumaça na chaminé, neblina rasteira.
- Jogador de **bota de couro**; outro personagem **descalço** andando sozinho pela trilha do sudeste; pegadas de **botina** do dono da casa levando à porta.
- Câmera isométrica **ortográfica**, como aprovado para a etapa intermediária.

Formas, cores e figuras são **provisórias** (primitivas do Godot). O protótipo testa técnica, não arte.

## Organização (mesma regra do MVP)

| Pasta | Camada | O que tem |
|---|---|---|
| `scripts/logica/` | Mundo (sem desenho) | Terreno, trilhas, mata, personagens, pegadas e **visão por linha de visada** |
| `scripts/apresentacao/` | Apresentação | Mata (MultiMesh por quadra de 32 m), cabana, pegadas em decalque, personagens, câmera e luz |
| `shaders/` | Apresentação | Mata (vento, tufos, transparência perto do jogador) e chão (barro e folhas) |
| `testes/` | — | Teste da lógica sem tela |

## Testes sem tela

```
godot --headless --path prototipo_3d --import
godot --headless --path prototipo_3d -s res://testes/teste_logica.gd
```

Capturas automáticas (precisa de tela ou de um servidor X virtual):

```
godot --path prototipo_3d -- --captura <pasta>
```
