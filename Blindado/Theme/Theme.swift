import SwiftUI

/// Tokens de design extraídos de `design/design-tokens.md` (Open Design, gerado em
/// 2026-09-21). Cores vêm de `Assets.xcassets` (adaptativas claro/escuro, tema escuro
/// como base por ser o primário do produto).
///
/// **Fora daqui de propósito**:
/// - `glass.*` (seção 7 do token doc) — `TabView`/`NavigationStack`/`.toolbar`/`.sheet`
///   nativos do iOS 26 renderizam Liquid Glass sozinhos, sem nenhum token do app
///   (research.md #10). Nenhuma View deste projeto deve reimplementar vidro à mão.
/// - `separator` e `bg.chrome` — o doc não fornece hex sRGB preciso para eles (só OKLch com
///   alfa) e ambos têm equivalente nativo direto: `separator` vira o hairline padrão de
///   `List`/`Divider()`; `bg.chrome` era a aproximação de vidro que o Liquid Glass nativo
///   substitui. Aproximar esses valores à mão arriscaria uma cor visivelmente errada por
///   pouco ganho — o sistema já resolve os dois.
enum Theme {
    enum Colors {
        // Cor semântica de status — único vocabulário de cor do app (design-tokens.md #1).
        static let statusProtected = Color("status.protected")
        static let statusPending = Color("status.pending")
        static let statusIdle = Color("status.idle")
        static let statusDanger = Color("status.danger")
        static let statusInfo = Color("status.info")

        static let statusProtectedSoft = Color("status.protected.soft")
        static let statusPendingSoft = Color("status.pending.soft")
        static let statusIdleSoft = Color("status.idle.soft")
        static let statusDangerSoft = Color("status.danger.soft")

        /// `accent` é `status.protected` — o app tem um único acento (design-tokens.md #1).
        static let accent = statusProtected
        static let accentPressed = Color("accent.pressed")

        // Superfícies e texto (design-tokens.md #2).
        static let bgCanvas = Color("bg.canvas")
        static let bgSurface = Color("bg.surface")
        static let bgSurfaceRaised = Color("bg.surfaceRaised")
        static let bgFillSubtle = Color("bg.fillSubtle")

        static let textPrimary = Color("text.primary")
        static let textSecondary = Color("text.secondary")
        static let textTertiary = Color("text.tertiary")
        /// Único texto autorizado sobre um preenchimento `accent` sólido — branco reprova em
        /// contraste sobre o verde do tema escuro (design-tokens.md #2).
        static let textOnAccent = Color("text.onAccent")

        static let borderStrong = Color("border.strong")

        /// Cor de status para um `ProtectionState` — a mesma tabela que decide a cor do
        /// escudo, pill, título e ação primária do Início (data-model.md, design-tokens.md #9).
        static func status(for state: ProtectionState) -> Color {
            switch state {
            case .naoConfigurado: statusIdle
            case .instaladoDesativado: statusPending
            case .blindado: statusProtected
            }
        }

        static func statusSoft(for state: ProtectionState) -> Color {
            switch state {
            case .naoConfigurado: statusIdleSoft
            case .instaladoDesativado: statusPendingSoft
            case .blindado: statusProtectedSoft
            }
        }
    }

    enum Typography {
        // Usa os *text styles* semânticos do sistema (não `.system(size:)` com ponto fixo)
        // para herdar Dynamic Type automaticamente (Constitution Princípio VI) — os pesos
        // abaixo replicam a escala de design-tokens.md #3, que já é a escala nativa do iOS.
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title2 = Font.title2.weight(.bold)
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline
        static let body = Font.body
        static let callout = Font.callout
        static let subhead = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption.weight(.medium)
        /// Reservado para domínios, endereços DoH, caminhos do sistema e a versão do app.
        static let mono = Font.system(.footnote, design: .monospaced)
    }

    enum Spacing {
        static let s1: CGFloat = 2
        static let s2: CGFloat = 4
        static let s3: CGFloat = 8
        static let s4: CGFloat = 12
        static let s5: CGFloat = 16
        static let s6: CGFloat = 20
        static let s7: CGFloat = 24
        static let s8: CGFloat = 32
        static let s9: CGFloat = 40
        static let s10: CGFloat = 56

        static let layoutGutter: CGFloat = 20
        static let rowPaddingV: CGFloat = 13
        static let rowMinHeight: CGFloat = 52
        static let cardPadding: CGFloat = 16
        /// Alvo mínimo de toque (Constitution Princípio VI).
        static let touchMin: CGFloat = 44
        static let buttonHeight: CGFloat = 52
    }

    enum Radius {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 20
        static let xl: CGFloat = 28
    }
}

/// Sombras neutras de design-tokens.md #6, aplicadas como `View.themeShadow(_:)`.
enum ThemeElevation {
    case card
    case floating
    case sheet

    fileprivate var style: (radius: CGFloat, y: CGFloat, opacity: Double) {
        switch self {
        case .card: (2, 1, 0.40)
        case .floating: (14, 4, 0.38)
        case .sheet: (44, 18, 0.46)
        }
    }
}

extension View {
    /// Aplica uma sombra neutra de `ThemeElevation` (design-tokens.md #6).
    func themeShadow(_ elevation: ThemeElevation) -> some View {
        let style = elevation.style
        return shadow(color: .black.opacity(style.opacity), radius: style.radius, x: 0, y: style.y)
    }
}
