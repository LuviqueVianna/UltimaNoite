# Visitas às bases (v1)

**Autor:** Claude · **Data:** 20/10/2026 · **Estado:** implementado na etapa 2 do jogo; valores para validar jogando.

Detalha como o jogo aplica o GDD v0.3 (seções 2.1 e 2.2) e o formato v3 das perguntas.

## 1. Fluxo

1. **Aproximação:** olhar pela janela (uma vez), entrar pela frente ou pelos fundos, ou voltar para a trilha. Olhar pela janela conta como "rondou" para as perguntas sobre aproximação.
2. **Abertura:** a narração do guardião e uma fala sorteada.
3. **Perguntas:** 4 a 6 sorteadas entre as que o jogador pode responder (mecânicas do MVP e `premissa` verdadeira).
4. **Indicação:** o guardião aponta uma panela, se cala, ou (Quincas) pede um item.
5. **Panelas:** o jogador come da esquerda ou da direita. Cada base é visitada uma vez.

A noite continua correndo durante a conversa.

## 2. Resposta

- O jogador escolhe o **tom** (firme, gentil, evasivo) e a resposta. Sem resposta em **10 s**, conta como silêncio.
- Afinidade da resposta = valor da resposta (ou `mentira`, se a verificação falhar) + modificador de tom (ou o `tom` próprio da resposta) + `contradicao`, se contradiz uma marca do histórico.
- Silêncio vale o campo `silencio` da pergunta (0 se não houver).
- A afinidade da visita começa na soma da `reputacao` (marcas de outras bases) e fica entre −10 e +10.
- **Verificação:** `conteudo/guardioes/verificacao.json` liga cada resposta verificável a fatos da noite (ex.: bases visitadas, pessoas vistas, itens). Resposta sem condição conta como verdadeira.

## 3. Indicação

| Situação | Condição |
|---|---|
| Má intenção | 2 ou mais respostas com intenção `ma` na visita (inclui mentiras com intenção `ma`) |
| Alta | Afinidade ≥ +8 |
| Baixa | Afinidade ≤ +1 |
| Neutra | Entre +2 e +7 |

| Guardião | Alta | Neutra | Baixa | Má intenção |
|---|---|---|---|---|
| Bento | Boa | Não indica | Ruim | Ruim |
| Iara | Boa | Boa | Ruim | Ruim |
| Anselmo | Boa | Boa | Não indica | Ruim |
| Marta | Boa | Não indica | Ruim | Ruim |
| Quincas | Pede item | Ao acaso | Ruim | Pede item |

- Quando o guardião indica a ruim, ele mente e faz o **sinal de mentira** (GDD 2.2). Quando diz a verdade, faz o gesto oposto.
- Quincas: recebendo um item, indica a boa e ganha afinidade pela raridade (+1, +2, +3). Recusando, indica a ruim.

## 4. Calibração

Os limites +8 e +1 vêm de simulação com o banco v3.1: as respostas são generosas (média perto de +1,3 por pergunta), e com o limite antigo (+4) quase toda visita ficava "alta". Com +8 e +1, um jogador que responde ao acaso fica perto de um terço em cada situação no Bento, na Iara e no Anselmo.

Pontos para observar no teste:
- **Seu Quincas** fica "alto" em 80% das visitas; o que decide é dar ou não um item.
- **Marta** quase nunca fica "baixa". O GDD previa afinidade inicial −3 para ela (em decisão).
- Nas noites simuladas, cerca de 88% das refeições dos personagens do computador são boas. O risco vem de mentir, da má intenção e do silêncio do Bento e da Marta.

## 5. Provisório

- Falas da indicação e gestos de verdade: textos curtos do Claude, até o ChatGPT fazer um banco.
- Pontuação no amanhecer: panelas boas comidas. A regra de vitória ainda não foi definida.
