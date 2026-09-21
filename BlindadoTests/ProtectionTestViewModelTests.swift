import Foundation
import XCTest
@testable import Blindado

@MainActor
final class ProtectionTestViewModelTests: XCTestCase {
    private func run(_ scenario: MockProtectionTester.Scenario) async -> ProtectionTestViewModel {
        let mock = MockProtectionTester()
        mock.scenario = scenario
        let sut = ProtectionTestViewModel(tester: mock)

        sut.runTest()
        while sut.isRunning {
            await Task.yield()
        }
        return sut
    }

    func testCasoProtegido() async {
        let sut = await run(.protegido)
        XCTAssertEqual(sut.overallStatus, .protegido)
        XCTAssertEqual(sut.items.count, ProtectionTester.testDomains.count)
    }

    func testCasoParcial() async {
        let sut = await run(.parcial)
        XCTAssertEqual(sut.overallStatus, .parcial)
    }

    func testCasoDesprotegido() async {
        let sut = await run(.desprotegido)
        XCTAssertEqual(sut.overallStatus, .desprotegido)
    }

    /// FR-010: sem rede, o app nunca afirma "protegido" nem "desprotegido".
    func testCasoIndeterminadoSemRede() async {
        let sut = await run(.indeterminado)
        XCTAssertEqual(sut.overallStatus, .indeterminado)
    }

    func testItensChegamIncrementalmente() async {
        let mock = MockProtectionTester()
        mock.scenario = .protegido
        let sut = ProtectionTestViewModel(tester: mock)

        sut.runTest()
        XCTAssertTrue(sut.isRunning)

        while sut.isRunning {
            await Task.yield()
        }
        XCTAssertFalse(sut.items.isEmpty)
    }
}
