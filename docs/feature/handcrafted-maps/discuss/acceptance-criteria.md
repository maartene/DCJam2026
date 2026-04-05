# Acceptance Criteria — handcrafted-maps

**Feature**: handcrafted-maps
**Date**: 2026-04-04
**Testing framework**: Swift Testing (`import Testing`, `#expect`, `@Suite`, `@Test`)

All tests use the driving port pattern established in the codebase:
- Domain logic: `RulesEngine.apply(command:to:deltaTime:)` or `FloorRegistry.floor(_:config:)`
- Rendering: `Renderer(output: TUIOutputSpy()).render(state)`

---

## AC-HM-01: FloorDefinition data type

### AC-HM-01-A: FloorDefinition holds character grid dimensions
```swift
@Test func `FloorDefinition rows count and width match authored grid`() {
    let rows = [
        "###################",
        "#.................#",
        "#.................#",
        "#.................#",
        "#.................#",
        "#.................#",
        "#.................#",
        "#.................#",
        "#.................#",
        "###################"
    ]
    let def = FloorDefinition(rows: rows)
    #expect(def.rows.count == 10)
    #expect(def.rows[0].count == 19)
}
```

### AC-HM-01-B: FloorDefinition character grid encodes landmarks inline
```swift
@Test func `FloorDefinition character grid — entry marker and walls parsed correctly`() {
    // Minimal L-shape floor 1 representation (abbreviated for clarity)
    let rows = [
        "###############",
        "#......^......#",  // ^ at col 7 = entry facing north
        "#......G......#",  // G at col 7 = guard encounter
        "#..####.......#",
        "#..#..........#",
        "#..#..S.......#",  // S = staircase
        "###############"
    ]
    let def = FloorDefinition(rows: rows)
    #expect(def.rows[1].contains("^"))
    #expect(def.rows[2].contains("G"))
    #expect(def.rows[5].contains("S"))
    // Passability: '#' is wall, all others are passable
    #expect(def.rows[0].first == "#")  // top border is wall
}
```

---

## AC-HM-02: FloorRegistry

### AC-HM-02-A: Floor 1 matches FloorGenerator output (safe migration gate)
// This test MUST pass before floors 2-5 are authored. It is the gate for the migration step:
// the character-grid FloorDefinition for floor 1 must produce a cell-for-cell identical FloorMap.
```swift
@Test func `FloorRegistry floor 1 matches FloorGenerator output`() {
    let regFloor = FloorRegistry.floor(1, config: .default)
    let genFloor = FloorGenerator.generate(floorNumber: 1, config: .default)
    #expect(regFloor.grid.width  == genFloor.grid.width)
    #expect(regFloor.grid.height == genFloor.grid.height)
    #expect(regFloor.entryPosition2D    == genFloor.entryPosition2D)
    #expect(regFloor.staircasePosition2D == genFloor.staircasePosition2D)
    #expect(regFloor.encounterPosition2D == genFloor.encounterPosition2D)
    #expect(regFloor.hasEggRoom         == genFloor.hasEggRoom)
    #expect(regFloor.hasBossEncounter   == genFloor.hasBossEncounter)
    #expect(regFloor.hasExitSquare      == genFloor.hasExitSquare)
    // Verify grid passability at all cells
    for y in 0..<genFloor.grid.height {
        for x in 0..<genFloor.grid.width {
            #expect(regFloor.grid.cell(x: x, y: y).isPassable ==
                    genFloor.grid.cell(x: x, y: y).isPassable,
                    "Cell (\(x),\(y)) passability differs")
        }
    }
}
```

### AC-HM-02-B: Floor 2 has egg room
```swift
@Test func `FloorRegistry floor 2 has egg room at a passable position`() {
    let floor = FloorRegistry.floor(2, config: .default)
    #expect(floor.hasEggRoom == true)
    let eggPos = try #require(floor.eggRoomPosition2D)
    #expect(floor.grid.cell(x: eggPos.x, y: eggPos.y).isPassable)
}
```

### AC-HM-02-C: Floor 5 has boss and exit, no egg
```swift
@Test func `FloorRegistry floor 5 has boss, exit, and no egg room`() {
    let floor = FloorRegistry.floor(5, config: .default)
    #expect(floor.hasBossEncounter == true)
    #expect(floor.hasExitSquare == true)
    #expect(floor.hasEggRoom == false)
    #expect(floor.eggRoomPosition2D == nil)
}
```

### AC-HM-02-D: RulesEngine uses FloorRegistry — movement on floor 2 uses floor 2 grid
```swift
@Test func `Ember moves into a cell that is passable on floor 2 but not at same coords on floor 1`() {
    // This test requires floor 2 to have a passable cell at a position that floor 1 does not.
    // Exact positions depend on floor 2's design (DESIGN wave); test is parameterized by floor definition.
    let floor2 = FloorRegistry.floor(2, config: .default)
    // Find a passable cell on floor 2 that is NOT passable on floor 1
    let floor1 = FloorRegistry.floor(1, config: .default)
    // Identify a distinguishing passable cell in floor 2's grid
    var testPos: Position? = nil
    outer: for y in 0..<floor2.grid.height {
        for x in 0..<floor2.grid.width {
            let f2Passable = floor2.grid.cell(x: x, y: y).isPassable
            let f1Passable = floor1.grid.cell(x: x, y: y).isPassable
            if f2Passable && !f1Passable {
                testPos = Position(x: x, y: y)
                break outer
            }
        }
    }
    guard let dest = testPos else {
        // Floors are identical in passable cells — acceptable only if floor 2 == floor 1 (not expected)
        Issue.record("Floor 2 has no passable cells absent from floor 1 — floors are not distinct")
        return
    }
    // Ember starts adjacent to dest on floor 2, facing so that forward = dest
    let dx = dest.x - floor2.entryPosition2D.x
    let dy = dest.y - floor2.entryPosition2D.y
    // Simple: place ember one step south of dest and face north (dy+1 → dy direction)
    // Exact setup depends on floor 2 topology — this is a sketch; DESIGN wave finalises
    _ = dest  // Referenced to suppress warning; full test authored in DELIVER wave
}
```

*Note: AC-HM-02-D is a sketch scenario. The concrete test body is authored in the DELIVER wave once floor 2's exact topology is defined.*

---

## AC-HM-03: Floor label in top border

### AC-HM-03-A: Floor label appears in row 1 right panel in dungeon mode
```swift
@Test func `Floor label is in the top border row 1 right panel in dungeon mode`() {
    let spy = TUIOutputSpy()
    let state = GameState.initial(config: .default)
        .withCurrentFloor(3)
        .withScreenMode(.dungeon)
    Renderer(output: spy).render(state)
    let row1RightWrites = spy.entries.filter { $0.row == 1 && (61...79).contains($0.col) }
    let text = row1RightWrites.map(\.string).joined()
    #expect(text.contains("Floor 3/5"), "Expected 'Floor 3/5' in row 1 right panel, got: \(text)")
}
```

### AC-HM-03-B: Floor label is absent from row 2 in dungeon mode
```swift
@Test func `Row 2 right panel contains no floor label text in dungeon mode`() {
    let spy = TUIOutputSpy()
    let state = GameState.initial(config: .default)
        .withCurrentFloor(1)
        .withScreenMode(.dungeon)
    Renderer(output: spy).render(state)
    let row2RightWrites = spy.entries.filter { $0.row == 2 && (61...79).contains($0.col) }
    let text = row2RightWrites.map(\.string).joined()
    #expect(!text.contains("Floor"), "Row 2 right panel must not contain 'Floor' label text, got: \(text)")
}
```

### AC-HM-03-C: Floor label absent in combat mode
```swift
@Test func `Floor label is absent from top border in combat mode`() {
    let spy = TUIOutputSpy()
    let state = GameState.initial(config: .default)
        .withCurrentFloor(2)
        .withScreenMode(.combat(encounter: EncounterModel.guard(isBossEncounter: false)))
    Renderer(output: spy).render(state)
    let row1RightWrites = spy.entries.filter { $0.row == 1 && (61...79).contains($0.col) }
    let text = row1RightWrites.map(\.string).joined()
    #expect(!text.contains("Floor"), "Floor label must not appear in combat mode top border, got: \(text)")
}
```

---

## AC-HM-04: Minimap dynamic dimensions

### AC-HM-04-A: Floor 1 minimap entry cell at correct screen position
```swift
@Test func `Floor 1 minimap entry cell renders at screen row 8 col 68`() {
    let spy = TUIOutputSpy()
    let floor = FloorRegistry.floor(1, config: .default)
    let state = GameState.initial(config: .default).withScreenMode(.dungeon)
    Renderer(output: spy).render(state)
    // Entry at (7, 0); screenRow = 2 + (floor.grid.height - 1 - 0) = 2 + 6 = 8; col = 61 + 7 = 68
    let expectedRow = 2 + (floor.grid.height - 1 - 0)
    let expectedCol = 61 + floor.entryPosition2D.x
    let writes = spy.entries.filter { $0.row == expectedRow && $0.col == expectedCol }
    #expect(!writes.isEmpty, "Expected minimap write at row \(expectedRow) col \(expectedCol)")
}
```

### AC-HM-04-B: No minimap write beyond col 79 for any floor
```swift
@Test func `No minimap write exceeds col 79 for any floor`() {
    for floorNum in 1...5 {
        let spy = TUIOutputSpy()
        let state = GameState.initial(config: .default)
            .withCurrentFloor(floorNum)
            .withScreenMode(.dungeon)
        Renderer(output: spy).render(state)
        let overflowWrites = spy.entries.filter { (2...16).contains($0.row) && $0.col > 79 }
        #expect(overflowWrites.isEmpty,
                "Floor \(floorNum): minimap writes at col > 79: \(overflowWrites.map { $0.col })")
    }
}
```

### AC-HM-04-C: No minimap write outside rows 2-16 for any floor
```swift
@Test func `No minimap write is outside rows 2-16 for any floor`() {
    for floorNum in 1...5 {
        let spy = TUIOutputSpy()
        let state = GameState.initial(config: .default)
            .withCurrentFloor(floorNum)
            .withScreenMode(.dungeon)
        Renderer(output: spy).render(state)
        // Filter writes that are in the right panel column range but wrong row range
        let rightPanelOutOfRange = spy.entries.filter {
            (61...79).contains($0.col) && !((2...16).contains($0.row))
        }
        #expect(rightPanelOutOfRange.isEmpty,
                "Floor \(floorNum): minimap writes outside rows 2-16: \(rightPanelOutOfRange.map { ($0.row, $0.col) })")
    }
}
```

---

## AC-HM-05: Five distinct floors

### AC-HM-05-A: All landmark positions are on passable cells
```swift
@Test func `All landmark positions are passable for all 5 floors`() {
    for floorNum in 1...5 {
        let floor = FloorRegistry.floor(floorNum, config: .default)
        let entry = floor.entryPosition2D
        #expect(floor.grid.cell(x: entry.x, y: entry.y).isPassable,
                "Floor \(floorNum): entry \(entry) is not passable")
        if !floor.hasExitSquare {
            let stairs = floor.staircasePosition2D
            #expect(floor.grid.cell(x: stairs.x, y: stairs.y).isPassable,
                    "Floor \(floorNum): staircase \(stairs) is not passable")
        }
        if let eggPos = floor.eggRoomPosition2D {
            #expect(floor.grid.cell(x: eggPos.x, y: eggPos.y).isPassable,
                    "Floor \(floorNum): egg room \(eggPos) is not passable")
        }
        if let encounterPos = floor.encounterPosition2D {
            #expect(floor.grid.cell(x: encounterPos.x, y: encounterPos.y).isPassable,
                    "Floor \(floorNum): encounter \(encounterPos) is not passable")
        }
    }
}
```

### AC-HM-05-B: Floors 2-4 have egg room, floor 1 and 5 do not
```swift
@Test func `Egg room rule: floors 2-4 have egg room, floors 1 and 5 do not`() {
    let config = GameConfig.default
    #expect(FloorRegistry.floor(1, config: config).hasEggRoom == false)
    #expect(FloorRegistry.floor(2, config: config).hasEggRoom == true)
    #expect(FloorRegistry.floor(3, config: config).hasEggRoom == true)
    #expect(FloorRegistry.floor(4, config: config).hasEggRoom == true)
    #expect(FloorRegistry.floor(5, config: config).hasEggRoom == false)
}
```

### AC-HM-05-C: All floors within size constraints
```swift
@Test func `All floors are within the 19x15 terminal constraint`() {
    for floorNum in 1...5 {
        let floor = FloorRegistry.floor(floorNum, config: .default)
        #expect(floor.grid.width  <= 19, "Floor \(floorNum) width \(floor.grid.width) exceeds 19")
        #expect(floor.grid.height <= 15, "Floor \(floorNum) height \(floor.grid.height) exceeds 15")
    }
}
```

### AC-HM-05-D: No two consecutive floors have identical dimensions and topology
```swift
@Test func `No two floors have identical grid width, height, and entry position`() {
    let floors = (1...5).map { FloorRegistry.floor($0, config: .default) }
    for i in 0..<floors.count {
        for j in (i+1)..<floors.count {
            let fi = floors[i], fj = floors[j]
            let sameDims = fi.grid.width == fj.grid.width && fi.grid.height == fj.grid.height
            let sameEntry = fi.entryPosition2D == fj.entryPosition2D
            // Topology differs if dimensions or entry differ (full grid equality check is expensive)
            #expect(!(sameDims && sameEntry),
                    "Floors \(i+1) and \(j+1) may have identical topology — check for distinct layouts")
        }
    }
}
```

*Note: This test is intentionally conservative — it checks a proxy for distinctness. Visual inspection by the developer is the definitive confirmation.*
