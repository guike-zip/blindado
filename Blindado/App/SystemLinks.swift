import Foundation

/// URLs de sistema usadas via `@Environment(\.openURL)` nas Views (SwiftUI puro — nenhuma
/// View ou ViewModel deste app importa UIKit/AppKit diretamente).
enum SystemLinks {
    /// Abre a tela raiz de Ajustes do app no iOS. O valor replica a constante
    /// `UIApplication.openSettingsURLString` (estável desde o iOS 8) sem precisar de
    /// `import UIKit` no restante do código — só este arquivo conhece o esquema.
    static let iOSSettings = URL(string: "app-settings:")!

    /// No macOS, abre o painel de Rede em Ajustes do Sistema, onde a configuração de DNS
    /// criptografado instalada pelo Blindado aparece (perfil de DNS do sistema).
    static let macOSNetworkSettings = URL(string: "x-apple.systempreferences:com.apple.Network-Settings.extension")!
}
