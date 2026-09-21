import SwiftUI

/// US1 — Blindar o aparelho. Escudo grande com os 3 estados de `ProtectionState`, ativação
/// guiada passo a passo, remoção, e o aviso de conflito de DNS/VPN de terceiros (FR-017).
struct HomeView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var viewModel: HomeViewModel
    var levelViewModel: ProtectionLevelViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.s7) {
                    shield
                    statusCard
                    if viewModel.conflictWarning == nil {
                        NavigationLink {
                            ProtectionLevelView(viewModel: levelViewModel)
                        } label: {
                            protectionLevelRow
                        }
                        .buttonStyle(.plain)
                    }
                    actions
                }
                .padding(.horizontal, Theme.Spacing.layoutGutter)
                .padding(.vertical, Theme.Spacing.s7)
            }
            .background(Theme.Colors.bgCanvas)
            .navigationTitle("Blindado")
            .alert(
                "Conflito de DNS/VPN",
                isPresented: .init(
                    get: { viewModel.conflictWarning != nil },
                    set: { if !$0 { viewModel.dismissConflictWarning() } }
                )
            ) {
                Button("Entendi", role: .cancel) { viewModel.dismissConflictWarning() }
            } message: {
                Text(viewModel.conflictWarning ?? "")
            }
        }
        .task { await viewModel.refreshState() }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            Task { await viewModel.refreshState() }
        }
    }

    private var shield: some View {
        Image(systemName: shieldSymbolName)
            .font(.system(size: 88, weight: .medium))
            .foregroundStyle(Theme.Colors.status(for: viewModel.state))
            .accessibilityLabel(stateTitle)
            .padding(.top, Theme.Spacing.s6)
    }

    private var shieldSymbolName: String {
        switch viewModel.state {
        case .naoConfigurado: "shield"
        case .instaladoDesativado: "shield.lefthalf.filled"
        case .blindado: "checkmark.shield.fill"
        }
    }

    private var statusCard: some View {
        VStack(spacing: Theme.Spacing.s3) {
            Text(statePillText)
                .font(Theme.Typography.caption)
                .textCase(.uppercase)
                .padding(.horizontal, Theme.Spacing.s4)
                .padding(.vertical, Theme.Spacing.s2)
                .background(Theme.Colors.statusSoft(for: viewModel.state), in: .capsule)
                .foregroundStyle(Theme.Colors.status(for: viewModel.state))

            Text(stateTitle)
                .font(Theme.Typography.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text(stateBody)
                .font(Theme.Typography.subhead)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.Colors.textSecondary)

            if viewModel.state == .instaladoDesativado {
                activationSteps
            }
        }
    }

    private var activationSteps: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            stepRow(1, "Abra o app Ajustes e toque em Geral.")
            stepRow(2, "Entre em Gestão de VPN e Dispositivo.")
            stepRow(3, "Toque em DNS e escolha Blindado.")

            Text("Ajustes › Geral › Gestão de VPN e Dispositivo › DNS › Blindado")
                .font(Theme.Typography.mono)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(Theme.Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.bgFillSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
        }
        .padding(.top, Theme.Spacing.s4)
    }

    private func stepRow(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s3) {
            Text("\(number)")
                .font(Theme.Typography.footnote.bold())
                .frame(width: 22, height: 22)
                .background(Theme.Colors.bgFillSubtle, in: .circle)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(text)
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var protectionLevelRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                Text("Nível de proteção")
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(levelViewModel.profile.level.displayName)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.cardPadding)
        .frame(minHeight: Theme.Spacing.rowMinHeight)
        .background(Theme.Colors.bgSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
    }

    @ViewBuilder
    private var actions: some View {
        switch viewModel.state {
        case .naoConfigurado:
            Button {
                Task { await viewModel.blindar() }
            } label: {
                Text("Blindar meu iPhone")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.accent)
            .foregroundStyle(Theme.Colors.textOnAccent)
            .controlSize(.large)
            .disabled(viewModel.isBusy)

            Text("Instala um perfil de DNS no iPhone. Você pode remover quando quiser.")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)

        case .instaladoDesativado:
            Button {
                openURL(SystemLinks.iOSSettings)
            } label: {
                Label("Abrir os Ajustes", systemImage: "arrow.up.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.accent)
            .foregroundStyle(Theme.Colors.textOnAccent)
            .controlSize(.large)

            Button("Já ativei — verificar de novo") {
                Task { await viewModel.refreshState() }
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .frame(maxWidth: .infinity)

        case .blindado:
            Button {
                // Navegação para a aba Testar fica a cargo do usuário via tab bar; aqui só
                // indicamos a ação disponível.
            } label: {
                Text("Testar a proteção")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button("Remover proteção", role: .destructive) {
                Task { await viewModel.remover() }
            }
            .font(Theme.Typography.callout)
            .disabled(viewModel.isBusy)
        }
    }

    private var statePillText: String {
        switch viewModel.state {
        case .naoConfigurado: "Não configurado"
        case .instaladoDesativado: "Aguardando ativação"
        case .blindado: "Protegido"
        }
    }

    private var stateTitle: String {
        switch viewModel.state {
        case .naoConfigurado: "Seu iPhone ainda não está protegido"
        case .instaladoDesativado: "Falta um passo"
        case .blindado: "Seu iPhone está blindado"
        }
    }

    private var stateBody: String {
        switch viewModel.state {
        case .naoConfigurado:
            "O Blindado liga um DNS criptografado para o sistema inteiro — apps, jogos e Safari. Leva menos de um minuto."
        case .instaladoDesativado:
            "O perfil já está no seu iPhone. Por segurança, o iOS pede que você confirme a ativação nos Ajustes."
        case .blindado:
            "As consultas DNS saem criptografadas. Anúncios e rastreadores conhecidos são bloqueados antes de carregar."
        }
    }
}

#Preview("Não configurado") {
    RootTabView(dnsManaging: MockDNSManager(), profileAccess: .inMemory())
}

#Preview("Blindado") {
    let mock = MockDNSManager()
    mock.state = .blindado
    return RootTabView(dnsManaging: mock, profileAccess: .inMemory())
}
