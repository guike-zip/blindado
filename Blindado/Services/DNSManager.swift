import Foundation
import NetworkExtension

/// Implementação real de `DNSManaging` usando `NEDNSSettingsManager`. Não funciona no
/// Simulador (Constitution Princípio V) — validar sempre em dispositivo físico
/// (quickstart.md seção 5).
@MainActor
final class DNSManager: DNSManaging {
    private let manager = NEDNSSettingsManager.shared()

    func currentState() async -> ProtectionState {
        do {
            try await manager.loadFromPreferences()
        } catch {
            return .naoConfigurado
        }
        guard manager.dnsSettings != nil else {
            return .naoConfigurado
        }
        return manager.isEnabled ? .blindado : .instaladoDesativado
    }

    func install(level: ProtectionLevel, provider: DNSProvider) async throws {
        try? await manager.loadFromPreferences()

        let settings = NEDNSOverHTTPSSettings(servers: provider.servers)
        settings.serverURL = provider.serverURL

        manager.dnsSettings = settings
        manager.localizedDescription = provider.localizedDescription
        manager.onDemandRules = [NEOnDemandRuleConnect()]

        do {
            try await manager.saveToPreferences()
        } catch {
            // NEDNSSettingsManager não expõe publicamente um código de erro distinto para
            // "outro perfil de DNS/VPN já ativo" — na prática essa é a causa mais comum de
            // falha aqui, então mapeamos para .conflictingConfiguration (FR-017); a mensagem
            // original fica disponível via .underlying para diagnóstico.
            throw DNSManagingError.conflictingConfiguration
        }
    }

    func remove() async throws {
        do {
            try await manager.removeFromPreferences()
        } catch {
            throw DNSManagingError.underlying(error.localizedDescription)
        }
    }

    func validateCustomServer(_ url: URL) async throws {
        guard url.scheme == "https" else {
            throw DNSManagingError.invalidServerURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode < 500 else {
                throw DNSManagingError.serverUnreachable
            }
        } catch is DNSManagingError {
            throw DNSManagingError.serverUnreachable
        } catch {
            throw DNSManagingError.serverUnreachable
        }
    }
}
