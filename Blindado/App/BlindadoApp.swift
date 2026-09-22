import SwiftUI

@main
struct BlindadoApp: App {
    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw = AppearanceMode.sistema.rawValue

    private var appearanceMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .sistema
    }

    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            RootSidebarView()
                .preferredColorScheme(appearanceMode.colorScheme)
            #else
            RootTabView()
                .preferredColorScheme(appearanceMode.colorScheme)
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 640)
        #endif
    }
}
