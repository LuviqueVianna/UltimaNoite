# Pontuação e chegada (v1)

**Autor:** Claude · **Data:** 20/10/2026

## Decidido pelo usuário (20/10/2026)

- **Ganha quem fizer mais pontos.**
- Para os pontos valerem, o personagem precisa **chegar ao ponto oposto do mapa** e registrar a chegada antes do amanhecer.

## Como foi implementado

- Cada personagem tem a sua **saída**, no ponto do mapa espelhado pelo centro a partir da sua partida. O caminho até ela tem de 154 a 476 m (2 a 5 minutos andando), medido em 300 mapas.
- O jogador **sabe onde fica** a saída (aparece como uma porteira no mapa, com direção e distância no alto da tela), mas **não sabe o caminho**: precisa descobrir as trilhas.
- Passar pela saída não encerra nada. Ao chegar, o jogador escolhe entre **registrar** (a noite dele termina e o tempo acelera até o amanhecer) ou **continuar na mata**.
- Quem não registrar até o amanhecer **não pontua**.
- Depois que o jogador registra a chegada, os personagens do computador param de visitar bases, andam 3 vezes mais rápido e vão direto para a saída, para o placar comparar o que cada um tinha feito até ali (pedido do usuário em 20/10/2026).
- Os personagens do computador voltam quando já visitaram todos os guardiões ou quando o tempo aperta (estimam o caminho conhecido, ou 2,5 vezes a distância em linha reta, com 60 s de folga). Nas simulações, cerca de 9 em cada 10 chegam a tempo.

## PROPOSTA — valores dos pontos

Implementado assim, aguardando aprovação:

| Evento | Pontos |
|---|---|
| Panela boa | +3 |
| Panela ruim | −1 (além de perder 1 ponto de atributo) |

Opções para considerar:

1. **Bônus pela ordem de chegada** (ex.: 1º +2, 2º +1). Cria a decisão entre visitar mais uma base ou sair antes dos outros.
2. **Bônus por guardião de afinidade alta** (ex.: +1). Premia quem convence, não só quem acerta a panela.
3. **Itens restantes** valendo pontos (ex.: +1 cada). Dá valor a guardar itens em vez de usá-los ou dá-los ao Quincas.
4. **Pontos de atributo no fim** (soma dos 5). Faz o veneno pesar também no placar.
