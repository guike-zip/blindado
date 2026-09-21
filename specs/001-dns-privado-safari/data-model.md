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

Provedor DoH candidato para um `ProtectionLevel` (FR-005, FR-006, FR-019). Para `.padrao` e
`.familia` existe **mais de uma opção catalogada** (research.md #2), para não depender de um
único fornecedor terceiro; para `.personalizado` é construído dinamicamente a partir do
endereço informado pelo usuário.

| Campo | Tipo | Regras |
|---|---|---|
| id | `String` | identificador estável do catálogo (ex.: `"adguard"`, `"controld"`) — usado para persistir a escolha em `ProtectionProfile` |
| nível | `ProtectionLevel` | nível ao qual o provedor pertence (`.padrao`/`.familia`); ausente para `.personalizado` |
| nome | `String` | nome exibido ao usuário (ex.: "AdGuard DNS", "Control D") |
| serverURL | `URL` | HTTPS obrigatório; endpoint DoH (`dns-query`) |
| servers | `[String]` | IPs de fallback (IPv4 + IPv6), fixos para `.padrao`/`.familia`, vazio para `.personalizado` |
| localizedDescription | `String` | Exibido em Ajustes do sistema como "Blindado" |
| éPadrãoDoNível | `Bool` | `true` para o provedor pré-selecionado de cada nível (research.md #2); apenas um por nível |

**Catálogo fixo** (valores exatos em research.md #2):
- `.padrao`: **AdGuard DNS** (padrão do nível) · **Control D "Ads & Trackers"** (alternativa)
- `.familia`: **AdGuard DNS Family** (padrão do nível) · **Control D "Family"** (alternativa)

**Validation rules**:
- `.personalizado`: `serverURL` DEVE usar esquema `https`; DEVE responder a uma checagem de
  alcançabilidade antes de ser salvo (research.md #3). Falha em qualquer uma bloqueia o salvamento
  e retorna erro amigável (FR-006).
- `.padrao` e `.familia`: valores fixos do catálogo, não editáveis pelo usuário — apenas a
  *escolha* de qual provedor do catálogo usar dentro do nível é editável (FR-019).

## ProtectionProfile

Configuração de proteção persistida pelo usuário (Key Entity da spec).

| Campo | Tipo | Regras |
|---|---|---|
| nível | `ProtectionLevel` | persistido |
| providerId | `String?` | `id` do `DNSProvider` selecionado dentro do nível `.padrao`/`.familia`; `nil` = usa o provedor com `éPadrãoDoNível == true` (FR-019) — o usuário leigo nunca precisa definir isso |
| customServerURL | `URL?` | presente apenas quando `nível == .personalizado`; `nil` caso contrário |

**Relationships**: resolve para um `DNSProvider` concreto — do catálogo fixo (usando
`providerId`, ou o provedor padrão do nível quando `nil`) para Padrão/Família, ou construído a
partir de `customServerURL` para Personalizado.

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
| testadoEm | `Date` | quando o teste foi concluído; exibido em Início ("Verificado hoje, 09:38") e em Testar — apenas o resultado mais recente é mantido, não um histórico |

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
