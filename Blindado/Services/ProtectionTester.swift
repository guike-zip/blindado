import Foundation

/// Implementação real de `ProtectionTesting` usando `URLSession` com timeout curto contra a
/// lista fixa de domínios (research.md #5).
@MainActor
final class ProtectionTester: ProtectionTesting {
    private let session: URLSession
    private let timeout: TimeInterval

    init(timeout: TimeInterval = 4) {
        self.timeout = timeout
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: configuration)
    }

    func runTest() -> AsyncStream<DomainCheckResult> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for (domain, categoria) in Self.testDomains {
                    let status = await checkDomain(domain, categoria: categoria)
                    continuation.yield(DomainCheckResult(domain: domain, categoria: categoria, status: status))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func checkDomain(_ domain: String, categoria: DomainCategory) async -> DomainCheckResult.Status {
        guard let url = URL(string: "https://\(domain)/") else {
            return categoria == .comum ? .indeterminado : .bloqueado
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = timeout

        do {
            _ = try await session.data(for: request)
            return .acessivel
        } catch {
            // Falha de resolução/conexão dentro do timeout: domínios de anúncio/rastreador
            // contam como bloqueados; o domínio de controle conta como indeterminado, já que
            // sua falha é o sinal de ausência de rede (FR-010), não de bloqueio.
            return categoria == .comum ? .indeterminado : .bloqueado
        }
    }
}
