import Foundation
import Observation

/// ViewModel da US5 (Transparência). Expõe o provedor de DNS atualmente em uso e o link para
/// a política de privacidade completa (FR-014) — o app não coleta dados, não tem servidor
/// próprio, e as consultas DNS vão para o provedor escolhido.
@MainActor
@Observable
final class PrivacyViewModel {
    /// Documento hospedado externamente (Assumptions da spec); conteúdo fora do escopo do app.
    static let privacyPolicyURL = URL(string: "https://www.seudominio.com/blindado/privacidade")!

    private(set) var currentProviderName: String?

    private let dnsManaging: DNSManaging
    private let loadProfile: () -> ProtectionProfile

    init(dnsManaging: DNSManaging, loadProfile: @escaping () -> ProtectionProfile = { ProtectionProfileStore.load() }) {
        self.dnsManaging = dnsManaging
        self.loadProfile = loadProfile
    }

    func refresh() async {
        currentProviderName = loadProfile().resolvedProvider?.name
    }
}
