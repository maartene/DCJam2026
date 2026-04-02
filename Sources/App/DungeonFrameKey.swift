// DungeonFrameKey — lookup key for first-person dungeon corridor frames.

struct DungeonFrameKey: Hashable, Sendable {
    let depth: Int       // 0=close wall, 1=mid wall, 2=far wall (brick), 3=fog
    let nearLeft: Bool   // opening at player's square going left
    let nearRight: Bool  // opening at player's square going right
    let farLeft: Bool    // opening one square ahead going left (depth >= 1 only)
    let farRight: Bool   // opening one square ahead going right (depth >= 1 only)

    init(depth: Int, nearLeft: Bool, nearRight: Bool, farLeft: Bool, farRight: Bool) {
        self.depth = depth
        self.nearLeft = nearLeft
        self.nearRight = nearRight
        self.farLeft = farLeft
        self.farRight = farRight
    }
}
