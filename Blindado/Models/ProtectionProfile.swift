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
    static let appGroupID = "group.io.blindado.app"

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

/// Ponto único de acesso a `ProtectionProfile` injetado nos ViewModels (`HomeViewModel`,
/// `ProtectionLevelViewModel`, `PrivacyViewModel`), em vez de cada um chamar
/// `ProtectionProfileStore` direto com os parâmetros-padrão.
///
/// Existe especificamente para isolar testes do `UserDefaults` real do App Group — sem isso,
/// um teste que salva um perfil escreve no mesmo arquivo que o app usaria em produção (foi
/// exatamente o que aconteceu ao rodar os testes antes de existir esta injeção: o Simulador
/// mostrou "Personalizado" na primeira abertura porque um teste anterior tinha escrito ali).
struct ProtectionProfileAccess {
    var load: () -> ProtectionProfile
    var save: (ProtectionProfile) -> Void

    @MainActor
    static let live = ProtectionProfileAccess(
        load: { ProtectionProfileStore.load() },
        save: { ProtectionProfileStore.save($0) }
    )

    /// Acesso em memória para Previews e testes — nunca toca em `UserDefaults`.
    @MainActor
    static func inMemory(initial: ProtectionProfile = .default) -> ProtectionProfileAccess {
        final class Box {
            var profile: ProtectionProfile
            init(_ profile: ProtectionProfile) { self.profile = profile }
        }
        let box = Box(initial)
        return ProtectionProfileAccess(
            load: { box.profile },
            save: { box.profile = $0 }
        )
    }
}
