import Foundation

/// Textos reaproveitados em mais de uma View — uma única fonte por chave de localização, para
/// não haver duas chamadas `String(localized:defaultValue:)` com a mesma chave e textos-padrão
/// divergentes (o que o compilador não pega, só revisão manual).
enum Strings {
    static var protectionLevelLabel: String {
        String(localized: "common.protection_level_label", defaultValue: "Nível de proteção")
    }

    static var appearanceLabel: String {
        String(localized: "settings.section.appearance", defaultValue: "Aparência")
    }

    static var privacyLabel: String {
        String(localized: "privacy.nav_title", defaultValue: "Privacidade")
    }

    static var openSettingsLabel: String {
        String(localized: "common.open_settings", defaultValue: "Abrir os Ajustes")
    }

    static var protectedStatusLabel: String {
        String(localized: "common.status_protected", defaultValue: "Protegido")
    }
}
