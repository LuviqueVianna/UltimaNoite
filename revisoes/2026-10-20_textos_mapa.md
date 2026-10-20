# Revisão — textos do mapa (demanda 2, entrega de 20/10/2026)

**Revisor:** Claude · **Data:** 20/10/2026 · **Entrega:** `entregas/2026-10-20_textos_mapa/`

**Resultado:** aprovada com 15 ajustes de concordância (5 janelas e 10 frases), causados por uma lacuna do briefing (não dizia como o jogo preenche os marcadores). Os ajustes são mecânicos e o Claude os aplica ao copiar para `conteudo/`, se o usuário aprovar.

## O que está bom

- Contagens exatas: 50 janelas, 28 eventos, 48 descobertas, 48 frases, 24 nomes.
- Sinais de mentira fiéis e sutis nas janelas (o sino parado do Anselmo, a mão no avental da Iara). Na Iara sozinha, a tigela "com as duas mãos" ensina o sinal sincero.
- Ambientação de Mata Atlântica consistente; o sobrenatural só sugerido (a cadeira que balança na Tapera).
- Frases prontas neutras o bastante para servir como verdade ou mentira.
- Nomes com cara de interior, todos com até 12 caracteres.

## Como o jogo preenche os marcadores

| Marcador | Valores | Usar assim |
|---|---|---|
| `{calcado}` | bota de couro, botina, alpercata, tamanco, pé descalço | Só depois de "de": "pegadas de {calcado}" |
| `{calcado_par}` (novo) | botas de couro, botinas, alpercatas, tamancos, pés descalços | "um par de {calcado_par}" |
| `{base}` | Cabana do Caçador, Casa da Curandeira, Capela dos Segredos, Torre do Vigia, Moinho Abandonado, Tapera | Depois de "em", "de", "a", "para"; nunca "na {base}" |
| `{item}` | Com artigo e minúsculo: um maço de ervas, uma lamparina... | "encontrei {item}" |
| `{lado}` | esquerda, direita | "a panela da {lado}" |
| `{personagem}` | Nome | Qualquer posição |

## Ajustes

| Arquivo | ID ou texto | Antes | Depois |
|---|---|---|---|
| janelas | bento_janela_05, iara_janela_05, anselmo_janela_05, marta_janela_05, quincas_janela_05 | `{calcado}` | `{calcado_par}` |
| frases | identidade | "{personagem} usa {calcado}." | "{personagem} deixa pegadas de {calcado}." |
| frases | identidade | "O {calcado} pertence a {personagem}." | "As marcas de {calcado} são de {personagem}." |
| frases | identidade | "Reconheci {personagem} pelo {calcado}." | "Reconheci {personagem} pelas pegadas de {calcado}." |
| frases | identidade | "Vi {personagem} calçando {calcado}." | "Vi {personagem} deixando pegadas de {calcado}." |
| frases | identidade | "Quem usa {calcado} é {personagem}." | "Quem deixa pegadas de {calcado} é {personagem}." |
| frases | identidade | "Comparei as pegadas: {calcado} é de {personagem}." | "Comparei: as pegadas de {calcado} são de {personagem}." |
| frases | pedido | "Diga quem usa {calcado}." | "Diga de quem são as pegadas de {calcado}." |
| frases | pedido | "Confirme se {personagem} usa {calcado}." | "Confirme se {personagem} deixa pegadas de {calcado}." |
| frases | panela | "Na {base}, a panela da {lado} é segura." | "Em {base}, a panela da {lado} é segura." |
| frases | panela | "Na {base}, eu escolheria a panela da {lado}." | "Em {base}, eu escolheria a panela da {lado}." |

Para as próximas demandas, a tabela de marcadores acima passa a valer como regra.

## Aplicação

Aprovado pelo usuário em 20/10/2026, com os ajustes aplicados pelo Claude (sem nova volta ao ChatGPT). Conteúdo em `conteudo/textos/` e `conteudo/nomes.json`.
