# Quickstart: DNS Privado e Bloqueador de Conteúdo para Safari (Blindado)

Guia para criar o projeto Xcode, habilitar as capabilities necessárias e validar cada história
de usuário em dispositivo físico (as APIs de DNS e Content Blocker não funcionam de forma
confiável no simulador — Constitution Princípio V exige mocks para Previews/testes, mas a
validação final de cada história é em hardware real, Constitution Princípio VIII).

## 1. Pré-requisitos

- Xcode mais recente com suporte a iOS 16+.
- Conta de desenvolvedor Apple (paga, necessária para `Network Extension` entitlement e App
  Groups em dispositivo físico).
- iPhone físico com iOS 16+ para testes de DNS/Content Blocker.

## 2. Criar o projeto no Xcode (manual — não via linha de comando)

1. Xcode → **File → New → Project → iOS → App**.
   - Product Name: `Blindado`
   - Interface: SwiftUI · Language: Swift
   - Bundle Identifier: `com.seudominio.blindado`
2. Adicionar o segundo target: **File → New → Target → Content Blocker Extension**.
   - Product Name: `BlindadoContentBlocker`
   - Bundle Identifier resultante: `com.seudominio.blindado.contentblocker`
3. Salvar o projeto na raiz deste repositório (mesmo diretório deste `specs/`).
4. Rodar `specify init --here --force` (ou equivalente) **depois** de o projeto compilar, para
   que os arquivos gerados pelo Spec Kit entrem numa estrutura que já builda.

## 3. Capabilities e entitlements

No portal da Apple (developer.apple.com → Certificates, Identifiers & Profiles) e no Xcode
(target → Signing & Capabilities):

1. **App Group**: criar `group.com.seudominio.blindado`; adicionar aos dois targets
   (`Blindado` e `BlindadoContentBlocker`).
2. **Network Extension**: adicionar ao target `Blindado`, com o entitlement
   `com.apple.developer.networking.networkextension = ["dns-settings"]`. Esse entitlement
   requer aprovação/associação da Apple ao App ID — solicitar com antecedência caso ainda não
   esteja liberado para a conta de desenvolvedor.
3. Verificar que o provisioning profile de cada target inclui as capabilities acima antes de
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

## 6. Pipeline de design (bloqueado até `DESIGN.md` existir)

1. Confirmar que `DESIGN.md` e `/design` existem na raiz do repositório.
2. Extrair tokens (cores, tipografia, espaçamentos, raios, sombras) para `Theme.swift` e
   `Assets.xcassets`.
3. Somente então iniciar/retomar as tarefas de `Views/` em `tasks.md`.

## 7. Testes automatizados

```bash
xcodebuild test -scheme Blindado -destination 'platform=iOS Simulator,name=iPhone 15'
```

Cobre apenas ViewModels e validação de URL (via mocks) — não substitui a validação em
dispositivo físico da seção 5, já que `NEDNSSettingsManager` e `SFContentBlockerManager` não
funcionam no simulador.
