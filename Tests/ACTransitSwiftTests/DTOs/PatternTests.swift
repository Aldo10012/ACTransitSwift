@testable import ACTransitSwift
import Foundation
import Testing

@Suite("Test Pattern")
final class PatternTests {
    @Test("make() applies overrides independently")
    func makeOverridesIndependently() {
        let result = Pattern.make(pid: 99999)
        #expect(result.pid == 99999)
        #expect(result.ln == Pattern.sample.ln)
        #expect(result.rtdir == Pattern.sample.rtdir)
        #expect(result.dtrid == Pattern.sample.dtrid)
        #expect(result.dtrpt == nil)
    }
}
