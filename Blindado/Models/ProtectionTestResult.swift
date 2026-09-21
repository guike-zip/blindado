import Foundation

/// Categoria de um domínio testado — define a interpretação do resultado (data-model.md).
enum DomainCategory: Sendable {
    /// Domínio de anúncio/rastreador conhecido: deve ser bloqueado quando a proteção está ativa.
    case anuncioRastreador
    /// Domínio de controle/comum: deve continuar acessível mesmo com a proteção ativa — é o
    /// que separa "desprotegido" de "sem rede" (Edge Case da spec).
    case comum
}

/// Resultado individual da checagem de um domínio (US3).
struct DomainCheckResult: Identifiable, Equatable, Sendable {
    enum Status: Equatable, Sendable {
        case bloqueado
        case acessivel
        case indeterminado
    }

    var id: String { domain }
    let domain: String
    let categoria: DomainCategory
    var status: Status
}

/// Resultado geral de uma execução do teste de proteção (Key Entity da spec, US3).
enum OverallProtectionStatus: Equatable, Sendable {
    case protegido
    case parcial
    case desprotegido
    case indeterminado
}

/// Resultado de uma execução do teste de proteção (data-model.md).
struct ProtectionTestResult: Equatable, Sendable {
    var itens: [DomainCheckResult]
    /// Quando o teste foi concluído; exibido em Início ("Verificado hoje, 09:38") e em Testar.
    /// Apenas o resultado mais recente é mantido, não um histórico.
    var testadoEm: Date

    /// Deriva o status geral a partir dos itens (data-model.md, FR-010):
    /// - `.protegido`: todos os domínios de anúncio/rastreador bloqueados **e** o domínio comum
    ///   acessível.
    /// - `.parcial`: pelo menos um domínio de anúncio/rastreador bloqueado, mas não todos.
    /// - `.desprotegido`: nenhum domínio de anúncio/rastreador bloqueado.
    /// - `.indeterminado`: teste não pôde ser concluído (ex.: sem rede) — nunca reporta
    ///   `.protegido`/`.desprotegido` nesse caso.
    var statusGeral: OverallProtectionStatus {
        let trackers = itens.filter { $0.categoria == .anuncioRastreador }
        let controle = itens.first { $0.categoria == .comum }

        guard !trackers.isEmpty, trackers.allSatisfy({ $0.status != .indeterminado }) else {
            return .indeterminado
        }
        if let controle, controle.status == .indeterminado {
            return .indeterminado
        }

        let bloqueados = trackers.filter { $0.status == .bloqueado }.count
        let controleAcessivel = controle?.status == .acessivel

        if bloqueados == trackers.count, controleAcessivel {
            return .protegido
        }
        if bloqueados == 0 {
            return .desprotegido
        }
        return .parcial
    }
}
