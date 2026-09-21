# Contract: ContentBlockerManaging

Abstrai `SFContentBlockerManager` para permitir mock em Previews/testes.

```swift
protocol ContentBlockerManaging {
    /// Estado real atual do content blocker no Safari — nunca cacheado.
    func currentState() async -> ContentBlockerState

    /// Solicita recarga das regras (reloadContentBlocker); atualiza lastReloadDate em caso de sucesso.
    /// - Throws: erro se a recarga falhar.
    func reloadRules() async throws
}
```

**Implementações**:
- `ContentBlockerManager`: usa `SFContentBlockerManager.getStateOfContentBlocker` e
  `SFContentBlockerManager.reloadContentBlocker(withIdentifier:)` com o identificador do target
  `BlindadoContentBlocker` (`io.blindado.app.contentblocker`).
- `MockContentBlockerManager`: estado em memória controlável, para Previews e `XCTest`.

**Consumidores**: `SafariViewModel` (US4).

**Garantias exigidas pela spec**:
- `currentState()` DEVE refletir o estado real dos Ajustes do Safari (FR-011).
- `reloadRules()` DEVE confirmar conclusão ao usuário (FR-012).
