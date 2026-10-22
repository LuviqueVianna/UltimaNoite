# Demanda 4 — Animais e diálogos dos guardiões

> Para o ChatGPT. Criada pelo Claude em 22/10/2026, a pedido do usuário.
> Leia antes: `STATUS.md`, `docs/briefings/BRIEFING_GPT_v0.4.md` (papéis e regras gerais), `docs/sistemas/animais_v1.md` (como os animais funcionam) e `revisoes/2026-10-20_textos_mapa.md` (tabela de marcadores).
> Mudanças de regra: listar à parte como **PROPOSTA**. Não alterar decisões por conta própria.

---

## 1. Contexto: o que mudou desde a demanda 2

- **Os animais entraram no jogo:** lobo, coruja, cão sem dono e **cobra** (nova, decidida pelo usuário em 21/10).
- Regra comum: **quem fica parado diante do perigo se sai melhor que quem corre.** Cada animal dá um sinal antes.
- **Sons:** uivo, rosnado, pio e latido usam gravações livres (CC0). O chacoalhar de folhas da cobra é provisório.
- O jogo roda hoje com **falas provisórias** escritas pelo Claude, listadas abaixo. Esta demanda substitui essas falas pelo banco definitivo.

| Animal | Comportamento resumido |
|---|---|
| Lobo | Ronda as trilhas perto das bases. Rosna e avança uns passos. Quem fica parado, ele deixa em paz; quem se mexe, ele persegue e derruba (a pessoa fica caída e depois anda devagar). Não entra nas bases. Em algumas noites está ferido: manca e não ataca. Uiva de tempos em tempos |
| Coruja | Pousa nas clareiras. Quando nota alguém, pia (e todos por perto ouvem de onde veio) ou, se houver outro personagem perto, vira a cabeça na direção dele |
| Cão sem dono | Abana o rabo e espera (quem chega perto é guiado até uma base) ou fica inquieto e late |
| Cobra | Escondida no meio das trilhas. Quem passa perto ouve folhas secas chacoalharem. Quem passa andando por cima é picado (veneno: perde 1 ponto da maior habilidade). Quem para, faz ela ir embora |

---

## 2. Entregas

Entregar tudo em `entregas/AAAA-MM-DD_demanda4/`, com um `LEIAME.md` dizendo o que foi feito, o que ficou mais fraco e as PROPOSTAS.

| Parte | Arquivo | Quantidade |
|---|---|---|
| A | `animais.json` | 16 sinais × 3 variações = 48 |
| B | `eventos_distancia_cobra.json` e `clareiras_cobra.json` | 4 + 6 = 10 |
| C | `sons_sugeridos.md` | 4 a 8 sons com link |
| D | `guardioes_animais.json` | 2 perguntas por guardião = 10 |
| E | `indicacao.json` | 5 guardiões, ver seção 7 |
| F | `panelas.json` | 4 resultados × 3 variações = 12 |

Regras comuns de texto (as mesmas da demanda 2): português do Brasil, tom de suspense, frases curtas, ambientação da Direção de Arte v1 (Mata Atlântica, interior rural, meados do século XX), sobrenatural sugerido e nunca mostrado. **Nunca nomear personagens.** Use só os marcadores da tabela.

---

## 3. Parte A — Sinais dos animais (`animais.json`)

O que o **jogador lê** quando encontra um animal. Aparece como mensagem curta no canto da tela, por 6 segundos, enquanto ele anda.

```json
{
  "versao_formato": 1,
  "sinais": [
    { "id": "lobo_rosna_01", "gatilho": "lobo_rosna", "texto": "Um lobo rosna para você, orelhas para trás. Não corra." }
  ]
}
```

- **3 variações por gatilho**, até 15 palavras.
- Os gatilhos marcados com **\*** precisam deixar claro o que fazer, sem tom de manual. Exemplos que funcionam: "Não corra.", "Fique quieto.", "Ele espera você." Exemplo que não funciona: "Pressione Espaço para parar."
- Só `coruja_avisa` tem marcador: `{direcao}` (ex.: "a leste", "bem perto").

| Gatilho | Quando aparece | Texto provisório de hoje |
|---|---|---|
| `lobo_rosna` \* | O lobo viu você e rosna. Se você se mexer, ele ataca | Um lobo rosna para você, orelhas para trás. Fique parado até ele se afastar. |
| `lobo_desiste` | Você ficou parado e o lobo foi embora | O lobo fareja o ar e se afasta. |
| `lobo_derruba` | O lobo te alcançou: você cai e depois anda devagar | O lobo te derruba. Você demora a levantar e segue mancando. |
| `lobo_escapou` | Você chegou a uma base com o lobo atrás | O lobo para na beira da clareira e não entra. |
| `lobo_ferido` | Você viu o lobo ferido (ele não ataca) | Um lobo passa mancando, sem forças para atacar. |
| `coruja_olha` | A coruja notou você e piou (os outros ouvem) | Uma coruja olha para você e pia. |
| `coruja_avisa` | A coruja notou você e virou a cabeça para onde há outra pessoa | Uma coruja olha para você e vira a cabeça {direcao}. |
| `cao_guia` \* | O cão abana o rabo e espera. Se você chegar perto, ele guia | Um cão sem dono abana o rabo e espera por você. Chegue perto dele. |
| `cao_seguindo` \* | Você chegou perto e o cão começou a guiar | O cão sai trotando pela trilha. Siga-o. |
| `cao_chegou` | O cão te deixou diante de uma base | O cão para diante da luz da base e volta para a mata. |
| `cao_late` | O cão ficou inquieto e latiu (os outros ouvem) | Um cão inquieto rosna e late para você. |
| `cobra_som` \* | Você passou a até 6 m da cobra e não a vê | Folhas secas chacoalham bem perto. Pare e espere. |
| `cobra_ve` \* | Você passou perto e, pela Inteligência, vê a cobra | Uma cobra, enrolada no meio da trilha. Pare e espere. |
| `cobra_some` | Você ficou parado e a cobra foi embora | A cobra desliza para o mato. |
| `cobra_pica` | Você foi picado e o veneno fez efeito | Uma picada no tornozelo. Você sente o veneno subir. |
| `cobra_resistiu` | Você foi picado, mas resistiu ao veneno | Uma picada no tornozelo, mas seu corpo aguenta o veneno. |

---

## 4. Parte B — Cobra nos textos do mapa

A demanda 2 não tinha cobra. Mesmo formato dos arquivos já entregues.

**`eventos_distancia_cobra.json`**: mesmo formato de `eventos_distancia.json`, gatilho **`cobra_picou`** (alguém foi picado longe de você). **4 variações**, até 12 palavras, sempre com `{direcao}`. O suspense vem de não saber quem foi.

**`clareiras_cobra.json`**: mesmo formato de `clareiras.json`, conteúdo **`animal_cobra`**, nos dois locais (`beco` e `clareira_vazia`). **3 variações por local** = 6.

---

## 5. Parte C — Sons sugeridos (`sons_sugeridos.md`)

O Claude não consegue baixar do Freesound. Precisamos de **links** para o usuário baixar.

Procurar, de preferência no Freesound:

| Som | Uso | Prioridade |
|---|---|---|
| Folhas secas chacoalhando / cascavel | Sinal da cobra (substitui o provisório) | Alta |
| Sibilo de cobra | Cobra vista de perto | Média |
| Ganido de cão ou lobo ferido | Lobo ferido | Média |
| Pássaros batendo asas | Coruja trocando de pouso | Baixa |

Regras:
- **Só licença CC0** (domínio público). Confirmar na página do som. Nada de CC-BY, CC-BY-NC ou "uso livre" sem licença clara.
- Até 6 s. Gravação limpa, sem música nem voz.
- Para cada som: nome, link da página, autor, licença conferida, duração e uma frase dizendo por que serve.
- Pode sugerir 2 opções por som.

---

## 6. Parte D — Perguntas dos guardiões sobre os animais (`guardioes_animais.json`)

Os guardiões já perguntam sobre lobo, coruja e cão. Faltam a **cobra** e o **lobo que derruba**.

**2 perguntas por guardião** (10 no total). Para cada guardião: pelo menos **1 sobre a cobra**; a outra pode ser sobre a cobra ou sobre o lobo ter derrubado o jogador. Mantenha o que cada um valoriza e despreza e a voz de cada um (Bento rude, Iara maternal, Anselmo solene, Marta seca, Quincas comerciante).

**Formato:** o mesmo das entradas do formato v3 (`docs/correcoes/CORRECOES_guardioes_v3.md`, seção 2). Todas com `"requer": ["animais"]`. O arquivo é uma lista por guardião:

```json
{
  "versao_formato": 3,
  "guardioes": {
    "bento": [ { "id": "bento_16", "tipo": "pergunta", "...": "..." } ],
    "iara": [ ]
  }
}
```

IDs: continuar a numeração de cada guardião a partir do maior id que já existe em `conteudo/guardioes/<guardiao>.json`.

**Premissas novas** (acrescentadas ao vocabulário por esta demanda):

| Premissa | Verdadeira quando |
|---|---|
| `cobra_avisou` | O jogador passou a até 6 m de uma cobra e ouviu (ou viu) o sinal |
| `cobra_picou` | O jogador foi picado por uma cobra |
| `cobra_desviou` | O jogador ficou parado e a cobra foi embora |
| `lobo_derrubou` | O lobo alcançou e derrubou o jogador |

**Fatos verificáveis** (para perguntas com `"verificavel": true`; explicar em `verificacao` o que é checado, como antes):

| Fato | Valores |
|---|---|
| `cobra_reacao` | `"parou"` (ficou parado e ela foi embora) ou `"passou"` (seguiu andando e foi picado) |
| `lobo_reacao` | `"ficou"` ou `"correu"` (já usado em bento_04) |

Todas as regras de qualidade das correções v2 e v3 continuam valendo. As principais:
- Mentira com afinidade pior que a pior resposta.
- Respostas "más" tentadoras, nunca caricatas.
- Quem não teve o fato não sai perdendo.
- No máximo metade das opções extras empatando ou superando a melhor resposta.

---

## 7. Parte E — Falas de indicação das panelas (`indicacao.json`)

O que o guardião diz ao apontar uma das duas panelas, e o gesto que acompanha. Hoje cada guardião tem **uma** versão provisória (em `godot/scripts/regras.gd`, constante `INDICACAO`).

| Campo | Quando aparece | Quantidade | Marcador |
|---|---|---|---|
| `fala` | O guardião indica uma panela (a boa ou, mentindo, a ruim) | 3 | `{lado}` (`esquerda` ou `direita`) obrigatório |
| `nada` | O guardião se recusa a indicar | 3 | — |
| `verdade` | Gesto quando diz a verdade | 3 | — |
| `mentira` | Gesto quando mente | 3 | — |
| `preco` | **Só Quincas**: pede um item antes de indicar | 3 | — |

```json
{
  "versao_formato": 1,
  "indicacao": {
    "bento": {
      "fala": ["A da {lado}. E não volte pra reclamar."],
      "nada": ["Escolha sozinho. Coragem não se empresta."],
      "verdade": ["Bento olha você nos olhos enquanto fala."],
      "mentira": ["Bento limpa a faca num pano, sem olhar para você."]
    }
  }
}
```

**Regras:**
- A `fala` **não pode denunciar** se é verdade ou mentira: a mesma frase serve para os dois casos. Quem denuncia é o **gesto**.
- Os gestos seguem o sinal de cada guardião, definido no GDD e já usado nas janelas. Variar as palavras sem mudar o sinal:

| Guardião | `verdade` | `mentira` |
|---|---|---|
| Bento | Olha nos olhos | Limpa a faca sem olhar para o jogador |
| Iara | Oferece a tigela com as duas mãos | Oferece com uma mão; a outra se esconde |
| Anselmo | O sino toca ao fim da fala | O sino não toca |
| Marta | Faz uma pausa antes de responder | Responde rápido demais |
| Quincas | Mãos paradas | Esfrega as mãos e ri |

- O gesto tem de ser **reconhecível** para quem conhece o guardião, mas **sutil**: nada de "ele mente" ou "parece sincero".
- Até 15 palavras por texto.

---

## 8. Parte F — Resultado das panelas (`panelas.json`)

O que o jogador lê depois de comer. Hoje há uma versão de cada, em `godot/scripts/cenas/dialogo.gd`.

| Resultado | Quando | Texto provisório de hoje |
|---|---|---|
| `boa` | Comeu da panela boa | O caldo esquenta o corpo. Você se sente inteiro. |
| `ruim_efeito` | Panela ruim, o veneno tirou 1 ponto (o jogo acrescenta a linha "Você perdeu 1 ponto de …") | O gosto é amargo e algo se apaga em você. |
| `ruim_resistiu` | Panela ruim, mas a Resistência segurou | O gosto é amargo e a cabeça gira, mas seu corpo aguenta. |
| `ruim_sem_efeito` | Panela ruim, mas todas as habilidades já estavam em 1 | O gosto é amargo. Você já não tinha o que perder. |

**3 variações por resultado**, até 15 palavras, no formato:

```json
{ "versao_formato": 1, "resultados": { "boa": ["..."], "ruim_efeito": ["..."], "ruim_resistiu": ["..."], "ruim_sem_efeito": ["..."] } }
```

---

## 9. Ao terminar

Entregar em `entregas/AAAA-MM-DD_demanda4/` e **parar**. O Claude revisa e o usuário aprova antes de qualquer arquivo entrar em `conteudo/`.
