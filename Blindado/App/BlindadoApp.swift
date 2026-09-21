import SwiftUI

@main
struct BlindadoApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(nil) // segue o sistema; escuro é o tema primário do design
        }
    }
}
