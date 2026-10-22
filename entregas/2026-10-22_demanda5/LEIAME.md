# Demanda 5 — guardiões menos previsíveis e armadilhas

**Data:** 22/10/2026. **Estado:** entregue para revisão do Claude e aprovação do usuário.

Base consultada após `git pull --ff-only`: `c4d6f83`. Lidos, na ordem indicada, `STATUS.md`, a demanda 5 e suas referências: briefing v0.4, correções v3 e os cinco bancos aprovados. Também consultados as correções v2, a tabela de marcadores, `conteudo/guardioes/verificacao.json`, as regras de armadilhas e o catálogo de itens.

## O que foi feito

- **Cinco bancos completos v3** em [guardioes/](guardioes/), cada um com a narração e as duas falas aprovadas, 14 perguntas revisadas ou preservadas entre `_04` e `_17`, e seis novas entre `_18` e `_23`: 20 perguntas por guardião, 100 no total. Foram alteradas 68 perguntas existentes e acrescentadas 30. `anselmo_04` e `anselmo_08` permanecem iguais.
- **Seis textos de armadilha na trilha** em [armadilhas_trilha.json](armadilhas_trilha.json): três deixam explícito o desvio sem disparo; três descrevem o acionamento, sem repetir o tempo de prisão e a lentidão acrescentados pelo jogo.
- **Tabela por pergunta alterada ou nova**, abaixo, com os valores em choque, a alternativa de estereótipo e todas as melhores respostas comuns, inclusive empates.
- **Condições das cinco novas perguntas verificáveis**, em [verificacao_novas.json](verificacao_novas.json), para revisão junto com o conteúdo. É um suplemento a incorporar depois da aprovação, não substitui o arquivo completo de verificação.
- **Auditoria e validador:** [auditoria_editorial.json](auditoria_editorial.json) registra as classificações usadas na tabela; [validar.cjs](validar.cjs) confere estrutura, contagens, afinidades, condições novas e compatibilidade com os bancos da revisão base.

Todos os arquivos deste trabalho estão nesta pasta de entrega. O commit e o push incluem somente esta pasta. Nenhum arquivo de produção foi editado para integrar a demanda.

## Como as perguntas ficaram mais difíceis

Conhecer a personalidade ainda ajuda, mas não fornece uma instrução única. Bento às vezes premia dar o passo sob medo e às vezes recusar uma demonstração de coragem. Iara distingue acolher, insistir, respeitar distância e oferecer uma certeza que não tem. Anselmo não confunde confessar com preencher lacunas ou fabricar culpa. Marta pode conservar uma fonte em vez de extrair tudo, mas aceita exposição quando a informação precisa ser conferida. Quincas alterna entre cobrar pela última oportunidade, preservar reserva e investir numa confiança sem retorno assegurado.

As alternativas de dilema têm custos concretos: perder a saída, deixar uma explicação incompleta, ferir uma confiança, conservar uma dúvida ou abrir mão de preço. As posições das melhores respostas variam nas perguntas livres. Nas verificáveis antigas, nenhuma alternativa foi deslocada.

Os modificadores de tom e a reputação de cada guardião foram mantidos. Nas perguntas verificáveis existentes, **somente afinidades foram alteradas**: redação, intenção, ordem 0/1/2/extra, premissas, mecânicas, marcas, penalidade de mentira e descrição da verificação permanecem intactas. Assim, os fatos continuam correspondendo às posições usadas pelo motor.

Nas perguntas livres, a revisão inclui redação e marcas quando necessário para acompanhar o novo sentido. Em `anselmo_12`, retirar uma garantia não inventa uma mentira passada: registra `admitiu_incerteza`, enquanto sustentar uma declaração contrária às confissões anteriores conserva o teste de contradição. `anselmo_15` passou a tratar de como interpretar uma falha; não grava uma confissão de mentira só por o jogador escolher uma posição sobre isso. Anselmo mantém quatro perguntas com registros e contradições.

## Conferência dos requisitos

As contagens de dilema e de gentileza são classificações editoriais explicitadas nas tabelas. O validador confere seus IDs, afinidades e quantidades; a leitura do conflito permanece parte da revisão humana.

| Guardião | Dilemas em 04–17 (mín. 6) | Dilemas em 18–23 (mín. 3) | Perguntas 04–17 com diferença até 1 (mín. 10) | Alternativa gentil/altruísta ≤ 0 (mín. 4) | Extras no topo / total |
|---|---:|---:|---:|---:|---:|
| Bento | 7 | 5 | 14 | 12 | 0 / 19 |
| Iara | 7 | 5 | 13 | 10 | 0 / 19 |
| Anselmo | 6 | 5 | 14 | 12 | 1 / 13 |
| Marta | 6 | 5 | 14 | 16 | 0 / 14 |
| Quincas | 10 | 5 | 14 | 15 | 0 / 18 |

A diferença foi calculada entre as três respostas comuns, sem usar a extra para satisfazer o requisito. As seis perguntas novas de cada guardião também têm diferença de até um ponto entre as duas melhores respostas comuns. Gentileza não é identificada apenas pelo campo `intencao`: uma deferência ou um consolo pode ter `null` e ainda ser a alternativa mais gentil da cena. Essas alternativas estão assinaladas nas tabelas com seu índice.

Os números são afinidades editoriais da resposta, antes do tom e de eventuais contradições, conforme o formato aprovado. O tom não foi usado para esconder um estereótipo ainda vencedor.

## Armadilhas e novas verificações

Cada `_18` exige `notou_armadilha` e `armadilhas`. A percepção e o desvio já ocorreram; a pergunta trata do julgamento ou da escolha seguinte. Quando menciona outra pessoa, usa uma condição, sem pressupor que ela passou por ali.

Cada `_19` pergunta quantas armadilhas o jogador acionou. Exige `armadilhas`, mas não uma premissa de disparo: as três respostas comuns cobrem **zero**, **um** e **dois ou mais**, com +1 em todos os relatos verdadeiros. Quem não acionou nenhuma tem uma resposta de mesmo valor. A extra, por Inteligência 4, afirma apenas **ao menos um**, vale 0 e também é verificada; não ganha uma dispensa de falar a verdade.

| Posição de todas as perguntas 19 | Condição |
|---|---|
| 0 | `armadilhas_acionadas == 0` |
| 1 | `armadilhas_acionadas == 1` |
| 2 | `armadilhas_acionadas >= 2` |
| extra | `armadilhas_acionadas >= 1` |

As outras cinco novas por guardião são julgamentos, planos condicionais ou disposições presentes; não fingem verificar pensamentos. Isso conserva a Iara majoritariamente verificável: 11 de 20 perguntas. Marta mantém silêncio positivo em 17 de 20.

Nas perguntas da cobra, aviso sem desfecho continua no mesmo patamar da melhor resposta comum. Os fatos cumulativos da noite e a prioridade de `cobra_reacao = passou` foram preservados. `quincas_05` também passou a dar a mesma afinidade aos três tamanhos de inventário: não ter itens não gera uma desvantagem por um fato ausente.

## Conflitos entre guardiões

As reputações aprovadas continuam fazendo os valores atravessarem as bases: delação recebe acolhimento na Marta e rejeição na Iara; proteção de identidade agrada à Iara e incomoda Bento, Marta e Quincas; o aviso de perigo rende reputação positiva em quatro bases e negativa na Marta. Todos conservam ao menos três fontes de marcas vindas de outros guardiões.

Além dessas marcas, a revisão mantém contrastes de julgamento: uma confissão de engano pode receber afinidade positiva com Anselmo, enquanto a dica falsa em si recebe valor negativo com Iara e Bento. Receber uma recompensa por confessar não apaga o dano do ato nem produz uma regra universal de afinidade entre bases.

## Validação realizada

Executado `node entregas/2026-10-22_demanda5/validar.cjs`, com resultado **OK**. Conferidos:

- cinco bancos, versões, IDs 01–23, 100 perguntas e 30 novas;
- preservação das três entradas introdutórias, dos tons e da reputação;
- comparação estrutural das verificáveis antigas contra `c4d6f83`, admitindo somente mudanças de afinidade;
- vocabulário de mecânicas e premissas, faixas numéricas, penalidade de mentira abaixo da pior resposta e limites das extras;
- cobertura das condições novas com contadores 0, 1, 2 e 4, sempre com exatamente uma resposta comum verdadeira;
- contagens editoriais da tabela acima, seis textos de trilha com até 15 palavras e nenhuma repetição de IDs.

Revisão manual da relação pergunta/resposta, dos custos dos dilemas, dos fatos das armadilhas e dos casos sem experiência. Não houve teste do jogo: o conteúdo permanece em entrega, sem integração. A validação estrutural não demonstra equilíbrio estatístico de uma visita nem dificuldade para um jogador humano.

## Pontos mais fracos

1. **Verificáveis antigas herdadas.** Algumas perguntas têm descrição ampla em `verificacao` e nenhuma condição operacional no arquivo atual; outras pressupõem usos de itens, como o cuidado do lobo ferido em `iara_04`. Foram preservadas conforme a restrição explícita da demanda. A entrega não transforma automaticamente essas perguntas em testes completos do histórico.
2. **Contagem repetida entre bases.** As perguntas 19 variam de voz, mas conferem o mesmo contador. É uma verificação simples e disponível que cobre as armadilhas sem inventar novos registros. As perguntas 18 acrescentam os dilemas do encontro.
3. **O tamanho das alternativas ainda pede leitura em tela.** A maioria das novas respostas tem uma ou duas frases curtas, mas alguns dilemas precisam explicitar o custo da decisão. O limite de 15 palavras foi aplicado aos textos de trilha, conforme solicitado, não às respostas dos guardiões.
4. **Redução de afinidades.** Muitos resultados saíram de +3 para +2 ou +1; isso torna o topo mais exigente junto com as regras atuais do motor. Não foi medido quanto isso muda as chances reais de comer da panela boa. O teste de dificuldade em partida fica para depois da aprovação e integração.
5. **Ponderação também pode virar padrão.** As alternativas foram revistas para que decisão rápida, recuo, exposição e reserva possam vencer conforme a cena. Ainda vale observar se os jogadores passam a escolher sempre a resposta que enumera mais custos; a tabela não substitui esse teste.

## PROPOSTAS — não aplicadas

**P1. Auditar a execução das verificáveis antigas numa demanda própria.** Conferir as perguntas marcadas como verificáveis que não têm condições operacionais e os fatos que dependem de usos de itens ainda pendentes. Não criar essas condições por suposição durante a integração desta entrega.

**P2. Medir as visitas antes de ajustar o motor novamente.** Depois da revisão, comparar a distribuição de afinidade e de indicação das panelas com os mesmos tons e regras atuais, usando este banco e o anterior. Seria uma validação de dificuldade; nenhum limiar, tom, pontuação ou regra do motor foi alterado aqui.

## Tabela por pergunta alterada ou nova

Os índices são **0, 1 e 2**, como em `verificacao.json`. Quando há empate, a coluna de melhores respostas lista todas. Em linhas exclusivamente factuais, “referência” indica a redação mantida para comparação, sem classificar um número ou um acontecimento como estereótipo moral. Uma ausência na coluna de conflito significa que não contei a pergunta como dilema novo. As linhas marcadas como gentis/altruístas ≤ 0 mostram a alternativa usada nessa contagem.

### Bento

| ID | Valor em choque | Resposta estereótipo ou referência e afinidade | Melhor resposta comum e afinidade | Gentil/altruísta ≤ 0 |
|---|---|---|---|---|
| bento_04 | — | Referência: [1] “Fiquei e sustentei o olhar.” (+2) | [0] “Corri, sim. Quis continuar vivo.” (+2)<br>[1] “Fiquei e sustentei o olhar.” (+2) | — |
| bento_05 | — | Referência: [0] “Reconheci o calçado; digo quem era.” (+2) | [0] “Reconheci o calçado; digo quem era.” (+2) | [2] “Reconheci, mas não entrego ninguém.” (-1) |
| bento_06 | — | Referência: [1] “Vim pela frente, sem me esconder.” (+1) | [0] “Rondei. Queria saber onde estava pisando.” (+2)<br>[2] “Entrei pelos fundos e assumo.” (+2) | — |
| bento_07 | Ousadia × franqueza sobre o próprio limite | [1] “Pego a curta. Já perdi tempo demais para dar outra volta.” (+1) | [2] “Dou a volta. Ainda não sei atravessar a curta e digo isso sem gosto.” (+2) | [0] “Espero alguém chegar. Assim posso impedir que entre sozinho.” (0) |
| bento_08 | — | Referência: [0] “Nenhuma.” (+2) | [0] “Nenhuma.” (+2) | — |
| bento_09 | Decisão rápida × assumir o desconhecimento | [0] “Espero. Quero sair sabendo que a escolha foi minha, não da pressa.” (+1) | [2] “Escolho agora. Posso estar lendo errado, mas não troco a saída por uma garantia.” (+2) | [1] “Deixo você escolher por mim. Não quero lhe fazer desfeita.” (0) |
| bento_10 | Insistência corajosa × reconhecer a escolha alheia | [0] “Peço outra vez, na frente dele. Um silêncio pode ser só desconfiança.” (+1) | [1] “Digo por que preciso e sigo sem a resposta se ele fechar a boca.” (+2) | [2] “Ofereço acompanhá-lo, mesmo sem saber se acompanho o passo.” (0) |
| bento_11 | — | Referência: [0] “Enviei. Preferi arriscar a informação.” (+1) | [1] “Não. Só enviei o que podia sustentar.” (+2) | — |
| bento_12 | Franqueza × preservar a própria travessia | [2] “Conto o caminho inteiro. Prefiro perder a chegada a deixar dúvida.” (+1) | [1] “Assumo a escolha, mas guardo a rota enquanto ainda serve para me alcançar.” (+2) | [0] “Divido a rota com todos. Ninguém merece atravessar sem saber.” (0) |
| bento_13 | — | Referência: [0] “Avancei pela trilha que já tinha escolhido.” (+1) | [1] “Mudei a rota. O risco ficou maior do que aceitei.” (+2) | — |
| bento_14 | Confiança direta × coragem de discordar | [1] “Vou à esquerda. Você conhece as panelas melhor do que eu.” (+1) | [0] “Vou à direita e digo por quê, mesmo que isso lhe ofenda.” (+2) | [2] “Peço que sirva primeiro. Assim não rejeito sua palavra.” (0) |
| bento_15 | Confissão imediata × sustentar a ação sob medo | [0] “Conto na hora. Esconder o medo é começar a mentir.” (+1) | [2] “Atravesso primeiro; depois conto quanto pesou dar o passo.” (+2) | [1] “Fico para acalmar quem estiver atrás, mesmo sem saber se aguento.” (0) |
| bento_16 | — | Referência: [1] “Passei e fui picado. Arrisquei o couro e assumo.” (+2) | [1] “Passei e fui picado. Arrisquei o couro e assumo.” (+2)<br>[2] “Só ouvi o aviso. Não esperei cobra sair nem levei picada; não vou inventar coragem.” (+2) | — |
| bento_17 | Franqueza × recobrar domínio da própria experiência | [1] “Conto tudo agora. A queda foi minha, inclusive o susto.” (+1) | [2] “Digo que ele me derrubou; guardo os detalhes até conseguir pôr ordem neles.” (+2) | — |
| bento_18 | Coragem de seguir × aceitar uma dúvida que não pode resolver | [0] “Fico olhando até entender tudo. Quero ter certeza de que não vou recuar depois.” (+1) | [2] “Passo pelo lado e sigo. Não preciso provar nada a um laço escondido.” (+2) | [1] “Espero quem vier atrás para conduzir cada passo, mesmo sem saber sua intenção.” (0) |
| bento_19 | — | — (contagem factual) | [0] “Nenhuma. Esse laço ainda não segurou meu pé.” (+1)<br>[1] “Uma. É o número que tenho para contar.” (+1)<br>[2] “Duas ou mais. Não vou diminuir a conta.” (+1) | — |
| bento_20 | Franqueza que custa uma confiança × dar ao outro tempo de assumir | [2] “Prometo guardar tudo. Já deve ser difícil carregar a vergonha sozinho.” (0) | [0] “Não prometo. Vou contar o risco, mesmo que perca quem confiou em mim.” (+2) | [2] “Prometo guardar tudo. Já deve ser difícil carregar a vergonha sozinho.” (0) |
| bento_21 | Determinação × reconhecer o limite do que enxerga | [1] “Volto. Quero chegar por um caminho que consiga defender, mesmo que chegue tarde.” (+1) | [2] “Dou o passo com medo. Não digo que está seguro só porque preciso seguir.” (+2) | [0] “Espero companhia e prometo ir na frente para tranquilizá-la.” (0) |
| bento_22 | Autonomia × necessidade de confiar em alguém | [1] “Aceito e guardo o nome para cobrar depois, se sair errado.” (+1) | [0] “Aceito só o trecho que posso conferir; o restante atravesso por minha conta.” (+2) | [2] “Aceito inteira para mostrar que ainda há confiança entre nós.” (0) |
| bento_23 | Dar satisfação × sustentar a própria prioridade sem disfarce | [0] “Dou a explicação inteira. Não quero chegar com uma pergunta nas costas.” (+1) | [2] “Digo o essencial agora e assumo que estou saindo com parte por explicar.” (+2) | [1] “Fico até todos entenderem. Ninguém deve atravessar carregando uma dúvida minha.” (0) |

### Iara

| ID | Valor em choque | Resposta estereótipo ou referência e afinidade | Melhor resposta comum e afinidade | Gentil/altruísta ≤ 0 |
|---|---|---|---|---|
| iara_04 | — | Referência: [0] “Cuidei da ferida e mantive distância.” (+2) | [0] “Cuidei da ferida e mantive distância.” (+2) | — |
| iara_05 | — | Referência: [0] “Desviei para não levar perigo até a pessoa.” (+1) | [1] “Evitei a área para preservar minha rota.” (+2) | — |
| iara_06 | — | Referência: [0] “Segui com cuidado e recuei quando ele ficou inquieto.” (0) | [1] “Não segui. Eu precisava manter minha rota.” (+2) | [0] “Segui com cuidado e recuei quando ele ficou inquieto.” (0) |
| iara_07 | Avisar quem vem atrás × não expor a própria fuga | [0] “Usei uma frase pronta para alertar quem viesse atrás.” (0) | [1] “Desviei e continuei. Eu estava sendo seguido.” (+2) | [0] “Usei uma frase pronta para alertar quem viesse atrás.” (0) |
| iara_08 | Partilhar ajuda incerta × não espalhar um risco | [0] “Repeti a dica como a recebi, avisando que não tinha certeza.” (0) | [1] “Guardei para mim; eu ainda precisava confirmar.” (+2) | [0] “Repeti a dica como a recebi, avisando que não tinha certeza.” (0) |
| iara_09 | Acolhimento imediato × confiança ferida | [2] “Vou até a pessoa. Estar em perigo já basta para eu esquecer a dica.” (0) | [0] “Ofereço só o que posso confirmar, sem me aproximar por enquanto.” (+2) | [2] “Vou até a pessoa. Estar em perigo já basta para eu esquecer a dica.” (0) |
| iara_10 | — | Referência: [0] “Sim, por acidente; avisei pela frase disponível.” (+1) | [0] “Sim, por acidente; avisei pela frase disponível.” (+1)<br>[2] “Não acionei nenhuma.” (+1) | — |
| iara_11 | Cuidar do outro × admitir o limite da própria ajuda | [0] “Fico ajudando até onde pedirem. A chegada pode esperar por mim.” (0) | [1] “Dou a informação que tenho e sigo, mesmo sabendo que pode não bastar.” (+2) | [0] “Fico ajudando até onde pedirem. A chegada pode esperar por mim.” (0) |
| iara_12 | — | Referência: [0] “Desviei sem conduzi-lo até a base.” (+1) | [1] “Recuei e procurei outra aproximação.” (+2) | — |
| iara_13 | Dar aviso gratuito × evitar uma segunda pessoa em perigo | [0] “Avisei do risco sem exigir nada.” (0) | [1] “Não avisei; revelar-me também seria perigoso.” (+2) | [0] “Avisei do risco sem exigir nada.” (0) |
| iara_14 | — | Referência: [0] “Respondi com a informação segura que eu tinha.” (+1) | [1] “Não respondi; eu não sabia se era uma isca.” (+2) | — |
| iara_15 | Conforto × honestidade sobre a incerteza | [2] “Ofereço minha melhor suspeita. A pessoa talvez precise de um ponto de onde começar.” (0) | [1] “Digo que não sei. Posso fazer companhia à dúvida, não escolher por ela.” (+2) | [2] “Ofereço minha melhor suspeita. A pessoa talvez precise de um ponto de onde começar.” (0) |
| iara_16 | — | Referência: [0] “Deixei que saísse, ficando parado. Nenhuma me picou nesta noite.” (+2) | [0] “Deixei que saísse, ficando parado. Nenhuma me picou nesta noite.” (+2)<br>[2] “Ouvi as folhas, meu bem. Ainda não esperei uma cobra sair nem sofri picada.” (+2) | — |
| iara_17 | Generosidade × não usar o outro para fugir do próprio susto | [1] “O que precisarem. Talvez cuidar deles me faça esquecer a queda.” (0) | [0] “Um aviso curto e depois sossego. Ainda não sei quanto consigo sustentar.” (+2) | [1] “O que precisarem. Talvez cuidar deles me faça esquecer a queda.” (0) |
| iara_18 | Amparo pessoal × não impor proximidade e segurança que desconhece | [0] “Fico esperando para acompanhar a pessoa, mesmo sem saber se quer aproximação.” (0) | [2] “Dou o aviso possível e sigo. Não sei se minha presença ajudaria mais.” (+2) | [0] “Fico esperando para acompanhar a pessoa, mesmo sem saber se quer aproximação.” (0) |
| iara_19 | — | — (contagem factual) | [0] “Ainda nenhuma nesta noite.” (+1)<br>[1] “Uma nesta noite.” (+1)<br>[2] “Mais de uma nesta noite.” (+1) | — |
| iara_20 | Acolher antes de entender × exigir precisão antes de responder | [0] “Espero uma mensagem mais clara. Preciso guardar atenção para quem consigo entender.” (0) | [1] “Respondo que ouvi e pergunto uma coisa por vez. Ainda não ofereço uma direção.” (+2) | — |
| iara_21 | Acolhimento × não confundir companhia com proteção | [2] “Fico por perto. A pessoa talvez não consiga continuar sozinha.” (+1) | [0] “Digo por que vou me afastar, mesmo sabendo que pode parecer abandono.” (+2) | — |
| iara_22 | Consolar × respeitar a decisão informada de quem escuta | [0] “Começo pela chance de dar certo. Sem ânimo, talvez ela nem consiga escolher.” (0) | [1] “Conto o que sei e paro aí, mesmo que a pessoa peça uma certeza maior.” (+2) | [0] “Começo pela chance de dar certo. Sem ânimo, talvez ela nem consiga escolher.” (0) |
| iara_23 | Respeitar a recusa imediatamente × esclarecer antes de aceitar o afastamento | [1] “Aceito de imediato. Talvez ela precisasse ouvir mais, mas não quero vencer sua recusa.” (+1) | [2] “Pergunto uma vez o que ela entendeu. Posso incomodar, mas não quero deixá-la recusar um engano.” (+2) | — |

### Anselmo

| ID | Valor em choque | Resposta estereótipo ou referência e afinidade | Melhor resposta comum e afinidade | Gentil/altruísta ≤ 0 |
|---|---|---|---|---|
| anselmo_05 | — | Referência: [0] “Sim. Menti para obter vantagem.” (+1) | [1] “Não menti para ninguém.” (+2) | — |
| anselmo_06 | — | Referência: [0] “Sim. Quis desviar outro jogador.” (+1) | [1] “Não. Só repeti uma dica que recebi.” (+2) | — |
| anselmo_07 | Responsabilidade × inteireza do relato | [0] “Só a escolha. Explicar o medo pode parecer um pedido de desconto.” (+1) | [1] “A escolha e o medo. Calar um deles também mudaria a história.” (+2) | [2] “O que poupar quem me escuta. O susto já fez estrago bastante.” (0) |
| anselmo_09 | — | Referência: [0] “Sim. Disse que não tinha nada.” (+1) | [1] “Não. Declarei o que carregava.” (+2) | — |
| anselmo_10 | Confissão completa × não transformar o outro em prova | [2] “Tudo, inclusive quem estava lá. Uma confissão não combina com recorte.” (+1) | [1] “O que fiz e o dano que causei; só dou o nome se fizer diferença.” (+2) | [0] “Nada que a exponha. Prefiro guardar também minha parte do erro.” (0) |
| anselmo_11 | — | Referência: [0] “Sim. O silêncio me protegeu.” (+1) | [1] “Fiquei calado porque não sabia responder.” (+2)<br>[2] “Não usei o silêncio para esconder nada.” (+2) | — |
| anselmo_12 | Corrigir a própria palavra × preservar a confiança recebida | [2] “Guardo a declaração. Quem confiou em mim precisa de algum chão durante a noite.” (0) | [0] “Retiro a garantia. Prefiro rever cada ato sem me declarar limpo antes da conta.” (+2)<br>[1] “Mantenho a declaração e aceito que confiram cada resposta, mesmo sem confiar em mim.” (+2) | [2] “Guardo a declaração. Quem confiou em mim precisa de algum chão durante a noite.” (0) |
| anselmo_13 | — | Referência: [0] “Avisei com a frase disponível.” (0) | [1] “Passei sem avisar e assumo.” (+2) | [0] “Avisei com a frase disponível.” (0) |
| anselmo_14 | Confessar sem demora × fazer o reparo antes do alívio | [0] “Confessaria logo. Se esperar, talvez encontre uma razão para calar.” (+1) | [2] “Daria o aviso necessário primeiro; depois contaria minha parte sem diminuir.” (+2) | [1] “Tentaria reparar em silêncio, para ninguém carregar minha culpa comigo.” (0) |
| anselmo_15 | Severidade consigo × precisão da confissão | [1] “Preciso. Se eu aliviar o juízo, posso aliviar também o relato.” (+1) | [2] “Conto o que fiz sem concluir que essa é minha natureza. Posso estar me poupando.” (+2) | [0] “Prefiro não contar. Quem me escuta não merece levar esse peso.” (0) |
| anselmo_16 | — | Referência: [0] “Parei até ela partir. Nenhuma cobra me picou nesta noite; é o que houve.” (+1) | [0] “Parei até ela partir. Nenhuma cobra me picou nesta noite; é o que houve.” (+1)<br>[1] “Segui andando e fui picado. Essa parte não retiro da confissão.” (+1)<br>[2] “Tenho apenas o aviso para contar: nenhuma espera concluída, nenhuma picada.” (+1) | — |
| anselmo_17 | Confissão direta × prudência ao interpretar a própria falha | [2] “Conto sem explicar. Qualquer motivo pode servir de desculpa.” (+1) | [0] “Digo o que houve e separo o que sei do que ainda tento entender.” (+2) | [1] “Conto só que me levantei. Quem me espera precisa de ânimo, não de susto.” (0) |
| anselmo_18 | Confissão do próprio acerto × não fabricar mérito | [0] “Conto como escapei. Se omitir meu juízo, a história fica incompleta.” (+1) | [1] “Conto o que vi, sem decidir se foi juízo ou sorte que me fez olhar.” (+2) | [2] “Conto primeiro que escapei, para acalmar quem ainda está na trilha.” (0) |
| anselmo_19 | — | — (contagem factual) | [0] “Nenhuma na minha conta.” (+1)<br>[1] “Uma. É esse o número.” (+1)<br>[2] “Pelo menos duas. Não retiro nenhuma do relato.” (+1) | — |
| anselmo_20 | Verdade urgente que expõe alguém × correção que preserva sua dignidade | [0] “Deixo como está. Prefiro que a pessoa conserve o pouco sossego que tem.” (0) | [2] “Corrijo já, diante de quem ouviu. Aceito ferir a confiança de quem contou.” (+2) | [0] “Deixo como está. Prefiro que a pessoa conserve o pouco sossego que tem.” (0) |
| anselmo_21 | Pureza do motivo × honestidade sobre o próprio interesse | [1] “Tira. Se espero ganhar, prefiro calar até não haver recompensa.” (+1) | [0] “Não tira o fato, mas digo também que estou esperando receber algo.” (+2) | [2] “Conto só a parte que lhe traga paz; a minha vantagem fica comigo.” (0) |
| anselmo_22 | Inteireza do relato × responsabilidade por quem será exposto | [0] “Precisa. Tirar nomes pode ser o primeiro jeito de tirar responsabilidades.” (+1) | [2] “Conto minha ação inteira e guardo o nome, aceitando que perguntem por ele.” (+2) | [1] “Guardo também a ação. A pessoa merece ficar fora desta conversa.” (0) |
| anselmo_23 | Não completar o desconhecido × desejo de oferecer uma confissão inteira | [2] “Conto a escolha e as razões que suspeito, mesmo arriscando uma explicação errada.” (+1) | [1] “Digo que não sei o motivo e paro nessa parte. Não preencho a lacuna para continuar.” (+2) | [0] “Escolho a explicação menos dura. Ela ajuda quem me escuta a perdoar.” (0) |

### Marta

| ID | Valor em choque | Resposta estereótipo ou referência e afinidade | Melhor resposta comum e afinidade | Gentil/altruísta ≤ 0 |
|---|---|---|---|---|
| marta_04 | — | Referência: [1] “Um; digo em qual direção.” (+1) | [0] “Nenhum.” (+2)<br>[2] “Dois ou mais; não distingui todos.” (+2) | — |
| marta_05 | — | Referência: [0] “Digo quem foi e por onde saiu.” (+1) | [1] “Tenho uma suspeita e a apresento como suspeita.” (+2) | [2] “Reconheci, mas não vou entregar.” (-1) |
| marta_06 | — | Referência: [0] “Digo o calçado e a direção.” (+2) | [0] “Digo o calçado e a direção.” (+2) | [2] “Reconheci o calçado, mas guardo o nome.” (-1) |
| marta_07 | Informação imediata × conservar uma fonte possível | [2] “Entrego se receber algo já. Amanhã essa pessoa pode não ter mais serventia.” (+1) | [1] “Guardo o lugar por enquanto. Posso perder a troca de agora por uma melhor.” (+2) | [0] “Não entrego. Estar escondido já mostra que ela precisa de algum resguardo.” (0) |
| marta_08 | — | Referência: [0] “Digo a direção e a trilha.” (+2) | [0] “Digo a direção e a trilha.” (+2) | [2] “Sei para onde foi, mas não entrego.” (-1) |
| marta_09 | Utilidade da informação × controle de sua circulação | [1] “Passo. Uma informação pela metade perde valor na mão de quem compra.” (+1) | [0] “Dou o trecho que vi, mas guardo o último rumo para não perder minha vantagem.” (+2) | [2] “Guardo tudo. Não quero facilitar uma perseguição contra quem tenta chegar.” (0) |
| marta_10 | — | Referência: [1] “Deixei sinais e depois mudei de rota.” (+2) | [1] “Deixei sinais e depois mudei de rota.” (+2) | — |
| marta_11 | — | Referência: [0] “Digo a direção exata.” (+1) | [1] “Digo apenas de onde veio.” (+2) | [2] “Não entrego a rota.” (-1) |
| marta_12 | Extração de informação × continuidade de uma fonte leal | [0] “A informação. Pressiono até ela contar o pedaço que falta.” (+1) | [2] “A fonte, por enquanto. Confiro o pedaço recebido antes de cobrar outro.” (+2) | [1] “A confiança dela. Aceito sem conferir para não parecer uma cobrança.” (0) |
| marta_13 | Informação nova × proteção da própria rota | [1] “Tudo, se a informação servir agora. Plano guardado também perde hora.” (+1) | [2] “O primeiro trecho. Aceito uma resposta menor para conservar o resto.” (+2) | [0] “Conto o que ajudar os dois a atravessar, mesmo sem receber nada.” (0) |
| marta_14 | — | Referência: [0] “Não. Guardei a informação.” (+1) | [1] “Avisei só a direção, guardando os detalhes.” (+2) | [2] “Avisei sem pedir nada.” (0) |
| marta_15 | Vigilância da pessoa × verificação independente do relato | [2] “Nela. Quem pede resguardo pode estar escondendo o melhor pedaço.” (+1) | [0] “Na trilha que descreveu. Confiro o relato sem gastar a fonte inteira.” (+2) | [1] “Em mim. Prefiro que observem minha rota a expor quem pediu proteção.” (0) |
| marta_16 | — | Referência: [1] “Passei andando. Houve picada; não estou chamando um susto de ataque.” (+2) | [1] “Passei andando. Houve picada; não estou chamando um susto de ataque.” (+2)<br>[2] “Aviso ouvido. Sem picada e sem espera até a cobra sair. Não tenho outro resultado.” (+2) | — |
| marta_17 | Negociar informação × ocultar vulnerabilidade útil aos outros | [0] “Vendo a quem pagar. Uma fraqueza também pode render informação.” (+1) | [1] “Conto só que me atrasei. Posso perder preço, mas guardo quanto ainda me custa.” (+2) | [2] “Conto tudo sem cobrar. O susto pode evitar que outra pessoa caia.” (0) |
| marta_18 | Exclusividade × utilidade de uma informação que pode circular | [2] “Guardo o lugar inteiro. Quem vier depois que pague para saber.” (+1) | [1] “Revelo o risco, guardo minha aproximação. Perco exclusividade sem entregar toda a rota.” (+2) | [0] “Revelo tudo sem cobrar. Quero que ninguém precise pensar nisso outra vez.” (0) |
| marta_19 | — | — (contagem factual) | [0] “Zero disparos meus.” (+1)<br>[1] “Um disparo meu.” (+1)<br>[2] “Dois ou mais disparos meus.” (+1) | — |
| marta_20 | Informação precisa × conservar a lealdade de uma fonte | [2] “A leal. Se a abandonar agora, estarei cobrando confiança que não devolvo.” (0) | [1] “A menos leal, só no trecho conferível. Posso perder a outra fonte por isso.” (+2) | [2] “A leal. Se a abandonar agora, estarei cobrando confiança que não devolvo.” (0) |
| marta_21 | Valor de revenda × duração do acesso à fonte | [0] “Repito se receber uma informação melhor. Segredo também tem preço.” (+1) | [2] “Guardo por enquanto e comparo com o que posso descobrir sem ela.” (+2) | [1] “Guardo sempre. Quem confiou não deveria precisar fazer outra pergunta.” (0) |
| marta_22 | Preço da informação × precisão que preserva crédito | [1] “Como caminho provável. Uma margem de erro não tira o valor todo.” (+1) | [2] “Como rumo visto. Cobro menos para não perder a próxima pergunta de quem comprar.” (+2) | [0] “Dou o rumo sem cobrar para ajudar quem está perdido, mesmo perdendo uma troca.” (0) |
| marta_23 | Informação confirmada que exige exposição × conservar a própria posição | [0] “Saio agora e aviso que é incerto. Guardo minha posição, mesmo levando menos para trocar.” (+1) | [2] “Fico mais um pouco e aceito ser visto. Não vendo esse rumo como se o tivesse confirmado.” (+2) | [1] “Mostro que estou ali para a outra pessoa não se sentir seguida.” (0) |

### Quincas

| ID | Valor em choque | Resposta estereótipo ou referência e afinidade | Melhor resposta comum e afinidade | Gentil/altruísta ≤ 0 |
|---|---|---|---|---|
| quincas_04 | Fechar rápido × preservar margem de negociação | [1] “Ponho o melhor. Quero fechar logo, antes que o valor da indicação caia.” (+1) | [0] “Começo menor e explico a oferta. Posso perder tempo, mas guardo margem.” (+2) | [2] “Deixo um item por gratidão, mesmo que você não queira indicar nada.” (0) |
| quincas_05 | — | — (contagem factual) | [0] “Nenhum.” (+1)<br>[1] “Um.” (+1)<br>[2] “Dois ou mais.” (+1) | — |
| quincas_06 | — | Referência: [0] “Ofereço o item mais útil que posso dispensar.” (+1) | [1] “Ofereço o de menor utilidade para mim.” (+2) | — |
| quincas_07 | Lucro imediato × crédito para negócios futuros | [0] “Cobro agora. Se esperar confirmação, outra boca pode chegar antes.” (+1) | [2] “Conto a dúvida junto e cobro pouco. Talvez a confiança pague o resto.” (+2) | [1] “Dou sem cobrar, junto com a dúvida. Prefiro que a pessoa não escolha sem nada.” (0) |
| quincas_08 | Valor da informação × reserva para continuar negociando | [1] “Aceito. Informação boa pode render mais do que guardo na mão.” (+1) | [2] “Peço só uma parte da informação por menos. Fico com uma dúvida e um recurso.” (+2) | [0] “Entrego sem acertar preço; prefiro que nenhum dos dois saia desconfiado.” (0) |
| quincas_09 | Preço próprio × utilidade do que se recebe | [2] “Peço pelo que ele me custa perder, mesmo que você não aceite.” (+1) | [0] “Aceito um pouco menos se a indicação resolver o problema que ele resolveria.” (+2) | [1] “Cedo pelo que você puder pagar. Sua necessidade deve vir primeiro.” (0) |
| quincas_10 | Comprar tempo × conservar recurso para o próximo risco | [0] “Quando a fonte é conhecida. Prefiro pagar do que carregar uma oportunidade perdida.” (+1) | [1] “Quando o tempo que ganho vale mais que o uso que perco. Senão, dou a volta.” (+2) | [2] “Pago também pela rota de quem vem atrás, mesmo ficando sem nada.” (0) |
| quincas_11 | Persistir no negócio × suportar a perda da oportunidade | [2] “Pago. Se começo a recuar no preço, posso perder a indicação inteira.” (+1) | [1] “Abro mão do negócio e guardo o item. A próxima base talvez cobre diferente.” (+2) | [0] “Deixo o item para facilitar seu próximo negócio, mesmo saindo sem indicação.” (0) |
| quincas_12 | Preço de ocasião × confiança sem garantia de retorno | [1] “Cobro o que a urgência permite. Outra chance assim pode não aparecer.” (+1) | [0] “Cobro menos e digo o limite da dica. Talvez não volte, mas não sai enganado.” (+2) | [2] “Dou a dica antes e deixo o preço para depois. Não quero prolongar o aperto.” (0) |
| quincas_13 | Exclusividade × abertura de uma fonte futura | [0] “Acaba. Vendo uma vez pelo máximo antes que corra de boca em boca.” (+1) | [2] “Baixa o preço, mas pode abrir outra fonte. Conto só o trecho que já conferi.” (+2) | [1] “Conto inteira para aliviar a noite de quem perguntar, sem esperar nada.” (0) |
| quincas_14 | — | Referência: [0] “Sim. Digo qual item separei.” (+1) | [1] “Tenho itens, mas ainda quero ouvir seu preço.” (+2) | — |
| quincas_15 | Preço atraente × compromisso que já pode ser cumprido | [1] “Uma parte do próximo ganho. Se eu vencer, nenhum dos dois perde.” (+1) | [2] “Um preço pequeno do que tenho agora. Pode valer menos do que você espera.” (+2) | [0] “Ofereço acertar depois, quando os dois tiverem tempo. Não quero pressionar sua escolha.” (0) |
| quincas_16 | — | Referência: [0] “Custou a espera até ela sair. Picada nenhuma; achei melhor gastar tempo.” (+1) | [0] “Custou a espera até ela sair. Picada nenhuma; achei melhor gastar tempo.” (+1)<br>[2] “Por enquanto, só o aviso: nem picada nem espera concluída para pôr na conta.” (+1) | — |
| quincas_17 | Comprar alívio imediato × manter capacidade de atravessar | [2] “O que eu puder pagar. Cada pergunta sobre o preço também custa tempo.” (+1) | [0] “Mais do que antes, mas guardo algo. O atraso não acabou com os outros riscos.” (+2) | [1] “Deixo a escolha do preço com você; prefiro confiar quando estou fraco.” (0) |
| quincas_18 | Receita da última oportunidade × confiança que talvez não tenha retorno | [1] “Cobro pouco para deixar confiança, mesmo sem saber se haverá outra conversa.” (+1) | [0] “Cobro agora e aviso que o valor acaba quando o laço ficar visível.” (+2) | [2] “Dou o lugar sem cobrar; basta que a pessoa não tenha o atraso que eu evitei.” (0) |
| quincas_19 | — | — (contagem factual) | [0] “Nenhuma entrou nessa conta.” (+1)<br>[1] “Uma por enquanto.” (+1)<br>[2] “Ao menos duas nessa conta.” (+1) | — |
| quincas_20 | Recuperar o custo da conversa × não ampliar o prejuízo | [2] “Melhoro logo. Se eu sair, perco tudo o que esta conversa já custou.” (+1) | [1] “Saio com o que ainda tenho. O tempo gasto não torna a oferta melhor.” (+2) | [0] “Deixo o item como sinal de apreço, mesmo sem levar nada.” (0) |
| quincas_21 | Melhor preço possível × valor de encerrar um negócio presente | [1] “Só fecho se cobrir o que espero receber lá. O risco da viagem é meu.” (+1) | [0] “Aceito um pouco menos agora se a diferença pagar o tempo que não gasto indo.” (+2) | [2] “Fecho por qualquer preço justo para não tratar sua confiança como leilão.” (0) |
| quincas_22 | Retorno assegurado × investimento que aceita não ser pago | [0] “Quando houver uma promessa de retribuição. Sem ela, só eu assino o risco.” (+1) | [2] “Quando eu puder perder aquela dica e ainda atravessar. Confiança não vem com recibo.” (+2) | [1] “Sempre. Quem precisa de ajuda deve receber tudo o que eu souber.” (0) |
| quincas_23 | Extrair o preço máximo × conservar a possibilidade de outro negócio | [1] “Espero. A urgência faz a pessoa mostrar quanto de fato pode pagar.” (+1) | [2] “Fecho antes. Posso perder o preço alto, mas ainda teremos motivo para conversar.” (+2) | [0] “Corto o preço antes de perguntarem. Prefiro aliviar a pressa a sustentar a cobrança.” (0) |
