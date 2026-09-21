import SwiftUI

/// Raiz de navegação do app — 4 abas via `TabView` **nativo** do SwiftUI, para herdar Liquid
/// Glass automaticamente na tab bar no iOS 26 (research.md #10; nenhuma View deste projeto
/// constrói chrome de navegação próprio).
struct RootTabView: View {
    @State private var homeViewModel: HomeViewModel
    @State private var protectionLevelViewModel: ProtectionLevelViewModel
    @State private var testViewModel: ProtectionTestViewModel
    @State private var safariViewModel: SafariViewModel
    @State private var privacyViewModel: PrivacyViewModel

    /// Parâmetros opcionais (em vez de valores-padrão) porque `DNSManager()`/
    /// `ContentBlockerManager()`/`ProtectionTester()` são `@MainActor` — um valor-padrão de
    /// parâmetro é avaliado fora do isolamento do `init`, então a construção real acontece
    /// no corpo do `init`, que já roda em `MainActor`.
    @MainActor
    init(
        dnsManaging: DNSManaging? = nil,
        contentBlockerManaging: ContentBlockerManaging? = nil,
        protectionTesting: ProtectionTesting? = nil,
        profileAccess: ProtectionProfileAccess = .live
    ) {
        let dnsManaging = dnsManaging ?? DNSManager()
        _homeViewModel = State(initialValue: HomeViewModel(dnsManaging: dnsManaging, profileAccess: profileAccess))
        _protectionLevelViewModel = State(initialValue: ProtectionLevelViewModel(dnsManaging: dnsManaging, profileAccess: profileAccess))
        _testViewModel = State(initialValue: ProtectionTestViewModel(tester: protectionTesting ?? ProtectionTester()))
        _safariViewModel = State(initialValue: SafariViewModel(contentBlockerManaging: contentBlockerManaging ?? ContentBlockerManager()))
        _privacyViewModel = State(initialValue: PrivacyViewModel(dnsManaging: dnsManaging, profileAccess: profileAccess))
    }

    var body: some View {
        TabView {
            Tab("Início", systemImage: "checkmark.shield.fill") {
                HomeView(viewModel: homeViewModel, levelViewModel: protectionLevelViewModel)
            }
            Tab("Safari", systemImage: "safari") {
                SafariView(viewModel: safariViewModel)
            }
            Tab("Testar", systemImage: "checkmark.circle") {
                ProtectionTestView(viewModel: testViewModel)
            }
            Tab("Ajustes", systemImage: "gearshape") {
                SettingsView(levelViewModel: protectionLevelViewModel, privacyViewModel: privacyViewModel)
            }
        }
        .tint(Theme.Colors.accent)
    }
}

#Preview {
    RootTabView(
        dnsManaging: MockDNSManager(),
        contentBlockerManaging: MockContentBlockerManager(),
        protectionTesting: MockProtectionTester(),
        profileAccess: .inMemory()
    )
}
