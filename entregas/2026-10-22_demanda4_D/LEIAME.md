# Demanda 4 — revisão somente da parte D

**22/10/2026 · Para revisão do Claude e aprovação do usuário.**

Base: revisão `45bb450` do repositório, após `git pull --ff-only`. Referência: seção 3 de `revisoes/2026-10-22_demanda4.md`, pontos D1 a D4.

## Entrega

[guardioes_animais.json](guardioes_animais.json): dez perguntas, duas por guardião, formato v3, com os mesmos IDs 16 e 17. Todas mantêm `requer: ["animais"]`; as perguntas 16 exigem `cobra_avisou`, e as 17 exigem `lobo_derrubou`.

Somente esta pasta integra o novo commit. A entrega original, o conteúdo aprovado, o código e as demais partes da demanda não foram editados. C continua aguardando a audição pelo usuário; a demanda 3 permanece em pausa.

## D1 — vozes e afinidades da cobra

As três situações foram mantidas na mesma ordem, com redação própria em cada guardião. As perguntas agora abordam franqueza, respeito ao animal, confissão, precisão e custo, respectivamente.

| Guardião | Parou, sem picada | Passou e foi picado | Aviso sem desfecho | Critério |
|---|---:|---:|---:|---|
| Bento | +1 | +3 | +3 | Prefere assumir o risco a evitá-lo; não penaliza a ausência de desfecho. |
| Iara | +3 | −1 | +3 | Valoriza dar espaço ao bicho; desaprova passar por pressa. |
| Anselmo | +2 | +2 | +2 | O relato verdadeiro vale igualmente nos três casos. |
| Marta | +2 | +3 | +3 | Premia distinguir picada confirmada de susto e delimitar o que se sabe. |
| Quincas | +2 | −1 | +2 | Aceita gastar tempo para evitar um custo; desaprova a aposta que saiu cara. |

O mesmo ato de passar e sofrer picada rende +3 com Bento e −1 com Iara ou Quincas. Esse contraste é de afinidade, não uma alteração da regra dos animais. Sem desfecho continua valendo o mesmo que a melhor resposta: ninguém perde pontos de afinidade por não ter concluído o encontro.

## D2 — opções extras respondem à pergunta

As cinco extras da cobra agora relatam uma situação concreta. Seus fatos entram expressamente em `verificacao`, inclusive o caso ainda sem desfecho; não há mais comentário genérico sobre como conversar. A extra de `quincas_17` também foi tornada explícita: a indicação vale mais pelo atraso, mas há um limite de preço.

| Pergunta | Condição factual da extra | Afinidade |
|---|---|---:|
| `bento_16` | `cobra_reacao = parou` | +2 |
| `iara_16` | `cobra_reacao = passou` | +1 |
| `anselmo_16` | `cobra_reacao = passou` | +2 |
| `marta_16` | `cobra_reacao` ausente | +2 |
| `quincas_16` | `cobra_reacao = passou` | +1 |

Apenas a extra de Anselmo empata com a melhor resposta comum: uma entre suas duas extras. Nos demais guardiões, nenhuma extra alcança o topo. A mentira continua em −4, abaixo de todas as respostas e extras das perguntas verificáveis.

## D3 — Iara depois da queda

`iara_17` pergunta **como o jogador quer seguir depois do susto**. As três respostas e a extra são posições presentes possíveis: cuidar de si sem descontar nos outros, priorizar a chegada, pedir sossego ou moderar o passo. A melhor resposta está disponível honestamente; foi removida a alegação impossível de ter ficado imóvel até ser derrubado.

A pergunta passou a `verificavel: false`, sem `mentira` ou `verificacao`. Isso evita supor um registro de ações depois de levantar ou de chegada mancando, que não faz parte dos fatos autorizados na demanda. A premissa da queda permanece. O silêncio acolhedor foi preservado em +1. As escolhas não acionam novas ações nem concedem recuperação física.

## D4 — intenção em Quincas

Em `quincas_17`, a resposta de índice 2, que pede ajuda sem cobrança, passou de `intencao: "boa"` para `intencao: null`. Texto e afinidade dessa resposta permanecem iguais.

## Verificação e integração futura

Para todas as perguntas 16, os índices continuam correspondendo a:

- **0:** `cobra_reacao = parou`, com espera concluída e nenhuma picada na noite.
- **1:** `cobra_reacao = passou`, com ao menos uma picada ao seguir andando.
- **2:** `cobra_reacao` ainda ausente, apesar de `cobra_avisou` verdadeiro.

O resumo é cumulativo: `passou` prevalece mesmo se também houve uma espera em outro encontro. As respostas de picada não afirmam perda de habilidade, pois pode haver resistência ao veneno. Motivos e avaliações não ganham fatos artificiais para verificação.

Depois da aprovação, a integração deve incluir as condições das cinco extras e o tratamento de ausência do fato, conforme já previsto na seção 5 da revisão. Nenhuma mudança em `conteudo/guardioes/verificacao.json` ou no motor foi feita aqui.

## Validação

Executado `node entregas/2026-10-22_demanda4_D/validar.cjs`: **OK**. Conferidos formato, dez IDs, premissas, três respostas por pergunta, atributos, afinidades, penalidade de mentira, limite das extras, ausência de respostas repetidas entre as cinco perguntas da cobra, igualdade das três afinidades de Anselmo, contraste Bento/Iara/Quincas e correção de D4. Conferida também a preservação integral de `bento_17`, `anselmo_17` e `marta_17` e das partes não solicitadas de `quincas_17`.

Revisão manual: extras respondem diretamente; a pergunta nova da Iara não pressupõe ação posterior desconhecida; o caso sem desfecho não é penalizado. Não houve teste de jogo, pois o banco não foi integrado.

## Pontos mais fracos

- Os três resultados verificáveis ainda limitam a variedade factual. As diferenças ficaram na voz, no julgamento e nas afinidades, preservando a compatibilidade.
- A terceira resposta da cobra precisa explicitar duas ausências e tende a ser mais longa.
- A nova `iara_17` avalia uma intenção presente, não confirma comportamento passado. É a escolha editorial para eliminar a pegadinha sem ampliar o sistema de fatos.

## PROPOSTAS

Nenhuma nova proposta de regra ou sistema. A implementação do tratamento de fato ausente já está prevista na revisão recebida e fica a cargo da integração após aprovação.

Entrega encerrada para revisão; não promover estes arquivos ao conteúdo do jogo antes da aprovação.
