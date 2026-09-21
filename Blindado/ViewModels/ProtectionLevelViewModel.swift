import Foundation
import Observation

/// ViewModel da US2 (Escolher o nível de proteção). Seleciona nível e, dentro de Padrão/
/// Família, o provedor DoH; valida e salva um servidor Personalizado (FR-006); persiste em
/// `ProtectionProfileStore` e reaplica via `DNSManaging.install` sem exigir nova ativação
/// manual em Ajustes (FR-008).
@MainActor
@Observable
final class ProtectionLevelViewModel {
    private(set) var profile: ProtectionProfile
    private(set) var validationError: String?
    private(set) var isBusy = false

    private let dnsManaging: DNSManaging
    private let profileAccess: ProtectionProfileAccess

    init(dnsManaging: DNSManaging, profileAccess: ProtectionProfileAccess = .live, profile: ProtectionProfile? = nil) {
        self.dnsManaging = dnsManaging
        self.profileAccess = profileAccess
        self.profile = profile ?? profileAccess.load()
    }

    /// Provedores disponíveis para o nível atualmente selecionado (FR-019). Vazio para
    /// `.personalizado`.
    var availableProviders: [DNSProvider] {
        dnsManaging.availableProviders(for: profile.level)
    }

    var selectedProvider: DNSProvider? {
        profile.resolvedProvider
    }

    /// Troca o nível de proteção (Padrão/Família/Personalizado) e reaplica imediatamente
    /// quando o nível já resolve para um provedor (Padrão/Família têm um provedor padrão;
    /// Personalizado só reaplica depois de `saveCustomServer` validar o endereço).
    func selectLevel(_ level: ProtectionLevel) async {
        validationError = nil
        var updated = profile
        updated.level = level
        if level != .personalizado {
            updated.providerId = nil
        }
        profile = updated

        guard level != .personalizado, let provider = profile.resolvedProvider else { return }
        await apply(profile: profile, provider: provider)
    }

    /// Troca o provedor dentro do nível Padrão/Família (FR-019) — não exige nova ativação
    /// manual em Ajustes.
    func selectProvider(_ provider: DNSProvider) async {
        guard profile.level == provider.level else { return }
        var updated = profile
        updated.providerId = provider.id
        profile = updated
        await apply(profile: profile, provider: provider)
    }

    /// Valida (FR-006) e salva um endereço de servidor DoH personalizado.
    func saveCustomServer(_ urlString: String) async {
        validationError = nil
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            validationError = DNSManagingError.invalidServerURL.errorDescription
            return
        }

        isBusy = true
        defer { isBusy = false }

        do {
            try await dnsManaging.validateCustomServer(url)
        } catch let error as DNSManagingError {
            validationError = error.errorDescription
            return
        } catch {
            validationError = error.localizedDescription
            return
        }

        var updated = profile
        updated.level = .personalizado
        updated.customServerURL = url
        profile = updated

        guard let provider = profile.resolvedProvider else { return }
        await apply(profile: profile, provider: provider)
    }

    private func apply(profile: ProtectionProfile, provider: DNSProvider) async {
        isBusy = true
        defer { isBusy = false }
        do {
            try await dnsManaging.install(level: profile.level, provider: provider)
            profileAccess.save(profile)
        } catch let error as DNSManagingError {
            validationError = error.errorDescription
        } catch {
            validationError = error.localizedDescription
        }
    }
}
