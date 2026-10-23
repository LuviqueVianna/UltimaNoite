# Consequências mais pesadas — v1

**Autor:** Claude · **Data:** 23/10/2026 · **Estado:** aprovado pelo usuário em 23/10/2026 e implementado; números provisórios em `godot/scripts/regras.gd`.

**Motivo (teste do usuário):** veneno, mordida e perda de habilidade pesavam pouco. Com 4 a 5 bases por noite, perder 1 ponto de habilidade e andar devagar por 10 s não mudava o resultado, e chutar a panela valia o mesmo que ir embora. Ninguém se preocupava em negociar bem com os guardiões.

**Descartado pelo usuário:** pegadas marcadas por mais tempo depois da mordida (não geram perigo real: ninguém persegue pelas pegadas).

## 1. Veneno acumula

Vale para a panela ruim e para a picada de cobra. A Resistência continua dando chance de aguentar (0% a 40%); dose aguentada não conta.

| Dose | Efeito |
|---|---|
| 1ª | −1 na maior habilidade (como antes) e **visão turva por 60 s**: o alcance de vista cai para 60% |
| 2ª | −1 na maior habilidade e **visão turva até o amanhecer** |
| 3ª | **Desmaio:** o personagem cai na trilha, não anda mais e **não registra a chegada** (não pontua) |

- A tela mostra no alto: `veneno 1/3`, `vista turva 42 s`.
- Os personagens do computador com 2 doses só comem quando o guardião está do lado deles (afinidade alta).

## 2. Lobo segue o faro de quem derrubou

- Depois de derrubar, o lobo recua um pouco (tempo de queda + 3 s) e passa a **seguir o faro** dessa pessoa por **40 s**, a 80% da velocidade normal dela. Enquanto ela está lenta, ele alcança.
- **Esconder-se ou sumir na mata não adianta** contra o faro.
- Se alcançar de novo: outra queda, e aí ele vai embora.
- Os personagens do computador derrubados correm para a base mais perto que conhecem.

## 3. Base como refúgio

- O lobo **não entra** em base nenhuma (com guardião, já visitada ou a tapera vazia). Quem chega a uma base com o lobo atrás (perseguindo ou no faro) fica protegido, mas o lobo **espera à porta por 45 s**.
- O jogador escolhe:
  - **Esperar o lobo ir embora:** o tempo passa (a noite corre mais rápido na tela) até ele cansar.
  - **Sair pela porta dos fundos:** chance de o lobo não perceber pela Furtividade (40% a 80%). Se perceber, ele continua à porta.
  - **Sair pela porta da frente:** ele ataca.
- Base ainda não visitada: a conversa com o guardião acontece normalmente; o refúgio aparece ao sair.
- Base já visitada: o guardião deixa esperar, mas não serve outra refeição.
- Os personagens do computador: o cauteloso espera; os outros tentam os fundos uma vez.

## 4. Os guardiões percebem o estado de quem chega

Quem chega **ferido** (derrubado pelo lobo nos últimos 2 minutos) ou **com a vista turva** pelo veneno:

| Guardião | Afinidade inicial | Leitura |
|---|---|---|
| Dona Iara | +1 | Se compadece |
| Marta | −1 | Gente machucada atrai bicho |
| Velho Bento | +1 | Respeita quem chegou de pé |
| Anselmo, Quincas | 0 | — |

A cena mostra a reação numa linha de narração no começo da visita.

## 5. Sumir na mata e moita (MVP, seção 8)

Implementados junto, porque sem eles a Furtividade quase não tinha uso.

- **Sumir na mata** (tecla F ou botão no alto): 5 s parado; andando, o gasto cresce 1,1x por segundo (cerca de 4,3 s andando sem parar). Usos por Furtividade (1, 1, 2, 2, 3).
  - Oculto, ninguém vê você, e **o lobo que ronda não percebe**. Diante do rosnado, sumir funciona como ficar parado.
  - Coruja e cão ainda percebem quem sumiu (sugestão do MVP).
  - Suas pegadas ficam fracas: só quem tem leitura de pegadas 4 ou mais as vê.
- **Moita** (na aproximação de cada base): fica escondido enquanto quiser, vendo quem chega. Ninguém o vê, nenhum animal o percebe, exceto o lobo que já está no seu faro.
- As premissas `usou_esconderijo` e `sumiu_na_mata` passam a valer, então as perguntas dos guardiões que dependem delas podem ser sorteadas.
- Os personagens do computador usam o "sumir" diante do lobo (os que não ficam parados e não são ousados). Ainda não usam a moita.

## 6. Textos provisórios

Falas novas do lobo, do veneno e da reação dos guardiões estão em `regras.gd` (`FALAS_ANIMAIS`, `FALAS_VENENO`, `REACAO_ESTADO_TEXTO`). Pedir o banco definitivo ao ChatGPT numa próxima demanda.

## 7. Simulação (`godot/testes/teste_consequencias.gd`)

40 noites com os 4 personagens no computador:
- Cerca de 4% desmaiam de veneno; cerca de 18% terminam com 2 doses.
- Cerca de 9 em cada 10 ainda chegam à saída.
- Jogador derrubado a 25-45 m de uma base, correndo para ela: chega em cerca de 9 de cada 10 vezes; nas outras, é derrubado de novo.
