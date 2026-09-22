import SwiftUI

/// Preferência de aparência do app, independente do modo do sistema (FR fora do escopo
/// original — pedido explícito do usuário). Persistida via `@AppStorage`.
enum AppearanceMode: String, CaseIterable, Identifiable, Sendable {
    case sistema
    case claro
    case escuro

    static let storageKey = "appearanceMode"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sistema: String(localized: "appearance.system", defaultValue: "Sistema")
        case .claro: String(localized: "appearance.light", defaultValue: "Claro")
        case .escuro: String(localized: "appearance.dark", defaultValue: "Escuro")
        }
    }

    /// `nil` deixa o SwiftUI seguir o `ColorScheme` do sistema.
    var colorScheme: ColorScheme? {
        switch self {
        case .sistema: nil
        case .claro: .light
        case .escuro: .dark
        }
    }
}
