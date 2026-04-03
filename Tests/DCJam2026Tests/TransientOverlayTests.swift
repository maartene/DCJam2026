import Testing
@testable import GameDomain

// TransientOverlay Tests — step 01-01 (game-polish-v1)
//
// Acceptance Criteria:
//   AC1: TransientOverlay compiles inside GameDomain with zero imports
//   AC2: TransientOverlay conforms to Equatable and Sendable
//   AC3: braceSuccess(framesRemaining: 23) == braceSuccess(framesRemaining: 23) → true
//   AC4: braceSuccess(framesRemaining: 23) == braceHit(framesRemaining: 23) → false
//   AC5: TransientOverlay.defaultDuration == 23
//
// Test Budget: 3 distinct behaviors × 2 = 6 max unit tests (using 4)

@Suite struct `TransientOverlay — value type` {

    // AC3: same case, same associated value → equal
    @Test func `braceSuccess with equal framesRemaining is equal to itself`() {
        let a = TransientOverlay.braceSuccess(framesRemaining: 23)
        let b = TransientOverlay.braceSuccess(framesRemaining: 23)
        #expect(a == b)
    }

    // AC4: different cases → not equal
    @Test func `braceSuccess and braceHit with same framesRemaining are not equal`() {
        let a = TransientOverlay.braceSuccess(framesRemaining: 23)
        let b = TransientOverlay.braceHit(framesRemaining: 23)
        #expect(a != b)
    }

    // AC5: defaultDuration constant
    @Test func `defaultDuration equals 23`() {
        #expect(TransientOverlay.defaultDuration == 23)
    }

    // AC2: Sendable conformance — verified at compile time via typed function
    @Test func `all three cases are constructible and Sendable`() {
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        let s = requireSendable(TransientOverlay.braceSuccess(framesRemaining: 1))
        let h = requireSendable(TransientOverlay.braceHit(framesRemaining: 2))
        let d = requireSendable(TransientOverlay.dash(framesRemaining: 3))
        #expect(s != h)
        #expect(h != d)
    }
}
