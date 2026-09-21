import SwiftUI

/// US2 — Escolher o nível de proteção. Padrão / Família / Personalizado, com seletor
/// opcional de provedor dentro de Padrão/Família (FR-019) e validação de URL personalizada
/// (FR-006).
struct ProtectionLevelView: View {
    var viewModel: ProtectionLevelViewModel

    @State private var customServerText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s3) {
                ForEach(ProtectionLevel.allCases) { level in
                    levelRow(level)
                }

                if viewModel.profile.level == .personalizado {
                    customServerField
                }

                Text("Trocar o nível atualiza o perfil automaticamente. Seu iPhone continua protegido durante a troca.")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.Spacing.s3)
            }
            .padding(Theme.Spacing.layoutGutter)
        }
        .background(Theme.Colors.bgCanvas)
        .navigationTitle("Nível de proteção")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func levelRow(_ level: ProtectionLevel) -> some View {
        let isSelected = viewModel.profile.level == level
        return VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
            Button {
                Task { await viewModel.selectLevel(level) }
            } label: {
                HStack(alignment: .top, spacing: Theme.Spacing.s3) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? Theme.Colors.accent : Theme.Colors.borderStrong)
                    VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                        Text(level.displayName)
                            .font(Theme.Typography.headline)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(level.summary)
                            .font(Theme.Typography.subhead)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if isSelected, level != .personalizado {
                providerPicker(for: level)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(
            isSelected ? Theme.Colors.statusProtectedSoft : Theme.Colors.bgSurface,
            in: RoundedRectangle(cornerRadius: Theme.Radius.md)
        )
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func providerPicker(for level: ProtectionLevel) -> some View {
        let providers = DNSProvider.providers(for: level)
        return VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
            Text("Provedor de DNS")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textTertiary)

            ForEach(providers) { provider in
                Button {
                    Task { await viewModel.selectProvider(provider) }
                } label: {
                    HStack {
                        Text(provider.name)
                            .font(Theme.Typography.subhead)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        if viewModel.selectedProvider?.id == provider.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Theme.Colors.accent)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.s2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, Theme.Spacing.s2)
    }

    private var customServerField: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
            Text("Endereço DoH (DNS sobre HTTPS)")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textTertiary)

            TextField("https://dns.meuprovedor.com/dns-query", text: $customServerText)
                .font(Theme.Typography.mono)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
                .padding(Theme.Spacing.s4)
                .background(Theme.Colors.bgSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm)
                        .stroke(
                            viewModel.validationError == nil ? Theme.Colors.borderStrong : Theme.Colors.statusDanger,
                            lineWidth: 1
                        )
                )

            if let error = viewModel.validationError {
                Text(error)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.statusDanger)
            } else {
                Text("O endereço costuma terminar em /dns-query e aparece na página de suporte do provedor.")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Button("Testar e salvar") {
                Task { await viewModel.saveCustomServer(customServerText) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.accent)
            .foregroundStyle(Theme.Colors.textOnAccent)
            .disabled(customServerText.isEmpty || viewModel.isBusy)
            .frame(maxWidth: .infinity)
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.bgSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

#Preview {
    NavigationStack {
        ProtectionLevelView(viewModel: ProtectionLevelViewModel(dnsManaging: MockDNSManager()))
    }
}
