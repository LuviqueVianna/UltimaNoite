# Revisão — banco de guardiões, formato v2 (entrega de 19/10/2026)

**Revisor:** Claude · **Data:** 20/10/2026 · **Entrega:** `entregas/2026-10-19_guardioes_v2/`

**Resultado:** formato aprovado; volta para correção. Correções em `docs/correcoes/CORRECOES_guardioes_v3.md`.

## O que está bom

- Formato v2 completo e válido nos 5 arquivos (75 entradas).
- Vozes consistentes. O Bento voltou a ser coragem e franqueza, sem invadir o território da Iara.
- Anselmo usa bem `registra`, `contradiz` e `contradicao`.
- Marta premia o silêncio prudente; Quincas cobra caro pela mentira.

## Problemas encontrados

1. **Perguntas que pressupõem um fato.** Cerca de 13 perguntas supõem que algo aconteceu (o lobo avançou, encontrou uma armadilha). Se não aconteceu, todas as respostas são mentira e o jogador honesto leva −4. Solução: campo `premissa` (formato v3).
2. **Pegadas sem nome.** bento_05 e marta_05 supõem identificar alguém pelo rastro. No MVP, só por visão ou calçado reconhecido.
3. **Mecânicas fora do MVP.** 9 perguntas dependem de trocas, prendas, escuta ou alerta de furtividade.
4. **Marcas sem uso.** 24 das 28 marcas registradas nunca são consultadas. Solução: campo `reputacao` (formato v3).
5. **iara_10:** quem não acionou armadilha recebe menos que quem acionou e avisou.

## Perguntas usáveis no MVP antes da correção

| Bento | Iara | Anselmo | Marta | Quincas |
|---|---|---|---|---|
| 11 | 11 | 10 | 10 | 7 |
