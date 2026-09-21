# Tasks: DNS Privado e Bloqueador de Conteúdo para Safari (Blindado)

**Input**: Design documents from `/specs/001-dns-privado-safari/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Incluídos — a Constitution (Princípio V, Testabilidade) exige testes unitários de
ViewModels com mocks para todo acesso a APIs de sistema.

**Organization**: Tarefas agrupadas por história de usuário (spec.md), em ordem de prioridade.

**⚠️ Gate de Design (Open Design)**: `DESIGN.md` e `/design` (nexu-io/open-design) ainda **não
existem** na raiz do repositório nesta data. Toda tarefa marcada **"bloqueada"** abaixo
(criação/edição de qualquer `View` em SwiftUI, incluindo `Theme.swift`/`Assets.xcassets`) NÃO
DEVE começar até esses arquivos existirem. Tarefas de Models, Services, ViewModels e testes NÃO
são afetadas e podem prosseguir normalmente (ver `research.md` #7).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: pode rodar em paralelo (arquivos diferentes, sem dependência pendente)
- **[Story]**: história de usuário à qual a tarefa pertence (US1–US5)
- Caminhos de arquivo são relativos à raiz do repositório

---

## Phase 1: Setup

**Purpose**: Inicialização do projeto Xcode e estrutura de pastas

- [ ] T001 Criar projeto Xcode `Blindado` (App, SwiftUI, bundle `com.seudominio.blindado`) e o
      target `BlindadoContentBlocker` (Content Blocker Extension, bundle
      `com.seudominio.blindado.contentblocker`) per `quickstart.md` seção 2
- [ ] T002 Configurar App Group `group.com.seudominio.blindado` em ambos os targets e o
      entitlement `com.apple.developer.networking.networkextension = ["dns-settings"]` no
      target `Blindado`, per `quickstart.md` seção 3
- [ ] T003 [P] Criar estrutura de pastas `Blindado/{App,Theme,Models,Services,ViewModels,Views,Resources}/`
      per `plan.md` → Project Structure
- [ ] T004 [P] Criar String Catalog `Blindado/Resources/Localizable.xcstrings` com pt-BR como
      idioma base e inglês preparado (research.md #8)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Modelos e serviço de DNS compartilhados por US1 e US2, e o gate de design
compartilhado por todas as Views

**⚠️ CRITICAL**: Nenhuma tarefa de história de usuário pode começar antes desta fase

- [ ] T005 [P] Criar enum `ProtectionLevel` em `Blindado/Models/ProtectionLevel.swift` — casos
      `.padrao`, `.familia`, `.personalizado`; persistido via `@AppStorage` (data-model.md)
- [ ] T006 [P] Criar `DNSProvider` em `Blindado/Models/DNSProvider.swift` — campos `nível`,
      `serverURL` (HTTPS obrigatório), `servers`, `localizedDescription` = "Blindado";
      `.padrao` = `https://dns.adguard-dns.com/dns-query` com servers
      `94.140.14.14, 94.140.15.15, 2a10:50c0::ad1:ff, 2a10:50c0::ad2:ff`; `.familia` =
      `https://family.adguard-dns.com/dns-query` com servers `94.140.14.15, 94.140.15.16`
      (research.md #2)
- [ ] T007 [P] Criar `ProtectionProfile` em `Blindado/Models/ProtectionProfile.swift` — `nível:
      ProtectionLevel` persistido via `@AppStorage` no App Group
      `group.com.seudominio.blindado`; `customServerURL: URL?` presente apenas quando
      `nível == .personalizado`, `nil` caso contrário (data-model.md)
- [ ] T008 [P] Criar enum `ProtectionState` em `Blindado/Models/ProtectionState.swift` — casos
      `.naoConfigurado`, `.instaladoDesativado`, `.blindado`; NUNCA persistido, sempre
      recalculado a partir do sistema (data-model.md, Constitution Princípio IV)
- [ ] T009 Criar protocolo `DNSManaging` em `Blindado/Services/DNSManaging.swift` conforme
      `contracts/DNSManaging.md` (depende de T005–T008)
- [ ] T010 [P] Implementar `DNSManager` (real) em `Blindado/Services/DNSManager.swift` usando
      `NEDNSSettingsManager.shared()`, `NEDNSOverHTTPSSettings`,
      `onDemandRules = [NEOnDemandRuleConnect()]`, `localizedDescription = "Blindado"`,
      `loadFromPreferences`/`saveToPreferences`/`removeFromPreferences` (depende de T009)
- [ ] T011 [P] Implementar `MockDNSManager` em `Blindado/Services/MockDNSManager.swift` com
      estado em memória controlável para Previews e XCTest (depende de T009)
- [ ] T012 ⚠️ **BLOQUEADA até `DESIGN.md` e `/design` existirem na raiz do repositório** —
      gerar `Blindado/Theme/Theme.swift` convertendo os tokens de cor, tipografia,
      espaçamento, raio e sombra do Open Design em constantes/estilos Swift (research.md #7).
      Todas as tarefas de View desta lista dependem desta tarefa.
- [ ] T013 ⚠️ **BLOQUEADA (mesma condição de T012)** — gerar
      `Blindado/Theme/Assets.xcassets` com os color sets adaptativos (claro/escuro) do Open
      Design (depende de T012)

**Checkpoint**: Modelos e `DNSManaging` prontos — ViewModels de qualquer história já podem ser
implementados. Views permanecem bloqueadas até T012/T013.

---

## Phase 3: User Story 1 - Blindar o aparelho (Priority: P1) 🎯 MVP

**Goal**: Usuário ativa/remove o DNS criptografado do sistema e sempre vê o estado real
(Blindado / Instalado mas desativado / Não configurado).

**Independent Test**: Em iPhone físico, tocar "Blindar meu iPhone", ativar em Ajustes, voltar
ao app e confirmar mudança automática para "Blindado"; remover e confirmar retorno a "Não
configurado" (quickstart.md seção 5, US1).

### Tests for User Story 1

- [ ] T014 [P] [US1] Teste unitário de `HomeViewModel` (transições
      naoConfigurado→instaladoDesativado→blindado→naoConfigurado, e o tratamento do erro de
      conflito quando outra configuração de DNS/VPN de terceiros já está ativa — FR-017,
      usando `MockDNSManager`) em `BlindadoTests/HomeViewModelTests.swift`

### Implementation for User Story 1

- [ ] T015 [US1] Implementar `HomeViewModel` em `Blindado/ViewModels/HomeViewModel.swift` —
      expõe `ProtectionState` atual (via `DNSManaging.currentState()`), ações `blindar()`,
      `remover()` e `abrirAjustesDoSistema()` (via `UIApplication.openSettingsURLString`),
      recalcula o estado ao voltar ao primeiro plano (`scenePhase`, FR-001, FR-003), e trata o
      erro de conflito lançado por `DNSManaging.install()` quando outra configuração de DNS/VPN
      de terceiros já está ativa, expondo um aviso orientando o usuário a resolvê-lo antes de
      blindar o aparelho (FR-017) (depende de T009, T014)
- [ ] T016 [US1] Criar `RootTabView` em `Blindado/Views/RootTabView.swift` — navegação por 4
      abas (Início→`HomeView`, Safari/Testar/Ajustes→placeholders temporários a serem
      substituídos pelas histórias US3/US4/US5), usando os tokens de `Theme.swift`
      **(bloqueada até T012, T013)** (depende de T015)
- [ ] T017 [US1] Criar `HomeView` em `Blindado/Views/HomeView.swift` — escudo grande com os 3
      estados visuais, botão "Blindar meu iPhone", instruções passo a passo
      (Ajustes > Geral > Gestão de VPN e Dispositivo > DNS > Blindado), botão de remover, e a
      exibição do aviso de conflito de DNS/VPN de terceiros (FR-017) exposto pelo ViewModel,
      usando somente tokens de `Theme.swift` **(bloqueada até T012, T013)** (depende de T015)

**Checkpoint**: US1 completa e testável isoladamente em dispositivo físico (MVP).

---

## Phase 4: User Story 2 - Escolher o nível de proteção (Priority: P1)

**Goal**: Usuário escolhe entre Padrão, Família ou Personalizado (com validação de URL), e a
escolha persiste e é reaplicada sem nova ativação manual.

**Independent Test**: Com a proteção ativa, trocar entre os 3 níveis e confirmar persistência;
testar URL personalizada inválida e válida (quickstart.md seção 5, US2).

### Tests for User Story 2

- [ ] T018 [P] [US2] Teste unitário de `ProtectionLevelViewModel` (troca de nível, rejeição de
      URL não-HTTPS/inacessível, persistência) usando `MockDNSManager` em
      `BlindadoTests/ProtectionLevelViewModelTests.swift`

### Implementation for User Story 2

- [ ] T019 [US2] Implementar `ProtectionLevelViewModel` em
      `Blindado/ViewModels/ProtectionLevelViewModel.swift` — seleciona nível, valida servidor
      personalizado via `DNSManaging.validateCustomServer` (FR-006), persiste
      `ProtectionProfile` e reaplica via `DNSManaging.install` (FR-008) (depende de T009, T018)
- [ ] T020 [US2] Criar `ProtectionLevelView` em `Blindado/Views/ProtectionLevelView.swift` —
      seleção dos 3 níveis, campo de URL personalizada, mensagens de erro de validação, usando
      tokens de `Theme.swift` **(bloqueada até T012, T013)** (depende de T019)
- [ ] T021 [US2] Conectar navegação de `HomeView` para `ProtectionLevelView`
      (`Blindado/Views/HomeView.swift`) **(bloqueada até T012, T013)** (depende de T017, T020)

**Checkpoint**: US1 e US2 funcionam de forma independente.

---

## Phase 5: User Story 3 - Testar a proteção (Priority: P2)

**Goal**: Usuário roda um teste item a item contra domínios conhecidos e vê um resultado geral
claro, incluindo o caso "indeterminado" sem rede.

**Independent Test**: Rodar o teste com proteção ativa, desativada, e em modo avião — conferir
os 3 resultados distintos (quickstart.md seção 5, US3).

### Tests for User Story 3

- [ ] T022 [P] [US3] Teste unitário de `ProtectionTestViewModel` (casos protegido, parcial,
      desprotegido, indeterminado) usando `MockProtectionTester` em
      `BlindadoTests/ProtectionTestViewModelTests.swift` (depende de T023–T026; pode ser
      escrito antes, como TDD, mas só compila/roda depois do Mock existir)

### Implementation for User Story 3

- [ ] T023 [P] [US3] Criar `ProtectionTestResult` e `DomainCheckResult` em
      `Blindado/Models/ProtectionTestResult.swift` com as regras de derivação de
      `statusGeral` (.protegido/.parcial/.desprotegido/.indeterminado) exatamente como
      descritas em `data-model.md` (FR-010)
- [ ] T024 [US3] Criar protocolo `ProtectionTesting` em `Blindado/Services/ProtectionTesting.swift`
      conforme `contracts/ProtectionTesting.md` (depende de T023)
- [ ] T025 [P] [US3] Implementar `ProtectionTester` (real) em
      `Blindado/Services/ProtectionTester.swift` — `URLSession` com timeout curto contra a
      lista fixa de domínios; falha de resolução conta como bloqueado; ausência de rede produz
      `.indeterminado` (depende de T024)
- [ ] T026 [P] [US3] Implementar `MockProtectionTester` em
      `Blindado/Services/MockProtectionTester.swift` com sequência de resultados pré-definida
      (depende de T024)
- [ ] T027 [US3] Implementar `ProtectionTestViewModel` em
      `Blindado/ViewModels/ProtectionTestViewModel.swift` — consome `AsyncStream` de
      `ProtectionTesting.runTest()`, expõe resultados item a item sem travar a UI (depende de
      T022, T024, T026)
- [ ] T028 [US3] Criar `ProtectionTestView` em `Blindado/Views/ProtectionTestView.swift` —
      lista de domínios com status individual e resultado geral, usando tokens de
      `Theme.swift` **(bloqueada até T012, T013)** (depende de T027)
- [ ] T029 [US3] Substituir o placeholder da aba "Testar" em `RootTabView` por
      `ProtectionTestView` (`Blindado/Views/RootTabView.swift`) **(bloqueada até T012, T013)**
      (depende de T016, T028)

**Checkpoint**: US1, US2 e US3 funcionam de forma independente.

---

## Phase 6: User Story 4 - Safari mais limpo (Priority: P3)

**Goal**: Usuário vê se o bloqueador de conteúdo do Safari está habilitado, recarrega as regras
e é ensinado a habilitá-lo.

**Independent Test**: Com o bloqueador desabilitado/habilitado nos Ajustes do Safari, conferir
que a aba Safari reflete o estado real e que "Recarregar regras" confirma conclusão
(quickstart.md seção 5, US4).

### Tests for User Story 4

- [ ] T030 [P] [US4] Teste unitário de `SafariViewModel` (estados habilitado/desabilitado,
      recarga) usando `MockContentBlockerManager` em `BlindadoTests/SafariViewModelTests.swift`
      (depende de T032, T034; pode ser escrito antes, como TDD, mas só compila/roda depois do
      Mock existir)

### Implementation for User Story 4

- [ ] T031 [P] [US4] Criar `ContentBlockerState` em
      `Blindado/Models/ContentBlockerState.swift` — `isEnabled: Bool`,
      `lastReloadDate: Date?` (data-model.md)
- [ ] T032 [US4] Criar protocolo `ContentBlockerManaging` em
      `Blindado/Services/ContentBlockerManaging.swift` conforme
      `contracts/ContentBlockerManaging.md` (depende de T031)
- [ ] T033 [P] [US4] Implementar `ContentBlockerManager` (real) em
      `Blindado/Services/ContentBlockerManager.swift` usando
      `SFContentBlockerManager.getStateOfContentBlocker` e
      `SFContentBlockerManager.reloadContentBlocker(withIdentifier:)` com identificador
      `com.seudominio.blindado.contentblocker` (depende de T032)
- [ ] T034 [P] [US4] Implementar `MockContentBlockerManager` em
      `Blindado/Services/MockContentBlockerManager.swift` (depende de T032)
- [ ] T035 [P] [US4] Criar `ContentBlockerRequestHandling.swift` no target
      `BlindadoContentBlocker/`
- [ ] T036 [P] [US4] Criar `blockerList.json` inicial no target `BlindadoContentBlocker/` —
      regras `url-filter`/`if-domain`/`css-display-none`, abaixo de 150.000 regras
- [ ] T037 [US4] Implementar `SafariViewModel` em `Blindado/ViewModels/SafariViewModel.swift`
      — estado atual, `recarregarRegras()`, instruções para habilitar (depende de T030, T032,
      T034)
- [ ] T038 [US4] Criar `SafariView` em `Blindado/Views/SafariView.swift` — estado do
      bloqueador, botão "Recarregar regras", instruções, usando tokens de `Theme.swift`
      **(bloqueada até T012, T013)** (depende de T037)
- [ ] T039 [US4] Substituir o placeholder da aba "Safari" em `RootTabView` por `SafariView`
      (`Blindado/Views/RootTabView.swift`) **(bloqueada até T012, T013)** (depende de T016,
      T038)

**Checkpoint**: US1–US4 funcionam de forma independente.

---

## Phase 7: User Story 5 - Transparência (Priority: P3)

**Goal**: Usuário entende, a partir do app, que nenhum dado é coletado e para onde as consultas
DNS são enviadas, com link para a política de privacidade completa.

**Independent Test**: Acessar Ajustes → Privacidade e conferir que o texto é consistente com o
comportamento real; abrir o link da política de privacidade (quickstart.md seção 5, US5).

### Tests for User Story 5

- [ ] T040 [P] [US5] Teste unitário de `PrivacyViewModel` (texto reflete o provedor DNS atual)
      usando `MockDNSManager` em `BlindadoTests/PrivacyViewModelTests.swift`

### Implementation for User Story 5

- [ ] T041 [US5] Implementar `PrivacyViewModel` em `Blindado/ViewModels/PrivacyViewModel.swift`
      — lê o provedor/estado atual via `DNSManaging`, expõe texto de privacidade e URL da
      política de privacidade (FR-014) (depende de T009, T040)
- [ ] T042 [US5] Criar `PrivacyView` em `Blindado/Views/PrivacyView.swift` — texto de
      privacidade e link, usando tokens de `Theme.swift` **(bloqueada até T012, T013)**
      (depende de T041)
- [ ] T043 [US5] Criar `SettingsView` em `Blindado/Views/SettingsView.swift` com entrada
      "Privacidade" navegando para `PrivacyView`, usando tokens de `Theme.swift`
      **(bloqueada até T012, T013)** (depende de T042)
- [ ] T044 [US5] Substituir o placeholder da aba "Ajustes" em `RootTabView` por `SettingsView`
      (`Blindado/Views/RootTabView.swift`) **(bloqueada até T012, T013)** (depende de T016,
      T043)

**Checkpoint**: Todas as 5 histórias de usuário funcionam de forma independente.

---

## Phase 8: Polish & Cross-Cutting Concerns

- [ ] T045 [P] Adicionar rótulos de VoiceOver e validar Dynamic Type em todas as Views
      (Constitution Princípio VI) — após T016–T044
- [ ] T046 [P] Revisar todos os textos de UI e o texto de `app-store-submission.md` contra a
      Constitution Princípio III (nenhuma menção a bloqueio de anúncios fora do Safari)
- [ ] T047 Rodar `quickstart.md` seção 5 (validação em dispositivo físico) para as 5 histórias
      de usuário antes de considerar a feature completa
- [ ] T048 [P] Preencher e validar o checklist final de `app-store-submission.md` antes do
      envio à App Store

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: sem dependências
- **Foundational (Phase 2)**: depende do Setup — bloqueia todas as histórias; T012/T013
  (Theme/Assets) especificamente bloqueiam apenas as tarefas de **View** de todas as histórias,
  não os Models/Services/ViewModels/testes
- **User Stories (Phase 3–7)**: dependem do Foundational (Models/`DNSManaging`); tarefas de
  ViewModel podem prosseguir sem T012/T013; tarefas de View exigem T012/T013 concluídas
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
  estiver pronto — **sem esperar DESIGN.md**
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
2. Completar Foundational — Models + `DNSManaging` (T005–T011); T012/T013 (Theme) só quando
   `DESIGN.md` existir
3. Completar US1 (Phase 3) — ViewModel pode ser feito e testado antes do Theme existir; Views
   (T016, T017) esperam T012/T013
4. **PARAR e VALIDAR**: testar US1 isoladamente em dispositivo físico (quickstart.md)

### Estratégia recomendada dado o bloqueio de Design

Enquanto `DESIGN.md` não existe: implementar e testar Models, Services (reais + mocks) e
ViewModels de **todas** as 5 histórias (T005–T011, T014–T015, T018–T019, T022–T027, T030–T037,
T040–T041) — nenhuma delas depende do Open Design. Assim que `DESIGN.md`/`​/design` existirem:
completar T012–T013 e então liberar, em ordem de prioridade, todas as tarefas de View marcadas
"bloqueada" (T016, T017, T020, T021, T028, T029, T038, T039, T042, T043, T044) e a Phase 8.

### Incremental Delivery

1. Setup + Foundational (lógica) → base pronta
2. US1 (lógica) → US2 (lógica) → US3 (lógica) → US4 (lógica) → US5 (lógica) — todas testáveis
   via ViewModel + mocks, sem UI
3. Ao receber `DESIGN.md`: Theme/Assets (T012–T013) → Views de US1 → US2 → US3 → US4 → US5, na
   ordem de prioridade, cada uma validada em dispositivo físico antes da próxima

---

## Notes

- [P] = arquivos diferentes, sem dependência pendente
- [Story] mapeia a tarefa à história de usuário correspondente para rastreabilidade
- Toda tarefa de View cita explicitamente sua dependência de T012/T013 (gate do Open Design)
- Verificar que os testes falham antes de implementar
- Parar em cada checkpoint para validar a história isoladamente em dispositivo físico
- Evitar: tarefas vagas, conflitos de mesmo arquivo, dependências entre histórias que quebrem a
  independência
