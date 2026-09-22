# Quickstart: DNS Privado e Bloqueador de Conteúdo para Safari (Blindado)

Guia para criar o projeto Xcode, habilitar as capabilities necessárias e validar cada história
de usuário em dispositivo físico (as APIs de DNS e Content Blocker não funcionam de forma
confiável no simulador — Constitution Princípio V exige mocks para Previews/testes, mas a
validação final de cada história é em hardware real, Constitution Princípio VIII).

## 1. Pré-requisitos

- **Xcode mais recente disponível** (mínimo absoluto: Xcode 26, necessário para compilar com o
  SDK do iOS 26 e obter Liquid Glass nativo em `TabView`/`NavigationStack`/toolbars —
  research.md #10). Sem dependências de terceiros para fixar versão, use sempre a toolchain
  mais atual no momento do build.
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) — gera
  `Blindado.xcodeproj` a partir de `project.yml`, em vez de montar o projeto na mão.
- Conta de desenvolvedor Apple (paga, necessária para `Network Extension` entitlement e App
  Groups em dispositivo físico).
- iPhone físico com **iOS 26+** para testes de DNS/Content Blocker e para ver o Liquid Glass
  real (o Simulador renderiza glass, mas a validação final de UI ainda é em hardware,
  Constitution Princípio VIII).

## 2. Gerar o projeto Xcode

O projeto **já está descrito** em `project.yml` na raiz do repositório (dois targets: `Blindado`
e `BlindadoContentBlocker`, App Group, entitlement de Network Extension, deployment target
iOS 26.0). Para (re)gerar `Blindado.xcodeproj` a partir dele — necessário sempre que um arquivo
novo for adicionado a `Blindado/`, `BlindadoContentBlocker/` ou `BlindadoTests/`:

```bash
xcodegen generate
```

Para validar sem abrir o Xcode (o que este projeto já faz a cada mudança relevante):

```bash
xcodebuild -project Blindado.xcodeproj -scheme Blindado \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build test
```

`CODE_SIGNING_ALLOWED=NO` só serve para compilar/testar sem uma conta de desenvolvedor
configurada — build para dispositivo físico exige assinatura de verdade (seção 3).

## 3. Capabilities e entitlements

Feito em 2026-09-22 no portal da Apple (developer.apple.com → Certificates, Identifiers &
Profiles): App IDs `io.blindado.app` e `io.blindado.app.contentblocker` registrados, ambos com
a capability **App Groups** habilitada e associados ao App Group `group.io.blindado.app`
(criado nesta mesma sessão); `io.blindado.app` também com **Network Extensions** habilitada —
self-service no portal atual, sem aviso de aprovação pendente.

Falta só, no Xcode (target → Signing & Capabilities), depois de `xcodegen generate`:

1. Selecionar o Team (`SEU_TEAM_ID`) em cada um dos 4 targets (`Blindado`, `BlindadoContentBlocker`,
   `BlindadoMac`, `BlindadoMacContentBlocker`) com "Automatically manage signing" ligado — o
   Xcode gera os provisioning profiles a partir das capabilities já configuradas no portal.
2. Verificar que o provisioning profile de cada target inclui as capabilities acima antes de
   rodar em dispositivo.

## 4. Estrutura de código

Ver `plan.md` → Project Structure para o layout completo de pastas/arquivos por target.

## 5. Validação por história de usuário (dispositivo físico)

Rodar cada validação isoladamente, na ordem de prioridade (Constitution Princípio VIII):

### US1 — Blindar o aparelho (P1)
1. Instalar o app em um iPhone físico (build de Debug assinado).
2. Abrir o app → confirmar escudo em "Não configurado".
3. Tocar "Blindar meu iPhone" → confirmar app abre Ajustes na tela correta.
4. Ativar manualmente em Ajustes → voltar ao app → confirmar escudo muda para "Blindado" sem
   ação adicional.
5. Remover a proteção pelo app → confirmar escudo volta a "Não configurado" e o perfil some de
   Ajustes.
6. **Aceita** quando os 4 estados batem com `ProtectionState` (`data-model.md`) em cada passo.

### US2 — Escolher o nível de proteção (P1)
1. Com a proteção ativa, trocar entre Padrão/Família/Personalizado.
2. Em Personalizado, testar uma URL inválida (não-HTTPS) → confirmar rejeição com mensagem
   clara, sem salvar.
3. Testar uma URL DoH válida e alcançável → confirmar salvamento e reaplicação sem nova
   ativação manual em Ajustes.
4. Fechar e reabrir o app → confirmar que o nível escolhido persiste.

### US3 — Testar a proteção (P2)
1. Com a proteção ativa, rodar o teste → confirmar itens de anúncio/rastreador como
   "bloqueado" e o domínio comum como "acessível"; resultado geral "Protegido".
2. Desativar a proteção → rodar o teste novamente → confirmar todos os itens como "acessível" e
   resultado geral "Desprotegido".
3. Rodar o teste em modo avião → confirmar resultado "Indeterminado" (nunca "Protegido" nem
   "Desprotegido" — FR-010).

### US4 — Safari mais limpo (P3)
1. Com o content blocker desabilitado em Ajustes do Safari, abrir a aba Safari no app →
   confirmar instrução para habilitar.
2. Habilitar em Ajustes → voltar ao app → confirmar estado atualizado.
3. Tocar "Recarregar regras" → confirmar confirmação visível de conclusão.

### US5 — Transparência (P3)
1. Abrir Ajustes → Privacidade → confirmar texto consistente com o comportamento real (nenhum
   dado coletado, provedor DNS atual nomeado).
2. Tocar no link da política de privacidade → confirmar abertura do conteúdo completo.

## 6. Pipeline de design

`DESIGN.md` e `/design` já existem (gerados via Open Design em 2026-09-21).

1. Abrir [`design/blindado-ios-prototype.html`](../../design/blindado-ios-prototype.html) no
   navegador para referência visual das 12 telas.
2. Extrair os tokens de [`design/design-tokens.md`](../../design/design-tokens.md) (cores,
   tipografia, espaçamentos, raios, sombras) para `Theme.swift` e `Assets.xcassets` (T012/T013
   em `tasks.md`).
3. Somente então iniciar/retomar as tarefas de `Views/` em `tasks.md`.

## 7. Testes automatizados

Via `xcodebuild` direto:

```bash
xcodebuild -project Blindado.xcodeproj -scheme Blindado \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO build test
```

Ou via [Fastlane](https://docs.fastlane.tools/) (`bundle install` uma vez, depois sempre pelo
wrapper `bin/fastlane`, nunca `fastlane` direto — ver research.md #13 sobre o porquê):

```bash
./bin/fastlane ios test   # ou: ./bin/fastlane mac test
```

Cobre apenas ViewModels e validação de URL (via mocks) — não substitui a validação em
dispositivo físico da seção 5, já que `NEDNSSettingsManager` e `SFContentBlockerManager` não
funcionam no simulador.

## 8. Deploy (TestFlight / App Store)

Via Fastlane — `./bin/fastlane ios beta` (TestFlight) e `./bin/fastlane ios release` (App
Store Connect, sem submeter para revisão automaticamente). **Não vão funcionar até você
configurar conta de desenvolvedor Apple + assinatura de código + API key** — passo a passo em
[`fastlane/README-SETUP.md`](../../fastlane/README-SETUP.md). `./bin/fastlane lanes` lista
todas as lanes disponíveis.
