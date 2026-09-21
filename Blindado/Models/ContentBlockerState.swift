import Foundation

/// Estado do bloqueador de conteúdo do Safari (US4) — recalculado a cada visita à aba Safari,
/// nunca cacheado como fonte da verdade (data-model.md).
struct ContentBlockerState: Equatable, Sendable {
    var isEnabled: Bool
    /// Preenchido após `reloadContentBlocker` bem-sucedido; usado apenas para feedback de UI,
    /// não para decisão de estado.
    var lastReloadDate: Date?
}
