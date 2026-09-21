import Foundation
import SafariServices

/// Implementação real de `ContentBlockerManaging` usando `SFContentBlockerManager`. A API só
/// expõe as variantes com completion handler — envolvidas aqui em continuations para expor
/// `async`/`await` ao resto do app.
@MainActor
final class ContentBlockerManager: ContentBlockerManaging {
    /// Identificador do target `BlindadoContentBlocker` (plan.md → Project Structure).
    static let extensionIdentifier = "com.seudominio.blindado.contentblocker"

    private var lastReloadDate: Date?

    func currentState() async -> ContentBlockerState {
        let isEnabled: Bool
        do {
            let state = try await Self.getState(withIdentifier: Self.extensionIdentifier)
            isEnabled = state?.isEnabled ?? false
        } catch {
            isEnabled = false
        }
        return ContentBlockerState(isEnabled: isEnabled, lastReloadDate: lastReloadDate)
    }

    func reloadRules() async throws {
        try await Self.reload(withIdentifier: Self.extensionIdentifier)
        lastReloadDate = Date()
    }

    private static func getState(withIdentifier identifier: String) async throws -> SFContentBlockerState? {
        try await withCheckedThrowingContinuation { continuation in
            SFContentBlockerManager.getStateOfContentBlocker(withIdentifier: identifier) { state, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: state)
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
