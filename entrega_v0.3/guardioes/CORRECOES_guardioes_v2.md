# A Última Noite — Correções do banco de guardiões (formato v2)

> Revisão da entrega v0.3 (bento, iara, anselmo, marta, quincas).
> A estrutura e os IDs estão corretos. As correções abaixo são de **design**: fazer a mentira ter custo, separar melhor as personalidades e evitar respostas óbvias.
> Entregar novamente os 5 arquivos no **formato v2** (seção 1). Sugestões que mudem regras: listar à parte como **PROPOSTA**.

---

## 1. Formato v2

Mudanças em relação à v1:

| Campo | Nível | O que faz |
|---|---|---|
| `versao_formato` | arquivo | Sempre `2` |
| `modificadores_tom` | arquivo | Como o guardião reage ao tom escolhido (firme, gentil, evasivo), somado à afinidade da resposta |
| `tipo: "narracao"` | entrada | Descrição de cena, lida pelo narrador. `"fala"` passa a ser só o que o guardião diz em voz alta |
| `mentira` | pergunta verificável | Afinidade aplicada **no lugar** da afinidade da resposta quando a verificação mostra que o jogador mentiu. **Obrigatório** em toda pergunta com `verificavel: true` |
| `requer` | pergunta | Lista de mecânicas do jogo das quais a pergunta depende (ver seção 2) |
| `registra` | resposta | Marcas que a resposta deixa no histórico do jogador, para outros guardiões ou perguntas consultarem |
| `contradiz` | resposta | Marcas que, se já existirem no histórico, tornam essa resposta uma contradição |
| `contradicao` | pergunta | Afinidade aplicada quando a resposta escolhida contradiz o histórico |
| `tom` | resposta (opcional) | Sobrescreve `modificadores_tom` só para aquela resposta |

Exemplo:

```json
{
  "guardiao": "anselmo",
  "versao_formato": 2,
  "modificadores_tom": { "firme": 1, "gentil": 0, "evasivo": -2 },
  "entradas": [
    { "id": "anselmo_01", "tipo": "narracao", "texto": "Frei Anselmo fecha o livro sem marcar a página." },
    { "id": "anselmo_02", "tipo": "fala", "texto": "Não vim julgar o que você fez. Vim ouvir se terá coragem de chamar o ato pelo nome." },
    {
      "id": "anselmo_05",
      "tipo": "pergunta",
      "texto": "Você mentiu para algum guardião esta noite?",
      "verificavel": true,
      "verificacao": "Checar respostas anteriores que falharam na verificação.",
      "requer": ["historico_respostas"],
      "mentira": { "afinidade": -4, "intencao": null },
      "contradicao": { "afinidade": -3 },
      "respostas": [
        { "texto": "Sim. Menti para obter vantagem.", "afinidade": 2, "intencao": null, "registra": ["confessou_mentira"] },
        { "texto": "Não menti para ninguém.", "afinidade": 1, "intencao": null, "registra": ["negou_mentira"], "contradiz": ["confessou_mentira"] },
        { "texto": "Não considero omissão uma mentira.", "afinidade": -2, "intencao": null, "tom": { "evasivo": -1 } }
      ],
      "silencio": { "afinidade": -2 }
    }
  ]
}
```

Regras de aplicação (o motor do jogo já fará assim):
- Afinidade final de uma resposta = afinidade da resposta (ou `mentira`, se verificada como falsa) + modificador de tom.
- Se a resposta contém uma marca de `contradiz` presente no histórico, soma-se `contradicao`.
- Afinidade de qualquer campo: inteiro entre −4 e +4. Modificadores de tom: entre −2 e +2.

---

## 2. Mecânicas que as perguntas podem usar

Usar em `requer` **apenas** mecânicas já definidas no GDD:

| Mecânica | Descrição |
|---|---|
| `bases_visitadas` | Quantas e quais bases o jogador visitou |
| `jogadores_vistos` | Jogadores detectados pelo personagem |
| `esconderijo` | Entradas em esconderijos |
| `aproximacao` | Por onde entrou na base (frente, fundos, se rondou a casa) |
| `rastros` | Rastros vistos ou deixados |
| `alerta_furtividade` | Alertas anônimos recebidos |
| `escuta` | Conversas ouvidas de esconderijo |
| `animais` | Encontros e ações com lobo, coruja e cão |
| `armadilhas` | Armadilhas encontradas ou acionadas |
| `inventario` | Itens carregados |
| `trocas` | Trocas de itens entre jogadores |
| `frases_prontas` | Frases trocadas entre jogadores (dicas verdadeiras ou falsas) |
| `prendas` | Prendas recebidas e cumpridas |
| `historico_respostas` | Respostas anteriores e marcas `registra` |

**Ainda não definidas** (não usar; se quiser propor, mandar como PROPOSTA): dar comida a outro jogador, promessas/acordos registrados, dano direto entre jogadores, apagar rastros de outro jogador, itens escondidos no inventário.

Perguntas da entrega v0.3 afetadas: bento_06, bento_11, bento_13, iara_08, iara_10, iara_14, anselmo_06, anselmo_11, marta_10, quincas_09, quincas_14. Reescrever usando mecânicas definidas ou trocar por outra pergunta.

---

## 3. Regras gerais de qualidade

1. **Toda pergunta verificável tem `mentira`**, com afinidade pior que a da resposta mais baixa. A mentira tem que doer.
2. **Sem respostas óbvias:** em pelo menos 8 das 12 perguntas, a diferença entre a melhor e a segunda melhor resposta é de no máximo 2 pontos.
3. **Respostas "más" precisam ser tentadoras**, nunca caricatas. Uma resposta egoísta ou pragmática que um jogador real escolheria ("Deixei para trás; eu estava sendo seguido") em vez de vilania declarada ("Quero ver os outros perderem").
4. **Opção extra nem sempre é a melhor.** No máximo metade das opções extras de cada guardião pode ter afinidade maior ou igual à melhor resposta. As outras devem ser alternativas com outro sabor (mais honesta, mais arriscada, revela algo ao guardião).
5. **Cruzamento entre guardiões:** em cada guardião, pelo menos 4 perguntas devem ter uma resposta que este guardião premia e que outro guardião puniria pelos mesmos valores.
6. **Entradas por guardião:** 1 `narracao` + 2 `fala` + 12 `pergunta`.
7. **Só elementos do mundo do jogo:** jogadores, guardiões, animais, bases, trilhas, itens. Nada de personagens que não existem (ex.: crianças).

---

## 4. Correções por guardião

### Velho Bento — reescrever
**Problema:** virou um personagem altruísta e ficou parecido demais com a Iara.
- O eixo dele é **coragem e franqueza**, não bondade. Ele não se importa se o jogador ajudou ou não os outros; se importa se enfrentou e se falou a verdade na cara.
- Ele **gosta de delação dita de frente** ("Fui eu que vi; foi o fulano") e despreza quem enrola. Isso precisa aparecer em pelo menos 2 perguntas, porque cria o conflito com a Iara.
- **Covardia confessada vale mais que bravata mentirosa.** Exemplo: "Corri, sim" (+1) contra "Nunca corro" quando a verificação mostra que correu (−4).
- Reescrever bento_03 (contradiz o design), bento_06, bento_07 e bento_13 (são perguntas de bondade, território da Iara).
- `modificadores_tom` sugerido: firme +2, gentil −1, evasivo −2.

### Dona Iara — reescrever as respostas
**Problema:** 10 das 12 perguntas têm resposta óbvia, e as respostas "más" são caricatas.
- Ela não descobre a má intenção pela confissão, e sim **pela verificação e pela reputação**. Por isso as perguntas dela devem ser majoritariamente verificáveis e com `mentira` forte: quem finge bondade é pego.
- As opções egoístas devem ser razoáveis (−1/−2) e tentadoras. As de má intenção explícita, quando existirem, devem render algo em outra base.
- Remover iara_13 (criança perdida).
- `modificadores_tom` sugerido: firme 0, gentil +1, evasivo −1.

### Frei Anselmo — ajustar
**Ponto forte:** premiar a confissão, inclusive de má intenção, está correto.
- Adicionar `mentira` em todas as verificáveis (anselmo_04 e anselmo_08 hoje não têm efeito algum).
- Usar `registra`, `contradiz` e `contradicao` em pelo menos 4 perguntas. Essa é a mecânica central dele.
- anselmo_12 ("se eu repetir sua primeira resposta...") deve ser ligada de fato a uma marca do histórico.
- `modificadores_tom` sugerido: firme +1, gentil 0, evasivo −2.

### Marta — ajustar
**Ponto forte:** a tensão entre delação (premiada) e proteção (punida) está ótima.
- **Silêncio:** ela lê silêncio como prudência e **gosta**. A maioria das perguntas deve ter `silencio` positivo (+1 ou +2). Exceção: perguntas em que ela exige informação diretamente.
- Adicionar `mentira` nas verificáveis. Hoje marta_04 dá +2 para "dois ou mais" mesmo quando é falso.
- `modificadores_tom` sugerido: firme +1, gentil −1, evasivo 0.

### Seu Quincas — ajustar
**Ponto forte:** voz e lógica de negociação estão consistentes.
- Adicionar `mentira` nas verificáveis (quincas_05, quincas_11, quincas_14). Mentir para o Quincas sobre o que se carrega deve custar caro.
- Rever quincas_09 e quincas_14, que dependem de mecânicas ainda não definidas (seção 2).
- `modificadores_tom` sugerido: firme 0, gentil +1, evasivo +1 (ele aprecia quem joga o jogo).

---

## 5. Entrega esperada

- 5 arquivos JSON no formato v2: `bento.json`, `iara.json`, `anselmo.json`, `marta.json`, `quincas.json`.
- Validador atualizado para as regras das seções 1 a 3.
- Lista separada de PROPOSTAS, se houver (por exemplo, novas mecânicas da seção 2).
