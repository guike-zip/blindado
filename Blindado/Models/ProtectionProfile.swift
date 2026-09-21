import Foundation

/// Configuração de proteção persistida pelo usuário (Key Entity da spec).
///
/// Persistida em `UserDefaults` compartilhado via App Group (plan.md → Storage), não em banco
/// de dados. `providerId == nil` significa "usa o provedor com `isDefaultForLevel == true`"
/// (FR-019) — o usuário leigo nunca precisa definir isso.
struct ProtectionProfile: Equatable, Sendable {
    var level: ProtectionLevel
    var providerId: String?
    /// Presente apenas quando `level == .personalizado`.
    var customServerURL: URL?

    static let `default` = ProtectionProfile(level: .padrao, providerId: nil, customServerURL: nil)

    /// Resolve para um `DNSProvider` concreto: do catálogo (usando `providerId`, ou o padrão
    /// do nível quando `nil`) para Padrão/Família, ou construído a partir de
    /// `customServerURL` para Personalizado.
    var resolvedProvider: DNSProvider? {
        switch level {
        case .padrao, .familia:
            let candidates = DNSProvider.providers(for: level)
            if let providerId, let match = candidates.first(where: { $0.id == providerId }) {
                return match
            }
            return DNSProvider.defaultProvider(for: level)
        case .personalizado:
            guard let customServerURL else { return nil }
            return .custom(serverURL: customServerURL)
        }
    }
}

/// Persistência de `ProtectionProfile` em `UserDefaults` compartilhado via App Group
/// (plan.md → Storage). Não é um protocolo mockável (Constitution Princípio V) porque não
/// encapsula uma API de sistema — testes usam um suite name próprio, sem necessidade de mock.
enum ProtectionProfileStore {
    static let appGroupID = "group.com.seudominio.blindado"

    private enum Key {
        static let level = "protectionProfile.level"
        static let providerId = "protectionProfile.providerId"
        static let customServerURL = "protectionProfile.customServerURL"
    }

    static func load(from defaults: UserDefaults = UserDefaults(suiteName: appGroupID)!) -> ProtectionProfile {
        guard
            let rawLevel = defaults.string(forKey: Key.level),
            let level = ProtectionLevel(rawValue: rawLevel)
        else {
            return .default
        }
        let providerId = defaults.string(forKey: Key.providerId)
        let customServerURL = defaults.string(forKey: Key.customServerURL).flatMap(URL.init(string:))
        return ProtectionProfile(level: level, providerId: providerId, customServerURL: customServerURL)
    }

    static func save(_ profile: ProtectionProfile, to defaults: UserDefaults = UserDefaults(suiteName: appGroupID)!) {
        defaults.set(profile.level.rawValue, forKey: Key.level)
        defaults.set(profile.providerId, forKey: Key.providerId)
        defaults.set(profile.customServerURL?.absoluteString, forKey: Key.customServerURL)
    }
}
