# Configurar o Fastlane para deploy de verdade

O Fastlane já está funcional para **build e teste local** (`./bin/fastlane ios test`,
`./bin/fastlane mac test`, `./bin/fastlane ios build_dev`, `./bin/fastlane mac build_dev`) —
essas lanes rodam sem nenhuma credencial Apple, do mesmo jeito que `xcodebuild ... 
CODE_SIGNING_ALLOWED=NO` (quickstart.md seção 2).

As lanes `beta` e `release` (TestFlight / App Store Connect) **vão falhar até o passo 3 abaixo
estar feito** — é o comportamento esperado, não um bug.

## 1. Conta de desenvolvedor Apple — ✅ feito em 2026-09-22

App IDs `io.blindado.app` e `io.blindado.app.contentblocker` registrados no Developer Portal,
com `App Groups` habilitada em ambos (associados a `group.io.blindado.app`) e `Network
Extensions` habilitada em `io.blindado.app`. Team ID: `J55LDMR2HC`.

## 2. App Store Connect API key — ✅ feito

`fastlane/.env` já está preenchido (reaproveitando uma chave existente da conta, papel
Administrador) e `fastlane/AuthKey.p8` já está no lugar certo — ambos fora do git. Validado
rodando `./bin/fastlane ios test`, que autentica sem erro.

## 3. Assinatura de código (certificados + perfis de provisionamento) — pendente, só no Xcode

Sem isso, `build_release`/`beta`/`release` falham na etapa de `build_app` (gym). Duas opções:

- **Xcode Cloud / assinatura automática pelo Xcode** — abra `Blindado.xcodeproj` no Xcode,
  selecione um time em Signing & Capabilities para os 4 targets, deixe "Automatically manage
  signing" ligado. Mais simples para um projeto solo.
- **[`match`](https://docs.fastlane.tools/actions/match/)** — guarda certificados/perfis
  criptografados num repositório git privado à parte, compartilhável entre máquinas/CI. Vale a
  pena se mais de uma pessoa ou uma esteira de CI for fazer deploy. Não configurado aqui de
  propósito — decisão de onde guardar esse repositório é sua.

## 4. Testar antes de gastar um envio de verdade

```bash
./bin/fastlane ios build_dev   # só compila para Simulador, sem exportar nada
./bin/fastlane ios build_release  # build assinado de verdade — primeiro teste real de signing
```

Só depois disso rodar `./bin/fastlane ios beta` (TestFlight) ou `./bin/fastlane ios release`
(App Store Connect, sem submeter para revisão — `submit_for_review: false` no Fastfile, de
propósito: revise o texto/screenshots contra `app-store-submission.md` e a Constitution
Princípio III antes de qualquer submissão manual).

## 5. Screenshots — ✅ feito

Os 7 screenshots reais (roteiro completo de `app-store-submission.md`) já estão em
`fastlane/screenshots/pt-BR/` e `skip_screenshots` já está `false` na lane `release`. Nada a
fazer aqui — só regenerar se a UI mudar (ver seção "Screenshots" de `app-store-submission.md`).
