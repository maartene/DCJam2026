# Data Models — handcrafted-maps

**Feature**: handcrafted-maps
**Wave**: DESIGN
**Date**: 2026-04-04

---

## 1. `FloorDefinition`

### Struct Fields

| Field | Type | Description |
|-------|------|-------------|
| `grid` | `String` | Multi-line character grid as a Swift `"""` string. Each line is one row. Row 0 (first line) = south (bottom of minimap). Last line = north (top of minimap). Column 0 = westmost character of each line. |

**Derived dimensions** (not stored — computed by `FloorDefinitionParser` at parse time):
- `width` = character count of any single row (all rows must be equal length)
- `height` = number of lines (after `.split(separator: "\n")`)

**Size constraint**: height must be ≤ 7. Width must be ≤ 19. These are authoring constraints; no runtime enforcement at jam scope.

### Swift declaration shape (for crafter reference)

```
public struct FloorDefinition: Sendable {
    public let grid: String
    public init(grid: String)
}
```

No methods. No computed properties. Pure data.

### Character Vocabulary

| Character | Meaning | Passable | Notes |
|-----------|---------|----------|-------|
| `#` | Wall | No | Impassable. All cells not in a corridor should be `#`. |
| `.` | Floor (empty) | Yes | Generic passable corridor cell with no landmark. |
| `^` | Player entry, facing north | Yes | Player starts here, facing north. |
| `>` | Player entry, facing east | Yes | Player starts here, facing east. |
| `v` | Player entry, facing south | Yes | Player starts here, facing south. |
| `<` | Player entry, facing west | Yes | Player starts here, facing west. |
| `E` | Entry point (no facing info) | Yes | Alternative entry marker — used when a separate entry marker without facing is preferred. Parser resolves facing from context. |
| `G` | Guard encounter | Yes | Position where stepping in triggers a standard combat encounter. |
| `B` | Boss encounter | Yes | Position where stepping in triggers the boss encounter (Head Warden). Floor 5 only. |
| `*` | Egg room | Yes | Position where Ember finds the stolen egg. Floors 2-4 only. |
| `S` | Staircase | Yes | Transition to the next floor. Floors 1-4 only. |
| `X` | Exit | Yes | Win condition position. Floor 5 only. Requires `hasEgg` to trigger win. |

### Coordinate Convention

Consistent with existing `FloorGenerator` and `FloorGrid`:
- Origin `(0, 0)` = south-west corner
- X increases eastward (column index within a row string)
- Y increases northward (row index from the **bottom** of the `rows` array)
- `rows[0]` = southernmost row (y=0)
- `rows[height - 1]` = northernmost row (y = height - 1)

This means: to access the character at `Position(x: col, y: row_from_south)`, use `rows[row_from_south][col_index]`.

**Visual example** — Floor 1 (L-shaped, 15×7):
```
line 0  "######S########"    y=6 (north) — S at col 7
line 1  "######.########"    y=5
line 2  "##*....G.######"    y=4 — * at col 2, G at col 7, branch x=2..7
line 3  "######.########"    y=3
line 4  "######.########"    y=2
line 5  "######^########"    y=1 — entry at col 7
line 6  "###############"    y=0 (south) — bottom wall row
        0123456789...14
```

As a `"""` literal (note: lines are ordered north-to-south in the string — line 0 = northernmost row = y=height-1):
```swift
let floor1 = FloorDefinition(grid: """
    ######S########
    ######.########
    ##*....G.######
    ######.########
    ######.########
    ######^########
    ###############
    """)
```

`FloorDefinitionParser` splits on `"\n"`, then maps `splitResult[i]` to `y = (height - 1) - i` so that `splitResult[0]` (first line in the `"""` block) corresponds to the northernmost row (y = height - 1). This keeps the visual orientation correct: north is at the top of the `"""` block, south at the bottom.

Note: cells at branch positions (y=4, x=2..7) and main corridor (x=7, y=1..6) are passable. All other cells are `#`.

---

## 2. `FloorDefinitionParser` — Parsing Contract

### Input
- A `FloorDefinition` (multi-line string grid). The parser calls `definition.grid.split(separator: "\n")` to obtain per-row substrings before scanning.

### Output (named struct or tuple — implementation detail for crafter)

| Field | Type | Populated from |
|-------|------|----------------|
| `grid` | `FloorGrid` | All cells: `#` → `isPassable: false`; all other vocab chars → `isPassable: true` |
| `entryPosition` | `Position?` | First occurrence of `^`, `>`, `v`, `<`, or `E` |
| `entryFacing` | `CardinalDirection?` | From entry character: `^`→north, `>`→east, `v`→south, `<`→west, `E`→north (default) |
| `staircasePosition` | `Position?` | First occurrence of `S` |
| `eggPosition` | `Position?` | First occurrence of `*` |
| `encounterPosition` | `Position?` | First occurrence of `G` |
| `bossPosition` | `Position?` | First occurrence of `B` |
| `exitPosition` | `Position?` | First occurrence of `X` |

### Scanning Order

Row-major, row 0 first (south to north), left-to-right within each row. First match wins for each landmark type. Duplicate landmarks in the grid are a developer authoring error — no runtime validation required at jam scope.

### Coordinate Mapping

After splitting `definition.grid` on `"\n"` into `splitRows` of length `height`:
- `splitRows[0]` = northernmost row = `y = height - 1`
- `splitRows[height - 1]` = southernmost row = `y = 0`
- Formula: `splitRows[i][colIndex]` maps to `Position(x: colIndex, y: (height - 1) - i)`

This preserves the visual convention that north appears at the top of the `"""` block.

---

## 3. `FloorRegistry` — Structure

### Interface

```
public enum FloorRegistry {
    public static func floor(_ floorNumber: Int, config: GameConfig) -> FloorMap
}
```

### Internal Structure

```
enum FloorRegistry {
    private static let floor1: FloorDefinition = ...  // L-shape — authored by crafter
    private static let floor2: FloorDefinition = ...  // placeholder — to be authored by developer
    private static let floor3: FloorDefinition = ...  // placeholder — to be authored by developer
    private static let floor4: FloorDefinition = ...  // placeholder — to be authored by developer
    private static let floor5: FloorDefinition = ...  // placeholder — to be authored by developer

    static func floor(_ floorNumber: Int, config: GameConfig) -> FloorMap {
        let definition = definition(for: floorNumber)
        let parsed = FloorDefinitionParser.parse(definition)
        return FloorMap(
            floorNumber: floorNumber,
            hasEggRoom: parsed.eggPosition != nil,
            hasBossEncounter: parsed.bossPosition != nil,
            hasExitSquare: parsed.exitPosition != nil,
            isNavigable: true,
            entryPosition2D: parsed.entryPosition ?? Position(x: 0, y: 0),
            staircasePosition2D: parsed.staircasePosition ?? Position(x: 0, y: 0),
            exitPosition2D: parsed.exitPosition ?? parsed.staircasePosition ?? Position(x: 0, y: 0),
            eggRoomPosition2D: parsed.eggPosition,
            encounterPosition2D: parsed.encounterPosition ?? parsed.bossPosition,
            grid: parsed.grid
        )
    }

    private static func definition(for floorNumber: Int) -> FloorDefinition {
        switch floorNumber {
        case 1: return floor1
        case 2: return floor2
        case 3: return floor3
        case 4: return floor4
        case 5: return floor5
        default: return floor1  // safe fallback; should not occur in jam scope
        }
    }
}
```

The crafter provides floor 1 as a complete character grid. Floors 2–5 should be placeholder `FloorDefinition` stubs — a minimal valid grid (e.g., a single-corridor 3×3 layout) that compiles and allows the game to run. The developer will replace these with the final authored layouts. The five `FloorDefinition` constants may be inlined in `FloorRegistry` or extracted to `HandcraftedFloors.swift` — the crafter decides based on file length.

---

## 4. Floor Layout Specifications

**Authoring responsibility**: The crafter authors floor 1 only. Floors 2–5 are developer-authored after the crafter's migration is complete. See DEC-DESIGN-09.

**Size constraint**: all floors must be ≤19 wide and ≤7 tall.

---

### Floor 1 — L-shaped corridor (15×7) — crafter-authored

Matches `FloorGenerator` topology. This is the safe migration gate (AC-HM-02-A).

| Landmark | Position |
|----------|----------|
| Entry (`^`) | (7, 1) — one row above south wall, facing north |
| Guard (`G`) | (7, 4) — junction of main corridor and branch |
| Egg room | absent (no `*`) |
| Staircase (`S`) | (7, 6) — north end |
| Boss | absent |
| Exit | absent |

Passable cells: `x=7` for y=1..6 (main corridor) + `y=4, x=2..7` (east-west branch).

Character grid (`"""` block, north at top):

```
######S########    y=6 (north)
######.########    y=5
##*....G.######    y=4
######.########    y=3
######.########    y=2
######^########    y=1
###############    y=0 (south) — bottom wall row
```

---

### Floors 2–5 — developer-authored (out of scope for crafter)

The crafter leaves floors 2–5 as minimal placeholder stubs that compile and allow the game to run. The developer will replace these with final authored layouts. Placeholders must be valid `FloorDefinition` values (at least 1 row, all rows equal length, at least one entry marker `^` and one staircase or exit `S`/`X` so `FloorRegistry` constructs a navigable `FloorMap`).

No topology specifications are provided here for floors 2–5. The developer authors these grids freely within the ≤19×7 size constraint.

---

## 5. `FloorMap` — No Changes

The `FloorMap` struct (in `FloorMap.swift`) is unchanged. `FloorRegistry.floor` returns the same `FloorMap` type with the same fields. All existing callers in `RulesEngine`, `Renderer`, and tests work without modification.

The `GameRun` struct is also unchanged — `FloorGenerator.generateRun` still compiles and produces `GameRun` values correctly.
