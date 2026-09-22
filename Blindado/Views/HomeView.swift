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
                String(localized: "home.alert.conflict.title", defaultValue: "Conflito de DNS/VPN"),
                isPresented: .init(
                    get: { viewModel.conflictWarning != nil },
                    set: { if !$0 { viewModel.dismissConflictWarning() } }
                )
            ) {
                Button(String(localized: "home.alert.conflict.confirm", defaultValue: "Entendi"), role: .cancel) {
                    viewModel.dismissConflictWarning()
                }
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
            ForEach(Array(activationStepTexts.enumerated()), id: \.offset) { index, text in
                stepRow(index + 1, text)
            }

            Text(activationPathText)
                .font(Theme.Typography.mono)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(Theme.Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.bgFillSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
        }
        .padding(.top, Theme.Spacing.s4)
    }

    /// O fluxo de ativação difere de verdade entre plataformas — não é só o texto do menu
    /// que muda, é o mecanismo: no iOS o perfil de DNS já existente vira uma opção para
    /// selecionar; no macOS ele aparece como um **novo serviço de rede** que precisa ser
    /// tornado ativo (quickstart.md, pendente de confirmação em hardware real — Constitution
    /// Princípio VIII).
    private var activationStepTexts: [String] {
        #if os(macOS)
        [
            String(localized: "home.activation_steps.mac.1", defaultValue: "Abra Ajustes do Sistema e clique em Rede."),
            String(localized: "home.activation_steps.mac.2", defaultValue: "Um novo serviço \"Blindado\" aparece na lista à esquerda."),
            String(localized: "home.activation_steps.mac.3", defaultValue: "Clique nele, depois no botão “•••” e escolha Tornar Serviço Ativo."),
        ]
        #else
        [
            String(localized: "home.activation_steps.ios.1", defaultValue: "Abra o app Ajustes e toque em Geral."),
            String(localized: "home.activation_steps.ios.2", defaultValue: "Entre em Gestão de VPN e Dispositivo."),
            String(localized: "home.activation_steps.ios.3", defaultValue: "Toque em DNS e escolha Blindado."),
        ]
        #endif
    }

    private var activationPathText: String {
        #if os(macOS)
        String(localized: "home.activation_path.mac", defaultValue: "Ajustes do Sistema › Rede › Blindado › ••• › Tornar Serviço Ativo")
        #else
        String(localized: "home.activation_path.ios", defaultValue: "Ajustes › Geral › Gestão de VPN e Dispositivo › DNS › Blindado")
        #endif
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
                Text(Strings.protectionLevelLabel)
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
                Text(String(localized: "home.action.blindar", defaultValue: "Blindar meu iPhone"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.accent)
            .foregroundStyle(Theme.Colors.textOnAccent)
            .controlSize(.large)
            .disabled(viewModel.isBusy)

            Text(String(localized: "home.action.blindar.caption", defaultValue: "Instala um perfil de DNS no iPhone. Você pode remover quando quiser."))
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)

        case .instaladoDesativado:
            Button {
                openURL(SystemLinks.systemSettings)
            } label: {
                Label(Strings.openSettingsLabel, systemImage: "arrow.up.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.accent)
            .foregroundStyle(Theme.Colors.textOnAccent)
            .controlSize(.large)

            Button(String(localized: "home.action.recheck", defaultValue: "Já ativei — verificar de novo")) {
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
                Text(String(localized: "home.action.test", defaultValue: "Testar a proteção"))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Button(String(localized: "home.action.remove", defaultValue: "Remover proteção"), role: .destructive) {
                Task { await viewModel.remover() }
            }
            .font(Theme.Typography.callout)
            .disabled(viewModel.isBusy)
        }
    }

    private var statePillText: String {
        switch viewModel.state {
        case .naoConfigurado: String(localized: "home.shield.status.not_configured", defaultValue: "Não configurado")
        case .instaladoDesativado: String(localized: "home.shield.status.pending", defaultValue: "Aguardando ativação")
        case .blindado: Strings.protectedStatusLabel
        }
    }

    private var stateTitle: String {
        switch viewModel.state {
        case .naoConfigurado: String(localized: "home.title.not_configured", defaultValue: "Seu iPhone ainda não está protegido")
        case .instaladoDesativado: String(localized: "home.title.pending", defaultValue: "Falta um passo")
        case .blindado: String(localized: "home.title.protected", defaultValue: "Seu iPhone está blindado")
        }
    }

    private var stateBody: String {
        switch viewModel.state {
        case .naoConfigurado:
            String(localized: "home.body.not_configured", defaultValue: "O Blindado liga um DNS criptografado para o sistema inteiro — apps, jogos e Safari. Leva menos de um minuto.")
        case .instaladoDesativado:
            String(localized: "home.body.pending", defaultValue: "O perfil já está no seu iPhone. Por segurança, o iOS pede que você confirme a ativação nos Ajustes.")
        case .blindado:
            String(localized: "home.body.protected", defaultValue: "As consultas DNS saem criptografadas. Anúncios e rastreadores conhecidos são bloqueados antes de carregar.")
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
