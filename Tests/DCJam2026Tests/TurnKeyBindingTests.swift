import Testing
@testable import DCJam2026
@testable import GameDomain

// Turn Key Binding Tests — US-TM-05 (InputHandler key bindings)
//
// Driving port: InputHandler — the App module's keyboard-to-command adapter.
//               Tests inject raw byte sequences and assert the returned GameCommand.
//
// Key mappings required (AC-05, WD-06/WD-07):
//   0x61 ('a') and 0x41 ('A') → .turn(.left)
//   0x64 ('d') and 0x44 ('D') → .turn(.right)
//   [0x1B, 0x5B, 0x44] (Arrow Left)  → .turn(.left)
//   [0x1B, 0x5B, 0x43] (Arrow Right) → .turn(.right)
//
// Implementation contract for crafter:
//   InputHandler exposes a public method:
//     func mapKey(bytes: [UInt8]) -> GameCommand?
//   All test bodies call this method.
//
// Note AC-05-8 (controls hint row): out of scope per DSGN-01.
//
// Mandate compliance:
//   CM-A: Tests drive through InputHandler (driving port for input translation).
//   CM-B: Test names describe the key Ember presses and the command it produces.
//   CM-C: Tests validate the observable command that flows into RulesEngine.

@Suite("Turning Mechanic — Turn Key Bindings")
struct TurnKeyBindingTests {

    // MARK: - US-TM-05: A / a key produces turn-left command

    @Test("Pressing lowercase 'a' produces a turn-left command")
    func lowercaseAProducesTurnLeft() {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [0x61])
        #expect(result == .turn(.left))
    }

    @Test("Pressing uppercase 'A' produces a turn-left command")
    func uppercaseAProducesTurnLeft() {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [0x41])
        #expect(result == .turn(.left))
    }

    // MARK: - US-TM-05: D / d key produces turn-right command

    @Test("Pressing lowercase 'd' produces a turn-right command")
    func lowercaseDProducesTurnRight() {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [0x64])
        #expect(result == .turn(.right))
    }

    @Test("Pressing uppercase 'D' produces a turn-right command")
    func uppercaseDProducesTurnRight() {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [0x44])
        #expect(result == .turn(.right))
    }

    // MARK: - US-TM-05: Arrow Left / Right escape sequences

    @Test("Arrow Left escape sequence [ESC [ D] produces a turn-left command")
    func arrowLeftProducesTurnLeft() {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [0x1B, 0x5B, 0x44])
        #expect(result == .turn(.left))
    }

    @Test("Arrow Right escape sequence [ESC [ C] produces a turn-right command")
    func arrowRightProducesTurnRight() {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [0x1B, 0x5B, 0x43])
        #expect(result == .turn(.right))
    }

    // MARK: - US-TM-05: Regression — existing W/S and Arrow Up/Down bindings unchanged

    @Test("Pressing 'w' still produces a move-forward command (regression guard)")
    func wKeyStillProducesMoveForward() {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [0x77])
        #expect(result == .move(.forward))
    }

    @Test("Pressing 's' still produces a move-backward command (regression guard)")
    func sKeyStillProducesMoveBackward() {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [0x73])
        #expect(result == .move(.backward))
    }

    @Test("Arrow Up escape sequence [ESC [ A] still produces move-forward (regression guard)")
    func arrowUpStillProducesMoveForward() {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [0x1B, 0x5B, 0x41])
        #expect(result == .move(.forward))
    }

    @Test("Arrow Down escape sequence [ESC [ B] still produces move-backward (regression guard)")
    func arrowDownStillProducesMoveBackward() {
        let handler = InputHandler()
        let result = handler.mapKey(bytes: [0x1B, 0x5B, 0x42])
        #expect(result == .move(.backward))
    }

    // MARK: - US-TM-05: Rapid turn round-trip

    @Test("Pressing 'd' then 'a' rapidly returns Ember to her original facing")
    func rapidRightThenLeftReturnsToOriginalFacing() {
        let handler = InputHandler()
        let initial = GameState.initial(config: .default)

        // 'd' → .turn(.right), apply to initial state (north → east)
        let rightCommand = handler.mapKey(bytes: [0x64])
        let afterRight = RulesEngine.apply(command: rightCommand, to: initial, deltaTime: 0)

        // 'a' → .turn(.left), apply to turned state (east → north)
        let leftCommand = handler.mapKey(bytes: [0x61])
        let afterLeft = RulesEngine.apply(command: leftCommand, to: afterRight, deltaTime: 0)

        #expect(afterLeft.facingDirection == initial.facingDirection)
    }
}
