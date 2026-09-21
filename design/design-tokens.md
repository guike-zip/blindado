# Blindado — design tokens

Fonte única de verdade dos valores: o bloco `:root` de `blindado-ios-prototype.html`.
Este documento existe para a extração em `Theme.swift` e é a referência de nomes.

- **Canônico:** OKLch. **Para o Swift:** use os hex sRGB abaixo (conversão exata do OKLch
  correspondente, arredondada para 8 bits) ou, se quiser fidelidade total em telas P3,
  instancie por OKLch/Display P3.
- **Escuro é o tema primário**, e as duas aparências já estão desenhadas: a seção
  *Aparência clara* do board repete as treze telas com a coluna clara desta tabela.
  Os frames claros saem dos mesmos templates dos escuros — só o esquema muda.
- Todos os pares de texto/fundo listados aqui passam em **4,5:1** (texto normal) e
  **3:1** (ícone/texto grande). Os valores medidos estão na última coluna.

---

## 1. Cor — status de proteção (semântico)

O único vocabulário de cor do app. Nunca decorativo: se algo está colorido, é porque
comunica estado ou é a ação primária da tela.

| Token | Escuro (OKLch / hex) | Claro (OKLch / hex) | Uso | Contraste |
|---|---|---|---|---|
| `status.protected` | `oklch(0.800 0.170 152)` · `#56DC85` | `oklch(0.500 0.150 152)` · `#007A34` | Blindado, badge “Bloqueado”, aba ativa, botão primário | 10,96:1 escuro · 5,48:1 claro |
| `status.pending` | `oklch(0.820 0.150 78)` · `#F9B73F` | `oklch(0.540 0.130 66)` · `#A05C00` | Instalado mas desativado; proteção parcial | 10,87:1 · 5,22:1 |
| `status.idle` | `oklch(0.660 0.012 258)` · `#8E939A` | `oklch(0.520 0.010 265)` · `#66696F` | Não configurado; indeterminado; sem rede | 6,21:1 · 5,50:1 |
| `status.danger` | `oklch(0.680 0.190 25)` · `#F75D59` | `oklch(0.540 0.200 25)` · `#C9222B` | Domínio acessível que deveria bloquear; erro de campo; remover proteção | 6,10:1 · 5,60:1 |
| `status.info` | `oklch(0.720 0.140 240)` · `#3FAFF3` | `oklch(0.520 0.160 250)` · `#006AC0` | Ícone neutro de lista (Safari em Ajustes) | 7,91:1 · 5,49:1 |

Cada cor sólida tem um par `*.soft` — a mesma cor com **16% de alfa** no escuro e
**12%** no claro — usado como fundo de pill, banner e linha selecionada. O texto sobre
um `soft` é sempre a versão sólida da mesma cor (o par é fixo, nunca se mistura).

| Token soft | Escuro | Claro |
|---|---|---|
| `status.protected.soft` | `protected / 16%` | `protected / 12%` |
| `status.pending.soft` | `pending / 16%` | `pending / 12%` |
| `status.idle.soft` | `idle / 16%` | `idle / 12%` |
| `status.danger.soft` | `danger / 16%` | `danger / 12%` |

`accent` **é** `status.protected` — o app tem um acento só.
`accent.pressed`: `oklch(0.860 0.150 152)` `#7DED9F` (escuro) · `oklch(0.440 0.140 152)` `#006727` (claro).

## 2. Cor — superfícies e texto

| Token | Escuro (OKLch / hex) | Claro (OKLch / hex) | Uso |
|---|---|---|---|
| `bg.canvas` | `oklch(0.165 0.012 258)` · `#0B0F14` | `oklch(0.962 0.004 265)` · `#F1F2F5` | Fundo da tela |
| `bg.surface` | `oklch(0.225 0.014 258)` · `#181C22` | `oklch(1 0 0)` · `#FFFFFF` | Cartão, lista agrupada |
| `bg.surfaceRaised` | `oklch(0.275 0.014 258)` · `#23282F` | `oklch(0.945 0.005 265)` · `#EBEDF0` | Botão secundário; **hover de linha** |
| `bg.fillSubtle` | `oklch(0.315 0.014 258)` · `#2D3239` | `oklch(0.910 0.006 265)` · `#DFE1E5` | Toggle desligado, número do passo, hover do secundário |
| `bg.chrome` | `canvas + 0.02 L / 82%` + blur 22 | `oklch(0.985 0.003 265) / 86%` + blur | Nav bar e tab bar translúcidas |
| `text.primary` | `oklch(0.980 0.003 258)` · `#F7F8FA` | `oklch(0.180 0.010 265)` · `#0F1216` | 18,1:1 escuro · 16,8:1 claro |
| `text.secondary` | `oklch(0.760 0.012 258)` · `#ACB1B9` | `oklch(0.460 0.012 265)` · `#55585F` | 8,9:1 · 6,4:1 |
| `text.tertiary` | `oklch(0.660 0.012 258)` · `#8E939A` | `oklch(0.520 0.010 265)` · `#66696F` | 6,2:1 · 4,9:1 — legenda, chevron, aba inativa |
| `text.onAccent` | `oklch(0.190 0.045 152)` · `#021909` | `oklch(1 0 0)` · `#FFFFFF` | **Único** texto sobre preenchimento verde: 10,5:1 · 5,5:1 |
| `separator` | `oklch(0.380 0.012 258 / 62%)` | `oklch(0.860 0.006 265 / 90%)` | Hairline de 0,5 pt entre linhas |
| `border.strong` | `oklch(0.460 0.014 258)` · `#535860` | `oklch(0.780 0.008 265)` · `#B5B7BD` | Borda de campo de texto, radio vazio |

> Branco sobre `status.protected` **reprova** no tema escuro (1,7:1). Por isso existe
> `text.onAccent`: verde-quase-preto no escuro, branco no claro. É o par obrigatório.

## 3. Tipografia — escala iOS

Família: **SF Pro Text / Display** (`-apple-system`). Mono: **SF Mono** para domínios,
caminhos do sistema, endereços DoH e número de versão. O board usa Space Grotesk e
IBM Plex Mono apenas no cromo de documentação — não fazem parte do app.

| Token | Tamanho / entrelinha | Peso | Onde |
|---|---|---|---|
| `type.largeTitle` | 34 / 41 | 700 | Título de cada raiz de aba |
| `type.title2` | 22 / 28 | 700 | Frase de estado do Início |
| `type.title3` | 20 / 25 | 600 | Título de banner; frase-chave de Privacidade |
| `type.headline` | 17 / 22 | 600 | Rótulo de botão; título de opção |
| `type.body` | 17 / 23 | 400 | Título de linha de lista |
| `type.callout` | 16 / 21 | 400 | Toast; botão destrutivo |
| `type.subhead` | 15 / 20 | 400 | Descrição de opção, passos, texto corrido |
| `type.footnote` | 13 / 18 | 400 | Subtítulo de linha, nota sob botão, rótulo de grupo |
| `type.caption` | 12 / 16 | 500 | Badge de teste, pill de status (maiúsculas, +0,06em) |
| `type.tabLabel` | 10 / 12 | 500 | Rótulo da tab bar |
| `type.mono` | 13–15 | 400 | `doubleclick.net`, caminhos, versão |

`largeTitle` e `title2` usam tracking −0,6 pt e −0,3 pt. Dynamic Type: escalar a partir
destes valores com `.relativeTo` no estilo de texto iOS equivalente.

## 4. Espaçamento — base 4

| Token | Valor | | Token | Valor |
|---|---|---|---|---|
| `space.1` | 2 pt | | `space.6` | 20 pt |
| `space.2` | 4 pt | | `space.7` | 24 pt |
| `space.3` | 8 pt | | `space.8` | 32 pt |
| `space.4` | 12 pt | | `space.9` | 40 pt |
| `space.5` | 16 pt | | `space.10` | 56 pt |

Derivados fixos: `layout.gutter` 20 pt (margem lateral da tela) · `row.paddingV` 13 pt ·
`row.minHeight` 52 pt · `card.padding` 16 pt · `touch.min` **44 pt** ·
`button.height` 52 pt · `safeArea.top` 59 pt · `tabBar.height` 49 + 34 pt.

## 5. Raio

| Token | Valor | Onde |
|---|---|---|
| `radius.xs` | 6 pt | Ícone de linha, chip de caminho |
| `radius.sm` | 10 pt | Campo de texto, toast |
| `radius.md` | 14 pt | Cartão, banner, botão |
| `radius.lg` | 20 pt | Painel de documentação (board) |
| `radius.xl` | 28 pt | Folha modal (reservado) |
| `radius.pill` | ∞ | Pill de status, badge, toggle |

## 6. Elevação

| Token | Valor (escuro) | Valor (claro) | Onde |
|---|---|---|---|
| `elev.0` | — | — | Linhas dentro do cartão |
| `elev.1` | `0 1 2 · preto 40%` | `0 1 2 · preto 8%` | Cartão sobre o canvas |
| `elev.2` | `0 4 14 · preto 38%` | `0 4 14 · preto 10%` | Elemento flutuante |
| `elev.3` | `0 18 44 · preto 46%` | `0 18 44 · preto 14%` | Folha modal, moldura do device |
| `elev.glow.protected` | `0 0 60 · protected 30%` | mesma cor, 18% | Halo do escudo ativo |
| `elev.glow.pending` | `0 0 60 · pending 26%` | mesma cor, 16% | Halo do escudo âmbar |

O botão primário leva ainda `0 6 20 · protected 22%` — sombra colorida, não neutra.

## 7. Estados de interação (regra, não sugestão)

| Estado | Regra |
|---|---|
| `hover` / `highlight` | Move **o fundo** em +0,05 L (`surface` → `surfaceRaised`). O texto **nunca** muda para uma cor mais próxima do fundo. |
| Botão primário pressionado | Fundo vai para `accent.pressed`; o texto continua `text.onAccent` — os dois trocam na mesma regra. |
| `focus-visible` | Anel de 2 pt em `accent / 55%`, offset 3 pt. Todo elemento focável tem um. |
| `selected` | Fundo `*.soft` **+** marca sólida. Cor sozinha nunca indica seleção. |
| `disabled` | `bg.surfaceRaised` + `text.tertiary`. Único estado autorizado a reduzir contraste. |
| `error` | Borda `status.danger` + fundo `danger / 7%` + mensagem em texto completo abaixo do campo. |

## 8. Mapeamento sugerido para `Theme.swift`

```swift
enum Theme {
  enum Color {                    // Color(light:dark:) via asset catalog ou ColorScheme
    static let bgCanvas, bgSurface, bgSurfaceRaised, bgFillSubtle: SwiftUI.Color
    static let textPrimary, textSecondary, textTertiary, textOnAccent: SwiftUI.Color
    static let separator, borderStrong: SwiftUI.Color
    static let statusProtected, statusPending, statusIdle, statusDanger, statusInfo: SwiftUI.Color
    static let accent = statusProtected
  }
  enum Space  { static let s1: CGFloat = 2 /* … s10 = 56 */ }
  enum Radius { static let xs: CGFloat = 6, sm = 10, md = 14, lg = 20, xl = 28 }
  enum Elevation { case card, floating, sheet, glowProtected, glowPending }
  enum Font { static let largeTitle, title2, title3, headline, body,
                         callout, subhead, footnote, caption, tabLabel: SwiftUI.Font }
}

enum ProtectionState { case notConfigured, installedInactive, protected }
// notConfigured → .statusIdle · installedInactive → .statusPending · protected → .statusProtected
```

`ProtectionState` é o que decide cor do escudo, pill, título, corpo e ação primária do
Início — um enum, cinco saídas. Nenhuma tela lê cor fora desta tabela.

**Nota de implementação (só vale para o board em CSS):** `accent` e `accent.fg` são
derivados — `accent: var(--status-protected)`. Como um `var()` é substituído no escopo em
que é *declarado*, eles precisam ser redeclarados dentro de `[data-theme="light"]`, senão
os frames claros herdam o verde escuro do `:root`. No Swift o problema não existe: basta
`accent` apontar para o mesmo `Color` dinâmico de `statusProtected`.
