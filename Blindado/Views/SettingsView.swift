import SwiftUI

/// Aba Ajustes — lista agrupada com o nível de proteção atual e a entrada para Privacidade
/// (US5, FR-014).
struct SettingsView: View {
    var levelViewModel: ProtectionLevelViewModel
    var privacyViewModel: PrivacyViewModel

    var body: some View {
        NavigationStack {
            List {
                Section("Proteção") {
                    NavigationLink {
                        ProtectionLevelView(viewModel: levelViewModel)
                    } label: {
                        LabeledContent("Nível de proteção", value: levelViewModel.profile.level.displayName)
                    }
                }

                Section("App") {
                    NavigationLink {
                        PrivacyView(viewModel: privacyViewModel)
                    } label: {
                        Label("Privacidade", systemImage: "hand.raised")
                    }
                }

                Section {
                    HStack {
                        Spacer()
                        Text("Blindado \(appVersion)")
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Ajustes")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    SettingsView(
        levelViewModel: ProtectionLevelViewModel(dnsManaging: MockDNSManager()),
        privacyViewModel: PrivacyViewModel(dnsManaging: MockDNSManager())
    )
}
