# Configurar o Fastlane para deploy de verdade

O Fastlane já está funcional para **build e teste local** (`./bin/fastlane ios test`,
`./bin/fastlane mac test`, `./bin/fastlane ios build_dev`, `./bin/fastlane mac build_dev`) —
essas lanes rodam sem nenhuma credencial Apple, do mesmo jeito que `xcodebuild ... 
CODE_SIGNING_ALLOWED=NO` (quickstart.md seção 2).

As lanes `beta` e `release` (TestFlight / App Store Connect) **vão falhar até você fazer os
passos abaixo** — é o comportamento esperado, não um bug. Nenhum deles pode ser feito por mim
(exigem sua conta/senha na Apple).

## 1. Conta de desenvolvedor Apple

Conta paga (Apple Developer Program, US$ 99/ano) com um App ID registrado para
`io.blindado.app` (troque pelo bundle ID real primeiro — ver `plan.md`), com as
capabilities `Network Extension` (`dns-settings`) e `App Groups` habilitadas — o mesmo passo
manual já descrito em `quickstart.md` seção 3.

## 2. App Store Connect API key (recomendado)

Evita 2FA interativo em cada deploy. Em App Store Connect → **Users and Access → Integrations
→ App Store Connect API**:

1. Crie uma chave com papel **App Manager** (ou "Admin" se for gerenciar metadados também).
2. Baixe o arquivo `.p8` **uma vez só** — a Apple não deixa baixar de novo.
3. Copie `fastlane/.env.default` para `fastlane/.env` (já está no `.gitignore`) e preencha:
   - `APP_STORE_CONNECT_API_KEY_KEY_ID` (Key ID mostrado na tabela)
   - `APP_STORE_CONNECT_API_KEY_ISSUER_ID` (Issuer ID, topo da página)
   - `APP_STORE_CONNECT_API_KEY_FILEPATH` (caminho do `.p8` baixado — sugestão:
     `fastlane/AuthKey.p8`, que também já está no `.gitignore`)
4. Preencha `FASTLANE_TEAM_ID` também (Apple Developer Portal → Membership → Team ID).

## 3. Assinatura de código (certificados + perfis de provisionamento)

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

## 5. Screenshots

`release` está com `skip_screenshots: true` porque ainda não existem screenshots reais (só o
roteiro em `app-store-submission.md`). Depois de gerá-los (`fastlane snapshot` ou capturas
manuais em dispositivo/simulador), tire essa flag e aponte `fastlane/Snapfile`/
`fastlane/metadata` para os arquivos.
