# Demanda 5 — Guardiões menos previsíveis e armadilhas

> Para o ChatGPT. Criada pelo Claude em 22/10/2026, a pedido do usuário.
> Leia antes: `STATUS.md`, `docs/briefings/BRIEFING_GPT_v0.4.md` (papéis e regras gerais), `docs/correcoes/CORRECOES_guardioes_v3.md` (formato v3 e vocabulário) e os bancos aprovados em `conteudo/guardioes/`.
> Mudanças de regra: listar à parte como **PROPOSTA**. Não alterar decisões por conta própria.

---

## 1. O problema

O usuário testou e achou **fácil demais** agradar os guardiões. O motor já ficou mais exigente:
- 4 ou 5 perguntas por visita.
- Confiança máxima só no topo da escala.
- Marta e Bento começam desconfiados.
- O gesto de mentira nem sempre é percebido.
- Panela ruim vale −3.

Falta a parte do conteúdo: **a melhor resposta é fácil de adivinhar.** Dois motivos:

1. **A personalidade de cada um é previsível.** Depois de uma ou duas visitas o jogador aprende o que cada um quer ouvir e repete isso sempre. Na Iara, por exemplo, nas 13 perguntas com uma resposta de boa intenção, essa resposta é sempre a melhor.
2. **A melhor resposta "grita".** O texto dela soa exatamente como o valor do guardião, e as outras soam como erro.

Cada partida tem os mesmos 5 guardiões. O jogador vai conhecê-los, e está tudo bem. O que precisamos é que **conhecer o guardião ajude, mas não resolva**.

---

## 2. Entregas

Entregar em `entregas/AAAA-MM-DD_demanda5/`, com `LEIAME.md` (o que foi feito, o que ficou mais fraco, PROPOSTAS). Fazer **commit e push só dessa pasta** e parar.

| Parte | Arquivo | O que é |
|---|---|---|
| A | `guardioes/<guardiao>.json` (5 arquivos) | Banco completo de cada guardião, revisado (seção 3) e com as perguntas novas (seção 4) |
| B | `armadilhas_trilha.json` | Textos de armadilha no meio da trilha (seção 5) |
| C | No `LEIAME.md` | A tabela da seção 6 |

---

## 3. Parte A1 — Revisar as perguntas que já existem

Para **cada guardião**, revisar as perguntas aprovadas (`_04` a `_17`) de modo que:

1. **Em pelo menos 6 perguntas, a melhor resposta é um dilema, não o estereótipo.** São perguntas em que dois valores do próprio guardião se chocam. Exemplos de choque:
   - Iara: bondade contra honestidade. Ajudar alguém mentindo para ele.
   - Bento: coragem contra franqueza. Admitir que teve medo.
   - Anselmo: confissão contra prudência. Contar algo que prejudica outra pessoa.
   - Marta: informação contra lealdade. Uma informação que só se consegue traindo alguém.
   - Quincas: lucro agora contra lucro depois. Dar de graça para ganhar confiança.
   
   A resposta que só repete o estereótipo ("sempre ajudo", "não tenho medo de nada") deve valer **menos** que a que mostra o conflito com honestidade.
2. **A melhor resposta não pode "gritar".** As três respostas devem soar igualmente plausíveis, com comprimento e tom parecidos. Nada de uma resposta claramente "certinha" ao lado de duas claramente erradas.
3. **Diferença pequena entre as boas.** Em pelo menos 10 das perguntas de cada guardião, a melhor e a segunda melhor diferem em **no máximo 1 ponto**. (Hoje a regra é 2 pontos em 8 de 12.)
4. **A resposta "simpática" nem sempre vence.** Em cada guardião, ao menos 4 perguntas em que a resposta mais gentil ou altruísta vale 0 ou menos.

**Não mexer** nas perguntas `verificavel: true` além de afinidade, `tom` e redação que não mude o fato. O jogo confere essas respostas **pela posição** (0, 1, 2, extra), em `conteudo/guardioes/verificacao.json`. Nessas perguntas:
- não trocar a ordem das respostas;
- não mudar o fato que cada uma afirma.

Os `modificadores_tom` de cada guardião ficam como estão.

---

## 4. Parte A2 — Perguntas novas

**6 perguntas novas por guardião** (IDs `_18` a `_23`), para o jogador não ver as mesmas perguntas toda noite.

- Pelo menos **3 das 6** já devem seguir as regras 1 a 4 da seção 3.
- Pelo menos **1 das 6 sobre armadilhas** (as armadilhas agora existem no jogo):
  - **Premissas:** `notou_armadilha` (o jogador viu uma armadilha antes de pisar) ou `acionou_armadilha` (pisou numa).
  - **Fatos verificáveis:** `armadilhas_acionadas` (número de armadilhas em que pisou) e `notou_armadilha` (`true` ou `false`).
  - **Bento e Quincas** ainda não têm nenhuma pergunta sobre armadilhas.
- As outras podem usar qualquer mecânica e premissa do vocabulário (formato v3, seção 3), inclusive as novas da demanda 4: `cobra_avisou`, `cobra_picou`, `cobra_desviou`, `lobo_derrubou`.

Como funcionam as armadilhas, para escrever certo:
- Ficam escondidas nas trilhas, mais no fim dos becos.
- Quem tem Inteligência nota antes e passa por elas sem disparar.
- Quem pisa fica preso alguns segundos e depois anda devagar.
- Uma armadilha disparada fica à vista de todos, e quem estiver perto ouve o estalo.

Todas as regras de qualidade das correções v2 e v3 continuam valendo:
- mentira abaixo da pior resposta;
- respostas "más" tentadoras;
- quem não teve o fato não sai perdendo;
- no máximo metade das opções extras empatando ou superando a melhor.

---

## 5. Parte B — Armadilha no meio da trilha (`armadilhas_trilha.json`)

O jogo usa os textos de `clareiras.json`, mas eles falam de "beco" e "clareira", e a maioria das armadilhas fica no meio da trilha. Mesmo formato de `clareiras.json`, com `"local": "trilha"`:

| `conteudo` | Quando | Quantidade |
|---|---|---|
| `armadilha_notada` | O jogador viu a armadilha antes de pisar e passa por ela. O texto deve deixar claro que ele **desviou** | 3 |
| `armadilha_acionada` | O jogador pisou. O jogo acrescenta depois a linha "Você fica preso por N s e depois anda devagar." | 3 |

Até 15 palavras, ambientação de sempre, sem nomear personagens.

---

## 6. Tabela para o `LEIAME.md`

Para cada guardião, uma linha por pergunta **alterada ou nova**:

| Id | Valor em choque (se for dilema) | Resposta "estereótipo" e quanto vale | Melhor resposta e quanto vale |
|---|---|---|---|

Assim o Claude confere as regras 1 a 4 sem ter de adivinhar a intenção.

---

## 7. Ao terminar

Entregar em `entregas/AAAA-MM-DD_demanda5/`, fazer commit e push só dessa pasta, e **parar**. O Claude revisa e o usuário aprova antes de qualquer arquivo entrar em `conteudo/`.
