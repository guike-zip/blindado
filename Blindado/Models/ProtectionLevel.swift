import Foundation

/// Nível de proteção escolhido pelo usuário (FR-005).
///
/// Persistido via `@AppStorage` no App Group; ver `ProtectionProfile`.
enum ProtectionLevel: String, CaseIterable, Codable, Identifiable, Sendable {
    case padrao
    case familia
    case personalizado

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .padrao: String(localized: "protection_level.padrao.name", defaultValue: "Padrão")
        case .familia: String(localized: "protection_level.familia.name", defaultValue: "Família")
        case .personalizado: String(localized: "protection_level.personalizado.name", defaultValue: "Personalizado")
        }
    }

    var summary: String {
        switch self {
        case .padrao:
            String(
                localized: "protection_level.padrao.summary",
                defaultValue: "Bloqueia anúncios, rastreadores e sites de malware conhecidos."
            )
        case .familia:
            String(
                localized: "protection_level.familia.summary",
                defaultValue: "Tudo do Padrão e mais o bloqueio de conteúdo adulto."
            )
        case .personalizado:
            String(
                localized: "protection_level.personalizado.summary",
                defaultValue: "Use o endereço de um servidor DNS seguro em que você já confia."
            )
        }
    }
}
