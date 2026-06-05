@testable import ACTransitSwift
import Foundation
import Testing

@Suite("Test BusTimeLocale")
final class BusTimeLocaleTests {
    @Test("make() applies overrides independently")
    func makeOverridesIndependently() {
        let result = BusTimeLocale.make(localeString: "es")
        #expect(result.localeString == "es")
        #expect(result.displayName == BusTimeLocale.sample.displayName)
    }
}
