# A Última Noite — Banco de guardiões v0.3 / formato v2

Entrega com 75 entradas JSON distribuídas em cinco arquivos individuais.

| Arquivo | Guardião | Narração | Falas | Perguntas | Total |
|---|---|---:|---:|---:|---:|
| `guardioes/bento.json` | Velho Bento | 1 | 2 | 12 | 15 |
| `guardioes/iara.json` | Dona Iara | 1 | 2 | 12 | 15 |
| `guardioes/anselmo.json` | Frei Anselmo | 1 | 2 | 12 | 15 |
| `guardioes/marta.json` | Marta | 1 | 2 | 12 | 15 |
| `guardioes/quincas.json` | Seu Quincas | 1 | 2 | 12 | 15 |

## Alterações v2

- `versao_formato: 2` e `modificadores_tom` em todos os arquivos.
- Separação entre `narracao` e `fala`.
- Toda pergunta verificável possui `verificacao`, `requer` e penalidade de `mentira`.
- Uso exclusivo das mecânicas já definidas no GDD.
- Marcas `registra`, `contradiz` e `contradicao`, com ênfase no sistema de Frei Anselmo.
- Respostas pragmáticas menos caricatas e alternativas mais próximas em valor.
- Opções extras reequilibradas para não serem sempre a melhor escolha.

Execute `validar.ps1` para repetir a validação automática descrita em `VALIDACAO.md`.
