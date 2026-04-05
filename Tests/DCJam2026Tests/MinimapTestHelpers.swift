import Testing
@testable import DCJam2026
@testable import GameDomain

// Shared helpers for all minimap test suites.
//
// Layout constants (DEC-DESIGN-05/06):
//   Row 2, cols 61-79  = floor label
//   Rows 3-9,  cols 61-79 = minimap grid (height = 7, 0-indexed from bottom)
//   Rows 10-16, cols 61-79 = minimap legend
//
// Cell coordinate formulae:
//   screenRow = 3 + (6 - y)   (where 7 is the grid height)
//   screenCol = 61 + x

// MARK: - ANSI

/// Strips ANSI escape sequences from a string.
func stripANSI(_ s: String) -> String {
    var result = ""
    var i = s.startIndex
    while i < s.endIndex {
        if s[i] == "\u{1B}", s.index(after: i) < s.endIndex, s[s.index(after: i)] == "[" {
            var j = s.index(after: s.index(after: i))
            while j < s.endIndex && s[j] != "m" { j = s.index(after: j) }
            if j < s.endIndex { j = s.index(after: j) }
            i = j
        } else {
            result.append(s[i])
            i = s.index(after: i)
        }
    }
    return result
}

// MARK: - Cell accessors

/// Raw content (ANSI intact) at minimap grid position (x, y).
/// Use for color assertions.
func minimapContent(x: Int, y: Int, spy: TUIOutputSpy) -> String {
    let targetRow = 3 + (6 - y)
    let targetCol = 61 + x
    return spy.entries
        .filter { $0.row == targetRow && $0.col == targetCol }
        .map(\.string)
        .joined()
}

/// Visible character at minimap grid position (x, y), ANSI stripped.
/// Use for symbol / character assertions.
func minimapChar(x: Int, y: Int, spy: TUIOutputSpy) -> Character? {
    return stripANSI(minimapContent(x: x, y: y, spy: spy)).first
}

// MARK: - Rendering

/// Creates a spy, renders state through the Renderer driving port, and returns the spy.
func render(_ state: GameState) -> TUIOutputSpy {
    let spy = TUIOutputSpy()
    Renderer(output: spy).render(state)
    return spy
}
