import Foundation
import XCTest
@testable import Blindado

@MainActor
final class SafariViewModelTests: XCTestCase {
    func testEstadoDesabilitado() async {
        let mock = MockContentBlockerManager()
        mock.isEnabled = false
        let sut = SafariViewModel(contentBlockerManaging: mock)

        await sut.refreshState()

        XCTAssertFalse(sut.state.isEnabled)
    }

    func testEstadoHabilitado() async {
        let mock = MockContentBlockerManager()
        mock.isEnabled = true
        let sut = SafariViewModel(contentBlockerManaging: mock)

        await sut.refreshState()

        XCTAssertTrue(sut.state.isEnabled)
    }

    func testRecarregarRegrasAtualizaDataEConfirma() async {
        let mock = MockContentBlockerManager()
        mock.isEnabled = true
        let sut = SafariViewModel(contentBlockerManaging: mock)

        await sut.recarregarRegras()

        XCTAssertNil(sut.reloadError)
        XCTAssertNotNil(sut.state.lastReloadDate)
    }

    func testFalhaAoRecarregarExpoeErro() async {
        struct FalhaFake: Error {}
        let mock = MockContentBlockerManager()
        mock.reloadError = FalhaFake()
        let sut = SafariViewModel(contentBlockerManaging: mock)

        await sut.recarregarRegras()

        XCTAssertNotNil(sut.reloadError)
    }
}
