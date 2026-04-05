// FloorDefinition — pure data container for a character-grid floor layout.

public struct FloorDefinition: Sendable {
    /// Multi-line character grid. North is the first line (highest y).
    /// Each character encodes a cell: '#' = wall, others = passable.
    /// Landmark characters: '^'=entry(N) 'v'=entry(S) '<'=entry(W) '>'=entry(E)
    ///   'E'=entry, 'S'=staircase, 'G'=guard encounter, 'B'=boss, '*'=egg room, 'X'=exit
    public let grid: String

    public init(grid: String) {
        self.grid = grid
    }
}
