# Blindado — Design

Fonte da verdade visual do app, gerada no Open Design (OpenDesign Cloud / Local Codex) a partir
do brief do produto (specs/001-dns-privado-safari/spec.md) e das diretrizes de marca definidas
pelo usuário: tema escuro como padrão, o escudo como único elemento figurativo (cinza = não
configurado, âmbar = instalado mas desativado, verde = blindado), **Liquid Glass nativo do
iOS 26** na camada de navegação (tab bar, toolbar), conteúdo sempre opaco.

Este arquivo é o índice. Os artefatos completos estão em [`/design`](design/):

- [`design/blindado-ios-prototype.html`](design/blindado-ios-prototype.html) — board navegável
  com 14 telas do protótipo (iPhone 390×844, incl. o estado de scroll que mostra o Liquid Glass
  da toolbar) em **tema escuro** (primário) e uma seção "06 — Aparência clara" com as mesmas 14
  telas em **tema claro**, geradas do mesmo template (mesmo conteúdo, só o esquema de cor
  muda). Abrir direto no navegador.
- [`design/design-tokens.md`](design/design-tokens.md) — **todos os tokens** (cor semântica de
  proteção, superfícies, texto, tipografia, espaçamento base-4, raio, elevação, regras de
  estado) com valor OKLch canônico, hex sRGB e contraste medido, além de um esqueleto sugerido
  de `Theme.swift`. É este arquivo que as tarefas `T012`/`T013` de
  `specs/001-dns-privado-safari/tasks.md` convertem em `Blindado/Theme/Theme.swift` +
  `Blindado/Theme/Assets.xcassets`.
- [`design/brand-spec.md`](design/brand-spec.md) — a direção de marca em 6 tokens base e as
  regras do idioma visual (uma ação primária por tela, cor só fala de estado, etc.).
- [`design/blindado-app-icon.html`](design/blindado-app-icon.html) — 4 conceitos de ícone do
  app (camadas fundo/glifo separadas para o pipeline do Icon Composer do iOS 26, preview em
  grade de Tela de Início clara/escura e no Dock do macOS). Ver seção "Ícone do app" abaixo.
- [`design/blindado-app-store-screenshots.html`](design/blindado-app-store-screenshots.html) —
  template panorâmico dos 7 screenshots de loja (artboard real 1320×2868, iPhone 6,9"). Compõe
  cada captura bruta do app dentro de uma moldura de iPhone com título/subtítulo do roteiro em
  `app-store-submission.md`; o resultado final (com moldura) é o que está em
  `fastlane/screenshots/pt-BR/`. Abrir no navegador para editar copy; `--zoom:1` no `:root`
  exporta em tamanho real, um painel por vez.

## Ícone do app

Quatro conceitos, todos a partir do mesmo path de escudo das telas do app — nenhuma cor nova
além de `status.protected`/`text.onAccent`/`bg.canvas`:

1. **Sólido** — escudo cheio em `status.protected` sobre `bg.canvas`.
2. **Linha invertida** — campo verde cheio, escudo em contorno (`text.onAccent`).
3. **Visto vazado** — escudo cheio com uma confirmação recortada (furo par-ímpar), não
   desenhada por cima.
4. **Negativo** — campo verde cheio, escudo recortado em `text.onAccent` (a ausência, não o
   traço).

**Recomendação: conceito 01 (Sólido).** O argumento é semântico, não estético: no Blindado o
verde significa "protegido", e o app existe porque a proteção pode estar desligada. Um campo
verde cheio (02, 04) ou um visto (03) carimbam "protegido" na Tela de Início o tempo todo,
inclusive quando o perfil caiu — o 01 usa o verde como assinatura sobre um campo neutro e
deixa o veredito real para a tela Início mostrar. Também degrada melhor no pipeline de
camadas do Icon Composer (fundo chapado + um path só gera as variantes tingida/transparente
sem redesenho) e permanece distinto a 58 pt numa grade cheia de ícones saturados.

## O sistema, em uma frase

O escudo *é* o estado — cinza, âmbar, verde — e a cor nunca aparece sozinha: vem sempre
acompanhada de pill, título e uma única ação por tela. Fundo `oklch(0.165 0.012 258)`
(azul-quase-preto, não cinza neutro), superfícies subindo em degraus de +0,05 L, SF Pro na
escala iOS inteira e SF Mono reservado para o que o usuário vai literalmente digitar ou ler no
sistema: domínios, endereços DoH e o caminho `Ajustes › Geral › Gestão de VPN e Dispositivo ›
DNS › Blindado`.

## Liquid Glass — só a camada de navegação

Regra de plataforma (não uma escolha estética): Liquid Glass é **exclusivo do chrome
flutuante** — tab bar inferior, toolbar superior e a aresta de sheets. Conteúdo (cartão,
linha, texto, pill, escudo, **todo botão de ação**) segue 100% opaco. No app real isso não
vira token nenhum — `TabView`, `NavigationStack`, `.toolbar` e `.sheet` nativos do iOS 26
(SDK Xcode 26) desenham o vidro sozinhos. A seção 7 de `design/design-tokens.md` documenta os
valores usados **só como referência visual** (desfoque, saturação, tint, realce especular,
sombra) nas duas aparências, com o aviso explícito de não portar isso para `Theme.swift`.

O frame `03 · E — Testar · lista rolada` é o que prova o material: a lista passa por baixo das
duas barras, com os badges verdes borrando visivelmente através do vidro.

## Telas do protótipo

- **Início** — os três estados: não configurado (um verbo, um botão), instalado-mas-desativado
  (a tela vira instrução, já que o iOS não deixa o app ativar sozinho) e blindado (repouso, com
  a saída sempre visível em texto vermelho — nunca um segundo botão sólido brigando com o
  verde).
- **Nível de proteção** — Padrão / Família / Personalizado, com o campo DoH expandindo no lugar
  e o erro de validação ancorado no campo, em frase completa e sem código de erro — o primário
  fica desabilitado até o servidor responder.
- **Testar** — os quatro vereditos (Protegido / Parcial / Desprotegido / Indeterminado). O
  domínio de controle (`apple.com`) é o que separa "desprotegido" de "sem rede" — por isso o
  estado sem conexão é cinza e se recusa a dar veredito.
- **Safari** — estado vazio que ensina em três passos + estado ativo com a confirmação inline
  logo acima do botão que a produziu.
- **Ajustes e Privacidade** — lista agrupada com o valor atual à direita; Privacidade abre com
  a frase-chave e é explícita sobre o limite: o provedor de DNS vê as consultas, e isso está
  escrito.

## Validação de qualidade

O protótipo passou por verificação automática de: conteúdo cortado/transbordando nos frames,
sobreposição de elementos, contraste (≥4,5:1 texto, ≥3:1 ícones) nos dois temas, hover/focus
nunca reduzindo contraste, uma ação primária por tela, e ausência de placeholders/métricas
inventadas. 8/8 checks passaram (4 com correção automática).

O tema claro passou pela mesma verificação (7/7 checks): cores de status escurecidas para
manter contraste ≥4,5:1 sobre fundo claro (o verde/âmbar do tema escuro reprovariam), halo do
escudo reduzido para não "sujar" o fundo claro, e ícones preenchidos com glifo invertido para
branco. Uma nota de implementação ficou registrada em `design-tokens.md`: o token `accent`
precisa ser redeclarado por esquema (não é um valor fixo), já que `status.protected` tem
valores diferentes no claro e no escuro.

## Como atualizar

Este protótipo vive como projeto `blindado-7a73` no Open Design. Para revisar ou pedir uma
iteração, abra o projeto no app Open Design ou peça para o Claude Code rodar um novo
`start_run` sobre esse projeto — não edite o HTML gerado à mão; qualquer ajuste de conteúdo
deve vir de uma nova geração para manter os tokens e o board consistentes.
