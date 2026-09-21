import Foundation

/// URLs de sistema usadas via `@Environment(\.openURL)` nas Views (SwiftUI puro — nenhuma
/// View ou ViewModel deste app importa UIKit/AppKit diretamente).
enum SystemLinks {
    /// Abre a tela raiz de Ajustes do app no iOS. O valor replica a constante
    /// `UIApplication.openSettingsURLString` (estável desde o iOS 8) sem precisar de
    /// `import UIKit` no restante do código — só este arquivo conhece o esquema.
    static let iOSSettings = URL(string: "app-settings:")!

    /// No macOS, abre o painel de Rede em Ajustes do Sistema, onde a configuração de DNS
    /// criptografado instalada pelo Blindado aparece como um novo serviço de rede.
    static let macOSNetworkSettings = URL(string: "x-apple.systempreferences:com.apple.Network-Settings.extension")!

    /// O link correto para "abrir Ajustes" nesta plataforma (FR-002) — a única diferença de
    /// verdade entre iOS e macOS que o resto do código (Views) precisa conhecer.
    static var systemSettings: URL {
        #if os(macOS)
        macOSNetworkSettings
        #else
        iOSSettings
        #endif
    }
}
