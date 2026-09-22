fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

Roda os testes unitários no Simulador — sem credenciais Apple

### ios build_dev

```sh
[bundle exec] fastlane ios build_dev
```

Build de desenvolvimento sem assinatura — só valida que compila (sem exportar .ipa)

### ios bump_build

```sh
[bundle exec] fastlane ios bump_build
```

Incrementa o build number em project.yml (fonte única de verdade) e regenera o projeto

### ios bump_version

```sh
[bundle exec] fastlane ios bump_version
```

Define a versão (MARKETING_VERSION) em project.yml e regenera o projeto. Uso: bundle exec fastlane ios bump_version version:1.1.0

### ios build_release

```sh
[bundle exec] fastlane ios build_release
```

Build assinado para distribuição (App Store) — exige conta de desenvolvedor configurada

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Sobe um novo build para o TestFlight — exige conta de desenvolvedor + API key (README-SETUP.md)

### ios release

```sh
[bundle exec] fastlane ios release
```

Sobe um build para o App Store Connect, SEM submeter para revisão automaticamente (Constitution Princípio III — revisão manual do texto/screenshots antes de qualquer submissão). Depois de submeter (manualmente, pelo App Store Connect), a publicação é automática assim que a Apple aprovar — automatic_release: true.

----


## Mac

### mac test

```sh
[bundle exec] fastlane mac test
```

Roda os testes unitários no macOS — sem credenciais Apple

### mac build_dev

```sh
[bundle exec] fastlane mac build_dev
```

Build de desenvolvimento sem assinatura — só valida que compila

### mac build_release

```sh
[bundle exec] fastlane mac build_release
```

Build assinado para distribuição (Mac App Store) — exige conta de desenvolvedor configurada

### mac beta

```sh
[bundle exec] fastlane mac beta
```

Sobe um novo build para o TestFlight de macOS — exige conta de desenvolvedor + API key

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
