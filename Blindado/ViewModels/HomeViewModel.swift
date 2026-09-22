import Foundation
import Observation

/// ViewModel da US1 (Blindar o aparelho). Expõe o `ProtectionState` real e as ações de
/// ativar/remover a proteção; nunca cacheia estado otimista (Constitution Princípio IV).
@MainActor
@Observable
final class HomeViewModel {
    private(set) var state: ProtectionState = .naoConfigurado
    /// Mensagem exposta quando `DNSManaging.install()` falha — conflito de DNS/VPN (FR-017)
    /// ou qualquer outro erro real do sistema. `nil` quando não há erro pendente. O nome
    /// (`conflictWarning`) ficou de um tempo em que só o caso de conflito era mostrado; hoje
    /// cobre qualquer falha, porque mostrar sempre "conflito" mesmo quando não era mascarava
    /// o diagnóstico real (achado em teste de dispositivo físico).
    private(set) var conflictWarning: String?
    private(set) var isBusy = false

    private let dnsManaging: DNSManaging
    private let profileAccess: ProtectionProfileAccess

    init(dnsManaging: DNSManaging, profileAccess: ProtectionProfileAccess = .live) {
        self.dnsManaging = dnsManaging
        self.profileAccess = profileAccess
    }

    /// Recalcula o estado a partir do sistema. Chamado na primeira aparição da tela e sempre
    /// que o app volta ao primeiro plano (`scenePhase == .active`, FR-001, FR-003).
    func refreshState() async {
        state = await dnsManaging.currentState()
    }

    /// Instala o perfil de DNS para o `ProtectionProfile` salvo (nível + provedor escolhidos
    /// em US2, ou os padrões se o usuário nunca configurou nada).
    func blindar() async {
        conflictWarning = nil
        isBusy = true
        defer { isBusy = false }

        let profile = profileAccess.load()
        guard let provider = profile.resolvedProvider else {
            return
        }

        do {
            try await dnsManaging.install(level: profile.level, provider: provider)
        } catch let error as DNSManagingError {
            conflictWarning = error.errorDescription
        } catch {
            conflictWarning = error.localizedDescription
        }
        await refreshState()
    }

    func remover() async {
        isBusy = true
        defer { isBusy = false }
        try? await dnsManaging.remove()
        await refreshState()
    }

    func dismissConflictWarning() {
        conflictWarning = nil
    }
}
