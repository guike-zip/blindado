import Foundation

/// Mock de `ContentBlockerManaging` para Previews e XCTest — estado em memória controlável.
@MainActor
final class MockContentBlockerManager: ContentBlockerManaging {
    var isEnabled = false
    var lastReloadDate: Date?
    var reloadError: Error?

    func currentState() async -> ContentBlockerState {
        ContentBlockerState(isEnabled: isEnabled, lastReloadDate: lastReloadDate)
    }

    func reloadRules() async throws {
        if let reloadError {
            throw reloadError
        }
        lastReloadDate = Date()
    }
}
