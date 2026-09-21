import Foundation

/// Abstrai `SFContentBlockerManager` para permitir mock em Previews/testes. Ver
/// contracts/ContentBlockerManaging.md.
@MainActor
protocol ContentBlockerManaging {
    /// Estado real atual do content blocker no Safari — nunca cacheado.
    func currentState() async -> ContentBlockerState

    /// Solicita recarga das regras (`reloadContentBlocker`); atualiza `lastReloadDate` em
    /// caso de sucesso (FR-012).
    /// - Throws: erro se a recarga falhar.
    func reloadRules() async throws
}
