@testable import ACTransitSwift
import Foundation
import Testing

@Suite("Test BusTimeRoute")
final class BusTimeRouteTests {
    @Test("make() applies overrides independently")
    func makeOverridesIndependently() {
        let result = BusTimeRoute.make(rt: "72")
        #expect(result.rt == "72")
        #expect(result.rtnm == BusTimeRoute.sample.rtnm)
        #expect(result.rtclr == BusTimeRoute.sample.rtclr)
        #expect(result.rtdd == BusTimeRoute.sample.rtdd)
        #expect(result.rtpidatafeed == BusTimeRoute.sample.rtpidatafeed)
    }
}
