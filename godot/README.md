# Projeto Godot — A Última Noite (MVP)

Godot **4.3** (renderizador Compatibility). O jogo lê o conteúdo aprovado em `../conteudo/`.

## Abrir e jogar

1. Instale o Godot 4.3: https://godotengine.org/download
2. No Godot, **Importar** e escolha o arquivo `godot/project.godot` deste repositório.
3. Aperte **F5**. Na tela inicial, escolha seu nome e distribua 12 pontos nos atributos.
4. Toque ou clique num ponto conhecido do mapa para andar até lá. A roda do mouse aproxima e afasta.

## Estado

| Etapa | Conteúdo | Situação |
|---|---|---|
| 1 | Mapa sorteado, movimento, pegadas com calçado, visão noturna e memória, personagens do computador | Pronta |
| 2 | Bases e diálogo com os guardiões, panelas, veneno | A fazer |
| 3 | Armadilhas, animais, sumir na mata, itens, frases prontas | A fazer |

## Testes (sem tela)

```
godot --headless --path godot --import
godot --headless --path godot -s res://testes/teste_etapa1.gd
godot --headless --path godot -s res://testes/teste_cena.gd
```

## Organização

| Pasta | O que tem |
|---|---|
| `scripts/regras.gd` | Números do MVP (tabela de atributos, tempos, distâncias) |
| `scripts/dados.gd` | Leitura do conteúdo aprovado (`../conteudo/`) |
| `scripts/mapa/` | Gerador do mapa e o grafo de trilhas |
| `scripts/mundo/` | Personagens, inteligência do computador e o estado da noite (sem desenho) |
| `scripts/cenas/` | Tela inicial, desenho do mapa e interface |
| `testes/` | Testes automáticos e geração de capturas |
