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

**Decision**: Enum `DNSProvider` com endpoints DoH fixos da AdGuard para Padrão
(`https://dns.adguard-dns.com/dns-query`) e Família
(`https://family.adguard-dns.com/dns-query`), e um caso `.personalizado(URL)` validado por
formato HTTPS antes de salvar.

**Rationale**: AdGuard oferece endpoints DoH públicos e estáveis com bloqueio de
anúncios/rastreadores (Padrão) e conteúdo adulto (Família) sem exigir conta ou chave de API —
compatível com o Princípio I (zero coleta, zero servidor próprio do Blindado).

**Alternatives considered**:
- *Resolver DoH próprio*: rejeitado — violaria "zero servidor próprio" (Constitution
  Princípio I).
- *Permitir apenas Personalizado (sem Padrão/Família fixos)*: rejeitado — não atende ao público
  leigo que quer proteção "sem configurar nada técnico" (spec, seção de público-alvo).

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

**Status**: `DESIGN.md` e `/design` ainda não existem no repositório nesta data. Toda tarefa de
criação/edição de View está bloqueada até que existam (ver `tasks.md`, gerado em
`/speckit-tasks`); tarefas de Model/Service/ViewModel/teste não são afetadas.

## 8. Localização

**Decision**: String Catalog (`Localizable.xcstrings`) com pt-BR como idioma base e inglês
preparado para tradução futura.

**Rationale**: É o mecanismo nativo recomendado pela Apple desde Xcode 15, substituindo
`.strings`/`.stringsdict`, e não introduz dependência externa.

**Alternatives considered**: nenhuma — não há motivo para usar formato legado `.strings` em um
projeto novo.
