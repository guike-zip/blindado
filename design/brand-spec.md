# Blindado — brand spec

Fonte: direção visual definida pelo usuário (tema escuro, escudo como motivo central,
verde = protegido / âmbar = pendente / cinza = não configurado, aparência nativa iOS).
Posture técnica emprestada de `tech-utility`: mono para valores técnicos, pills de status
com fundo tingido discreto, zero copy de marketing dentro do produto.

## Seis tokens base (tema escuro — tema primário)

```css
:root {
  --bg:      oklch(0.165 0.012 258);  /* fundo da tela (systemBackground escuro) */
  --surface: oklch(0.225 0.014 258);  /* cartões e listas agrupadas */
  --fg:      oklch(0.980 0.003 258);  /* texto primário */
  --muted:   oklch(0.760 0.012 258);  /* texto secundário */
  --border:  oklch(0.380 0.012 258);  /* separadores hairline */
  --accent:  oklch(0.800 0.170 152);  /* verde "protegido" = acento único */

  --font-display: 'Space Grotesk', system-ui, sans-serif;   /* apenas cromo do board */
  --font-body:    -apple-system, BlinkMacSystemFont, 'SF Pro Text', system-ui, sans-serif;
  --font-mono:    'IBM Plex Mono', ui-monospace, 'SF Mono', Menlo, monospace;
}
```

Equivalentes claros (desenhados na seção *Aparência clara* do board):
`--bg oklch(0.962 0.004 265)` · `--surface oklch(1 0 0)` · `--fg oklch(0.180 0.010 265)` ·
`--muted oklch(0.460 0.012 265)` · `--border oklch(0.860 0.006 265)` ·
`--accent oklch(0.500 0.150 152)`.

## Regras do idioma visual

1. **O escudo é o único elemento figurativo.** Ele carrega o estado: cinza (não
   configurado), âmbar (aguardando ativação), verde (blindado). Nenhuma outra ilustração.
2. **A cor só fala de estado.** Verde/âmbar/cinza/vermelho nunca são decoração; um
   elemento colorido sempre significa "este é o status atual" ou "esta é a ação principal".
3. **SF Pro em todo o produto**, SF Symbols-style em traço 1.7px, alinhamento à esquerda,
   large title de 34pt em cada raiz de aba. O board (rótulos, documentação) usa Space
   Grotesk + IBM Plex Mono para não se confundir com a UI.
4. **Uma ação primária por tela.** Tudo mais é secundário, texto ou linha de lista com chevron.
5. **Linguagem sem jargão.** "DNS criptografado" aparece explicado; caminhos do iOS vêm
   em mono, como instrução literal a ser seguida em Ajustes.
