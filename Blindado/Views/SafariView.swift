import SwiftUI

/// US4 — Safari mais limpo. Estado do bloqueador de conteúdo e a ação de recarregar regras
/// (FR-011, FR-012, FR-013).
struct SafariView: View {
    var viewModel: SafariViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.s6) {
                    if viewModel.state.isEnabled {
                        enabledCard
                    } else {
                        disabledCard
                    }
                }
                .padding(Theme.Spacing.layoutGutter)
            }
            .background(Theme.Colors.bgCanvas)
            .navigationTitle("Safari")
        }
        .task { await viewModel.refreshState() }
    }

    private var disabledCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
            Text("Bloqueador desativado")
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("O Safari só aceita bloqueadores que você ligar na mão. São três toques e vale para todas as abas.")
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                Text("1. Abra Ajustes e role até Safari.")
                Text("2. Toque em Extensões.")
                Text("3. Ligue a chave do Blindado.")
            }
            .font(Theme.Typography.subhead)
            .foregroundStyle(Theme.Colors.textPrimary)

            Text("Ajustes › Safari › Extensões › Blindado")
                .font(Theme.Typography.mono)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(Theme.Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.bgFillSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))

            Button {
                viewModel.abrirAjustesDoSafari()
            } label: {
                Text("Abrir os Ajustes do Safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.accent)
            .foregroundStyle(Theme.Colors.textOnAccent)
            .controlSize(.large)

            Text("O DNS criptografado continua funcionando mesmo com isso desligado.")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.bgSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
    }

    private var enabledCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
            Text("Bloqueador ativo")
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("O Safari está usando as regras do Blindado em todas as abas deste iPhone.")
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                labeledRow("Lista aplicada", "Padrão")
                labeledRow("Última atualização", lastReloadText)
            }

            Button {
                Task { await viewModel.recarregarRegras() }
            } label: {
                Text("Recarregar regras")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.accent)
            .foregroundStyle(Theme.Colors.textOnAccent)
            .controlSize(.large)
            .disabled(viewModel.isBusy)

            if let error = viewModel.reloadError {
                Text(error)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.statusDanger)
            } else if viewModel.state.lastReloadDate != nil {
                Text("Regras recarregadas no Safari")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.statusProtected)
            }
        }
        .padding(Theme.Spacing.cardPadding)
        .background(Theme.Colors.bgSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
    }

    private func labeledRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Colors.textTertiary)
            Spacer()
            Text(value)
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }

    private var lastReloadText: String {
        guard let date = viewModel.state.lastReloadDate else { return "—" }
        return date.formatted(date: .omitted, time: .shortened)
    }
}

#Preview {
    let mock = MockContentBlockerManager()
    mock.isEnabled = true
    return SafariView(viewModel: SafariViewModel(contentBlockerManaging: mock))
}
