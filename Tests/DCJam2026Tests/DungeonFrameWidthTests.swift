import Testing
@testable import DCJam2026

// DungeonFrameWidth Tests — Step 05-03
//
// Driving port: buildFrameTable() — module-level function returning all frame art.
// Behavior: all frame art strings fit within the 58-column dungeon view interior.
//
// Mandate compliance:
//   CM-A: Tests invoke buildFrameTable() (driving port), not individual private frame functions.
//   CM-B: Test names use game domain terms (frame art, dungeon view, column width).
//   CM-C: Tests validate observable outcome: maximum line width of all frame strings ≤ 58.
//
// Test Budget: 1 distinct behavior × 2 = 2 max unit tests
//   B1: All frame art lines are ≤ 58 characters wide (fits in 58-col dungeon view panel)
// Total tests used: 1 (within budget)

@Suite("DungeonFrameWidth — all frame art fits within 58-column dungeon view")
struct DungeonFrameWidthTests {

    private static let maxWidth = 58

    @Test("all frame art lines are at most 58 characters wide")
    func allFrameLinesAreAtMost58CharsWide() {
        let table = buildFrameTable()
        var violations: [(key: String, lineIndex: Int, width: Int, content: String)] = []

        for (key, lines) in table {
            for (i, line) in lines.enumerated() {
                let w = line.count
                if w > Self.maxWidth {
                    violations.append((key: "\(key)", lineIndex: i, width: w, content: line))
                }
            }
        }

        #expect(violations.isEmpty,
            "Frame art overflow detected (\(violations.count) violation(s)). First: key=\(violations.first?.key ?? ""), line=\(violations.first?.lineIndex ?? -1), width=\(violations.first?.width ?? 0)")
    }
}
