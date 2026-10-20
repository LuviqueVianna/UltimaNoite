# Revisão — banco de guardiões, formato v3 (entrega de 20/10/2026)

**Revisor:** Claude · **Data:** 20/10/2026 · **Entrega:** `entregas/2026-10-20_guardioes_v3/`

**Resultado:** aprovada com ajustes pequenos. A estrutura v3 está completa e as correções pedidas foram aplicadas. Restam 4 ajustes de conteúdo e 1 de vocabulário (este, do Claude).

## O que está bom

- 12 perguntas usáveis no MVP por guardião; 9 perguntas preservadas em `fora_do_mvp/`.
- `premissa` aplicada em todas as perguntas que pressupõem um fato, com o vocabulário fechado.
- Identidade só por visão ou calçado reconhecido (bento_05, marta_05, marta_06, marta_08).
- iara_10 corrigida: quem não acionou armadilha recebe o mesmo que quem acionou e avisou.
- Seu Quincas reconstruído em torno do inventário do jogador (quincas_06, 09, 11, 14).
- `reputacao` em todos os guardiões, coerente com o que cada um valoriza.
- Regras mensuráveis: 12/12 perguntas sem resposta óbvia em todos; nenhuma mentira mais branda que a pior resposta.

## Ajustes

### 1. Respostas impossíveis no MVP (ChatGPT)

Perguntas verificáveis com uma resposta que descreve troca entre jogadores, que não existe no MVP. Essa resposta é sempre mentira; no caso da marta_14 é a segunda melhor opção.

| Pergunta | Resposta a substituir |
|---|---|
| iara_08 | "Troquei a dica por um item de que precisava." |
| iara_13 | "Ofereci o aviso em troca de um item." |
| anselmo_13 | "Usei a informação numa troca." |
| marta_14 | "Avisei em troca de outra dica." |

Substituir por uma ação possível no MVP, mantendo o valor de afinidade e o papel da resposta.

### 2. Marca de reputação que nunca dispara (ChatGPT)

Iara: `explorou_vulneravel` só é registrada pela própria Iara, e `reputacao` só conta marcas de outras bases. Trocar por uma marca registrada em outro guardião (ex.: `confessou_egoismo`, `aceitou_delacao`).

### 3. Opções extras e o Carisma (ChatGPT)

Em Bento, Iara, Marta e Quincas, **nenhuma** opção extra iguala a melhor resposta (0 de 38). No MVP, o Carisma só tem efeito no diálogo, por meio dessas opções. Assim ele não vale nada.

Novo critério: em cada guardião, **2 a 4** opções extras com afinidade igual ou maior que a melhor resposta comum, de preferência as de Carisma. Continua valendo o limite de no máximo metade.

### 4. Premissas específicas demais para o vocabulário (Claude)

Três perguntas supõem um fato mais estreito que a premissa disponível:

| Pergunta | Supõe | Premissa nova |
|---|---|---|
| iara_08 | Recebeu uma dica sobre **panela** | `recebeu_frase_panela` |
| iara_14 | Recebeu um **pedido de ajuda** | `recebeu_frase_pedido` |
| iara_13 | Viu alguém **entrar numa base** | `viu_jogador_entrar_base` |

O Claude acrescenta as três ao vocabulário v3 (`docs/correcoes/CORRECOES_guardioes_v3.md`, seção 3.2). O ChatGPT só troca as premissas nessas três perguntas.

## Observação para a implementação

Respostas como "digo quem era" (bento_05, marta_05, marta_15) exigem que o jogador **escolha** um personagem. Isso depende da decisão pendente sobre nomes dos personagens.
