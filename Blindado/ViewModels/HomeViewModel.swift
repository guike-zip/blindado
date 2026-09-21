import Foundation
import Observation

/// ViewModel da US1 (Blindar o aparelho). Expõe o `ProtectionState` real e as ações de
/// ativar/remover a proteção; nunca cacheia estado otimista (Constitution Princípio IV).
@MainActor
@Observable
final class HomeViewModel {
    private(set) var state: ProtectionState = .naoConfigurado
    /// Aviso de conflito exposto quando `DNSManaging.install()` falha porque outra
    /// configuração de DNS/VPN de terceiros já está ativa (FR-017). `nil` quando não há
    /// conflito pendente.
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
            if case .conflictingConfiguration = error {
                conflictWarning = error.errorDescription
            }
        } catch {
            // Erros não mapeados não têm um aviso específico de UI (fora do escopo de FR-017);
            // o estado permanece o que já estava antes da tentativa.
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
