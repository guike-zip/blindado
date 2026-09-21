# Tasks: DNS Privado e Bloqueador de Conteúdo para Safari (Blindado)

**Input**: Design documents from `/specs/001-dns-privado-safari/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Incluídos — a Constitution (Princípio V, Testabilidade) exige testes unitários de
ViewModels com mocks para todo acesso a APIs de sistema.

**Organization**: Tarefas agrupadas por história de usuário (spec.md), em ordem de prioridade.

**Gate de Design (Open Design)**: `DESIGN.md` e `/design` foram gerados via Open Design em
2026-09-21 (board de 12 telas + token set em `design/design-tokens.md`) — o gate que bloqueava
as tarefas de `View` está **resolvido**. As marcações "(depende de T012, T013)" abaixo
continuam válidas como dependência normal de execução (extrair os tokens antes de usá-los),
não mais como bloqueio por arquivo ausente.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência pendente)
- **[Story]**: história de usuário à qual a tarefa pertence (US1–US5)
- Caminhos de arquivo são relativos à raiz do repositório

---

## Phase 1: Setup

**Purpose**: Inicialização do projeto Xcode e estrutura de pastas

- [x] T001 Gerar `Blindado.xcodeproj` a partir de `project.yml` (xcodegen) — App
      `io.blindado.app` e target `BlindadoContentBlocker`
      (`io.blindado.app.contentblocker`); verificado com `xcodebuild build`/`test`
      reais contra o SDK do iOS 26 (per `quickstart.md` seção 2)
- [x] T002 App Group `group.io.blindado.app` e entitlement
      `com.apple.developer.networking.networkextension = ["dns-settings"]` declarados em
      `Blindado/Blindado.entitlements` / `BlindadoContentBlocker/BlindadoContentBlocker.entitlements`
      via `project.yml`. **Falta**: aprovar o entitlement de Network Extension e provisionar o
      App ID na conta de desenvolvedor Apple (Apple Developer Portal) — isso só o usuário pode
      fazer (per `quickstart.md` seção 3)
- [x] T003 [P] Criar estrutura de pastas `Blindado/{App,Theme,Models,Services,ViewModels,Views,Resources}/`
      per `plan.md` → Project Structure
- [x] T004 [P] Criar String Catalog `Blindado/Resources/Localizable.xcstrings` com pt-BR como
      idioma base e inglês preparado (research.md #8)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Modelos e serviço de DNS compartilhados por US1 e US2, e o gate de design
compartilhado por todas as Views

**⚠️ CRITICAL**: Nenhuma tarefa de história de usuário pode começar antes desta fase

- [x] T005 [P] Criar enum `ProtectionLevel` em `Blindado/Models/ProtectionLevel.swift` — casos
      `.padrao`, `.familia`, `.personalizado`; persistido via `@AppStorage` (data-model.md)
- [x] T006 [P] Criar `DNSProvider` e o catálogo fixo de provedores em
      `Blindado/Models/DNSProvider.swift` — campos `id`, `nível`, `nome`, `serverURL` (HTTPS
      obrigatório), `servers`, `localizedDescription` = "Blindado", `éPadrãoDoNível` (FR-019,
      data-model.md). Catálogo (research.md #2), dois provedores por nível, um marcado
      `éPadrãoDoNível = true`:
      `.padrao` → **AdGuard DNS** (padrão) `https://dns.adguard-dns.com/dns-query` servers
      `94.140.14.14, 94.140.15.15, 2a10:50c0::ad1:ff, 2a10:50c0::ad2:ff`; **Control D "Ads &
      Trackers"** (alternativa) `https://freedns.controld.com/p2` servers
      `76.76.2.2, 76.76.10.2, 2606:1a40::2, 2606:1a40:1::2`.
      `.familia` → **AdGuard DNS Family** (padrão) `https://family.adguard-dns.com/dns-query`
      servers `94.140.14.15, 94.140.15.16, 2a10:50c0::bad1:ff, 2a10:50c0::bad2:ff`; **Control D
      "Family"** (alternativa) `https://freedns.controld.com/family` servers
      `76.76.2.4, 76.76.10.4, 2606:1a40::4, 2606:1a40:1::4`.
- [x] T007 [P] Criar `ProtectionProfile` em `Blindado/Models/ProtectionProfile.swift` — `nível:
      ProtectionLevel` persistido via `@AppStorage` no App Group
      `group.io.blindado.app`; `providerId: String?` (`nil` = usa o provedor com
      `éPadrãoDoNível == true`, FR-019); `customServerURL: URL?` presente apenas quando
      `nível == .personalizado`, `nil` caso contrário (data-model.md) (depende de T006)
- [x] T008 [P] Criar enum `ProtectionState` em `Blindado/Models/ProtectionState.swift` — casos
      `.naoConfigurado`, `.instaladoDesativado`, `.blindado`; NUNCA persistido, sempre
      recalculado a partir do sistema (data-model.md, Constitution Princípio IV)
- [x] T009 Criar protocolo `DNSManaging` em `Blindado/Services/DNSManaging.swift` conforme
      `contracts/DNSManaging.md`, incluindo `availableProviders(for:)` (retorna o catálogo de
      T006; ≥2 provedores para `.padrao`/`.familia`, FR-019) (depende de T005–T008)
- [x] T010 [P] Implementar `DNSManager` (real) em `Blindado/Services/DNSManager.swift` usando
      `NEDNSSettingsManager.shared()`, `NEDNSOverHTTPSSettings`,
      `onDemandRules = [NEOnDemandRuleConnect()]`, `localizedDescription = "Blindado"`,
      `loadFromPreferences`/`saveToPreferences`/`removeFromPreferences` (depende de T009)
- [x] T011 [P] Implementar `MockDNSManager` em `Blindado/Services/MockDNSManager.swift` com
      estado em memória controlável para Previews e XCTest (depende de T009)
- [x] T012 Gerar `Blindado/Theme/Theme.swift` a partir de `design/design-tokens.md`,
      convertendo os tokens de cor semântica (`status.*`/`status.*.soft`, `text.onAccent`),
      tipografia, espaçamento, raio e sombra do Open Design em constantes/estilos Swift
      (research.md #7). **Não inclui tokens de vidro/blur** — Liquid Glass (tab bar, toolbar)
      vem de graça do `TabView`/`NavigationStack` nativos do iOS 26 (research.md #10), sem
      token nenhum do app. Todas as tarefas de View desta lista dependem desta tarefa.
- [x] T013 Gerar `Blindado/Theme/Assets.xcassets` com os color sets adaptativos
      claro/escuro do Open Design a partir de `design/design-tokens.md` (valores OKLch/hex de
      cada tema documentados por token) (depende de T012)

**Checkpoint**: Modelos, `DNSManaging` e tokens de tema prontos — ViewModels de qualquer
história e as tarefas de View já podem ser implementados.

---

## Phase 3: User Story 1 - Blindar o aparelho (Priority: P1) 🎯 MVP

**Goal**: Usuário ativa/remove o DNS criptografado do sistema e sempre vê o estado real
(Blindado / Instalado mas desativado / Não configurado).

**Independent Test**: Em iPhone físico, tocar "Blindar meu iPhone", ativar em Ajustes, voltar
ao app e confirmar mudança automática para "Blindado"; remover e confirmar retorno a "Não
configurado" (quickstart.md seção 5, US1).

### Tests for User Story 1

- [x] T014 [P] [US1] Teste unitário de `HomeViewModel` (transições
      naoConfigurado→instaladoDesativado→blindado→naoConfigurado, e o tratamento do erro de
      conflito quando outra configuração de DNS/VPN de terceiros já está ativa — FR-017,
      usando `MockDNSManager`) em `BlindadoTests/HomeViewModelTests.swift`

### Implementation for User Story 1

- [x] T015 [US1] Implementar `HomeViewModel` em `Blindado/ViewModels/HomeViewModel.swift` —
      expõe `ProtectionState` atual (via `DNSManaging.currentState()`), ações `blindar()`,
      `remover()` e `abrirAjustesDoSistema()` (via `UIApplication.openSettingsURLString`),
      recalcula o estado ao voltar ao primeiro plano (`scenePhase`, FR-001, FR-003), e trata o
      erro de conflito lançado por `DNSManaging.install()` quando outra configuração de DNS/VPN
      de terceiros já está ativa, expondo um aviso orientando o usuário a resolvê-lo antes de
      blindar o aparelho (FR-017) (depende de T009, T014)
- [x] T016 [US1] Criar `RootTabView` em `Blindado/Views/RootTabView.swift` usando `TabView`
      **nativo** do SwiftUI (não construir chrome próprio, para herdar Liquid Glass
      automaticamente do iOS 26, research.md #10) — navegação por 4 abas (Início→`HomeView`,
      Safari/Testar/Ajustes→placeholders temporários a serem substituídos pelas histórias
      US3/US4/US5), usando os tokens de `Theme.swift` só para o conteúdo (depende de T012,
      T013, T015)
- [x] T017 [US1] Criar `HomeView` em `Blindado/Views/HomeView.swift`, dentro de um
      `NavigationStack` com `.toolbar` padrão (Liquid Glass automático no título/toolbar) —
      escudo grande com os 3 estados visuais, botão "Blindar meu iPhone" como botão de
      conteúdo normal/prominente (**não** `.glassEffect`, é conteúdo — research.md #10),
      instruções passo a passo (Ajustes > Geral > Gestão de VPN e Dispositivo > DNS >
      Blindado), botão de remover, e a exibição do aviso de conflito de DNS/VPN de terceiros
      (FR-017) exposto pelo ViewModel, usando somente tokens de `Theme.swift` (depende de
      T012, T013, T015)

**Checkpoint**: US1 completa e testável isoladamente em dispositivo físico (MVP).

---

## Phase 4: User Story 2 - Escolher o nível de proteção (Priority: P1)

**Goal**: Usuário escolhe entre Padrão, Família ou Personalizado (com validação de URL), e a
escolha persiste e é reaplicada sem nova ativação manual. Dentro de Padrão/Família, o usuário
pode opcionalmente ver e trocar qual dos provedores do catálogo está em uso (FR-019).

**Independent Test**: Com a proteção ativa, trocar entre os 3 níveis e confirmar persistência;
testar URL personalizada inválida e válida; em Padrão/Família, trocar de provedor (ex.: AdGuard
→ Control D) e confirmar reaplicação sem nova ativação manual (quickstart.md seção 5, US2).

### Tests for User Story 2

- [x] T018 [P] [US2] Teste unitário de `ProtectionLevelViewModel` (troca de nível, troca de
      provedor dentro do nível, rejeição de URL não-HTTPS/inacessível, persistência) usando
      `MockDNSManager` em `BlindadoTests/ProtectionLevelViewModelTests.swift`

### Implementation for User Story 2

- [x] T019 [US2] Implementar `ProtectionLevelViewModel` em
      `Blindado/ViewModels/ProtectionLevelViewModel.swift` — seleciona nível, lista provedores
      via `DNSManaging.availableProviders(for:)` e permite trocar o `providerId` dentro de
      Padrão/Família (FR-019), valida servidor personalizado via
      `DNSManaging.validateCustomServer` (FR-006), persiste `ProtectionProfile` e reaplica via
      `DNSManaging.install` (FR-008) (depende de T009, T018)
- [x] T020 [US2] Criar `ProtectionLevelView` em `Blindado/Views/ProtectionLevelView.swift` —
      seleção dos 3 níveis, seletor opcional de provedor dentro de Padrão/Família (nome do
      provedor, não a URL técnica), campo de URL personalizada, mensagens de erro de
      validação, usando tokens de `Theme.swift` (depende de T012, T013, T019)
- [x] T021 [US2] Conectar navegação de `HomeView` para `ProtectionLevelView`
      (`Blindado/Views/HomeView.swift`) (depende de T012, T013, T017, T020)

**Checkpoint**: US1 e US2 funcionam de forma independente.

---

## Phase 5: User Story 3 - Testar a proteção (Priority: P2)

**Goal**: Usuário roda um teste item a item contra domínios conhecidos e vê um resultado geral
claro, incluindo o caso "indeterminado" sem rede.

**Independent Test**: Rodar o teste com proteção ativa, desativada, e em modo avião — conferir
os 3 resultados distintos (quickstart.md seção 5, US3).

### Tests for User Story 3

- [x] T022 [P] [US3] Teste unitário de `ProtectionTestViewModel` (casos protegido, parcial,
      desprotegido, indeterminado) usando `MockProtectionTester` em
      `BlindadoTests/ProtectionTestViewModelTests.swift` (depende de T023–T026; pode ser
      escrito antes, como TDD, mas só compila/roda depois do Mock existir)

### Implementation for User Story 3

- [x] T023 [P] [US3] Criar `ProtectionTestResult` e `DomainCheckResult` em
      `Blindado/Models/ProtectionTestResult.swift` — inclui `testadoEm: Date` (data-model.md)
      e as regras de derivação de `statusGeral`
      (.protegido/.parcial/.desprotegido/.indeterminado) exatamente como descritas em
      `data-model.md` (FR-010)
- [x] T024 [US3] Criar protocolo `ProtectionTesting` em `Blindado/Services/ProtectionTesting.swift`
      conforme `contracts/ProtectionTesting.md` (depende de T023)
- [x] T025 [P] [US3] Implementar `ProtectionTester` (real) em
      `Blindado/Services/ProtectionTester.swift` — `URLSession` com timeout curto contra a
      lista fixa de domínios: `doubleclick.net`, `googleadservices.com`,
      `google-analytics.com`, `ads.tiktok.com`, `graph.facebook.com` (categoria
      anúncio/rastreador) e `apple.com` como domínio de controle/comum (categoria comum — deve
      continuar acessível mesmo com a proteção ativa); falha de resolução nos 5 primeiros
      conta como bloqueado, falha no domínio de controle é sinal de ausência de rede
      (`.indeterminado`, não `.desprotegido`) (depende de T024)
- [x] T026 [P] [US3] Implementar `MockProtectionTester` em
      `Blindado/Services/MockProtectionTester.swift` com sequência de resultados pré-definida
      (depende de T024)
- [x] T027 [US3] Implementar `ProtectionTestViewModel` em
      `Blindado/ViewModels/ProtectionTestViewModel.swift` — consome `AsyncStream` de
      `ProtectionTesting.runTest()`, expõe resultados item a item sem travar a UI (depende de
      T022, T024, T026)
- [x] T028 [US3] Criar `ProtectionTestView` em `Blindado/Views/ProtectionTestView.swift` —
      lista de domínios com status individual e resultado geral, usando tokens de
      `Theme.swift` (depende de T012, T013, T027)
- [x] T029 [US3] Substituir o placeholder da aba "Testar" em `RootTabView` por
      `ProtectionTestView` (`Blindado/Views/RootTabView.swift`) (depende de T012, T013, T016, T028)

**Checkpoint**: US1, US2 e US3 funcionam de forma independente.

---

## Phase 6: User Story 4 - Safari mais limpo (Priority: P3)

**Goal**: Usuário vê se o bloqueador de conteúdo do Safari está habilitado, recarrega as regras
e é ensinado a habilitá-lo.

**Independent Test**: Com o bloqueador desabilitado/habilitado nos Ajustes do Safari, conferir
que a aba Safari reflete o estado real e que "Recarregar regras" confirma conclusão
(quickstart.md seção 5, US4).

### Tests for User Story 4

- [x] T030 [P] [US4] Teste unitário de `SafariViewModel` (estados habilitado/desabilitado,
      recarga) usando `MockContentBlockerManager` em `BlindadoTests/SafariViewModelTests.swift`
      (depende de T032, T034; pode ser escrito antes, como TDD, mas só compila/roda depois do
      Mock existir)

### Implementation for User Story 4

- [x] T031 [P] [US4] Criar `ContentBlockerState` em
      `Blindado/Models/ContentBlockerState.swift` — `isEnabled: Bool`,
      `lastReloadDate: Date?` (data-model.md)
- [x] T032 [US4] Criar protocolo `ContentBlockerManaging` em
      `Blindado/Services/ContentBlockerManaging.swift` conforme
      `contracts/ContentBlockerManaging.md` (depende de T031)
- [x] T033 [P] [US4] Implementar `ContentBlockerManager` (real) em
      `Blindado/Services/ContentBlockerManager.swift` usando
      `SFContentBlockerManager.getStateOfContentBlocker` e
      `SFContentBlockerManager.reloadContentBlocker(withIdentifier:)` com identificador
      `io.blindado.app.contentblocker` (depende de T032)
- [x] T034 [P] [US4] Implementar `MockContentBlockerManager` em
      `Blindado/Services/MockContentBlockerManager.swift` (depende de T032)
- [x] T035 [P] [US4] Criar `ContentBlockerRequestHandling.swift` no target
      `BlindadoContentBlocker/`
- [x] T036 [P] [US4] Criar `blockerList.json` inicial no target `BlindadoContentBlocker/` —
      regras `url-filter`/`if-domain`/`css-display-none`, abaixo de 150.000 regras
- [x] T037 [US4] Implementar `SafariViewModel` em `Blindado/ViewModels/SafariViewModel.swift`
      — estado atual, `recarregarRegras()`, instruções para habilitar (depende de T030, T032,
      T034)
- [x] T038 [US4] Criar `SafariView` em `Blindado/Views/SafariView.swift` — estado do
      bloqueador, botão "Recarregar regras", instruções, usando tokens de `Theme.swift`
      (depende de T012, T013, T037)
- [x] T039 [US4] Substituir o placeholder da aba "Safari" em `RootTabView` por `SafariView`
      (`Blindado/Views/RootTabView.swift`) (depende de T012, T013, T016,
      T038)

**Checkpoint**: US1–US4 funcionam de forma independente.

---

## Phase 7: User Story 5 - Transparência (Priority: P3)

**Goal**: Usuário entende, a partir do app, que nenhum dado é coletado e para onde as consultas
DNS são enviadas, com link para a política de privacidade completa.

**Independent Test**: Acessar Ajustes → Privacidade e conferir que o texto é consistente com o
comportamento real; abrir o link da política de privacidade (quickstart.md seção 5, US5).

### Tests for User Story 5

- [x] T040 [P] [US5] Teste unitário de `PrivacyViewModel` (texto reflete o provedor DNS atual)
      usando `MockDNSManager` em `BlindadoTests/PrivacyViewModelTests.swift`

### Implementation for User Story 5

- [x] T041 [US5] Implementar `PrivacyViewModel` em `Blindado/ViewModels/PrivacyViewModel.swift`
      — lê o provedor/estado atual via `DNSManaging`, expõe texto de privacidade e URL da
      política de privacidade (FR-014) (depende de T009, T040)
- [x] T042 [US5] Criar `PrivacyView` em `Blindado/Views/PrivacyView.swift` — texto de
      privacidade e link, usando tokens de `Theme.swift` (depende de T012, T013, T041)
- [x] T043 [US5] Criar `SettingsView` em `Blindado/Views/SettingsView.swift` com entrada
      "Privacidade" navegando para `PrivacyView`, usando tokens de `Theme.swift`
      (depende de T012, T013, T042)
- [x] T044 [US5] Substituir o placeholder da aba "Ajustes" em `RootTabView` por `SettingsView`
      (`Blindado/Views/RootTabView.swift`) (depende de T012, T013, T016,
      T043)

**Checkpoint**: Todas as 5 histórias de usuário funcionam de forma independente.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T045 [P] Adicionar rótulos de VoiceOver e validar Dynamic Type em todas as Views
      (Constitution Princípio VI) — após T016–T044
- [x] T046 [P] Revisar todos os textos de UI e o texto de `app-store-submission.md` contra a
      Constitution Princípio III (nenhuma menção a bloqueio de anúncios fora do Safari) e
      contra o Princípio IX/FR-018 (nenhuma menção a "versão Pro", compra ou assinatura)
- [ ] T047 Rodar `quickstart.md` seção 5 (validação em dispositivo físico) para as 5 histórias
      de usuário antes de considerar a feature completa
- [ ] T048 [P] Preencher e validar o checklist final de `app-store-submission.md` antes do
      envio à App Store
- [x] T049 [P] Auditar o projeto Xcode (targets, capabilities, dependências) para confirmar
      ausência de StoreKit, de qualquer framework de compra/assinatura, e de código morto de
      versão "Pro" (Constitution Princípio IX, FR-018)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências
- **Foundational (Phase 2)**: depende do Setup — bloqueia todas as histórias; T012/T013
  (Theme/Assets, a partir de `design/design-tokens.md`) especificamente precisam estar prontas
  antes de qualquer tarefa de **View** de qualquer história, não dos Models/Services/ViewModels/testes
- **User Stories (Phase 3–7)**: dependem do Foundational (Models/`DNSManaging`); tarefas de
  ViewModel podem prosseguir em paralelo às de Theme (T012/T013); tarefas de View exigem
  T012/T013 concluídas
- **Polish (Phase 8)**: depende de todas as histórias desejadas estarem completas

### User Story Dependencies

- **US1 (P1)**: só depende do Foundational — nenhuma dependência de outra história
- **US2 (P1)**: depende do Foundational; a View (T021) se conecta a `HomeView` (US1), mas o
  ViewModel (T019) é independente
- **US3 (P2)**: depende do Foundational; a View (T029) substitui um placeholder do
  `RootTabView` criado em US1, mas o ViewModel/Service são independentes
- **US4 (P3)**: mesmo padrão de US3
- **US5 (P3)**: mesmo padrão de US3

### Parallel Opportunities

- T003, T004 (Setup) em paralelo
- T005–T008 (Models fundacionais) em paralelo
- T010, T011 (DNSManager real + mock) em paralelo após T009
- Dentro de cada história, os testes `[P]` e os models/mocks `[P]` de arquivos diferentes podem
  rodar em paralelo
- Todos os ViewModels de todas as histórias (T015, T019, T027, T037, T041) podem ser
  implementados em paralelo por pessoas diferentes assim que o Foundational (T005–T011)
  estiver pronto, em paralelo a T012/T013
- Todas as tarefas de View ficam paralelas entre si **somente depois** de T012/T013 estarem
  prontas

---

## Parallel Example: User Story 1

```bash
Task: "Teste unitário de HomeViewModel em BlindadoTests/HomeViewModelTests.swift"
# (T016 e T017 dependem uma da outra via HomeViewModel, não são paralelas entre si)
```

---

## Implementation Strategy

### MVP First (User Story 1)

1. Completar Setup (Phase 1)
2. Completar Foundational — Models + `DNSManaging` (T005–T011) e Theme/Assets a partir de
   `design/design-tokens.md` (T012–T013)
3. Completar US1 (Phase 3) — ViewModel e Views
4. **PARAR e VALIDAR**: testar US1 isoladamente em dispositivo físico (quickstart.md)

### Incremental Delivery

1. Setup + Foundational (Models, `DNSManaging`, Theme/Assets) → base pronta
2. US1 → US2 → US3 → US4 → US5, cada uma validada em dispositivo físico (quickstart.md) antes
   de avançar para a próxima
3. Times maiores podem paralelizar: ViewModels de todas as histórias assim que T005–T011
   estiverem prontos; Views de cada história assim que T012–T013 estiverem prontos

---

## Addendum: suporte nativo a macOS (research.md #11)

Fora da numeração original (feature já estava com as Views do iPhone prontas quando o suporte
a macOS foi pedido). Todo concluído e verificado com `xcodebuild build`/`test` reais:

- [x] `Blindado/Views/RootSidebarView.swift` — raiz de navegação por sidebar
      (`NavigationSplitView`) para macOS, reaproveitando `HomeView`/`SafariView`/
      `ProtectionTestView`/`SettingsView` já existentes
- [x] `#if os(iOS)`/`#if os(macOS)` em `HomeView`, `SafariView`, `ProtectionLevelView`,
      `PrivacyView` — instruções de ativação por plataforma e remoção de modificadores
      iOS-only (`navigationBarTitleDisplayMode`, `keyboardType`, `textInputAutocapitalization`)
- [x] `Blindado/App/SystemLinks.swift` — link de Ajustes correto por plataforma
- [x] `BlindadoApp.swift` escolhe `RootSidebarView` (macOS) ou `RootTabView` (iOS)
- [x] `project.yml`: targets `BlindadoMac` + `BlindadoMacContentBlocker` + `BlindadoMacTests`,
      App Sandbox + entitlements, reaproveitando as mesmas pastas de fonte do iOS
- [x] `xcodebuild -scheme BlindadoMac ... build test` — build e os mesmos 25 testes passando
      no macOS

**Pendente** (mesma natureza do T045/T047/T048 do iOS — precisa de hardware/verificação
manual):
- [ ] Validar em Mac físico se o fluxo de ativação descrito (Ajustes do Sistema → Rede → novo
      serviço "Blindado" → Tornar Serviço Ativo) está correto — a fonte usada foi indireta
      (fóruns de desenvolvedor), não documentação primária da Apple (research.md #11)
- [ ] VoiceOver/Acessibilidade no macOS (Constitution Princípio VI) — não testado
- [x] Ícone do app — conceito 01 "Sólido" (`design/blindado-app-icon.html`), renderizado em
      `Blindado/Theme/Assets.xcassets/AppIcon.appiconset/` (iOS universal light/dark + macOS
      16–1024px) e verificado com build real nos dois alvos (research.md #12)

---

## Addendum: Fastlane (deploy para TestFlight/App Store, research.md #13)

- [x] `Gemfile`/`Gemfile.lock` (fastlane via Bundler, `vendor/bundle/` local) +
      `bin/fastlane` (wrapper que corrige o locale UTF-8 antes de subir o processo — sem isso
      `xcpretty` quebra com nosso texto em pt-BR)
- [x] `project.yml`: `MARKETING_VERSION`/`CURRENT_PROJECT_VERSION` como fonte única de verdade
      da versão, referenciados via `$(...)` nos 4 `Info.plist`
- [x] `fastlane/Fastfile` — lanes `ios`/`mac` `test`, `build_dev`, `bump_build`,
      `bump_version`, `build_release`, `beta`, `release` (as duas últimas com
      `submit_for_review: false` de propósito — Constitution Princípio III exige revisão
      manual do texto/screenshots antes de qualquer submissão)
- [x] `fastlane/Appfile`, `fastlane/.env.default` (placeholders, sem segredos),
      `fastlane/README-SETUP.md` (passo a passo do que falta — conta Apple, API key,
      assinatura)
- [x] Verificado de ponta a ponta: `./bin/fastlane ios test` e `./bin/fastlane mac test`
      rodam os mesmos 25 testes com sucesso; `./bin/fastlane ios bump_build` incrementa a
      versão em `project.yml` e regenera o projeto corretamente

**Pendente** (só o usuário pode fazer — ver `fastlane/README-SETUP.md`):
- [ ] Conta Apple Developer Program configurada com App ID + capabilities (mesmo pendente do
      T002)
- [ ] App Store Connect API key (`fastlane/.env` + `.p8`, nenhum dos dois commitado)
- [ ] Assinatura de código (Xcode automático ou `match`) — sem isso, `build_release`/`beta`/
      `release` falham na etapa de build assinado, de propósito

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente
- [Story] mapeia a tarefa à história de usuário correspondente para rastreabilidade
- Toda tarefa de View cita explicitamente sua dependência de T012/T013 (Theme/Assets, gerados a
  partir de `design/design-tokens.md`)
- **Regra de Liquid Glass** (research.md #10): toda `View` de nível de aba usa `TabView` +
  `NavigationStack` + `.toolbar` nativos para herdar o vidro automaticamente na tab bar e no
  toolbar — nenhuma tarefa deve construir chrome de navegação customizado. Botões e cards de
  conteúdo (ex.: "Blindar meu iPhone", "Testar de novo", "Recarregar regras") NÃO usam
  `.glassEffect`; ficam como botões normais/prominentes, seguindo a diretriz da Apple de que
  glass é só para a camada de navegação.
- Zero dependências de terceiros (Constitution Princípio II) — não há biblioteca para manter
  atualizada. O que precisa ficar sempre na versão mais recente é a toolchain: Xcode/Swift/SDK
  usados no build (T001) devem ser os mais atuais disponíveis no momento de cada build, não uma
  versão fixada neste documento.
- Verificar que os testes falham antes de implementar
- Parar em cada checkpoint para validar a história isoladamente em dispositivo físico
- Evitar: tarefas vagas, conflitos de mesmo arquivo, dependências entre histórias que quebrem a
  independência
