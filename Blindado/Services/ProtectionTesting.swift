import Foundation

/// Abstrai a verificação de domínios via `URLSession` para permitir mock em Previews/testes.
/// Ver contracts/ProtectionTesting.md.
@MainActor
protocol ProtectionTesting {
    /// Testa cada domínio da lista fixa e emite resultados incrementalmente (um
    /// `DomainCheckResult` por vez), sem travar a UI (Acceptance Scenario 3 da US3). Falha de
    /// resolução/conexão dentro do timeout conta como "bloqueado" para domínios de
    /// anúncio/rastreador; ausência total de rede resulta em `.indeterminado` (FR-010).
    func runTest() -> AsyncStream<DomainCheckResult>
}

extension ProtectionTesting {
    /// Lista fixa de domínios testados (tasks.md T025): 5 conhecidos de anúncios/rastreadores
    /// e `apple.com` como domínio de controle/comum — precisa continuar acessível mesmo com a
    /// proteção ativa, para distinguir "desprotegido" de "sem rede".
    static var testDomains: [(domain: String, categoria: DomainCategory)] {
        [
            ("doubleclick.net", .anuncioRastreador),
            ("googleadservices.com", .anuncioRastreador),
            ("google-analytics.com", .anuncioRastreador),
            ("ads.tiktok.com", .anuncioRastreador),
            ("graph.facebook.com", .anuncioRastreador),
            ("apple.com", .comum),
        ]
    }
}
