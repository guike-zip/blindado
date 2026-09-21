import Foundation
import XCTest
@testable import Blindado

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testEstadoInicialNaoConfigurado() async {
        let mock = MockDNSManager()
        let sut = HomeViewModel(dnsManaging: mock, profileAccess: .inMemory())

        await sut.refreshState()

        XCTAssertEqual(sut.state, .naoConfigurado)
    }

    func testBlindarInstalaEFicaAguardandoAtivacao() async {
        let mock = MockDNSManager()
        let sut = HomeViewModel(dnsManaging: mock, profileAccess: .inMemory())

        await sut.blindar()

        XCTAssertEqual(sut.state, .instaladoDesativado)
        XCTAssertNotNil(mock.installedProvider)
        XCTAssertNil(sut.conflictWarning)
    }

    func testAtivacaoManualEmAjustesRefleteAoAtualizarEstado() async {
        let mock = MockDNSManager()
        let sut = HomeViewModel(dnsManaging: mock, profileAccess: .inMemory())

        await sut.blindar()
        XCTAssertEqual(sut.state, .instaladoDesativado)

        // Simula o usuário ativando manualmente em Ajustes, fora do app (FR-003).
        mock.simulateUserActivatedInSettings()
        await sut.refreshState()

        XCTAssertEqual(sut.state, .blindado)
    }

    func testRemoverVoltaParaNaoConfigurado() async {
        let mock = MockDNSManager()
        let sut = HomeViewModel(dnsManaging: mock, profileAccess: .inMemory())

        await sut.blindar()
        mock.simulateUserActivatedInSettings()
        await sut.refreshState()
        XCTAssertEqual(sut.state, .blindado)

        await sut.remover()

        XCTAssertEqual(sut.state, .naoConfigurado)
    }

    /// FR-017: quando outra configuração de DNS/VPN de terceiros já está ativa, o ViewModel
    /// expõe um aviso em vez de silenciosamente falhar ou fingir sucesso.
    func testConflitoDeConfiguracaoExpoeAviso() async {
        let mock = MockDNSManager()
        mock.installError = .conflictingConfiguration
        let sut = HomeViewModel(dnsManaging: mock, profileAccess: .inMemory())

        await sut.blindar()

        XCTAssertNotNil(sut.conflictWarning)
        XCTAssertEqual(sut.state, .naoConfigurado)
    }
}
