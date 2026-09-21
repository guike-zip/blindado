import Foundation
import Observation
#if canImport(UIKit)
import UIKit
#endif

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

    func abrirAjustesDoSafari() {
        #if canImport(UIKit)
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
        #endif
    }
}
