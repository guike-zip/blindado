import SwiftUI

/// US5 — Transparência. Explica que o app não coleta dados e para onde as consultas DNS vão
/// (FR-014).
struct PrivacyView: View {
    var viewModel: PrivacyViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
                Text("O Blindado não coleta nada sobre você.")
                    .font(Theme.Typography.title3)
                    .foregroundStyle(Theme.Colors.textPrimary)

                factRow(icon: "person.crop.circle.badge.xmark", title: "Sem conta", body: "Sem e-mail, telefone ou cadastro.")
                factRow(icon: "server.rack", title: "Sem servidor nosso", body: "O app não manda nada para nós.")
                factRow(icon: "eye.slash", title: "Sem rastreadores", body: "Nenhum SDK de análise ou anúncio.")

                Text("PARA ONDE VÃO SUAS CONSULTAS")
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .padding(.top, Theme.Spacing.s4)

                Text("Para achar um site, seu iPhone faz uma pergunta chamada consulta DNS. O Blindado faz essa pergunta sair criptografada, direto para o provedor que você escolheu.")
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(Theme.Colors.textSecondary)

                if let provider = viewModel.currentProviderName {
                    Text("Quem responde é esse provedor (\(provider)), e é a política dele que vale. Você pode trocar em Nível de proteção.")
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                Link(destination: PrivacyViewModel.privacyPolicyURL) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text("Ler a política completa")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(Theme.Spacing.cardPadding)
                    .background(Theme.Colors.bgSurface, in: RoundedRectangle(cornerRadius: Theme.Radius.md))
                }
            }
            .padding(Theme.Spacing.layoutGutter)
        }
        .background(Theme.Colors.bgCanvas)
        .navigationTitle("Privacidade")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.refresh() }
    }

    private func factRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s4) {
            Image(systemName: icon)
                .foregroundStyle(Theme.Colors.statusInfo)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                Text(title)
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(body)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        PrivacyView(viewModel: PrivacyViewModel(dnsManaging: MockDNSManager()))
    }
}
