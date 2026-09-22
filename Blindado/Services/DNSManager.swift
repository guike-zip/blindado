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
        // Antes só usava `try?` aqui (erro descartado em silêncio) — se o load falhasse, o
        // save seguinte falhava por causa disso, e antes essa falha genérica virava sempre
        // "conflito de DNS/VPN" (achado errado, corrigido abaixo). Não silenciar deixa o
        // save já falhar com o erro real em vez de propagar um estado carregado errado.
        try await manager.loadFromPreferences()

        let settings = NEDNSOverHTTPSSettings(servers: provider.servers)
        settings.serverURL = provider.serverURL

        manager.dnsSettings = settings
        manager.localizedDescription = provider.localizedDescription
        manager.onDemandRules = [NEOnDemandRuleConnect()]

        do {
            try await manager.saveToPreferences()
        } catch {
            throw Self.mapSaveError(error)
        }
    }

    /// `NEDNSSettingsManagerError` (o único domínio documentado pela Apple para esta API) não
    /// tem nenhum caso "outro perfil já ativo" — os 4 casos reais são configurationInvalid,
    /// configurationDisabled, configurationStale e configurationCannotBeRemoved. Mapear
    /// incondicionalmente para .conflictingConfiguration (como este código fazia antes) era
    /// uma suposição nunca verificada em hardware real — achado em teste real de dispositivo
    /// (Constitution Princípio VIII). Preserva a mensagem real para qualquer erro não mapeado,
    /// em vez de mostrar um diagnóstico inventado.
    private static func mapSaveError(_ error: Error) -> DNSManagingError {
        let nsError = error as NSError
        if nsError.domain == "NEDNSSettingsManagerErrorDomain" || nsError.domain.contains("NEDNSSettingsManager") {
            switch nsError.code {
            case 2: // NEDNSSettingsManagerErrorConfigurationDisabled
                return .conflictingConfiguration
            default:
                break
            }
        }
        return .underlying(error.localizedDescription)
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
