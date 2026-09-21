import Foundation
import Observation

/// ViewModel da US3 (Testar a proteção). Consome o `AsyncStream` de `ProtectionTesting.runTest()`
/// e expõe os resultados item a item, sem travar a UI (Acceptance Scenario 3 da US3).
@MainActor
@Observable
final class ProtectionTestViewModel {
    private(set) var items: [DomainCheckResult] = []
    private(set) var isRunning = false
    private(set) var lastResult: ProtectionTestResult?

    private let tester: ProtectionTesting
    private var currentTask: Task<Void, Never>?

    init(tester: ProtectionTesting) {
        self.tester = tester
    }

    /// Status geral exibido no banner: reflete o último resultado concluído enquanto um novo
    /// teste ainda está rodando, para a tela nunca ficar sem veredito.
    var overallStatus: OverallProtectionStatus? {
        lastResult?.statusGeral
    }

    func runTest() {
        currentTask?.cancel()
        items = []
        isRunning = true

        currentTask = Task {
            for await item in tester.runTest() {
                guard !Task.isCancelled else { return }
                items.append(item)
            }
            guard !Task.isCancelled else { return }
            lastResult = ProtectionTestResult(itens: items, testadoEm: Date())
            isRunning = false
        }
    }
}
