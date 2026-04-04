import Testing
@testable import DCJam2026
@testable import GameDomain

// Start screen version number tests — step 01-01
//
// Acceptance criteria:
//   AC1: start screen rendered output contains a string matching 'v\d+\.\d+\.\d+'
//   AC2: version string is written at row 25, col 1 (lower-left corner)
//   AC3: dungeon screen rendered output does NOT contain the version string
//   AC4: version string is defined as a named constant AppVersion.current (not magic inline string)
//
// Test budget: 4 behaviors × 2 = 8 max. Using 5 tests (4 AC + 1 unit for AppVersion).

@Suite struct `Renderer — Start Screen Version` {

    private func capturedOutput(screenMode: ScreenMode) -> [TUIOutputSpy.Entry] {
        let spy = TUIOutputSpy()
        let renderer = Renderer(output: spy)
        var state = GameState.initial(config: .default)
        state = state.withScreenMode(screenMode)
        renderer.render(state)
        return spy.entries
    }

    private func allText(screenMode: ScreenMode) -> String {
        capturedOutput(screenMode: screenMode).map(\.string).joined()
    }

    // AC1: start screen contains a version string matching semver pattern
    @Test func `start screen output contains version string`() {
        let text = allText(screenMode: .startScreen)
        let plain = stripANSI(text)
        let versionPattern = /v\d+\.\d+\.\d+/
        #expect(plain.contains(versionPattern), "Start screen must contain a version string matching 'v\\d+.\\d+.\\d+', got: \(plain)")
    }

    // AC2: version string is written at row 25, col 1
    @Test func `start screen writes version at row 25 col 1`() {
        let entries = capturedOutput(screenMode: .startScreen)
        let versionEntry = entries.first { entry in
            entry.row == 25 && entry.col == 1 && stripANSI(entry.string).contains(/v\d+\.\d+\.\d+/)
        }
        #expect(versionEntry != nil, "Start screen must write version string at row 25 col 1, entries at row 25: \(entries.filter { $0.row == 25 }.map { "(\($0.row),\($0.col)): \($0.string)" })")
    }

    // AC3: dungeon screen does NOT contain the version string at row 25 col 1
    @Test func `dungeon screen does not write version at row 25 col 1`() {
        let entries = capturedOutput(screenMode: .dungeon)
        let versionEntry = entries.first { entry in
            entry.row == 25 && entry.col == 1 && stripANSI(entry.string).contains(/v\d+\.\d+\.\d+/)
        }
        #expect(versionEntry == nil, "Dungeon mode must NOT write version string at row 25 col 1")
    }

    // AC4: AppVersion.current is accessible and matches the version pattern
    @Test func `AppVersion current matches semver pattern`() {
        let version = AppVersion.current
        let versionPattern = /v\d+\.\d+\.\d+/
        #expect(version.contains(versionPattern), "AppVersion.current must match 'v\\d+.\\d+.\\d+', got: \(version)")
    }

    private func stripANSI(_ s: String) -> String {
        var result = ""
        var i = s.startIndex
        while i < s.endIndex {
            if s[i] == "\u{1B}", s.index(after: i) < s.endIndex, s[s.index(after: i)] == "[" {
                i = s.index(after: i)
                i = s.index(after: i)
                while i < s.endIndex && !s[i].isLetter {
                    i = s.index(after: i)
                }
                if i < s.endIndex { i = s.index(after: i) }
            } else {
                result.append(s[i])
                i = s.index(after: i)
            }
        }
        return result
    }
}
