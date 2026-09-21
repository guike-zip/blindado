import Foundation
import Observation

/// ViewModel da US4 (Safari mais limpo). Expõe o estado real do bloqueador de conteúdo e a
/// ação de recarregar as regras (FR-011, FR-012, FR-013).
@MainActor
@Observable
final class SafariViewModel {
    private(set) var state = ContentBlockerState(isEnabled: false, lastReloadDate: nil)
    private(set) var isBusy = false
    private(set) var reloadError: String?

    private let contentBlockerManaging: ContentBlockerManaging

    init(contentBlockerManaging: ContentBlockerManaging) {
        self.contentBlockerManaging = contentBlockerManaging
    }

    func refreshState() async {
        state = await contentBlockerManaging.currentState()
    }

    func recarregarRegras() async {
        reloadError = nil
        isBusy = true
        defer { isBusy = false }

        do {
            try await contentBlockerManaging.reloadRules()
        } catch {
            reloadError = error.localizedDescription
        }
        await refreshState()
    }
}
