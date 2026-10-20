# Validação do formato v2

Resultado da execução de `validar.ps1`: **APROVADO — 75/75 entradas válidas**.

## Testes automáticos aprovados

- Cinco arquivos JSON válidos, todos com `versao_formato: 2`.
- Exatamente 15 entradas por guardião: 1 narração, 2 falas e 12 perguntas.
- 75 IDs únicos, sequenciais e no padrão de cada guardião.
- Modificadores de tom completos e dentro da faixa de -2 a +2.
- Afinidades inteiras entre -4 e +4 e intenções limitadas a `boa`, `ma` ou `null`.
- Toda pergunta verificável contém explicação, dependências válidas e penalidade de mentira.
- Penalidade de mentira estritamente pior que a resposta de menor afinidade.
- `requer` limitado às 14 mecânicas existentes no GDD.
- Estruturas `registra`, `contradiz`, `contradicao`, `tom`, `opcao_extra` e `silencio` válidas.
- Pelo menos 8 de 12 perguntas sem diferença superior a 2 entre a melhor e a segunda resposta.
- No máximo metade das opções extras iguala ou supera a melhor resposta comum.
- Iara possui maioria de perguntas verificáveis.
- Marta possui silêncio positivo na maioria das perguntas.
- Anselmo usa `registra`, `contradiz` e `contradicao` em pelo menos quatro perguntas.

## Revisão editorial

- **Bento:** coragem e franqueza substituem altruísmo; confissão de medo é premiada e há duas situações explícitas de delação direta.
- **Iara:** nove perguntas verificáveis detectam bondade fingida; escolhas egoístas são plausíveis em vez de caricatas; a criança foi removida.
- **Anselmo:** confissões difíceis continuam premiadas e quatro perguntas cruzam marcas do histórico.
- **Marta:** delação permanece valiosa, proteção tem custo e oito perguntas aceitam silêncio prudente com afinidade positiva.
- **Quincas:** inventário e trocas substituem promessas e itens ocultos; mentira comercial recebe penalidade forte.
- Cada guardião contém ao menos quatro conflitos de valores com outro guardião, sobretudo delação/proteção, franqueza/cautela, confissão/reputação e lucro/altruísmo.
- Não foram introduzidos personagens ou elementos externos ao mundo definido.

## PROPOSTAS

Nenhuma. As correções foram executadas sem acrescentar mecânicas ou alterar decisões do GDD.
