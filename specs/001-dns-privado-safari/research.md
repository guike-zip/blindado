# Research: DNS Privado e Bloqueador de Conteúdo para Safari (Blindado)

Nenhum item do Technical Context ficou marcado como `NEEDS CLARIFICATION` — o usuário forneceu
detalhes técnicos completos. Este documento registra as decisões e alternativas consideradas
para as escolhas principais.

## 1. Ativação de DNS criptografado em todo o sistema

**Decision**: Usar `NEDNSSettingsManager.shared()` com `NEDNSOverHTTPSSettings` (DNS-over-HTTPS),
`onDemandRules = [NEOnDemandRuleConnect()]` para valer em Wi-Fi e celular, encapsulado atrás do
protocolo `DNSManaging`.

**Rationale**: É a única API pública do iOS para configurar DNS criptografado em todo o sistema
sem VPN. Exige ativação manual do usuário em Ajustes (fora do controle do app), por isso o
fluxo de UI precisa guiar passo a passo e detectar o estado via `scenePhase`. Não funciona no
simulador — daí a exigência de protocolo + mock (Constitution Princípio V).

**Alternatives considered**:
- *NEVPNManager / Packet Tunnel Provider*: rejeitado — implica VPN completa, fora do escopo
  (spec marca VPN como fora do escopo) e exige revisão de App Store mais rigorosa.
- *DNS via configuração de rede Wi-Fi apenas*: rejeitado — não cobre rede celular, violando o
  requisito de proteção "em toda rede".

## 2. Provedores de DNS (Padrão / Família / Personalizado)

**Decision**: Para os níveis Padrão e Família, oferecer **dois provedores DoH independentes**
por nível (catálogo curado, não editável pelo usuário), com um deles pré-selecionado como
padrão. Nível Personalizado continua sendo um `.personalizado(URL)` validado por formato HTTPS
e alcançabilidade antes de salvar.

| Nível | Provedor padrão | Provedor alternativo |
|---|---|---|
| Padrão (ads/rastreadores) | AdGuard DNS — `https://dns.adguard-dns.com/dns-query`<br>IPv4: `94.140.14.14`, `94.140.15.15`<br>IPv6: `2a10:50c0::ad1:ff`, `2a10:50c0::ad2:ff` | Control D Free "Ads & Trackers" — `https://freedns.controld.com/p2`<br>IPv4: `76.76.2.2`, `76.76.10.2`<br>IPv6: `2606:1a40::2`, `2606:1a40:1::2` |
| Família (ads/rastreadores + adulto) | AdGuard DNS Family — `https://family.adguard-dns.com/dns-query`<br>IPv4: `94.140.14.15`, `94.140.15.16`<br>IPv6: `2a10:50c0::bad1:ff`, `2a10:50c0::bad2:ff` | Control D Free "Family" — `https://freedns.controld.com/family`<br>IPv4: `76.76.2.4`, `76.76.10.4`<br>IPv6: `2606:1a40::4`, `2606:1a40:1::4` |

O usuário pode ver e trocar o provedor ativo dentro do nível escolhido (FR-019, US2 cenário 5),
mas nunca precisa fazer isso — o padrão já funciona sem nenhuma ação.

**Rationale**: AdGuard e Control D publicam endpoints DoH públicos e estáveis, sem exigir conta
ou chave de API — compatível com o Princípio I (zero coleta, zero servidor próprio do
Blindado). Ter dois provedores reais por nível atende ao requisito de não depender de um único
fornecedor terceiro (FR-019, SC-007): se um deles sair do ar ou mudar de política, o usuário
ainda tem proteção funcional trocando de provedor dentro do mesmo nível, sem perder a ativação
do DNS do sistema.

**Alternatives considered**:
- *Resolver DoH próprio*: rejeitado — violaria "zero servidor próprio" (Constitution
  Princípio I).
- *Permitir apenas Personalizado (sem Padrão/Família fixos)*: rejeitado — não atende ao público
  leigo que quer proteção "sem configurar nada técnico" (spec, seção de público-alvo).
- *Mullvad DNS público* (sugestão inicial): **rejeitado** — a Mullvad anunciou o encerramento do
  seu serviço público de DNS criptografado em 2 de novembro de 2026, recomendando a migração
  para o Quad9. Incluir um provedor com desligamento anunciado violaria diretamente o próprio
  objetivo de FR-019 (o app pararia de proteger silenciosamente em poucas semanas) e o
  Princípio IV (Honestidade com o Usuário).
- *Quad9* (sugestão inicial): **rejeitado** para Padrão/Família — Quad9 é focado exclusivamente
  em segurança (malware/phishing) e não oferece bloqueio de anúncios/rastreadores nem de
  conteúdo adulto, não atendendo à definição desses dois níveis. Pode ser reavaliado no futuro
  como um nível adicional "Segurança", fora do escopo desta feature.

## 3. Validação do servidor DNS personalizado

**Decision**: Validar formato (URL HTTPS bem formada) e, antes de salvar, fazer uma checagem de
alcançabilidade com timeout curto via `URLSession`.

**Rationale**: Atende ao FR-006 (rejeitar endereços inválidos/inacessíveis) sem exigir nenhuma
biblioteca externa de parsing de DNS.

**Alternatives considered**:
- *Validar apenas formato, sem checar alcançabilidade*: rejeitado — permitiria salvar um
  servidor inexistente, quebrando a Honestidade com o Usuário (Princípio IV) quando a proteção
  "ativa" na verdade não resolve nada.

## 4. Bloqueador de conteúdo do Safari

**Decision**: Target de Content Blocker Extension com `blockerList.json` estático (regras
`url-filter` / `if-domain` / `css-display-none`), mantido abaixo de 150.000 regras; estado lido
via `SFContentBlockerManager.getStateOfContentBlocker` e recarga via `reloadContentBlocker`,
atrás do protocolo `ContentBlockerManaging`.

**Rationale**: É o único mecanismo suportado pela Apple para bloquear conteúdo no Safari sem
JavaScript injetado ou proxy — alinhado ao posicionamento "bloqueador de conteúdo para Safari"
(Princípio III).

**Alternatives considered**:
- *Safari Web Extension com JavaScript dinâmico*: rejeitado — maior superfície de revisão da
  App Store e não necessário para bloqueio baseado em listas de domínios/seletores CSS.

## 5. Teste de proteção

**Decision**: `URLSession` com timeout curto contra uma lista fixa de domínios conhecidos de
anúncios/rastreadores + um domínio comum; falha de resolução conta como bloqueado; execução
assíncrona item a item atrás do protocolo `ProtectionTesting`.

**Rationale**: Não requer acesso de baixo nível a resolução de DNS (indisponível para apps de
terceiros no iOS) — o efeito observável (domínio acessível ou não) já responde à pergunta que
o usuário quer: "a proteção está funcionando?".

**Alternatives considered**:
- *Inspecionar a resposta DNS diretamente*: rejeitado — API de baixo nível não disponível para
  apps de terceiros no iOS.

## 6. Persistência

**Decision**: `@AppStorage` sobre `UserDefaults(suiteName: "group.com.seudominio.blindado")`
para nível de proteção escolhido e servidor personalizado.

**Rationale**: App Group é necessário de qualquer forma para o Content Blocker Extension
acessar a mesma configuração; `@AppStorage` evita uma camada de persistência adicional
(Princípio VII — Simplicidade).

**Alternatives considered**:
- *CoreData*: rejeitado — excesso de complexidade para dois valores escalares.

## 7. Sistema de design (Open Design)

**Decision**: `DESIGN.md` + artefatos em `/design` (nexu-io/open-design) são a fonte da verdade
visual. Ao existirem, seus tokens são convertidos manualmente em `Theme.swift` (cores,
tipografia, espaçamentos, raios, sombras como constantes/estilos Swift) e em `Assets.xcassets`
(cores adaptativas claro/escuro). Views consomem somente esses tokens — nenhum valor solto
(`Color(red:green:blue:)`, `.padding(16)` literal, etc.) no código de View. As telas HTML do
Open Design são referência de layout/hierarquia a ser reproduzida em SwiftUI nativo — nunca
carregadas via `WKWebView`/`WebView`.

**Rationale**: Garante consistência visual centralizada e alinhamento com Dynamic Type/modo
escuro (Princípio VI) a partir de uma única fonte, sem introduzir dependência de terceiros
(Princípio II) nem WebView (que traria overhead, risco de acessibilidade e fugiria do padrão
"nativo" da Constitution).

**Alternatives considered**:
- *Carregar as telas HTML do Open Design em WebView dentro do app*: rejeitado explicitamente
  pelo usuário e pela Constitution (Princípio II — apenas frameworks nativos).
- *Hardcode de valores de design direto nas Views*: rejeitado — quebra a fonte única da
  verdade e dificulta manutenção/expansão do design system.

**Status**: `DESIGN.md` e `/design` foram gerados via Open Design (OpenDesign Cloud/Local
Codex) em 2026-09-21 — board de 12 telas em tema escuro (tema primário) com token set
documentado em `design/design-tokens.md`; uma segunda geração está em andamento para adicionar
as versões em tema claro usando os tokens claros já documentados. O gate de View em `tasks.md`
(T012/T013) deixa de estar bloqueado a partir desta data.

## 8. Localização

**Decision**: String Catalog (`Localizable.xcstrings`) com pt-BR como idioma base e inglês
preparado para tradução futura.

**Rationale**: É o mecanismo nativo recomendado pela Apple desde Xcode 15, substituindo
`.strings`/`.stringsdict`, e não introduz dependência externa.

**Alternatives considered**: nenhuma — não há motivo para usar formato legado `.strings` em um
projeto novo.

## 9. Modelo de negócio (app pago, sem compras internas)

**Decision**: Blindado é distribuído como app pago de download único (preço definido no App
Store Connect, ver `app-store-submission.md`). Nenhum código de StoreKit, compra dentro do
app, assinatura ou paywall é implementado; todos os níveis de proteção e funcionalidades ficam
disponíveis para todo usuário que baixar o app.

**Rationale**: Atende à decisão de negócio do usuário (Constitution Princípio IX) e simplifica
a experiência do usuário leigo — nenhuma decisão de upgrade, nenhum recurso bloqueado para
explicar. Também elimina uma superfície inteira de complexidade e risco de conformidade
(validação de recibo, tratamento de reembolso/downgrade, restauração de compras) que um modelo
de assinatura ou IAP exigiria.

**Alternatives considered**:
- *Freemium com IAP para Família/Personalizado*: rejeitado pelo usuário — contraria a decisão
  de negócio e adicionaria StoreKit, violando a Simplicidade (Princípio VII) e a nova
  Constitution Princípio IX.
- *Assinatura recorrente*: rejeitado pelo mesmo motivo; também exigiria lógica de expiração e
  validação de recibo, incompatível com "zero servidor próprio" (Princípio I).

## 10. Linguagem visual: Liquid Glass nativo (iOS 26)

**Decision**: Adotar o Liquid Glass do iOS 26 via APIs nativas do SwiftUI, e elevar o mínimo do
app de iOS 16+ para **iOS 26+** (decisão explícita do usuário, dado que essas APIs não existem
em versões anteriores). Regra de aplicação (diretriz da própria Apple, confirmada em pesquisa):
**glass é exclusivo da camada de navegação — nunca aplicado ao conteúdo**.

- `TabView`, `NavigationStack`/toolbars e sheets nativos **herdam Liquid Glass automaticamente**
  ao compilar com Xcode 26 (SDK iOS 26), sem nenhum modificador manual — desde que `RootTabView`
  use `TabView` de verdade (não uma tab bar customizada) e cada raiz de aba use
  `NavigationStack` com `.toolbar` padrão.
- `.glassEffect(_:in:)` / `GlassEffectContainer` / `.glassEffectID(_:in:)` ficam reservados para
  elementos verdadeiramente flutuantes sobre conteúdo (se algum surgir); nenhuma tela do
  Blindado hoje tem esse tipo de elemento — os botões de ação (“Blindar meu iPhone”, “Testar de
  novo”, “Recarregar regras”) são conteúdo, não navegação, e continuam como botões
  normais/prominentes (`.buttonStyle(.borderedProminent)` ou equivalente), **não** glass.
- Acessibilidade (Reduzir Transparência, Reduzir Movimento, Aumentar Contraste) é adaptada
  automaticamente pelo sistema para Liquid Glass nativo, sem código adicional — reforça a
  Constitution Princípio VI.
- Os tokens semânticos de cor/status (`status.protected` etc., research.md #1 do design)
  continuam válidos como tinte (`Glass.tint(_:)` quando algum elemento de navegação precisar,
  ou como cor sólida no conteúdo) — não são substituídos pelo Liquid Glass, são compostos com
  ele.

**Rationale**: O usuário pediu explicitamente a linguagem visual nativa atual da Apple, não uma
aproximação. Usar os componentes nativos (`TabView`/`NavigationStack`) em vez de construir
chrome customizado é também a opção mais simples (Princípio VII) — o sistema operacional faz o
trabalho de renderizar o vidro, sem manutenção de tokens de blur/opacidade pelo app.

**Alternatives considered**:
- *iOS 16+ com fallback via `Material` (`.ultraThinMaterial`/`.regularMaterial`, disponíveis
  desde iOS 15) para versões pré-26*: rejeitado pelo usuário — manteria alcance de dispositivos
  maior, mas exigiria dois caminhos visuais (`if #available(iOS 26, *)`) por tela e a aparência
  não seria idêntica nas versões antigas.
- *Aplicar glass também a cards/botões de conteúdo para "parecer mais Liquid Glass"*: rejeitado
  — contraria a diretriz de design da própria Apple e arrisca ilegibilidade (glass sobre glass
  sem `GlassEffectContainer` degrada contraste e performance).
