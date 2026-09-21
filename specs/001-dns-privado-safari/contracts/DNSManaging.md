# Contract: DNSManaging

Abstrai `NEDNSSettingsManager` para permitir mock em Previews/testes (Constitution
Princípio V — a API real não funciona no simulador).

```swift
protocol DNSManaging {
    /// Estado real atual, recalculado a partir do sistema — nunca cacheado.
    func currentState() async -> ProtectionState

    /// Catálogo fixo de provedores DoH suportados para um nível (.padrao/.familia).
    /// Sempre retorna mais de um provedor para esses dois níveis (FR-019); vazio para
    /// .personalizado, cujo DNSProvider é construído a partir do endereço do usuário.
    func availableProviders(for level: ProtectionLevel) -> [DNSProvider]

    /// Instala (mas não ativa) o perfil de DNS para o nível e provedor informados.
    /// Equivale a construir um NEDNSOverHTTPSSettings e chamar saveToPreferences.
    /// - Throws: erro se o salvamento falhar (ex.: outro perfil de DNS/VPN já ativo).
    func install(level: ProtectionLevel, provider: DNSProvider) async throws

    /// Remove o perfil de DNS instalado (removeFromPreferences).
    func remove() async throws

    /// Valida um endereço de servidor DoH personalizado (formato HTTPS + alcançabilidade).
    /// - Throws: erro descritivo se inválido ou inacessível.
    func validateCustomServer(_ url: URL) async throws
}
```

**Implementações**:
- `DNSManager`: usa `NEDNSSettingsManager.shared()` (`NEDNSOverHTTPSSettings`,
  `onDemandRules = [NEOnDemandRuleConnect()]`, `localizedDescription = "Blindado"`).
- `MockDNSManager`: estado em memória controlável, para Previews e `XCTest`.

**Consumidores**: `HomeViewModel` (US1), `ProtectionLevelViewModel` (US2).

**Garantias exigidas pela spec**:
- `currentState()` DEVE refletir mudanças feitas fora do app assim que chamado após o app
  voltar ao primeiro plano (FR-001, FR-003, SC-002).
- `install` DEVE ser idempotente ao trocar de nível ou de provedor sem exigir nova ativação
  manual (FR-008).
- `availableProviders(for:)` DEVE retornar pelo menos 2 provedores para `.padrao` e `.familia`
  (FR-019, SC-007) e exatamente um deles com `éPadrãoDoNível == true`.
- `validateCustomServer` DEVE rejeitar URLs não-HTTPS ou inacessíveis antes de qualquer
  chamada a `install` (FR-006).
