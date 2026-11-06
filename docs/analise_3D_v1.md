# A Última Noite — Análise da mudança de 2D para 3D

> Status: **ANÁLISE APROVADA** em 03/11/2026 (decisões na seção 7). Protótipo técnico 3D feito no mesmo dia (seção 8).
> Relação com outros documentos: complementa o `PROPOSTA_caminho_3D_v1.md` (aprovado em 21/10/2026), que define as etapas MVP → isométrico 3D → terceira pessoa.
> Base da análise: repositório `LuviqueVianna/UltimaNoite`, commit `e7005c1` (23/10/2026).

---

## 1. O que já temos

O código do MVP tem cerca de 5.400 linhas de GDScript, já separado como a proposta de 21/10 pedia.

| Camada | Arquivos | Linhas (aprox.) | Na mudança para 3D |
|---|---|---|---|
| **Conteúdo** | `conteudo/`: 5 guardiões com 20 perguntas cada, textos do mapa, animais, panelas, itens, nomes | — | **100% reaproveitado** |
| **Lógica** | `mundo/` (mundo, personagem, IA, fauna, armadilhas, visita), `mapa/`, `regras.gd`, `dados.gd` | ~2.500 | **Quase toda reaproveitada** |
| **Apresentação** | `mapa_view.gd`, `main.gd`, `dialogo.gd`, tutorial, configurações, shader do pergaminho | ~1.900 | **Trocada ou adaptada** |
| **Sons** | 17 arquivos `.ogg` | — | Reaproveitados; melhoram com som posicional em 3D |

Verificado no código:
- Nenhum script de lógica depende de nó visual: todos são `RefCounted`, sem desenho e sem acesso à cena.
- O mapa já está em metros (450 × 450 m). Os `Vector2` da lógica passam a ser o chão do mundo 3D (x, z) sem reescrever regras.
- A tela de diálogo é interface e continua 2D mesmo num jogo 3D.

---

## 2. Impacto da mudança

### 2.1 Código — moderado
A apresentação é refeita: câmera, terreno, mata, bases, pegadas como decalques (`Decal`) e escuridão. A lógica precisa de dois ajustes:
- **Visão por linha de visada.** Em 3D, árvores e casas bloqueiam a vista. A regra "vejo quem está a X metros" vira "vejo quem está a X metros e sem nada no meio". Isso muda o equilíbrio: a Torre da Marta, por exemplo, passa a ver mais por causa da altura.
- **Altura.** Hoje o mundo é plano. Torre, moinho e terreno passam a ter altura.

### 2.2 Design — maior do que parece
O MVP foi pensado em torno de **não ver as pessoas**: só pegadas num pergaminho que se revela. Em 3D o jogador vê silhuetas, luz e movimento.
- O mistério do calçado sem nome continua funcionando.
- O jogo tende a ficar mais de furtividade e menos de dedução.
- A etapa isométrica (câmera alta, ortográfica) preserva melhor a ideia original do que a terceira pessoa.

### 2.3 Arte — o maior custo, de longe
Será preciso:
- modelos para 4 personagens, 5 guardiões, 4 animais (lobo, coruja, cão, cobra) e 6 bases;
- vegetação de Mata Atlântica;
- **animações**: andar, correr, agachar, esconder, mancar, morder.

Pacotes prontos (Kenney, Quaternius) servem para prototipar, mas quase nada pronto tem cara de interior rural brasileiro dos anos 1950. Esse custo é parecido em qualquer engine.

### 2.4 Plataforma
O MVP usa o renderizador **Compatibility** e exporta para **navegador**. Com a decisão por **PC** (seção 7), o 3D usa o renderizador **Forward+**, que permite névoa volumétrica, sombras suaves e mais luzes. O MVP 2D continua como está.

---

## 3. Godot continua sendo a melhor escolha?

**Para este projeto, sim.** Situação em novembro de 2026:
- **Godot 4.6** (janeiro/2026): Jolt Physics como física padrão em projetos 3D novos, reflexos de tela refeitos, IDs internos de nós estáveis.
- **Godot 4.7** (junho/2026): nó `AreaLight3D` para fontes de luz retangulares, como janelas, com sombras suaves — combina diretamente com a luz âmbar saindo das janelas das bases.
- Licença MIT, sem custo nem risco de mudança unilateral.

O escopo do jogo (poucas personagens, cenário estilizado, noite, câmera controlada) está bem dentro do que o Godot faz em 3D.

---

## 4. O Unity atenderia?

Atenderia, tecnicamente sem problema. A licença hoje não é obstáculo: o **Unity Personal é gratuito** para receita e investimento abaixo de US$ 200 mil nos últimos 12 meses, e a Runtime Fee foi cancelada em 2024.

| | Godot | Unity |
|---|---|---|
| Código existente | Reaproveitado (~2.500 linhas de lógica) | **Reescrever tudo em C#**; só os JSON sobrevivem |
| Assets prontos | Poucos | Loja muito maior — ajuda no item mais caro (arte e animação) |
| Animação de personagens | Adequada | Ferramentas mais maduras |
| Material de estudo em 3D | Bom e crescendo | Muito maior |
| Trabalho via repositório (Claude) | Cenas em texto simples: o Claude cria e altera cenas pelo repositório | Cenas e prefabs dependem mais do editor: mais trabalho manual do usuário |
| Console no futuro | Possível, mais trabalhoso | Caminho mais direto (plano Pro) |
| Licença | MIT, gratuita | Gratuita abaixo de US$ 200 mil; histórico de mudanças unilaterais |

**Recomendação:** ficar no Godot. Reconsiderar o Unity só se as três coisas acontecerem juntas:
1. a decisão for ir direto para terceira pessoa com personagens bem animados;
2. a arte vier majoritariamente comprada pronta;
3. houver alguém além do Claude trabalhando no editor.

---

## 5. Riscos

- **Arte e animação** dominam o custo e o prazo do 3D.
- **Legibilidade das pegadas** em chão escuro precisa do mesmo teste do pergaminho (200 px).
- **Mata como parede** exige câmera alta ou árvores que ficam transparentes entre câmera e jogador.
- **Desempenho** com mata densa, sombras e névoa precisa ser medido em PC comum.
- **Equilíbrio da visão** muda com a linha de visada; regras de detecção e perguntas verificáveis precisam ser retestadas.

---

## 6. Caminho proposto

| Passo | O que fazer | Situação |
|---|---|---|
| 1 | **Fechar o MVP 2D** (etapa 3 e ajustes em teste). É ele que valida se o jogo é divertido | Em andamento |
| 2 | **Decidir a plataforma** | ✅ PC (03/11/2026) |
| 3 | **Protótipo técnico 3D pequeno**, fora do jogo principal: clareira com a Cabana do Bento, câmera isométrica ortográfica, lua, luz de lampião na janela, pegadas como decalque, mata transparente e escuridão por linha de visada. Responde: as pegadas são legíveis? o desempenho é aceitável? a atmosfera está certa? | ✅ Feito (seção 8); aguarda teste do usuário no PC |
| 4 | **Ajustar a lógica do MVP** para visão por linha de visada e altura, mantendo o 2D funcionando com as mesmas regras | Depois do passo 3 aprovado |
| 5 | **Etapa isométrica completa** e planejamento de arte própria, com a Direção de Arte v1, tipo B, como referência | Depois do passo 4 |

---

## 7. Decisões do usuário

Decididas em 03/11/2026:

- [x] **Engine:** manter o Godot para o 3D.
- [x] **Plataforma-alvo:** **PC**. O 3D usa o renderizador Forward+.
- [x] **Protótipo técnico 3D:** aprovado, com o pedido de que inclua **uma floresta bem densa à noite**. Feito num projeto separado, sem mexer no MVP.

---

## 8. Protótipo técnico 3D (03/11/2026)

Pasta `prototipo_3d/` do repositório, projeto Godot **4.7.1** separado do MVP. Ainda local, aguardando o usuário testar e fechar.

**O que tem:** 160 × 160 m de mata fechada (~4.100 árvores de 5 espécies e ~10.400 plantas de sub-bosque), trilhas com bifurcação e beco, clareira vazia, a Cabana do Bento (Direção de Arte v1, 3.1), lua do canto superior esquerdo, luz âmbar na janela e na porta, fumaça, neblina rasteira, jogador de bota, outro personagem descalço, pegadas de botina levando à porta, câmera isométrica ortográfica. Arte provisória (primitivas do Godot).

**Organização:** a mesma regra do MVP. `scripts/logica/` não desenha nada (terreno, mata, personagens, pegadas e linha de visada); `scripts/apresentacao/` só lê esse estado.

**Respostas às três perguntas do passo 3 (primeira leitura, por capturas):**

| Pergunta | Resposta | Observação |
|---|---|---|
| A atmosfera está certa? | **Sim, na clareira.** A cabana iluminada no meio da mata escura funciona | As copas ainda parecem "bolotas"; é arte provisória |
| As pegadas são legíveis? | **De perto e na clareira, sim. Sob a mata, não** | No tamanho real ficam pequenas; 1,5x é o padrão do protótipo. Sob as copas o chão fica escuro demais |
| O desempenho é aceitável? | **No PC, sim, com margem a ganhar: 39 FPS** sem nenhuma otimização (medido pelo usuário em 03/11/2026). **No navegador, 7 a 9 FPS** | O navegador é só para teste em computador sem Godot; o jogo será jogado no PC (decisão do usuário em 03/11/2026) |

**Descobertas que afetam o design:**
- **A mata transparente perto do jogador é obrigatória.** Sem ela, numa mata densa vista do alto, o jogador some sob as copas.
- **Com linha de visada, numa trilha sinuosa se vê só de 5 a 8 m à frente.** É a "mata como parede" funcionando, mas encurta muito o alcance de visão em relação ao MVP. Quanto de mata tapa a vista (hoje 2,5 m) é um número de equilíbrio a decidir.
- **Luz sob a mata:** o jogo vai precisar de uma regra de visão no escuro (a "luz de visão" do protótipo é provisória) ou de fendas de luar sobre as trilhas.

**Ajustes de 03/11/2026, depois do teste do usuário:**
- A mata transparente deixou de ser um círculo pontilhado: cada árvore entre a câmera e o personagem some inteira, e a abertura acompanha o zoom (o usuário achou o círculo estranho).
- Versão para navegador publicada como página do claude.ai. No navegador o Godot usa o renderizador Compatibility: névoa rasteira simples no lugar da volumétrica e pegadas como planos no chão, porque não há decalques.

**Terceira pessoa no protótipo (03/11/2026, pedido do usuário):**
- Tecla C alterna entre a isométrica e a terceira pessoa: câmera atrás do ombro, mouse para olhar, câmera que volta para trás do personagem quando ele anda, neblina de distância.
- **60 FPS no PC do usuário em terceira pessoa**, contra 39 na isométrica: a neblina esconde a mata distante.
- Mata com mais vida (casca, musgo e líquen nos troncos, copas com variação de tom, folhas secas e musgo no chão, vagalumes), grilos com som posicional que se calam quando o jogador chega perto e personagem com traços humanos, a partir de uma foto de referência do usuário. As trilhas ficaram quase limpas para não atrapalhar a leitura das pegadas.
- Ponto em aberto: o visual de referência (boné, camiseta estampada, tênis) é de hoje; o jogo se passa nos anos 1950.

**Noite completa do MVP no protótipo (04/11/2026, pedido do usuário):**
- O protótipo passou a rodar a lógica do MVP (cópia em `prototipo_3d/scripts/mvp/`): mapa sorteado de 450 × 450 m, seis bases, três personagens do computador, pegadas, lobo, corujas, cão, cobras, armadilhas, veneno, chegada e amanhecer. Ainda sem as conversas com os guardiões.
- As cinco bases que faltavam foram montadas pela Direção de Arte v1, seção 3. Mata de ~34 mil árvores e ~84 mil plantas, para testar desempenho. Montagem da cena: cerca de 2 s.
- O personagem passou a seguir as trilhas do grafo, como no MVP; na terceira pessoa, "para a frente" segue a trilha mais alinhada.
- Velocidade do jogador: 4 m/s, a do protótipo de uma casa (pedido do usuário).
- Achado: no MVP, `mundo/fauna.gd` lê `Dialogo.NOMES_ATRIBUTO` da tela de diálogo (lógica dependendo da interface). Corrigido na cópia; falta corrigir no MVP.
- FPS no PC do usuário com o mapa grande: ainda não medido.

**Ajustes de 05–06/11/2026, depois do teste do usuário:**
- Andar livre de volta: o jogador anda pela trilha e pela clareira em qualquer direção, sem ficar preso ao grafo; chegada a uma base por proximidade. O grafo continua valendo para os personagens do computador.
- Barra de vida (regra nova, só no protótipo): armadilha −20, lobo −30, cobra −20; cada casa nova recupera 35. Vida zero desmaia. Lentidão, prisão, queda e desmaio continuam como no MVP.
- Saída visível: porteira com lanternas e luz alta; o HUD mostra distância e rumo.
- Mini bússola com N/L/S/O que gira com a câmera, e marca âmbar apontando a saída. Os avisos ("vem do norte") agora têm referência na tela.
- Os três personagens do computador ficaram diferentes entre si (roupa, pele, altura, calçado, mulheres por nome) e mostram hesitação quando param.
- Mata mais detalhada: folhas em cartões com recorte, galhos, cipós, epífitas, relevo na casca e no chão. Para ficar realista de fato, o próximo passo é usar texturas fotográficas CC0 do Poly Haven, que o usuário vai baixar.
- Corrigido o erro ao chegar perto da cobra (atributos do jogador eram constantes).
- O projeto exige Godot 4.4 ou mais novo (testado no 4.7); no 4.3 dá erro de script.

**Próximo passo sugerido:** integrar as texturas do Poly Haven, medir o FPS no mapa grande e decidir tamanho das pegadas, alcance da visão e luz sob a mata.

---

## Fontes

- Godot 4.6 lançado (Jolt Physics, novo editor): https://app.cinevva.com/news/2026-02-27-godot-4-6-released
- Godot 4.6 — resumo das novidades: https://alternativeto.net/news/2026/1/godot-4-6-debuts-modern-theme-jolt-physics-node-ids-and-libgodot-embed
- Godot 4.7 lançado (AreaLight3D, HDR): https://wnhub.io/zh/news/engines/item-51174
- Unity — planos e preços 2026: https://unity.com/products/pricing-updates
- Unity — cancelamento da Runtime Fee: https://unity.com/blog/terms-update-runtime-fee-cancellation
