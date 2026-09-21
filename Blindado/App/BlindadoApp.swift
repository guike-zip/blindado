import SwiftUI

@main
struct BlindadoApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            RootSidebarView()
            #else
            RootTabView()
            #endif
        }
        #if os(macOS)
        .defaultSize(width: 900, height: 640)
        #endif
    }
}
