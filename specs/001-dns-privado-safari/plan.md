# Implementation Plan: DNS Privado e Bloqueador de Conteúdo para Safari (Blindado)

**Branch**: `001-dns-privado-safari` | **Date**: 2026-09-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-dns-privado-safari/spec.md`

## Summary

App iOS nativo (SwiftUI) que ativa DNS criptografado em todo o sistema via
`NEDNSSettingsManager` (três níveis: Padrão, Família, Personalizado) e oferece um Content
Blocker Extension para o Safari. Arquitetura MVVM enxuta, sem dependências de terceiros, com
todo acesso a APIs de sistema por trás de protocolos mockáveis (a API de DNS não funciona no
simulador). A camada visual consome exclusivamente tokens de um design system externo (Open
Design) via `Theme.swift` + `Assets.xcassets`, gerados a partir de `DESIGN.md` — trabalho de
View fica bloqueado até esse arquivo existir; a lógica de negócio (managers, ViewModels, testes)
não depende dele.

## Technical Context

**Language/Version**: Swift 5.9

**Primary Dependencies**: SwiftUI, NetworkExtension (`NEDNSSettingsManager`,
`NEDNSOverHTTPSSettings`, `NEOnDemandRuleConnect`), SafariServices (`SFContentBlockerManager`),
Foundation (`URLSession`, `UserDefaults`) — todos frameworks nativos da Apple, zero pacotes de
terceiros (Constitution Princípio II).

**Storage**: `UserDefaults` compartilhado via App Group (`group.com.seudominio.blindado`),
acessado com `@AppStorage` — persiste apenas o nível de proteção escolhido e o endereço DNS
personalizado. Nenhum dado do usuário é enviado a servidor próprio (Constitution Princípio I).

**Testing**: XCTest — testes unitários de ViewModels (com mocks dos protocolos de sistema) e de
validação de URL de DNS personalizado.

**Target Platform**: iOS 16+ (iPhone)

**Project Type**: App iOS nativo com dois targets (App + Content Blocker Extension)

**Performance Goals**: ativação percebida em <2min (SC-001); troca de nível refletida em <10s
(SC-003); verificação de cada domínio no teste de proteção não deve travar a UI (execução
assíncrona item a item).

**Constraints**: nenhuma chamada de rede além da consulta DoH do provedor escolhido e do teste
de proteção (Constitution Princípio I); `blockerList.json` deve ficar abaixo de 150.000 regras
(limite do `SFContentBlockerManager`); o estado exibido deve sempre refletir o estado real do
sistema, inclusive quando alterado fora do app (Constitution Princípio IV); textos de UI/loja
não podem sugerir bloqueio de anúncios fora do Safari (Constitution Princípio III); toda
implementação de View está bloqueada até `DESIGN.md` existir na raiz do repositório.

**Scale/Scope**: single-user, sem backend; 4 abas (Início, Safari, Testar, Ajustes), ~9 telas.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Princípio | Avaliação | Status |
|---|---|---|
| I. Privacidade Absoluta | Nenhum SDK de analytics, nenhum servidor próprio; único tráfego de rede é a consulta DoH do provedor escolhido pelo usuário e o teste de proteção (lista fixa de domínios). | PASS |
| II. Apenas Frameworks Nativos da Apple | SwiftUI, NetworkExtension, SafariServices, Foundation apenas; nenhuma dependência via SPM/CocoaPods/Carthage. | PASS |
| III. Conformidade com a App Store | Nenhum texto de UI ou de loja menciona bloqueio de anúncios fora do Safari; posicionamento "DNS privado e bloqueador de conteúdo para Safari" mantido em todo material (ver `app-store-submission.md`). | PASS |
| IV. Honestidade com o Usuário | Estado exibido é recalculado a partir de `NEDNSSettingsManager.isEnabled` e `SFContentBlockerManager` a cada `scenePhase` ativo, nunca fica em cache otimista. | PASS |
| V. Testabilidade | `DNSManaging`, `ContentBlockerManaging` e `ProtectionTesting` são protocolos com mocks; ViewModels dependem das abstrações, não das APIs concretas, permitindo Previews e testes sem dispositivo. | PASS |
| VI. Acessibilidade Obrigatória | Tokens do Open Design incluem tipografia/cores compatíveis com Dynamic Type e modo claro/escuro; rótulos de VoiceOver são parte explícita das tarefas de View. | PASS (a validar em dispositivo por história) |
| VII. Simplicidade | MVVM enxuto; os únicos protocolos introduzidos são os exigidos pelo Princípio V (testabilidade), não abstrações especulativas. `@AppStorage` usado diretamente, sem camada de repositório adicional. | PASS |
| VIII. Entrega Independente por História | Estrutura de código (abaixo) mantém cada história de usuário como fatia vertical (Model + Service + ViewModel + View) testável isoladamente em dispositivo físico. | PASS |

Nenhuma violação identificada — tabela de Complexity Tracking permanece vazia.

## Project Structure

### Documentation (this feature)

```text
specs/001-dns-privado-safari/
├── plan.md                    # Este arquivo
├── research.md                 # Fase 0
├── data-model.md               # Fase 1
├── quickstart.md               # Fase 1 (inclui setup do projeto Xcode e capabilities)
├── app-store-submission.md     # Fase 1 (descrição, palavras-chave, notas de revisão, privacidade)
├── contracts/                  # Fase 1 — protocolos internos mockáveis
│   ├── DNSManaging.md
│   ├── ContentBlockerManaging.md
│   └── ProtectionTesting.md
└── tasks.md                    # Fase 2 (/speckit-tasks — não criado por /speckit-plan)
```

### Source Code (repository root)

```text
Blindado.xcodeproj

Blindado/                                  # Target: app principal
├── App/
│   ├── BlindadoApp.swift
│   └── RootTabView.swift                  # Navegação por 4 abas
├── Theme/
│   ├── Theme.swift                        # Gerado a partir de DESIGN.md (BLOQUEADO até existir)
│   └── Assets.xcassets                    # Cores/tokens do Open Design (BLOQUEADO até existir)
├── Models/
│   ├── ProtectionLevel.swift
│   ├── DNSProvider.swift
│   ├── ProtectionProfile.swift
│   ├── ProtectionState.swift
│   ├── ProtectionTestResult.swift
│   └── ContentBlockerState.swift
├── Services/
│   ├── DNSManaging.swift                  # protocolo (contracts/DNSManaging.md)
│   ├── DNSManager.swift                   # implementação real (NEDNSSettingsManager)
│   ├── MockDNSManager.swift               # para Previews/testes
│   ├── ContentBlockerManaging.swift        # protocolo
│   ├── ContentBlockerManager.swift         # implementação real (SFContentBlockerManager)
│   ├── MockContentBlockerManager.swift
│   ├── ProtectionTesting.swift             # protocolo
│   ├── ProtectionTester.swift              # implementação real (URLSession)
│   └── MockProtectionTester.swift
├── ViewModels/
│   ├── HomeViewModel.swift                 # US1 - Blindar o aparelho
│   ├── ProtectionLevelViewModel.swift      # US2 - Escolher nível
│   ├── ProtectionTestViewModel.swift       # US3 - Testar a proteção
│   ├── SafariViewModel.swift               # US4 - Safari mais limpo
│   └── PrivacyViewModel.swift              # US5 - Transparência
├── Views/
│   ├── HomeView.swift
│   ├── ProtectionLevelView.swift
│   ├── ProtectionTestView.swift
│   ├── SafariView.swift
│   ├── SettingsView.swift
│   └── PrivacyView.swift
└── Resources/
    └── Localizable.xcstrings              # String Catalog (pt-BR base, en preparado)

BlindadoContentBlocker/                    # Target: Content Blocker Extension
├── ContentBlockerRequestHandling.swift
└── blockerList.json                       # <150.000 regras (url-filter, if-domain, css-display-none)

BlindadoTests/                             # Target: testes unitários
├── DNSProviderValidationTests.swift
├── HomeViewModelTests.swift
├── ProtectionLevelViewModelTests.swift
├── ProtectionTestViewModelTests.swift
├── SafariViewModelTests.swift
└── PrivacyViewModelTests.swift
```

**Structure Decision**: App iOS nativo com dois targets no mesmo `.xcodeproj` (App +
`ContentBlocker` Extension) compartilhando o App Group `group.com.seudominio.blindado`. Sem
módulo de API/backend (Constitution Princípio I — sem servidor próprio). Cada história de
usuário mapeia para uma fatia vertical Model → Service (com protocolo + mock) → ViewModel →
View, permitindo build e teste independentes em dispositivo físico por história
(Constitution Princípio VIII). `Theme/` fica isolado para deixar explícito o bloqueio pelo
Open Design/`DESIGN.md`.

## Complexity Tracking

Nenhuma violação da Constitution identificada nesta fase — tabela não aplicável.
