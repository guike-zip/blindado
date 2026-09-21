import SwiftUI

/// US4 — Safari mais limpo. Estado do bloqueador de conteúdo e a ação de recarregar regras
/// (FR-011, FR-012, FR-013).
struct SafariView: View {
    @Environment(\.openURL) private var openURL

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

    private var enableStepTexts: [String] {
        #if os(macOS)
        [
            "Abra o Safari e vá em Safari › Ajustes.",
            "Clique na aba Extensões.",
            "Ligue a chave do Blindado.",
        ]
        #else
        [
            "Abra Ajustes e role até Safari.",
            "Toque em Extensões.",
            "Ligue a chave do Blindado.",
        ]
        #endif
    }

    private var enablePathText: String {
        #if os(macOS)
        "Safari › Ajustes › Extensões › Blindado"
        #else
        "Ajustes › Safari › Extensões › Blindado"
        #endif
    }

    private var disabledCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
            Text("Bloqueador desativado")
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("O Safari só aceita bloqueadores que você ligar na mão. Leva poucos toques e vale para todas as abas.")
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Colors.textSecondary)

            VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                ForEach(Array(enableStepTexts.enumerated()), id: \.offset) { index, text in
                    Text("\(index + 1). \(text)")
                }
            }
            .font(Theme.Typography.subhead)
            .foregroundStyle(Theme.Colors.textPrimary)

            Text(enablePathText)
                .font(Theme.Typography.mono)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(Theme.Spacing.s4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.bgFillSubtle, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))

            #if os(iOS)
            // No iOS, `app-settings:` abre o app Ajustes, de onde o usuário alcança
            // Safari › Extensões em poucos toques.
            Button {
                openURL(SystemLinks.systemSettings)
            } label: {
                Text("Abrir os Ajustes")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.Colors.accent)
            .foregroundStyle(Theme.Colors.textOnAccent)
            .controlSize(.large)
            #else
            // No macOS as preferências de extensão são do próprio Safari (Safari › Ajustes),
            // não do sistema — não existe um esquema de URL público para abrir essa aba
            // direto de outro app, então mostramos só a instrução acima.
            #endif

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
