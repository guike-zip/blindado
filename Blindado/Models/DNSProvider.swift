import Foundation

/// Provedor DoH candidato para um `ProtectionLevel` (FR-005, FR-006, FR-019).
///
/// Para `.padrao` e `.familia` existe mais de uma opção no catálogo (research.md #2), para não
/// depender de um único fornecedor terceiro. Para `.personalizado` é construído dinamicamente
/// a partir do endereço informado pelo usuário (ver `DNSProvider.custom(serverURL:)`).
struct DNSProvider: Identifiable, Equatable, Sendable {
    /// Identificador estável do catálogo (ex.: "adguard", "controld"); usado para persistir a
    /// escolha em `ProtectionProfile.providerId`. `nil` para provedores personalizados.
    let id: String?
    let level: ProtectionLevel
    let name: String
    /// Endpoint DoH (`dns-query`). HTTPS obrigatório.
    let serverURL: URL
    /// IPs de fallback (IPv4 + IPv6); vazio para provedores personalizados.
    let servers: [String]
    /// Exibido em Ajustes do sistema como o nome do perfil de DNS instalado.
    let localizedDescription: String
    /// `true` para o único provedor pré-selecionado de cada nível (data-model.md).
    let isDefaultForLevel: Bool

    static func custom(serverURL: URL) -> DNSProvider {
        DNSProvider(
            id: nil,
            level: .personalizado,
            name: serverURL.host ?? serverURL.absoluteString,
            serverURL: serverURL,
            servers: [],
            localizedDescription: "Blindado",
            isDefaultForLevel: false
        )
    }
}

extension DNSProvider {
    /// Catálogo fixo de provedores para `.padrao` e `.familia` (research.md #2).
    ///
    /// Cada nível tem exatamente dois provedores reais e verificados, um marcado como padrão,
    /// para que o usuário leigo nunca precise escolher — e para não depender de um único
    /// serviço (FR-019, SC-007).
    static let catalog: [DNSProvider] = [
        DNSProvider(
            id: "adguard",
            level: .padrao,
            name: "AdGuard DNS",
            serverURL: URL(string: "https://dns.adguard-dns.com/dns-query")!,
            servers: [
                "94.140.14.14", "94.140.15.15",
                "2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff",
            ],
            localizedDescription: "Blindado",
            isDefaultForLevel: true
        ),
        DNSProvider(
            id: "controld",
            level: .padrao,
            name: "Control D",
            serverURL: URL(string: "https://freedns.controld.com/p2")!,
            servers: [
                "76.76.2.2", "76.76.10.2",
                "2606:1a40::2", "2606:1a40:1::2",
            ],
            localizedDescription: "Blindado",
            isDefaultForLevel: false
        ),
        DNSProvider(
            id: "adguard",
            level: .familia,
            name: "AdGuard DNS Family",
            serverURL: URL(string: "https://family.adguard-dns.com/dns-query")!,
            servers: [
                "94.140.14.15", "94.140.15.16",
                "2a10:50c0::bad1:ff", "2a10:50c0::bad2:ff",
            ],
            localizedDescription: "Blindado",
            isDefaultForLevel: true
        ),
        DNSProvider(
            id: "controld",
            level: .familia,
            name: "Control D Family",
            serverURL: URL(string: "https://freedns.controld.com/family")!,
            servers: [
                "76.76.2.4", "76.76.10.4",
                "2606:1a40::4", "2606:1a40:1::4",
            ],
            localizedDescription: "Blindado",
            isDefaultForLevel: false
        ),
    ]

    /// Provedores disponíveis para um nível (FR-019). Vazio para `.personalizado`.
    static func providers(for level: ProtectionLevel) -> [DNSProvider] {
        catalog.filter { $0.level == level }
    }

    /// O provedor pré-selecionado de um nível (FR-019). `nil` para `.personalizado`.
    static func defaultProvider(for level: ProtectionLevel) -> DNSProvider? {
        providers(for: level).first { $0.isDefaultForLevel }
    }
}
