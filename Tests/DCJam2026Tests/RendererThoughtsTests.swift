import Testing
@testable import DCJam2026
@testable import GameDomain

// Captures every (row, col, string) triple written through the port.
final class TUIOutputSpy: TUIOutputPort {
    struct Entry { let row: Int; let col: Int; let string: String }
    var entries: [Entry] = []
    private var currentRow = 0
    private var currentCol = 0

    func write(_ string: String) { entries.append(Entry(row: currentRow, col: currentCol, string: string)) }
    func moveCursor(row: Int, col: Int) { currentRow = row; currentCol = col }
    func clearScreen() {}
    func hideCursor() {}
    func showCursor() {}
    func flush() {}
}

@Suite struct `Renderer — Thoughts wrapping` {

    // Rows 21-24 are the Thoughts content rows; each write starts at col 2 and must fit
    // in 78 chars (cols 2-79 of the 80-column terminal).
    @Test func `Thoughts rows never exceed 78 characters`() {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        let state = GameState.initial(config: .default)
        renderer.render(state)
        let thoughtsWrites = spy.entries.filter { (21...24).contains($0.row) }
        for entry in thoughtsWrites {
            #expect(entry.string.count <= 78,
                    "Thoughts row \(entry.row) exceeds 78 chars: \"\(entry.string)\"")
        }
    }
}
