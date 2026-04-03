import Testing
@testable import DCJam2026

// Quit Key Binding Tests — game-polish-v1 step 03-01
//
// Driving port: InputHandler
// Acceptance criteria:
//   - 'q' (0x71) returns .none and does NOT set shouldQuit
//   - 'Q' (0x51) returns .none and does NOT set shouldQuit
//   - ESC (0x1B) still sets shouldQuit (regression guard)

@Suite struct `Quit Key Bindings — Q removed, ESC only` {

    // MARK: - AC: q / Q no longer quit

    @Test(arguments: [UInt8(0x71), UInt8(0x51)])
    func `Pressing q or Q returns none without setting shouldQuit`(byte: UInt8) {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [byte])
        #expect(result == .none)
        #expect(handler.shouldQuit == false)
    }

    // MARK: - AC: ESC still quits (regression guard)

    @Test func `Pressing ESC still sets shouldQuit to true`() {
        let handler = InputHandler()
        _ = handler.mapKey(bytes: [0x1B])
        #expect(handler.shouldQuit == true)
    }
}
