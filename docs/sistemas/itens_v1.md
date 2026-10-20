# Catálogo de itens do MVP (v1)

**Autor:** Claude · **Data:** 20/10/2026 · **Estado:** aprovado pelo usuário em 20/10/2026. Dados em `conteudo/itens.json`.

Cada item resolve um problema que já existe no MVP (lobo, armadilha, veneno, pegadas, escuridão) ou alimenta o Seu Quincas. Nenhum cria mecânica nova. Os números são ponto de partida para teste.

---

## 1. Regras gerais

- **Capacidade:** 3 itens por personagem.
- **Início:** cada personagem começa com **1 item sorteado** entre os comuns.
- **No mapa:** 4 a 6 itens espalhados em becos e clareiras vazias, sorteados por partida.
- **Raridade:** comum, valioso ou raro. Define a chance de aparecer e o valor para o Seu Quincas.
- **Oferecer ao Quincas:** o item sai do inventário e soma afinidade com ele: comum **+1**, valioso **+2**, raro **+3**. Os outros guardiões não aceitam itens no MVP.
- **Personagens do computador** usam itens pelas mesmas regras (seção 3).
- Ninguém vê o inventário dos outros.

---

## 2. Os 8 itens

| Item | Raridade | Uso | Efeito | Tem relação com |
|---|---|---|---|---|
| **Maço de ervas** | Comum | 1 | Usado em si: acaba na hora com a lentidão da armadilha. Usado no lobo ferido: o lobo passa a escoltar o jogador por 60 s | Armadilha, lobo, Dona Iara |
| **Carne seca** | Comum | 1 | Jogada perto do lobo, ele para de perseguir por 20 s. Perto do cão, ele aceita guiar mesmo se estiver inquieto | Lobo, cão |
| **Fumo de rolo** | Comum | — | Não tem uso próprio; só serve para oferecer a um guardião | Seu Quincas |
| **Lamparina** | Comum | 2 | Alcance de vista +6 m por 30 s. Durante o uso, sua posição aparece como ponto de luz para quem estiver a até 40 m | Visão noturna |
| **Pano de saco** | Valioso | 1 | Enrolado nos pés: por 60 s, suas pegadas não mostram o calçado, só que alguém passou | Pegadas e calçado |
| **Facão** | Valioso | Ilimitado | Desarma uma armadilha já notada (3 s parado). Ao abrir caminho na mata, conta como Força +1 | Armadilha, Força |
| **Apito de taquara** | Valioso | 2 | Imita a coruja: todos ouvem "uma coruja piou" na sua direção, como um evento real. Serve para atrair ou despistar | Eventos à distância, coruja |
| **Raiz amarga** | Raro | 1 | Tomada antes de comer, anula o efeito do veneno da panela ruim. Só existe 1 por mapa e nunca é item inicial | Veneno, panelas |

---

## 3. Personagens do computador

| Perfil | Como usa os itens |
|---|---|
| Cauteloso | Usa ervas e carne seca assim que precisa; guarda a raiz amarga para a última base; oferece ao Quincas só o fumo de rolo |
| Ousado | Usa a lamparina cedo; desarma armadilhas com o facão; oferece qualquer item ao Quincas se a afinidade estiver baixa |
| Trapaceiro | Usa o pano de saco antes de entrar numa base; usa o apito para despistar quem o segue; mente ao Quincas sobre o que carrega |

---

## 4. Riscos a observar no teste

- **Raiz amarga** pode tornar uma panela irrelevante. Por isso é única no mapa e não é inicial; se ainda assim pesar demais, passa a reduzir o efeito em vez de anular.
- **Apito de taquara** pode gerar eventos falsos demais. Se acontecer, cai para 1 uso.
- **Lamparina** pode ser pouco usada por expor a posição. Se ninguém usar, aumentar o bônus de alcance.

---

## 5. Impacto em outros arquivos

- As perguntas do Seu Quincas já usam inventário genérico; continuam válidas.
- `{item}` nos textos do mapa passa a ser preenchido com estes 8 nomes.
- Novas marcas possíveis para os guardiões, depois do MVP: `disfarcou_pegadas` (pano de saco), `despistou_com_apito`, `ajudou_animal` (ervas no lobo, já existe).
