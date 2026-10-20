# A Última Noite — Correções do banco de guardiões (formato v3)

> Revisão da entrega v2 (bento, iara, anselmo, marta, quincas), feita pelo Claude e aprovada pelo usuário em 20/10/2026.
> A escrita e as vozes estão boas e devem ser mantidas. As correções abaixo vêm de duas causas: falhas de estrutura que o validador não pega, e decisões novas do MVP (mapa de pegadas, single-player, 5 guardiões).
> Entregar novamente os 5 arquivos no **formato v3**. Mudanças de regra: listar à parte como **PROPOSTA**. Não alterar decisões por conta própria.

---

## 1. O que mudou no jogo (contexto)

- O MVP é um **mapa visto de cima**: o jogador controla só as próprias pegadas, e o mapa se desenha conforme ele anda.
- **Single-player:** os outros 3 personagens são controlados pelo computador e seguem as mesmas regras. Nas perguntas, "outro jogador" continua valendo (o jogador não sabe quem é humano).
- **Pegadas sem nome, com tipo de calçado.** Cada personagem usa um calçado diferente (sorteado entre bota de couro, botina, alpercata, tamanco e pé descalço). A pegada mostra o calçado, nunca o nome. O jogador só sabe **quem** usa um calçado se já **viu a pessoa**, ou se alguém contou por frase pronta (que pode ser falsa).
- **O lobo fica perto das bases.** O encontro é provável, mas não garantido.
- **Inventário entra** no MVP, mas **sem troca entre jogadores**: os itens são do próprio jogador e podem ser oferecidos a um guardião (principalmente ao Seu Quincas). O jogador **não vê** o inventário dos outros.

---

## 2. Formato v3

Tudo do v2 continua valendo. Mudanças:

| Campo | Nível | O que faz |
|---|---|---|
| `versao_formato` | arquivo | Sempre `3` |
| `premissa` | pergunta | Lista de fatos que precisam ter acontecido para a pergunta ser sorteada. Todos precisam ser verdadeiros. Vocabulário fechado (seção 3) |
| `reputacao` | arquivo | Como o guardião reage a marcas deixadas em **outras** bases. Mapa `marca → afinidade`, aplicado **uma vez** no início da visita. Cada valor entre −2 e +2 |

Exemplo:

```json
{
  "guardiao": "iara",
  "versao_formato": 3,
  "modificadores_tom": { "firme": 0, "gentil": 1, "evasivo": -1 },
  "reputacao": { "delatou_jogador": -2, "protegeu_identidade": 1, "alertou_perigo": 1 },
  "entradas": [
    {
      "id": "iara_04",
      "tipo": "pergunta",
      "texto": "Você encontrou o lobo ferido? O que fez?",
      "verificavel": true,
      "verificacao": "Checar a ação do jogador diante do lobo ferido.",
      "requer": ["animais"],
      "premissa": ["encontrou_lobo_ferido"],
      "mentira": { "afinidade": -4, "intencao": "ma" },
      "respostas": [ ]
    }
  ]
}
```

Regras de aplicação (o motor já fará assim):
- Só é sorteada a pergunta cujas mecânicas de `requer` existem no MVP **e** cuja `premissa` é verdadeira para aquele jogador.
- `reputacao` soma à afinidade inicial da visita, uma vez por marca presente no histórico, e só conta marcas registradas em **outras** bases.

---

## 3. Vocabulário

### 3.1 Mecânicas permitidas em `requer` (MVP)

`bases_visitadas`, `jogadores_vistos`, `esconderijo`, `aproximacao`, `rastros`, `armadilhas`, `historico_respostas`, `frases_prontas`, `animais`, `inventario`

**Fora do MVP** (não usar em `requer`): `trocas`, `prendas`, `escuta`, `alerta_furtividade`.

### 3.2 Premissas permitidas

| Premissa | Verdadeira quando |
|---|---|
| `encontrou_lobo` | O lobo entrou no alcance de vista do jogador |
| `lobo_avancou` | O lobo rosnou e avançou sobre o jogador |
| `encontrou_lobo_ferido` | O jogador viu o lobo mancando |
| `coruja_notou` | A coruja olhou para o jogador e piou |
| `coruja_avisou` | A coruja avisou sobre outro personagem por perto |
| `cao_ofereceu_guia` | O cão abanou o rabo e esperou o jogador |
| `notou_armadilha` | O jogador percebeu uma armadilha sem pisar |
| `acionou_armadilha` | O jogador pisou numa armadilha |
| `viu_jogador` | O jogador viu ao menos um outro personagem |
| `viu_pegadas_alheias` | O jogador viu pegadas de outro personagem |
| `reconhece_calcado` | O jogador viu pegadas de um calçado cujo dono ele já viu |
| `usou_esconderijo` | O jogador entrou em algum esconderijo |
| `sumiu_na_mata` | O jogador usou "sumir na mata" ao menos uma vez |
| `recebeu_frase` | O jogador recebeu ao menos uma frase pronta |
| `enviou_frase` | O jogador enviou ao menos uma frase pronta |
| `tem_item` | O inventário do jogador não está vazio |
| `visitou_outra_base` | O jogador já visitou outra base antes desta |
| `marca:<nome>` | A marca `<nome>` existe no histórico (ex.: `marca:negou_mentira`) |

Precisa de uma premissa que não está na lista: mandar como **PROPOSTA**.

---

## 4. Regras gerais

1. **Toda pergunta que supõe um fato tem `premissa`.** Teste: se o fato não aconteceu, alguma resposta continua verdadeira? Se nenhuma continua, a pergunta precisa de `premissa`.
2. **12 perguntas usáveis no MVP por guardião.** Perguntas que dependem de mecânicas fora do MVP saem do arquivo principal. Para não perder o trabalho, guarde-as em `fora_do_mvp/<guardiao>.json`, no mesmo formato.
3. **Quem não teve o fato não pode sair perdendo por isso.** Se uma pergunta oferece "não aconteceu" como resposta, ela não pode valer menos que a melhor resposta para quem passou pelo fato, só por ter sido honesta (caso da iara_10).
4. **Identidade só por visão.** Uma resposta que nomeia alguém só é verdadeira se o jogador viu a pessoa, ou viu pegadas de um calçado cujo dono já viu. A `verificacao` deve dizer isso.
5. **`reputacao` em todos os guardiões.** Cada arquivo reage a pelo menos 3 marcas registradas por **outros** guardiões, coerente com o que ele valoriza e despreza. Use as marcas que já existem (seção 6).
6. Todas as regras do CORRECOES v2 continuam valendo (mentira dói, sem respostas óbvias, respostas más tentadoras, opção extra nem sempre a melhor, cruzamento entre guardiões, 1 narração + 2 falas + 12 perguntas, só elementos do mundo do jogo).

---

## 5. Correções por pergunta

### Precisam de `premissa`
| Pergunta | Premissa sugerida |
|---|---|
| bento_04 | `lobo_avancou` |
| bento_05 | `viu_pegadas_alheias` (ver também regra 4) |
| bento_13 | `coruja_notou` |
| iara_04 | `encontrou_lobo_ferido` |
| iara_05 | `coruja_avisou` |
| iara_06 | `cao_ofereceu_guia` |
| iara_07 | `notou_armadilha` ou `acionou_armadilha` (escolha pelo texto) |
| iara_13 | `viu_jogador` |
| iara_14 | `recebeu_frase` |
| anselmo_12 | `marca:negou_mentira` |
| anselmo_13 | `notou_armadilha` |
| marta_05 | `visitou_outra_base` e `viu_pegadas_alheias` |
| marta_14 | `notou_armadilha` |

Revise as demais com o teste da regra 1; esta lista pode não estar completa.

### Dependem de mecânicas fora do MVP: substituir
| Pergunta | Mecânica fora | Orientação |
|---|---|---|
| bento_11 | `escuta` | Nova pergunta de coragem ou franqueza com mecânica do MVP |
| iara_12 | `prendas` | Nova pergunta verificável de bondade (ex.: frases prontas, animais) |
| anselmo_09 | `trocas` | Nova pergunta de confissão que use `inventario` ou `frases_prontas` |
| anselmo_11 | `prendas` | Nova pergunta com `registra`/`contradiz` |
| marta_06 | `alerta_furtividade` | Nova pergunta de informação (ex.: calçados, rotas, pegadas) |
| quincas_06, 09, 11, 14 | `trocas` | Ver Quincas, abaixo |

### Ajustes de conteúdo
- **bento_05 e marta_05:** reescrever a `verificacao` pela regra 4 (calçado + visão).
- **marta_08:** o jogador não vê o inventário dos outros. Reescrever sobre o que o jogador pode ver (calçados, rotas, para onde alguém foi) ou trocar por outra pergunta.
- **iara_10:** "Não acionei nenhuma" vale menos que acionar e avisar. Corrigir pela regra 3.
- **Seu Quincas:** sem troca entre jogadores, o centro dele passa a ser **o próprio inventário do jogador e o que ele oferece ao Quincas**. As 4 perguntas novas devem usar `inventario` (o que carrega, o que oferece, se mente sobre o que tem). Mentir sobre o inventário continua custando caro.

---

## 6. Marcas existentes (para `reputacao` e `contradiz`)

Hoje 24 das 28 marcas nunca são consultadas. Exemplos de uso esperado:
- **Iara** reage mal a `delatou_jogador`, `explorou_vulneravel`, `enviou_dica_falsa`; bem a `protegeu_identidade`, `alertou_perigo`.
- **Bento** reage bem a `confessou_fuga` e `delatou_jogador` (dito de frente); pode usar `contradiz` entre `alegou_coragem` e `confessou_fuga`.
- **Marta** reage bem a `delatou_jogador`; mal a `protegeu_identidade`, `protegeu_jogador`.
- **Anselmo** reage bem a `confessou_mentira`, `confessou_omissao`, `corrigiu_contradicao`.
- **Quincas** reage bem a `negociou_com_lucro` e mal a quem deixa claro que não negocia.

Marcas novas podem ser criadas nas perguntas novas, com nome descritivo em `snake_case`.

---

## 7. Entrega esperada

- 5 arquivos no formato v3: `bento.json`, `iara.json`, `anselmo.json`, `marta.json`, `quincas.json`, cada um com 12 perguntas usáveis no MVP.
- Pasta `fora_do_mvp/` com as perguntas retiradas, no mesmo formato.
- Validador atualizado: `versao_formato` 3, `requer` só com a lista 3.1, `premissa` só com a lista 3.2, faixa de `reputacao` (−2 a +2) e mínimo de 3 marcas de outros guardiões por arquivo.
- Lista de **PROPOSTAS**, se houver.
