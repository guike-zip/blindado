import Foundation

/// Mock de `DNSManaging` para Previews e XCTest — estado em memória controlável, já que a API
/// real não funciona no Simulador (Constitution Princípio V).
@MainActor
final class MockDNSManager: DNSManaging {
    var state: ProtectionState = .naoConfigurado
    var installedProvider: DNSProvider?

    /// Quando definido, a próxima chamada a `install(level:provider:)` lança esse erro em vez
    /// de instalar — usado para testar o tratamento de conflito (FR-017).
    var installError: DNSManagingError?
    /// Quando definido, `validateCustomServer` lança esse erro.
    var validationError: DNSManagingError?

    func currentState() async -> ProtectionState {
        state
    }

    func install(level: ProtectionLevel, provider: DNSProvider) async throws {
        if let installError {
            throw installError
        }
        installedProvider = provider
        state = .instaladoDesativado
    }

    func remove() async throws {
        installedProvider = nil
        state = .naoConfigurado
    }

    func validateCustomServer(_ url: URL) async throws {
        if let validationError {
            throw validationError
        }
        guard url.scheme == "https" else {
            throw DNSManagingError.invalidServerURL
        }
    }

    /// Simula a ativação manual em Ajustes (fora do controle do app) — usado por testes de
    /// `HomeViewModel` para exercitar a transição `instaladoDesativado → blindado`.
    func simulateUserActivatedInSettings() {
        guard state == .instaladoDesativado else { return }
        state = .blindado
    }
}
