# A Última Noite

Jogo de suspense psicológico: numa noite na mata, quatro personagens visitam guardiões que oferecem duas panelas, uma boa e uma ruim. O guardião induz a escolha conforme o que pensa de você.

Este repositório é o **ponto de encontro** entre o usuário, o Claude e o ChatGPT. Tudo o que um precisa entregar ao outro passa por aqui.

## Comece por aqui

1. **[STATUS.md](STATUS.md)** — o que está acontecendo agora, quem está com qual tarefa e qual é a próxima demanda.
2. **[docs/MVP_v0.4.md](docs/MVP_v0.4.md)** — todas as decisões do MVP. É a fonte da verdade.
3. O briefing da sua próxima demanda, indicado no STATUS.

## Pastas

| Pasta | O que tem | Quem escreve |
|---|---|---|
| `docs/` | Decisões do jogo (MVP), briefings, correções e direção de arte | Claude |
| `docs/briefings/` | Pedidos ao ChatGPT, um por versão | Claude |
| `docs/correcoes/` | Listas de correção de entregas revisadas | Claude |
| `docs/arte/` | Direção de arte | Claude |
| `entregas/` | Tudo o que o ChatGPT entrega, **sem alterar depois** | ChatGPT (via usuário) |
| `revisoes/` | Revisões do Claude sobre cada entrega | Claude |
| `conteudo/` | Só conteúdo **aprovado pelo usuário**, pronto para o jogo | Claude, após aprovação |
| `godot/` | Projeto do jogo (Godot 4 + GDScript), quando começar | Claude |

## Como uma entrega circula

1. O Claude escreve o briefing em `docs/briefings/` e atualiza o `STATUS.md`.
2. O ChatGPT lê o `STATUS.md` e o briefing, e produz a entrega.
3. A entrega entra em `entregas/AAAA-MM-DD_<nome>/`, com um `README.md` dizendo o que contém e as PROPOSTAS, se houver.
4. O Claude revisa e escreve o resultado em `revisoes/`. Se houver correções, gera um arquivo em `docs/correcoes/`.
5. O usuário aprova. O Claude copia o conteúdo aprovado para `conteudo/`.

## Regras

- **Ninguém altera decisões por conta própria.** Sugestões vão como **PROPOSTA**, em lista separada.
- **Uma demanda por vez.** Ao terminar, pare e aguarde.
- **Entregas não são editadas depois de entrar em `entregas/`.** Uma correção vira uma nova entrega, com nova data.
- Nomes de arquivo sem acento e sem espaço.
