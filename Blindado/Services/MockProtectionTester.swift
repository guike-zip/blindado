import Foundation

/// Mock de `ProtectionTesting` para Previews e XCTest — emite uma sequência de resultados
/// pré-definida em vez de bater na rede.
@MainActor
final class MockProtectionTester: ProtectionTesting {
    enum Scenario {
        /// Todos os domínios de anúncio/rastreador bloqueados, controle acessível.
        case protegido
        /// Alguns domínios de anúncio/rastreador acessíveis, controle acessível.
        case parcial
        /// Todos os domínios acessíveis (nenhum bloqueio), controle acessível.
        case desprotegido
        /// Nenhum domínio responde — sem rede.
        case indeterminado
    }

    var scenario: Scenario = .protegido
    /// Atraso simulado entre cada item, para exercitar o estado "verificando" na UI.
    var delayPerItem: Duration = .zero

    func runTest() -> AsyncStream<DomainCheckResult> {
        let items = resultados(for: scenario)
        return AsyncStream { continuation in
            let task = Task { @MainActor in
                for item in items {
                    if delayPerItem > .zero {
                        try? await Task.sleep(for: delayPerItem)
                    }
                    continuation.yield(item)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func resultados(for scenario: Scenario) -> [DomainCheckResult] {
        Self.testDomains.enumerated().map { index, entry in
            let status: DomainCheckResult.Status
            switch scenario {
            case .protegido:
                status = entry.categoria == .comum ? .acessivel : .bloqueado
            case .parcial:
                if entry.categoria == .comum {
                    status = .acessivel
                } else {
                    status = index.isMultiple(of: 2) ? .bloqueado : .acessivel
                }
            case .desprotegido:
                status = .acessivel
            case .indeterminado:
                status = .indeterminado
            }
            return DomainCheckResult(domain: entry.domain, categoria: entry.categoria, status: status)
        }
    }
}
