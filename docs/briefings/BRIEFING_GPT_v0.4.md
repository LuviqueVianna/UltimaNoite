# A Última Noite — Briefing para o ChatGPT (v0.3 → v0.4)

> Atualiza o BRIEFING_GPT_v0.3. Decisões tomadas pelo usuário em 20/10/2026.
> **Fonte da verdade:** a proposta de MVP v0.4 aprovada (resumida na seção 1) e, para o que não mudou, o GDD v0.3.
> Sugestões que mudem decisões: sempre em lista separada, com o título **PROPOSTA**. Não altere decisões por conta própria.

---

## 1. O que mudou

O primeiro MVP **não é isométrico**. É um mapa visto de cima, inspirado na ideia de "ver só pegadas":

| Tema | v0.3 | v0.4 (MVP) |
|---|---|---|
| Câmera | Isométrica 2.5D | Mapa visto de cima, num **pergaminho** que começa **escuro e desfocado** (é noite) e fica nítido onde o jogador anda e enxerga |
| Controle | Personagem com sprite | O jogador controla **só as próprias pegadas** |
| Modo | Multiplayer 4 jogadores | **Single-player**: os outros 3 personagens são controlados pelo computador, com as mesmas regras |
| Guardiões | 9 + 1 base vazia | Jogo completo continua 9 + 1. **MVP: só os 5 já definidos + 1 base vazia**, em 10 a 12 clareiras |
| Mapa | Labirinto de clareiras | Mata fechada (parede), trilhas estreitas com **bifurcações e becos**, clareiras com bases |
| Pegadas | — | **Sem nome.** Cada personagem tem um **tipo de calçado** sorteado por partida (bota de couro, botina, alpercata, tamanco, pé descalço). Só se sabe quem é **vendo a pessoa** |
| Bases | Pontos de interesse ao redor | Vistas em **planta baixa**, com janela, porta da frente, porta dos fundos e esconderijo destacados |
| Animais | 3 animais ambíguos | Entram no MVP; **o lobo fica perto das bases** |
| Mecânicas fora do MVP | — | Trocas entre jogadores, prendas, escuta, alerta de furtividade |
| Novas regras | — | Armadilhas ocultas; "sumir na mata" (5 s por uso, usos limitados por noite); Força abre caminho pela mata; Resistência contra veneno e armadilha; veneno tira 1 ponto da maior habilidade |

---

## 2. Como trabalhamos

- **Usuário:** decide e aprova. Nada entra no projeto sem aprovação.
- **Claude:** regras, sistemas, formatos, código e **revisão** de toda entrega do ChatGPT antes de chegar ao usuário.
- **ChatGPT:** conteúdo em volume e arte, sempre nos formatos definidos aqui.

Regras:
1. **Uma demanda por vez**, na ordem da seção 3. Ao terminar uma, pare e aguarde.
2. Entrega fora do formato volta sem revisão de conteúdo.
3. Junto de cada entrega: o que foi feito, o que ficou mais fraco e as PROPOSTAS, se houver.
4. Só elementos do mundo do jogo: personagens, guardiões, animais, bases, trilhas, clareiras, itens. Nada de personagens que não existem.

---

## 3. Fila de demandas

| Ordem | Demanda | Arquivo de referência |
|---|---|---|
| 1 | Correções do banco de guardiões | `CORRECOES_guardioes_v3.md` |
| 2 | Textos do mapa: janelas, eventos à distância, becos e clareiras, frases prontas | Seção 4 deste briefing |
| 3 | Quadro de estilo do pergaminho | Seção 5 deste briefing |

Os textos vêm antes da arte porque o protótipo roda com arte provisória, mas não roda sem texto.

---

## 4. Demanda 2 — Textos do mapa

Cinco arquivos JSON. Regras comuns:
- Português do Brasil, tom de suspense, frases curtas (até 15 palavras, salvo indicação).
- **Nunca** nomear personagens nem revelar se uma informação é verdadeira. Use os marcadores entre chaves, que o jogo preenche: `{direcao}` ("ao norte", "perto do moinho"), `{calcado}`, `{personagem}`, `{base}`, `{lado}`, `{item}`.
- IDs únicos no padrão indicado. `versao_formato: 1` em todos.

### 4.1 `janelas.json` — o que se vê ao olhar pela janela

```json
{
  "versao_formato": 1,
  "janelas": [
    { "id": "bento_janela_01", "base": "bento", "situacao": "sozinho", "texto": "Bento afia a faca devagar, de costas para a porta." }
  ]
}
```

- `base`: `bento`, `iara`, `anselmo`, `marta`, `quincas`, `vazia`.
- `situacao`:
  - `sozinho`: o guardião está só.
  - `com_visitante`: outro personagem está lá dentro. Descrever **sem identificar** (pode usar `{calcado}`: "botas de couro junto ao fogão").
  - `sinal_mentira`: o guardião faz o **seu** sinal de mentira (GDD 2.2) para o visitante.
  - `sem_ninguem`: só para a base `vazia`.
- Quantidade: **3 textos por situação** para cada guardião (9 por guardião); **5** para a base vazia.
- O sinal de mentira tem de ser reconhecível por quem conhece o guardião, mas sutil.

### 4.2 `eventos_distancia.json` — o que se ouve de longe

```json
{
  "versao_formato": 1,
  "eventos": [
    { "id": "lobo_uivou_01", "gatilho": "lobo_uivou", "texto": "Um lobo uiva {direcao}." }
  ]
}
```

- `gatilho`: `lobo_uivou`, `lobo_atacou`, `coruja_piou`, `cao_latiu`, `armadilha_acionada`, `porta_de_base`, `mato_quebrado`.
- **4 variações por gatilho**, até 12 palavras, sempre com `{direcao}`.
- Os eventos são verdadeiros; o suspense vem de não saber **quem** causou.

### 4.3 `clareiras.json` — becos e clareiras sem base

```json
{
  "versao_formato": 1,
  "descobertas": [
    { "id": "beco_nada_01", "local": "beco", "conteudo": "nada", "texto": "A trilha morre num paredão de samambaias. Só o vento responde." }
  ]
}
```

- `local`: `beco` ou `clareira_vazia`.
- `conteudo`: `nada`, `esconderijo`, `item` (usar `{item}`), `animal_lobo`, `animal_coruja`, `animal_cao`, `armadilha_notada`, `armadilha_acionada`.
- **3 variações** por combinação de `local` e `conteudo` (48 no total).
- Texto lido **quando o jogador descobre** o conteúdo. Uma armadilha só aparece ao ser notada ou acionada.
- Ambientação da Direção de Arte v1, seção 1.1 (Mata Atlântica, interior rural, meados do século XX). Sobrenatural sugerido, nunca mostrado.

### 4.4 `frases_prontas.json` — mensagens entre personagens

```json
{
  "versao_formato": 1,
  "frases": [
    { "id": "fp_panela_01", "categoria": "panela", "texto": "Na {base}, a panela da {lado} é a boa.", "marcadores": ["base", "lado"] }
  ]
}
```

- `categoria`: `panela`, `rota` (para onde leva uma trilha), `perigo` (armadilha ou lobo numa região), `identidade` (quem usa qual calçado), `pedido` (pedir ajuda ou informação), `aviso` (alerta genérico).
- **8 frases por categoria**, até 10 palavras.
- Cada frase precisa funcionar **verdadeira ou falsa**: o jogo decide o conteúdo dos marcadores. Nada de frase que só faz sentido como mentira.
- `marcadores`: lista dos marcadores usados no texto.

### 4.5 `nomes.json` — nomes dos personagens do computador

O jogador escolhe o próprio nome. Os 3 personagens do computador recebem nomes sorteados desta lista.

```json
{
  "versao_formato": 1,
  "nomes": [
    { "id": "nome_01", "nome": "Zé Tonico" }
  ]
}
```

- **24 nomes**, metade femininos e metade masculinos.
- Nomes e apelidos do interior do Brasil em meados do século XX (ex.: Zé Tonico, Dona Cotinha, Bastião, Filó).
- Até 12 caracteres, sem repetir, sem nomes de pessoas famosas e sem coincidir com os guardiões.

---

## 5. Demanda 3 — Quadro de estilo do pergaminho

A Direção de Arte v1 fica assim:
- **Suspensa no MVP:** tipo B (base isométrica). O quadro de estilo isométrico da Cabana do Bento já entregue fica arquivado.
- **Baixa prioridade:** tipos A (ficha) e C (cena de diálogo).
- **Continuam valendo:** 1.1 (ambientação), 1.4 (paleta-base, adaptada ao pergaminho), 1.6 (proibidos) e as fichas da seção 3.

### 5.1 Pedido

**3 estilos diferentes** de pergaminho, **uma imagem por estilo**, mostrando o mesmo trecho de mapa:
- Vista **de cima, ortográfica**, sem perspectiva.
- Metade da imagem **escura e desfocada** (não explorada); a outra metade nítida (explorada).
- Na parte nítida: duas trilhas que se cruzam, uma bifurcação que termina em beco, e a **Cabana do Bento em planta baixa** com janela, porta da frente, porta dos fundos e moita (esconderijo) destacadas.
- Pegadas de **dois calçados diferentes** (bota de couro e pé descalço) cruzando a trilha, legíveis a 200 px.
- Na parte escura: **um ponto de luz âmbar ao longe** (uma base ainda não alcançada).

Sugestões de direção para os 3 estilos (pode propor outras):
1. Nanquim sobre papel envelhecido, traço de cartógrafo.
2. Carvão e grafite, como caderno de campo de um caçador.
3. Tinta aguada sépia com manchas de umidade.

### 5.2 Regras

- **Não** pode lembrar o mapa de Harry Potter: nada de nomes ao lado das pegadas, faixas ou bandeirolas com letras, moldura ornamental, brasões, castelo.
- Sem texto, letras ou números em parte alguma.
- Paleta: tons de pergaminho e sépia na parte explorada; azul-noite `#0E1A2B` e verde-musgo `#1F3328` na parte escura; âmbar `#E89A3C` só na luz da base.
- Pare depois das 3 imagens e aguarde a escolha do usuário.

Junto de cada imagem: estilo, prompt exato usado e o que ficou mais fraco.

### 5.3 Depois da escolha (não fazer agora)

No estilo escolhido: plantas baixas das 6 bases do MVP, os 5 tipos de pegada, e símbolos para luz de base ao longe, armadilha notada, armadilha acionada, mato quebrado e esconderijo.
