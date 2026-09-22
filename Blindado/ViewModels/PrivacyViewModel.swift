import Foundation
import Observation

/// ViewModel da US5 (Transparência). Expõe o provedor de DNS atualmente em uso e o link para
/// a política de privacidade completa (FR-014) — o app não coleta dados, não tem servidor
/// próprio, e as consultas DNS vão para o provedor escolhido.
@MainActor
@Observable
final class PrivacyViewModel {
    /// Documento hospedado externamente (Assumptions da spec); conteúdo fora do escopo do app.
    /// Fonte: design/privacidade.html, publicado via GitHub Pages do próprio repositório.
    static let privacyPolicyURL = URL(string: "https://guike-zip.github.io/blindado/design/privacidade.html")!

    private(set) var currentProviderName: String?

    private let dnsManaging: DNSManaging
    private let profileAccess: ProtectionProfileAccess

    init(dnsManaging: DNSManaging, profileAccess: ProtectionProfileAccess = .live) {
        self.dnsManaging = dnsManaging
        self.profileAccess = profileAccess
    }

    func refresh() async {
        currentProviderName = profileAccess.load().resolvedProvider?.name
    }
}
