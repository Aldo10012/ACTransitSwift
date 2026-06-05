@testable import ACTransitSwift
import Foundation
import Testing

@Suite("Test ActRealtimeDirection")
final class ActRealtimeDirectionTests {
    @Test("make() applies overrides independently")
    func makeOverridesIndependently() {
        let result = ActRealtimeDirection.make(id: "TO RICHMOND")
        #expect(result.id == "TO RICHMOND")
        #expect(result.name == ActRealtimeDirection.sample.name)
    }
}
