import Foundation
import XCTest
@testable import Blindado

@MainActor
final class ProtectionLevelViewModelTests: XCTestCase {
    private func makeSUT() -> (ProtectionLevelViewModel, MockDNSManager) {
        let mock = MockDNSManager()
        // Acesso em memória — nunca toca no UserDefaults real do App Group (research.md /
        // data-model.md), então os testes não podem poluir o estado que o app veria em produção.
        let sut = ProtectionLevelViewModel(dnsManaging: mock, profileAccess: .inMemory(), profile: .default)
        return (sut, mock)
    }

    func testNivelPadraoUsaProvedorPadraoDoCatalogo() async {
        let (sut, mock) = makeSUT()

        await sut.selectLevel(.padrao)

        XCTAssertEqual(sut.selectedProvider?.id, "adguard")
        XCTAssertEqual(mock.installedProvider?.id, "adguard")
    }

    func testTrocarDeNivelReaplicaSemExigirNovaAtivacao() async {
        let (sut, mock) = makeSUT()

        await sut.selectLevel(.padrao)
        await sut.selectLevel(.familia)

        XCTAssertEqual(sut.profile.level, .familia)
        XCTAssertEqual(mock.installedProvider?.level, .familia)
        // O mock só simula o fluxo real de instalação — a troca em si não deve exigir que o
        // teste passe por um estado "não configurado" intermediário.
        XCTAssertEqual(mock.state, .instaladoDesativado)
    }

    /// FR-019: dentro de Padrão/Família, o usuário pode trocar de provedor sem sair do nível.
    func testTrocarDeProvedorDentroDoNivel() async {
        let (sut, mock) = makeSUT()
        await sut.selectLevel(.padrao)

        let alternativo = sut.availableProviders.first { $0.id != sut.selectedProvider?.id }!
        await sut.selectProvider(alternativo)

        XCTAssertEqual(sut.selectedProvider?.id, alternativo.id)
        XCTAssertEqual(mock.installedProvider?.id, alternativo.id)
        XCTAssertEqual(sut.profile.level, .padrao)
    }

    func testPadraoEFamiliaTemPeloMenosDoisProvedores() {
        let (sut, _) = makeSUT()
        XCTAssertGreaterThanOrEqual(DNSProvider.providers(for: .padrao).count, 2)
        XCTAssertGreaterThanOrEqual(DNSProvider.providers(for: .familia).count, 2)
        _ = sut
    }

    func testURLPersonalizadaNaoHTTPSEhRejeitada() async {
        let (sut, _) = makeSUT()

        await sut.saveCustomServer("http://dns.exemplo.com/dns-query")

        XCTAssertNotNil(sut.validationError)
        XCTAssertNotEqual(sut.profile.level, .personalizado)
    }

    func testURLPersonalizadaInacessivelEhRejeitada() async {
        let (sut, mock) = makeSUT()
        mock.validationError = .serverUnreachable

        await sut.saveCustomServer("https://dns.exemplo.com/dns-query")

        XCTAssertNotNil(sut.validationError)
        XCTAssertNotEqual(sut.profile.level, .personalizado)
    }

    func testURLPersonalizadaValidaEhSalvaEAplicada() async {
        let (sut, mock) = makeSUT()

        await sut.saveCustomServer("https://dns.exemplo.com/dns-query")

        XCTAssertNil(sut.validationError)
        XCTAssertEqual(sut.profile.level, .personalizado)
        XCTAssertEqual(mock.installedProvider?.serverURL.absoluteString, "https://dns.exemplo.com/dns-query")
    }

    func testEscolhaPersisteEntreInstancias() async {
        let mock = MockDNSManager()
        let access = ProtectionProfileAccess.inMemory()

        let sut1 = ProtectionLevelViewModel(dnsManaging: mock, profileAccess: access, profile: .default)
        await sut1.selectLevel(.familia)

        // Uma segunda instância, criada depois (simulando reabrir o app), lê o que a
        // primeira salvou através do mesmo `ProtectionProfileAccess`.
        let sut2 = ProtectionLevelViewModel(dnsManaging: mock, profileAccess: access)
        XCTAssertEqual(sut2.profile.level, .familia)
    }
}
