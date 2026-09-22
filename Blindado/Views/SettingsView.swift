import SwiftUI

/// Aba Ajustes — lista agrupada com o nível de proteção atual e a entrada para Privacidade
/// (US5, FR-014).
struct SettingsView: View {
    var levelViewModel: ProtectionLevelViewModel
    var privacyViewModel: PrivacyViewModel

    @AppStorage(AppearanceMode.storageKey) private var appearanceModeRaw = AppearanceMode.sistema.rawValue

    private var appearanceMode: Binding<AppearanceMode> {
        Binding(
            get: { AppearanceMode(rawValue: appearanceModeRaw) ?? .sistema },
            set: { appearanceModeRaw = $0.rawValue }
        )
    }

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "settings.section.protection", defaultValue: "Proteção")) {
                    NavigationLink {
                        ProtectionLevelView(viewModel: levelViewModel)
                    } label: {
                        LabeledContent(Strings.protectionLevelLabel, value: levelViewModel.profile.level.displayName)
                    }
                }

                Section(Strings.appearanceLabel) {
                    Picker(Strings.appearanceLabel, selection: appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section(String(localized: "settings.section.app", defaultValue: "App")) {
                    NavigationLink {
                        PrivacyView(viewModel: privacyViewModel)
                    } label: {
                        Label(Strings.privacyLabel, systemImage: "hand.raised")
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
            .navigationTitle(String(localized: "settings.nav_title", defaultValue: "Ajustes"))
        }
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

#Preview {
    let access = ProtectionProfileAccess.inMemory()
    SettingsView(
        levelViewModel: ProtectionLevelViewModel(dnsManaging: MockDNSManager(), profileAccess: access),
        privacyViewModel: PrivacyViewModel(dnsManaging: MockDNSManager(), profileAccess: access)
    )
}
