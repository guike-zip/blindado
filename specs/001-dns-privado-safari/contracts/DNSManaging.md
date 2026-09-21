# Contract: DNSManaging

Abstrai `NEDNSSettingsManager` para permitir mock em Previews/testes (Constitution
Princípio V — a API real não funciona no simulador).

```swift
protocol DNSManaging {
    /// Estado real atual, recalculado a partir do sistema — nunca cacheado.
    func currentState() async -> ProtectionState

    /// Instala (mas não ativa) o perfil de DNS para o nível informado.
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
- `install` DEVE ser idempotente ao trocar de nível sem exigir nova ativação manual (FR-008).
- `validateCustomServer` DEVE rejeitar URLs não-HTTPS ou inacessíveis antes de qualquer
  chamada a `install` (FR-006).
