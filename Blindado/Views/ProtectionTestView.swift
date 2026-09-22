import SwiftUI

/// US3 — Testar a proteção. Lista de domínios com status individual e um banner de resultado
/// geral (FR-009, FR-010).
struct ProtectionTestView: View {
    var viewModel: ProtectionTestViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.s6) {
                    banner
                    domainList
                    runButton
                }
                .padding(Theme.Spacing.layoutGutter)
            }
            .background(Theme.Colors.bgCanvas)
            .navigationTitle(String(localized: "test.nav_title", defaultValue: "Testar"))
        }
        .task {
            if viewModel.items.isEmpty {
                viewModel.runTest()
            }
        }
    }

    @ViewBuilder
    private var banner: some View {
        let status = viewModel.overallStatus
        VStack(spacing: Theme.Spacing.s2) {
            Text(bannerTitle(status))
                .font(Theme.Typography.title3)
                .foregroundStyle(bannerColor(status))
            Text(bannerBody(status))
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.cardPadding)
        .background(bannerColor(status).opacity(0.12), in: RoundedRectangle(cornerRadius: Theme.Radius.md))
        .accessibilityElement(children: .combine)
    }

    private var domainList: some View {
        VStack(spacing: 0) {
            ForEach(viewModel.items) { item in
                domainRow(item)
                if item.id != viewModel.items.last?.id {
                    Divider()
                }
            }
        }
        .background(Theme.Colors.bgSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
    }

    private func domainRow(_ item: DomainCheckResult) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                Text(item.domain)
                    .font(Theme.Typography.mono)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(
                    item.categoria == .comum
                        ? String(localized: "test.category.control", defaultValue: "Controle — precisa continuar acessível")
                        : String(localized: "test.category.tracker", defaultValue: "Anúncios/rastreadores")
                )
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            Spacer()
            statusBadge(item.status, categoria: item.categoria)
        }
        .padding(Theme.Spacing.cardPadding)
        .accessibilityElement(children: .combine)
    }

    private func statusBadge(_ status: DomainCheckResult.Status, categoria: DomainCategory) -> some View {
        let (text, color) = badgeStyle(status, categoria: categoria)
        return Text(text)
            .font(Theme.Typography.caption)
            .foregroundStyle(color)
            .padding(.horizontal, Theme.Spacing.s3)
            .padding(.vertical, Theme.Spacing.s1)
            .background(color.opacity(0.16), in: .capsule)
    }

    private func badgeStyle(_ status: DomainCheckResult.Status, categoria: DomainCategory) -> (String, Color) {
        switch status {
        case .bloqueado:
            (String(localized: "test.badge.blocked", defaultValue: "Bloqueado"), Theme.Colors.statusProtected)
        case .acessivel:
            (
                String(localized: "test.badge.accessible", defaultValue: "Acessível"),
                categoria == .comum ? Theme.Colors.statusProtected : Theme.Colors.statusDanger
            )
        case .indeterminado:
            (String(localized: "test.badge.no_response", defaultValue: "Sem resposta"), Theme.Colors.statusIdle)
        }
    }

    private var testingLabel: String {
        String(localized: "test.banner.title.testing", defaultValue: "Testando…")
    }

    private var runButton: some View {
        Button(viewModel.isRunning ? testingLabel : String(localized: "test.button.run", defaultValue: "Testar de novo")) {
            viewModel.runTest()
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(viewModel.isRunning)
        .frame(maxWidth: .infinity)
    }

    private func bannerTitle(_ status: OverallProtectionStatus?) -> String {
        switch status {
        case .protegido: Strings.protectedStatusLabel
        case .parcial: String(localized: "test.banner.title.parcial", defaultValue: "Parcialmente protegido")
        case .desprotegido: String(localized: "test.banner.title.desprotegido", defaultValue: "Desprotegido")
        case .indeterminado: String(localized: "test.banner.title.indeterminado", defaultValue: "Indeterminado")
        case nil: viewModel.isRunning ? testingLabel : String(localized: "test.banner.title.idle", defaultValue: "Toque em testar")
        }
    }

    private func bannerBody(_ status: OverallProtectionStatus?) -> String {
        switch status {
        case .protegido:
            String(localized: "test.banner.body.protegido", defaultValue: "Nenhum domínio de rastreamento passou, e o domínio de controle continua acessível.")
        case .parcial:
            String(localized: "test.banner.body.parcial", defaultValue: "Alguns domínios continuaram acessíveis. Isso costuma acontecer quando outro app de VPN assume o DNS.")
        case .desprotegido:
            String(localized: "test.banner.body.desprotegido", defaultValue: "Todos os domínios de rastreamento responderam. O perfil do Blindado não está ativo neste iPhone.")
        case .indeterminado:
            String(localized: "test.banner.body.indeterminado", defaultValue: "Seu iPhone está sem conexão, então não dá para afirmar nada sobre a proteção. Conecte-se e teste de novo.")
        case nil:
            String(localized: "test.banner.body.idle", defaultValue: "Vamos verificar, item a item, se a sua proteção está funcionando.")
        }
    }

    private func bannerColor(_ status: OverallProtectionStatus?) -> Color {
        switch status {
        case .protegido: Theme.Colors.statusProtected
        case .parcial: Theme.Colors.statusPending
        case .desprotegido: Theme.Colors.statusDanger
        case .indeterminado, nil: Theme.Colors.statusIdle
        }
    }
}

#Preview {
    let mock = MockProtectionTester()
    mock.scenario = .protegido
    return ProtectionTestView(viewModel: ProtectionTestViewModel(tester: mock))
}
