import SwiftUI

/// Raiz de navegação no macOS — `NavigationSplitView` com sidebar, o padrão nativo do Mac
/// (diferente do `TabView` do iOS). O sidebar e a toolbar herdam Liquid Glass automaticamente
/// do AppKit/SwiftUI no macOS 26, do mesmo jeito que o `TabView` no iOS (research.md #10) —
/// nenhum código de vidro manual aqui também.
struct RootSidebarView: View {
    enum Section: String, CaseIterable, Identifiable {
        case inicio = "Início"
        case safari = "Safari"
        case testar = "Testar"
        case ajustes = "Ajustes"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .inicio: "checkmark.shield.fill"
            case .safari: "safari"
            case .testar: "checkmark.circle"
            case .ajustes: "gearshape"
            }
        }

        var displayName: String {
            switch self {
            case .inicio: String(localized: "tab.inicio", defaultValue: "Início")
            case .safari: String(localized: "safari.nav_title", defaultValue: "Safari")
            case .testar: String(localized: "test.nav_title", defaultValue: "Testar")
            case .ajustes: String(localized: "settings.nav_title", defaultValue: "Ajustes")
            }
        }
    }

    @State private var selection: Section? = .inicio

    @State private var homeViewModel: HomeViewModel
    @State private var protectionLevelViewModel: ProtectionLevelViewModel
    @State private var testViewModel: ProtectionTestViewModel
    @State private var safariViewModel: SafariViewModel
    @State private var privacyViewModel: PrivacyViewModel

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
        NavigationSplitView {
            List(Section.allCases, selection: $selection) { section in
                Label(section.displayName, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Blindado")
        } detail: {
            switch selection {
            case .inicio, nil:
                HomeView(viewModel: homeViewModel, levelViewModel: protectionLevelViewModel)
            case .safari:
                SafariView(viewModel: safariViewModel)
            case .testar:
                ProtectionTestView(viewModel: testViewModel)
            case .ajustes:
                SettingsView(levelViewModel: protectionLevelViewModel, privacyViewModel: privacyViewModel)
            }
        }
        .tint(Theme.Colors.accent)
    }
}

#Preview {
    RootSidebarView(
        dnsManaging: MockDNSManager(),
        contentBlockerManaging: MockContentBlockerManager(),
        protectionTesting: MockProtectionTester(),
        profileAccess: .inMemory()
    )
}
