import Foundation
import SafariServices

/// Implementação real de `ContentBlockerManaging` usando `SFContentBlockerManager`. A API só
/// expõe as variantes com completion handler — envolvidas aqui em continuations para expor
/// `async`/`await` ao resto do app.
@MainActor
final class ContentBlockerManager: ContentBlockerManaging {
    /// Identificador do target `BlindadoContentBlocker` (plan.md → Project Structure).
    static let extensionIdentifier = "io.blindado.app.contentblocker"

    private var lastReloadDate: Date?

    func currentState() async -> ContentBlockerState {
        let isEnabled = (try? await Self.getIsEnabled(withIdentifier: Self.extensionIdentifier)) ?? false
        return ContentBlockerState(isEnabled: isEnabled, lastReloadDate: lastReloadDate)
    }

    func reloadRules() async throws {
        try await Self.reload(withIdentifier: Self.extensionIdentifier)
        lastReloadDate = Date()
    }

    /// Extrai só o `Bool` de `SFContentBlockerState` dentro do closure, antes de cruzar para
    /// o `MainActor` — `SFContentBlockerState` não é `Sendable` (Swift 6 strict concurrency).
    private static func getIsEnabled(withIdentifier identifier: String) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: identifier) { state, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: state?.isEnabled ?? false)
                }
            }
        }
    }

    private static func reload(withIdentifier identifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            SFContentBlockerManager.reloadContentBlocker(withIdentifier: identifier) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
