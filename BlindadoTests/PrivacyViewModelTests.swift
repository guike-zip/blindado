import Foundation
import XCTest
@testable import Blindado

@MainActor
final class PrivacyViewModelTests: XCTestCase {
    func testTextoRefleteOProvedorAtual() async {
        let mock = MockDNSManager()
        let sut = PrivacyViewModel(dnsManaging: mock, profileAccess: .inMemory(initial: .default))

        await sut.refresh()

        XCTAssertEqual(sut.currentProviderName, "AdGuard DNS")
    }

    func testTextoRefleteProvedorPersonalizado() async {
        let mock = MockDNSManager()
        let customURL = URL(string: "https://dns.exemplo.com/dns-query")!
        let profile = ProtectionProfile(level: .personalizado, providerId: nil, customServerURL: customURL)
        let sut = PrivacyViewModel(dnsManaging: mock, profileAccess: .inMemory(initial: profile))

        await sut.refresh()

        XCTAssertEqual(sut.currentProviderName, "dns.exemplo.com")
    }

    func testLinkDaPoliticaDePrivacidadeUsaHTTPS() {
        XCTAssertEqual(PrivacyViewModel.privacyPolicyURL.scheme, "https")
    }
}
