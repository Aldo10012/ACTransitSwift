@testable import ACTransitSwift
import Foundation
import Testing

@Suite("Test BusTimeVehicle")
final class BusTimeVehicleTests {
    @Test("make() applies overrides independently")
    func makeOverridesIndependently() {
        let result = BusTimeVehicle.make(vid: "9999")
        #expect(result.vid == "9999")
        #expect(result.tmstmp == BusTimeVehicle.sample.tmstmp)
        #expect(result.lat == BusTimeVehicle.sample.lat)
        #expect(result.lon == BusTimeVehicle.sample.lon)
        #expect(result.hdg == BusTimeVehicle.sample.hdg)
        #expect(result.pid == BusTimeVehicle.sample.pid)
        #expect(result.pdist == BusTimeVehicle.sample.pdist)
        #expect(result.rt == BusTimeVehicle.sample.rt)
        #expect(result.des == BusTimeVehicle.sample.des)
        #expect(result.dly == BusTimeVehicle.sample.dly)
        #expect(result.rtpidatafeed == BusTimeVehicle.sample.rtpidatafeed)
        #expect(result.tmres == BusTimeVehicle.sample.tmres)
    }
}
