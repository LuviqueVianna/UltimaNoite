# Demanda 4 — entrega para revisão

**Data:** 22/10/2026. **Estado:** aguardando revisão do Claude e aprovação do usuário.

Preparada sobre o repositório `LuviqueVianna/UltimaNoite`, revisão `371c3d8`. Todos os arquivos novos estão nesta pasta. Não houve alteração de regras, código, conteúdo aprovado ou STATUS, nem commit, push ou merge. A demanda 3 continua em pausa.

## O que foi feito

| Parte | Arquivo | Entrega |
|---|---|---|
| A | [animais.json](animais.json) | 48 sinais: 16 gatilhos, três variações cada; até 15 palavras. |
| B | [eventos_distancia_cobra.json](eventos_distancia_cobra.json) | Quatro eventos `cobra_picou`, sempre com `{direcao}`; até 12 palavras. |
| B | [clareiras_cobra.json](clareiras_cobra.json) | Seis descobertas `animal_cobra`: três em beco e três em clareira vazia; até 15 palavras. |
| C | [sons_sugeridos.md](sons_sugeridos.md) | Seis candidatos com link original, autor, licença CC0 conferida, duração original até seis segundos e avaliação de uso. Audição pendente. |
| D | [guardioes_animais.json](guardioes_animais.json) | Dez perguntas v3: uma sobre cobra e uma sobre o lobo que derruba para cada guardião. IDs 16 e 17, posteriores ao maior ID de cada banco aprovado (15). |
| E | [indicacao.json](indicacao.json) | 63 textos: três por campo e guardião, incluindo os três preços exclusivos de Quincas. |
| F | [panelas.json](panelas.json) | 12 textos: três para cada um dos quatro resultados. |

As falas de indicação servem tanto para a panela boa quanto para a ruim. A informação sobre a mentira aparece somente nos gestos aprovados: olhos/faca; duas mãos/uma escondida; sino/silêncio; pausa/pressa; mãos paradas/esfregadas com riso. Nenhum texto exibido nomeia personagens ou guardiões.

Os textos de veneno não escolhem uma habilidade nem repetem a linha numérica que o jogo acrescenta. A panela boa não promete aumento de atributo. As descobertas da cobra descrevem um animal já descoberto; não devem revelar uma cobra ainda oculta fora das condições de percepção existentes.

## Referências lidas

Na ordem solicitada: `STATUS.md`, `docs/briefings/DEMANDA_4_animais_e_guardioes.md`, briefing v0.4, sistema de animais v1, revisão dos textos do mapa com a tabela de marcadores e correções v3. Também consultados: correções v2, direção de arte v1, bancos aprovados dos cinco guardiões, tabela atual de verificação e registros de fatos em `godot/scripts/mundo/fauna.gd`.

As contagens antigas de 12 perguntas por guardião e os campos de reputação/tom pertencem ao banco completo. Esta entrega é o suplemento de duas perguntas solicitado pela demanda 4; não substitui nem repete esses campos aprovados.

## Leitura e verificação das perguntas

- Todas exigem `animais`. As cinco perguntas 16 exigem `cobra_avisou`; as cinco perguntas 17 exigem `lobo_derrubou`. Quem não passou pelo fato não recebe a pergunta.
- As cinco perguntas da cobra e `iara_17` são verificáveis; as outras quatro perguntas do lobo tratam de uma posição que o jogador adota agora, depois da queda. Não fingem verificar pensamentos, planos ou sentimentos.
- Em cada pergunta da cobra, a terceira resposta cobre aviso sem desfecho: nem espera concluída, nem picada. Vale +3, igual à melhor resposta. Ouvir o aviso não obriga o jogador a alegar um resultado que ainda não ocorreu.
- As verificações estão descritas por índice em `verificacao` (0, 1, 2 e opção extra). A mentira vale −4, abaixo de todas as respostas e extras da pergunta. Nenhuma opção extra empata ou supera a melhor resposta comum.
- Marta mantém silêncio positivo nas duas perguntas. Bento cobra franqueza; Iara acolhe o susto; Anselmo distingue admitir, omitir e disfarçar; Marta avalia o valor da informação; Quincas calcula o custo do atraso. Respostas egoístas oferecem proteção ou vantagem plausíveis.
- As perguntas hipotéticas não registram confissões de atos passados: dizer que esconderia uma queda não prova que já omitiu algo em outra base. Não foram criadas marcas nem contradições entre encontros diferentes.

### Atenção à integração após aprovação

O código atual conserva `cobra_reacao = passou` depois de uma picada, mesmo se uma cobra posterior for evitada; `parou` só é gravado quando o fato ainda não existe. Por isso a primeira resposta explicita que não houve picada na noite, e a segunda admite a picada sem negar uma espera em outro encontro. Não se deve verificar apenas o encontro mais recente.

| Perguntas | Resposta 0 | Resposta 1 | Resposta 2 | Extra |
|---|---|---|---|---|
| As cinco perguntas 16 | `cobra_reacao = parou` | `cobra_reacao = passou` | Fato ainda ausente, com `cobra_avisou` verdadeiro | Posição presente, sem teste factual |
| `iara_17` | `lobo_reacao = correu` | `lobo_reacao = ficou` | Pedido presente de tempo, sem teste factual | Posição presente, sem teste factual |

Em `iara_17`, a alegação de ter ficado imóvel até ser derrubado é a opção de mentira; ela não cria uma exceção à regra do lobo. O texto explica essa distinção na verificação.

O motor usa também `conteudo/guardioes/verificacao.json`; as condições destas perguntas ainda precisam ser incorporadas pelo responsável pela integração, depois da aprovação. Esta entrega só especifica o conteúdo e as condições: copiar apenas o banco de perguntas para produção não completa a integração. Nenhum desses arquivos existentes foi modificado.

## Validação realizada

Executado `node entregas/2026-10-22_demanda4/validar.cjs`, com resultado **OK**: seis JSONs válidos; contagens exatas; IDs sem repetição e em sequência com os bancos existentes; versões corretas; marcadores permitidos e obrigatórios; limites de palavras; premissas; campos das perguntas; faixas de afinidade; mentira abaixo da pior resposta; opções extras; ausência de nomes nos textos exibidos.

Revisão editorial manual dos sinais de perigo, da concordância de `{lado}` e `{direcao}`, dos gestos e das consequências. O limite conta palavras separadas por espaço, com o marcador como uma palavra; não mede a duração de leitura após expansão. Conferência final de escopo: somente esta pasta aparece como nova no Git.

O validador é somente de leitura e fica em [validar.cjs](validar.cjs). Não valida qualidade sonora, execução em Godot ou equilíbrio em partidas. Não foi executado teste do jogo, pois o pacote não foi integrado.

## Pontos mais fracos

1. **Áudio:** licença e duração estão conferidas nas páginas, mas não houve audição. Limpeza, ausência de voz/música e adequação final permanecem pendentes. As folhas vêm de passos ou de vento; o lamento de lobo pode soar como o uivo normal. As limitações estão indicadas individualmente na seleção.
2. **Variedade das perguntas sobre cobra:** o fato verificável tem dois resultados, mais o caso ainda sem desfecho. Essa limitação deixa as respostas factuais parecidas entre guardiões. A voz varia sobretudo na pergunta e na opção extra, sem inventar novas ações verificáveis.
3. **Resposta sem desfecho:** é mais descritiva que dramática, mas evita punir quem apenas ouviu o aviso. A elegibilidade ampla pode fazer esse caso aparecer com frequência; isso depende do teste de jogo.
4. **Sutileza dos gestos:** o sino que não toca e a resposta apressada precisam funcionar na apresentação da cena. Os textos preservam os sinais aprovados, mas a leitura visual ainda depende da integração.

## PROPOSTAS — separadas, não aplicadas

**P1 — Perguntar por um encontro específico no futuro.** Se for desejável maior variedade, registrar o desfecho de cada encontro e autorizar uma premissa específica de encontro concluído. Isso permitiria perguntas menos repetitivas sem confundir uma espera com uma picada ocorrida depois. É mudança de sistema/vocabulário e não foi usada nesta entrega; o suplemento funciona com os fatos atuais.

**P2 — Rever a escolha sonora se a audição reprovar os candidatos.** Se as folhas parecerem passos/vento ou o lamento parecer apenas uivo, considerar gravação própria ou autorizar uma seleção com recortes de fontes CC0 mais longas, mantendo cada efeito final com até seis segundos. Nenhuma exceção de duração foi aplicada à lista entregue.

Não há outras propostas de alteração de regra, atributo, pontuação, comportamento animal ou sinal dos guardiões.

## Próximo passo

Revisão do Claude e aprovação do usuário. Entrega encerrada nesta pasta; aguardar revisão antes de promover qualquer conteúdo ou modificar a implementação.
