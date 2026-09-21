import Foundation

/// Erros retornados por `DNSManaging` (FR-006, FR-017).
enum DNSManagingError: LocalizedError, Equatable {
    /// Outra configuração de DNS/VPN de terceiros já está ativa no dispositivo (FR-017).
    case conflictingConfiguration
    /// O endereço informado não usa o esquema HTTPS (FR-006).
    case invalidServerURL
    /// O endereço informado não respondeu à checagem de alcançabilidade (FR-006).
    case serverUnreachable
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .conflictingConfiguration:
            String(
                localized: "dns_error.conflict",
                defaultValue: "Outra configuração de DNS ou VPN já está ativa neste iPhone. Resolva o conflito nos Ajustes antes de blindar o aparelho."
            )
        case .invalidServerURL:
            String(
                localized: "dns_error.invalid_url",
                defaultValue: "O endereço precisa começar com https://."
            )
        case .serverUnreachable:
            String(
                localized: "dns_error.unreachable",
                defaultValue: "Não conseguimos falar com esse servidor. Confira o endereço e tente de novo."
            )
        case .underlying(let message):
            message
        }
    }
}

/// Abstrai `NEDNSSettingsManager` para permitir mock em Previews/testes (Constitution
/// Princípio V — a API real não funciona no simulador). Ver contracts/DNSManaging.md.
@MainActor
protocol DNSManaging {
    /// Estado real atual, recalculado a partir do sistema — nunca cacheado.
    func currentState() async -> ProtectionState

    /// Catálogo fixo de provedores DoH suportados para um nível (.padrao/.familia). Sempre
    /// retorna mais de um provedor para esses dois níveis (FR-019); vazio para .personalizado.
    func availableProviders(for level: ProtectionLevel) -> [DNSProvider]

    /// Instala (mas não ativa) o perfil de DNS para o nível e provedor informados. Equivale a
    /// construir um `NEDNSOverHTTPSSettings` e chamar `saveToPreferences`.
    /// - Throws: `DNSManagingError.conflictingConfiguration` se outro perfil de DNS/VPN já
    ///   estiver ativo (FR-017).
    func install(level: ProtectionLevel, provider: DNSProvider) async throws

    /// Remove o perfil de DNS instalado (`removeFromPreferences`).
    func remove() async throws

    /// Valida um endereço de servidor DoH personalizado (formato HTTPS + alcançabilidade).
    /// - Throws: `DNSManagingError.invalidServerURL` ou `.serverUnreachable` (FR-006).
    func validateCustomServer(_ url: URL) async throws
}

extension DNSManaging {
    /// Catálogo fixo — implementação padrão compartilhada por `DNSManager` e
    /// `MockDNSManager`, já que o catálogo não depende de estado do sistema.
    func availableProviders(for level: ProtectionLevel) -> [DNSProvider] {
        DNSProvider.providers(for: level)
    }
}
