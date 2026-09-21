# Data Model: DNS Privado e Bloqueador de Conteúdo para Safari (Blindado)

Modelos de domínio derivados de `spec.md` (Key Entities) e dos requisitos funcionais. Sem
persistência em banco de dados — apenas valores escalares em `UserDefaults` (App Group) e
estado computado a partir de APIs de sistema (nunca cacheado como fonte da verdade).

## ProtectionLevel

Nível de proteção escolhido pelo usuário (FR-005).

| Campo | Tipo | Regras |
|---|---|---|
| caso | `.padrao` \| `.familia` \| `.personalizado` | enum |

- **Persistido**: sim, via `@AppStorage` (App Group).
- **Padrão inicial**: `.padrao` (nenhum nível ativo até a primeira ativação — ver `ProtectionState`).

## DNSProvider

Provedor DoH associado a um `ProtectionLevel` (FR-005, FR-006).

| Campo | Tipo | Regras |
|---|---|---|
| nível | `ProtectionLevel` | — |
| serverURL | `URL` | HTTPS obrigatório; para `.personalizado`, informado pelo usuário e validado (FR-006) antes de salvar |
| servers | `[String]` | IPs de fallback; fixos para `.padrao`/`.familia`, vazio para `.personalizado` |
| localizedDescription | `String` | Exibido em Ajustes do sistema como "Blindado" |

**Validation rules**:
- `.personalizado`: `serverURL` DEVE usar esquema `https`; DEVE responder a uma checagem de
  alcançabilidade antes de ser salvo (research.md #3). Falha em qualquer uma bloqueia o salvamento
  e retorna erro amigável (FR-006).
- `.padrao` e `.familia`: valores fixos, não editáveis pelo usuário.

## ProtectionProfile

Configuração de proteção persistida pelo usuário (Key Entity da spec).

| Campo | Tipo | Regras |
|---|---|---|
| nível | `ProtectionLevel` | persistido |
| customServerURL | `URL?` | presente apenas quando `nível == .personalizado`; `nil` caso contrário |

**Relationships**: resolve para um `DNSProvider` concreto (fixo para Padrão/Família, construído
a partir de `customServerURL` para Personalizado).

## ProtectionState

Estado real da proteção no sistema — **nunca persistido**, sempre recalculado a partir de
`NEDNSSettingsManager` ao entrar em primeiro plano (`scenePhase`), conforme Constitution
Princípio IV (Honestidade com o Usuário).

| Caso | Significado |
|---|---|
| `.naoConfigurado` | Nenhum perfil de DNS foi instalado ainda |
| `.instaladoDesativado` | Perfil instalado, porém não ativado pelo usuário em Ajustes (ou desativado manualmente fora do app) |
| `.blindado` | Perfil instalado e ativo (`NEDNSSettingsManager.isEnabled == true`) |

**State transitions**:

```text
naoConfigurado --(usuário toca "Blindar meu iPhone"; saveToPreferences)--> instaladoDesativado
instaladoDesativado --(usuário ativa em Ajustes; detectado via scenePhase)--> blindado
blindado --(usuário desativa em Ajustes, fora do app)--> instaladoDesativado   [Edge Case]
instaladoDesativado | blindado --(usuário remove a proteção no app; removeFromPreferences)--> naoConfigurado
```

## ProtectionTestResult

Resultado de uma execução do teste de proteção (Key Entity da spec, US3).

| Campo | Tipo | Regras |
|---|---|---|
| itens | `[DomainCheckResult]` | um por domínio testado |
| statusGeral | `.protegido` \| `.parcial` \| `.desprotegido` \| `.indeterminado` | derivado dos itens |

**Derivation rules**:
- `.protegido`: todos os domínios de anúncio/rastreador bloqueados **e** o domínio comum
  acessível.
- `.parcial`: pelo menos um domínio de anúncio/rastreador bloqueado, mas não todos.
- `.desprotegido`: nenhum domínio de anúncio/rastreador bloqueado.
- `.indeterminado`: teste não pôde ser concluído (ex.: sem rede) — nunca reportar
  `.protegido`/`.desprotegido` nesse caso (Edge Case da spec, FR-010).

## DomainCheckResult

| Campo | Tipo | Regras |
|---|---|---|
| domain | `String` | domínio testado |
| categoria | `.anuncioRastreador` \| `.comum` | define a interpretação do resultado |
| status | `.bloqueado` \| `.acessivel` \| `.indeterminado` | resultado individual |

## ContentBlockerState

Estado do bloqueador de conteúdo do Safari (US4) — também recalculado a cada visita à aba
Safari, nunca cacheado como fonte da verdade.

| Campo | Tipo | Regras |
|---|---|---|
| isEnabled | `Bool` | de `SFContentBlockerManager.getStateOfContentBlocker` |
| lastReloadDate | `Date?` | preenchido após `reloadContentBlocker` bem-sucedido; usado apenas para feedback de UI, não para decisão de estado |
