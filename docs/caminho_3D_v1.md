# A Última Noite — Caminho para o 3D no Godot

> Status: **APROVADO** pelo usuário em 21/10/2026 (proposta do Claude, mesma data). Os 3 pontos da seção 5 foram aprovados.
> Relação com o GDD: o GDD v0.3 já prevê "3D só depois do protótipo completo e funcional". Este documento define **como** chegar lá sem retrabalho.

---

## 1. Resumo

O Godot 4 renderiza o jogo em 3D sem impedimento técnico. Quase todo o design atual (guardiões, afinidade, perguntas em JSON, premissas, marcas, reputação, animais, armadilhas, inventário) é **lógica e dados**, independente da câmera.

Decisões:
1. **Separar lógica e apresentação desde o MVP**, para que a troca de visual não exija reescrever regras.
2. **Etapa intermediária**: cena 3D com **câmera ortográfica isométrica** (visual 2.5D, luz real), entre o MVP de pegadas e o 3D completo.
3. **3D completo (terceira pessoa)** continua no "Futuro", sem prazo.

---

## 2. Arquitetura do código do MVP

| Camada | Responsabilidade | Muda ao ir para 3D? |
|---|---|---|
| **Dados** | JSON de guardiões, textos do mapa, frases prontas | Não |
| **Mundo (lógica)** | Grade/grafo de trilhas e clareiras, posição dos personagens, pegadas, eventos, relógio da noite, regras de visão, IA dos 3 personagens do computador | Não |
| **Diálogo** | Sorteio de perguntas, aplicação de afinidade, tom, mentira, contradição, reputação | Não (só a tela muda) |
| **Apresentação** | Desenhar o mapa, as pegadas, a névoa, a interface | **Sim — é a única camada trocada** |

Regra: a camada de apresentação **só lê** o estado do Mundo e emite comandos do jogador (andar, esconder, sumir na mata, entrar na base). Nenhuma regra de jogo dentro de nós visuais.

**Situação do código em 21/10/2026:** já segue a regra. `scripts/mundo/`, `scripts/mapa/` e `scripts/regras.gd` são `RefCounted` (sem nós visuais); o desenho fica em `scripts/cenas/`.

---

## 3. Etapas de visual

| Etapa | Visual | Como fica no Godot | Quando |
|---|---|---|---|
| **MVP** | Pergaminho visto de cima, só pegadas | 2D (`Node2D`, shader de desfoque/escuridão) | Agora |
| **Intermediária** | Isométrico com luz real | Cena **3D** + `Camera3D` ortográfica em ângulo isométrico; lua como `DirectionalLight3D` (superior esquerdo, azul-esverdeada); lampiões como `OmniLight3D` âmbar nas janelas; pegadas como `Decal` por tipo de calçado; escuridão por névoa volumétrica ou máscara de visão | Após MVP completo e aprovado |
| **Futuro** | Terceira pessoa 3D | Mesma cena 3D com câmera atrás do personagem, colisão de câmera, animações | A definir |

A Direção de Arte v1, tipo B (base isométrica), fica **arquivada, não descartada**: será a referência da etapa intermediária.

---

## 4. Riscos e cuidados

- **Custo de arte:** o código muda pouco; o volume de assets cresce muito. Prototipar com pacotes prontos (Kenney, Quaternius) antes de arte própria.
- **Mata como parede:** em 3D, árvores tapam a visão. Exigirá câmera alta ou árvores que ficam transparentes entre câmera e jogador.
- **Mobile:** se a plataforma incluir celular, usar renderizador *Mobile* ou *Compatibility*, com LOD, *occlusion culling* e poucas luzes dinâmicas. Plataforma continua em aberto.
- **Leitura das pegadas:** decalques no chão escuro precisam do mesmo teste de legibilidade do pergaminho.

---

## 5. Decisões aprovadas (21/10/2026)

1. ✅ Separação lógica/apresentação é regra do código do MVP.
2. ✅ Etapa intermediária (3D ortográfico isométrico) entra no roadmap, entre MVP e Futuro.
3. ✅ Direção de Arte v1, tipo B, arquivada para essa etapa.

Nada disto muda a fila atual do ChatGPT (BRIEFING v0.4, seção 3).
