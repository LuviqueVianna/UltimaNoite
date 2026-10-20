# Projeto Godot — A Última Noite (MVP)

Godot **4.3** (renderizador Compatibility). O jogo lê o conteúdo aprovado em `../conteudo/`.

## Abrir e jogar

1. Instale o Godot 4.3: https://godotengine.org/download
2. No Godot, **Importar** e escolha o arquivo `godot/project.godot` deste repositório.
3. Aperte **F5**. Na tela inicial, escolha seu nome e distribua 12 pontos nos atributos.
4. **Para andar:** use as setas ou W, A, S, D (o personagem segue a trilha que aponta para aquela direção e para quando você solta a tecla), ou clique numa trilha visível. A roda do mouse aproxima e afasta.
5. Ao chegar numa base: olhe pela janela, entre, responda escolhendo o tom (10 s de silêncio contam como resposta) e escolha uma das duas panelas.

## Estado

| Etapa | Conteúdo | Situação |
|---|---|---|
| 1 | Mapa sorteado, movimento, pegadas com calçado, visão noturna e memória, personagens do computador | Pronta |
| 2 | Bases e diálogo com os guardiões, panelas, veneno ([regras](../docs/sistemas/visitas_v1.md)) | Pronta |
| 3 | Armadilhas, animais, sumir na mata, itens, frases prontas | A fazer |

## Testes (sem tela)

```
godot --headless --path godot --import
godot --headless --path godot -s res://testes/teste_etapa1.gd
godot --headless --path godot -s res://testes/teste_etapa2.gd
godot --headless --path godot -s res://testes/teste_cena.gd
```

## Organização

| Pasta | O que tem |
|---|---|
| `scripts/regras.gd` | Números do MVP (tabela de atributos, tempos, distâncias) |
| `scripts/dados.gd` | Leitura do conteúdo aprovado (`../conteudo/`) |
| `scripts/mapa/` | Gerador do mapa e o grafo de trilhas |
| `scripts/mundo/` | Personagens, inteligência do computador, visitas às bases e o estado da noite (sem desenho) |
| `scripts/cenas/` | Tela inicial, desenho do mapa e interface |
| `testes/` | Testes automáticos e geração de capturas |
