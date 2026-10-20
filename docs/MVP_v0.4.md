# A Última Noite — Decisões do MVP (v0.4)

> Aprovado pelo usuário em 20/10/2026. **Fonte da verdade** do MVP.
> O que não estiver aqui continua valendo como no GDD v0.3 (guardiões, sistema de afinidade, animais, modelo de diálogo).
> Itens marcados **(sugestão)** são orientação de design ainda não testada; podem mudar no protótipo.

---

## 1. Resumo

O primeiro MVP é jogado num **mapa visto de cima**, onde o jogador controla **apenas as pegadas** do seu personagem. A câmera isométrica fica para depois que o MVP provar que o jogo é divertido.

O centro do jogo é informação incompleta: quem passou por onde, quem mente, qual panela é a boa.

| Item | Decisão |
|---|---|
| Modo | **Single-player.** Os outros 3 personagens são controlados pelo computador |
| Velocidade | Jogador 5 m/s; personagens do computador 1,5 m/s (ajustado em 20/10/2026). Depois que o jogador registra a chegada, o computador anda 3x mais rápido e vai direto para a saída, sem novas visitas |
| Ritmo | Tempo real, com movimento lento entre clareiras |
| Guardiões | Só os 5 definidos (Bento, Iara, Anselmo, Marta, Quincas) + 1 base vazia. Os guardiões 6 a 9 ficam para depois dos testes |
| Mapa | 450 × 450 m, 10 a 12 clareiras: 6 com base, 4 a 6 sem base |
| Tecnologia | Godot 4 + GDScript, dados em JSON |

---

## 2. Floresta, trilhas e clareiras

- A mata fechada funciona como parede. O jogador anda por trilhas estreitas que ligam clareiras.
- Uma trilha pode se abrir em **2 ou 3 caminhos** ou terminar num **beco**.
- No código, o mapa é um grafo: pontos (clareiras, bifurcações, becos) ligados por trechos de trilha.
- A posição das bases e as trilhas são sorteadas a cada partida.

**Becos (sugestão):** cada beco sorteia um conteúdo entre esconderijo, armadilha, animal, item ou nada.

**Regras do sorteio (sugestão):** toda base alcançável; a maioria das bases com mais de um caminho até ela; becos de 1 ou 2 trechos; pontos de partida a distâncias parecidas das bases.

---

## 3. Visão noturna

- O mapa é um **pergaminho que começa escuro e desfocado**. As áreas ficam nítidas conforme o jogador anda e enxerga.
- **Mata (20/10/2026):** mata fechada de copas escuras vistas de cima, com sub-bosque, árvores grandes e tons variados de claro e escuro, fora das trilhas e em anel em volta das clareiras. Aparecem só onde a névoa se abriu. São só desenho: nas regras, a mata já é parede.
- **Contraste e daltonismo (20/10/2026):** nada importante depende só de cor. A trilha é um tracejado fino; as pegadas têm borda clara; as suas pegadas são vazadas e as dos outros cheias; você é um círculo com anel escuro e os outros, losangos; nomes em letra clara com contorno escuro.
- **Visual (decidido em 20/10/2026):** onde a névoa se abre aparece pergaminho bege com manchas de umidade e borda tostada; trilhas em tinta marrom; pegadas pretas em forma de sola e salto (bota, botina), sola fina (alpercata), bloco (tamanco) e pé com dedos (descalço). A noite em volta é azul-escura. Referências do usuário: pegadas de sola e salto sobre papel envelhecido e a paleta de mapa antigo, sem copiar elementos de obras existentes.
- Aparecem as trilhas percorridas e o que está no alcance de vista.
- Trilhas percorridas nunca somem. Pegadas vistas e trechos vistos de longe voltam ao escuro depois de um tempo (ver Inteligência, seção 7).
- **(sugestão)** A luz âmbar das bases se vê de longe, como ponto de luz, sem a trilha até ela.
- **(sugestão)** O mapa guarda o que foi visto, não o que está acontecendo: as pegadas numa trilha são as da última passagem.
- **(sugestão)** Eventos à distância chegam como texto: um lobo uivou ao norte, a coruja piou perto do moinho.

---

## 4. Pegadas e calçados

- **O nome dos personagens nunca aparece nas pegadas.**
- Só as suas pegadas aparecem destacadas para você. As dos outros só são vistas dentro do seu alcance de vista.
- Cada um dos 4 personagens usa um **tipo de calçado**, sorteado por partida entre 5: **bota de couro, botina, alpercata, tamanco e pé descalço**. A pegada mostra o calçado.
- Para ligar um calçado a uma pessoa, o jogador precisa **ver a pessoa** ao menos uma vez, ou receber essa informação por frase pronta (que pode ser falsa).

### Nomes

- **O jogador escolhe o nome do próprio personagem** (decidido em 20/10/2026).
- Os personagens do computador recebem nomes sorteados de uma lista, sem repetir na partida.
- Um nome só aparece para o jogador depois que ele **vê** aquele personagem, ou numa frase pronta. Nas respostas do tipo "digo quem era", o jogador escolhe entre os nomes que conhece.
- **(sugestão)** Nome do jogador com até 12 caracteres, diferente dos nomes da lista dos personagens do computador.

---

## 5. Bases

- Cada base aparece em **planta baixa**, com janela, porta da frente, porta dos fundos e esconderijo destacados. O jogador escolhe por onde se aproximar.
- **(sugestão)** Olhar pela janela mostra o que o guardião faz, se há alguém dentro, ou se ele faz o sinal de mentira para alguém.
- O diálogo com os guardiões segue o modelo híbrido da v0.3, com perguntas no formato v3 (ver `docs/correcoes/CORRECOES_guardioes_v3.md`).

---

## 6. Perigos

### Armadilhas
- Ficam **ocultas** até alguém pisar nelas ou percebê-las.
- Ao pisar: o personagem fica **preso** (tempo definido pela Força) e depois **lento**, com metade da velocidade por 10 s (duração reduzida pela Resistência).
- **(sugestão)** Uma armadilha acionada deixa um rastro diferente, que outros leem depois.

### Veneno (panela ruim)
- Retira **1 ponto da maior habilidade** do personagem, perdido pela noite toda.
- Empate entre as maiores: sorteio.
- Nenhuma habilidade cai abaixo de 1. Com todas em 1, o veneno não afeta as habilidades.

### Animais
- Lobo, coruja e cão entram no MVP, como na v0.3.
- **O lobo fica perto das bases.**

---

## 7. Atributos

Força, Inteligência, Carisma, Furtividade e Resistência: 12 pontos, mínimo 1 e máximo 5 em cada. Os números são ponto de partida para teste.

Referência de escala: velocidade na trilha de 1,5 m/s; trechos de trilha de 20 a 40 m.

| Atributo | Efeito | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| Força | Velocidade abrindo caminho na mata, em relação à trilha | 20% | 30% | 40% | 50% | 60% |
| Força | Tempo preso numa armadilha | 8 s | 6,5 s | 5 s | 3,5 s | 2 s |
| Inteligência | Alcance de vista | 8 m | 11 m | 14 m | 17 m | 20 m |
| Inteligência | Tempo que pegadas vistas e trechos vistos de longe ficam no mapa | 30 s | 45 s | 60 s | 90 s | 120 s |
| Inteligência | Distância para notar uma armadilha | só ao pisar | 2 m | 3 m | 4 m | 5 m |
| Furtividade | Usos do "sumir na mata" por noite | 1 | 1 | 2 | 2 | 3 |
| Furtividade | Tempo que suas pegadas ficam visíveis para os outros (ajustado em 20/10/2026) | 20 s | 19 s | 18 s | 16,5 s | 15 s |
| Furtividade | Leitura de pegadas alheias (cumulativa) | alguém passou + calçado | + direção | + recente ou antiga | + pegadas fracas de quem andou oculto | + quantas pessoas passaram |
| Resistência | Chance de resistir ao veneno | 0% | 10% | 20% | 30% | 40% |
| Resistência | Redução da duração da lentidão por armadilha | 0% | 15% | 30% | 45% | 60% |
| Carisma | Opções extras no diálogo | conforme o mínimo de cada pergunta |  |  |  |  |

Regras:
- O rastro de mato quebrado de quem abre caminho fica visível para todos por 180 s.
- O Carisma não tem efeito no mapa no MVP.
- Risco a observar: a Inteligência pode ficar forte demais; o Carisma, fraco demais fora das bases.

---

## 8. Sumir na mata

- Habilidade ativa: o personagem fica oculto. Vê quem passa ao lado sem ser visto.
- Cada uso dura **5 s**. Usos por noite pela Furtividade (seção 7).
- **Parado**, gasta 1 s por segundo. **Andando**, o gasto começa em 1,0 e é multiplicado por 1,1 a cada segundo seguido de movimento; volta a 1,0 só depois de 1 s parado. Andando sem parar, o uso dura cerca de 4,3 s.
- **(sugestão)** O cão e a coruja percebem quem está oculto.

---

## 9. Personagens do computador

- Jogam com as **mesmas regras e limites** do jogador. Só sabem o que a própria visão e lembrança mostram.
- No início da partida são sorteados: atributos (12 pontos, de 1 a 5), ponto de partida e um **perfil** (pode repetir).

| Perfil | Na trilha | Pegadas alheias | Ao ver alguém | Aproximação | Diálogo | Panela |
|---|---|---|---|---|---|---|
| Cauteloso | Evita becos; prefere trilhas conhecidas | Desvia | Some na mata se puder; senão se afasta | Olha pela janela antes | Verdade; silêncio quando não sabe | Segue o guardião, salvo se perceber o sinal de mentira |
| Ousado | Explora trilhas novas e becos | Segue | Continua | Porta da frente | Verdade, tom firme | Segue o guardião |
| Trapaceiro | Ronda as bases antes | Segue à distância | Some na mata para observar | Porta dos fundos | Mente quando compensa | Escolhe a oposta se desconfiar |

**Ciclo:** escolher a base mais próxima ainda não visitada cuja luz já viu (sem nenhuma, explorar) → andar até lá → reagir ao que aparece → aproximar, conversar, escolher a panela → repetir até o fim da noite.

**Regras extras:**
- Chance de perceber o sinal de mentira: 10% por ponto de Inteligência.
- Pausa de 2 a 5 s nas bifurcações.
- **(sugestão)** Cada um manda 1 ou 2 frases prontas ao jogador por noite; as do Trapaceiro são falsas.

---

## 10. Mecânicas do MVP

| Entram | Ficam para depois |
|---|---|
| Bases visitadas, jogadores vistos, esconderijo, aproximação, rastros (com calçado), armadilhas, histórico de respostas, frases prontas, animais, inventário | Trocas entre jogadores, prendas, escuta, alerta de furtividade |

O **inventário** é do próprio jogador; ele pode oferecer itens a um guardião (principalmente ao Seu Quincas). Não há troca entre jogadores, e ninguém vê o inventário dos outros.

---

## 11. Vitória

- **Ganha quem fizer mais pontos** (decidido em 20/10/2026).
- Para pontuar, o personagem precisa **chegar ao ponto oposto do mapa** e registrar a chegada antes do amanhecer.
- Detalhes e valores dos pontos: `docs/sistemas/pontuacao_v1.md`.

## 12. Em aberto

- [x] Nomes: o jogador escolhe o seu; os do computador vêm de uma lista sorteada.
- [x] Catálogo de itens aprovado: `docs/sistemas/itens_v1.md`.
- [ ] Valores dos pontos (proposta em `docs/sistemas/pontuacao_v1.md`).
