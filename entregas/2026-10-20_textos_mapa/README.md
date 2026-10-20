# Textos do mapa — demanda 2

Entrega da demanda 2 indicada no `STATUS.md`, seguindo a seção 4 do `docs/briefings/BRIEFING_GPT_v0.4.md` e a ambientação da seção 1.1 de `docs/arte/DIRECAO_DE_ARTE_v1.md`.

## Conteúdo

| Arquivo | Conteúdo | Entradas |
|---|---|---:|
| `janelas.json` | Cenas vistas nas cinco bases e na base vazia | 50 |
| `eventos_distancia.json` | Sons verdadeiros ouvidos de longe | 28 |
| `clareiras.json` | Descobertas em becos e clareiras sem base | 48 |
| `frases_prontas.json` | Mensagens parametrizadas entre personagens | 48 |
| `nomes.json` | Nomes sorteáveis para personagens do computador | 24 |

Total: **198 entradas**, todas com `versao_formato: 1`.

## Critérios aplicados

- Português do Brasil, frases curtas e clima de suspense.
- Limite de 15 palavras nos textos gerais, 12 nos eventos à distância e 10 nas frases prontas.
- Marcadores restritos a `{direcao}`, `{calcado}`, `{personagem}`, `{base}`, `{lado}` e `{item}`.
- Nenhum item de inventário foi inventado: os textos de descoberta e comunicação usam `{item}`.
- Três cenas para cada situação de cada guardião, preservando o sinal de mentira aprovado.
- Cinco cenas exclusivas de `sem_ninguem` para a base vazia.
- Quatro variações para cada um dos sete gatilhos de som, sempre com `{direcao}`.
- Três variações para cada combinação de local e conteúdo em becos e clareiras.
- Oito frases para cada categoria, formuladas para poderem ser verdadeiras ou falsas.
- Doze nomes masculinos seguidos de doze femininos, todos únicos e com até 12 caracteres.
- Ambientação de Mata Atlântica e interior rural de meados do século XX, sem sobrenatural explícito.

## Validação

Executar nesta pasta:

```powershell
./validar.ps1
```

Resultado esperado:

```text
VALIDO: 5 arquivos, 198 entradas e formato 1.
Janelas: 50 | Eventos: 28 | Descobertas: 48 | Frases: 48 | Nomes: 24
```

O validador confere JSON, versão, contagens, IDs, combinações obrigatórias, limites de palavras, marcadores, sinais de mentira, nomes únicos e divisão de gênero da lista revisada.

## Ponto mais fraco

As frases prontas são deliberadamente neutras para funcionarem como verdade ou mentira. Essa flexibilidade limita a personalidade individual das mensagens, mas evita que o texto revele a veracidade antes da decisão do jogo.

## PROPOSTAS

Nenhuma. A entrega segue somente as decisões já aprovadas para a demanda 2.
