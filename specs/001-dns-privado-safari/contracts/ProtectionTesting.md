# Contract: ProtectionTesting

Abstrai a verificação de domínios via `URLSession` para permitir mock em Previews/testes.

```swift
protocol ProtectionTesting {
    /// Testa cada domínio da lista fixa e emite resultados incrementalmente
    /// (um DomainCheckResult por vez), terminando com o ProtectionTestResult consolidado.
    /// Falha de resolução/conexão dentro do timeout conta como "bloqueado".
    /// Ausência total de rede deve resultar em status .indeterminado, nunca em
    /// .protegido/.desprotegido (FR-010, Edge Cases da spec).
    func runTest() -> AsyncStream<DomainCheckResult>
}
```

**Implementações**:
- `ProtectionTester`: usa `URLSession` com timeout curto contra a lista fixa de domínios
  (anúncios/rastreadores conhecidos + um domínio comum).
- `MockProtectionTester`: sequência de resultados pré-definida, para Previews e `XCTest`.

**Consumidores**: `ProtectionTestViewModel` (US3).

**Garantias exigidas pela spec**:
- Cada domínio reporta resultado individual assim que verificado, sem travar a UI (Acceptance
  Scenario 3 da US3).
- Resultado geral segue as regras de derivação de `ProtectionTestResult` (`data-model.md`).
