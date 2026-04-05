<!-- markdownlint-disable MD024 -->
# User Stories — handcrafted-maps

**Feature**: handcrafted-maps
**Date**: 2026-04-04

---

## US-HM-01: FloorDefinition data type

### Problem
Maartene is a solo developer who needs to express distinct floor layouts as static data. They find it tedious and error-prone to encode layout decisions inside a generation algorithm — changing one floor risks breaking all floors.

### Who
- Solo developer | Authoring floor layouts in Swift source | Wants a clear, self-documenting data structure with no hidden logic

### Solution
A `FloorDefinition` struct in `GameDomain` that holds all floor data as a `[String]` character grid — an array of strings, one per row. Landmark positions are encoded as characters in the grid (`^`/`>`/`v`/`<` for entry, `G` for guard, `B` for boss, `*` for egg room, `S` for stairs, `X` for exit). `FloorRegistry` scans the grid once to extract positions when constructing a `FloorMap`. No logic in `FloorDefinition` itself — pure data.

### Domain Examples

#### 1: Floor 1 happy path — L-shape expressed as character grid (safe migration)
Maartene converts the current L-shape to a `FloorDefinition` using the character grid format. The `rows` field is a `[String]` where each string is one row, `^` marks the entry at column 7 row 0, `S` marks the staircase, `G` marks the guard encounter, `#` marks walls, `.` marks passable floor. The struct compiles. All existing movement and minimap tests pass without modification — the topology is byte-for-byte identical to the current `FloorGenerator` output.

#### 2: Floor 3 T-junction — wider, taller grid
Maartene defines floor 3 as a `[String]` with 10 rows each 19 characters wide. The T-arm is visible in the character pattern. `*` marks the egg room on the west branch, `S` marks the staircase at the north end. The struct compiles without modification to any other file.

#### 3: Floor 5 edge case — exit present, egg absent, boss present
Maartene defines floor 5 as a `[String]` with 8 rows, 13 characters wide. `B` appears at position (x=6, y=4), `X` at position (x=6, y=7). No `*` character anywhere in the grid. All floor-5-specific invariants are expressed without conditional logic — the character grid states what's there.

### UAT Scenarios (BDD)

#### Scenario: FloorDefinition holds character grid for floor 1 (safe migration)
```
Given Maartene defines a FloorDefinition with a [String] character grid
      representing the existing L-shape (15 chars wide, 7 rows),
      with ^ at row 0 col 7, S at row 6 col 7, G at row 2 col 7, no * anywhere
When  the FloorDefinition is instantiated
Then  floorDef.rows.count == 7
And   floorDef.rows[0].count == 15
And   floorDef.rows[0][floorDef.rows[0].index(floorDef.rows[0].startIndex, offsetBy: 7)] == "^"
And   the FloorMap built from this definition has entryPosition == Position(x: 7, y: 0)
And   the FloorMap built from this definition has hasEggRoom == false
```

#### Scenario: FloorDefinition for a 19-wide floor compiles without modification elsewhere
```
Given Maartene defines a FloorDefinition with rows of 19 characters wide, 10 rows
When  the project compiles (swift build)
Then  compilation succeeds
And   no changes are required outside of the floor definition file
```

#### Scenario: FloorDefinition for floor 5 has exit and boss, no egg
```
Given Maartene defines a FloorDefinition whose rows contain B at (x=6,y=4), X at (x=6,y=7),
      and no * character anywhere
When  FloorRegistry builds a FloorMap from this definition
Then  floorMap.hasBossEncounter == true
And   floorMap.hasExitSquare == true
And   floorMap.hasEggRoom == false
```

### Acceptance Criteria
- [ ] `FloorDefinition` struct compiles in `GameDomain` with no imports from other modules
- [ ] Grid field is `[String]` (array of strings, one per row; each character is one cell)
- [ ] Character vocabulary is documented: `#` wall, `.` floor, `^>`v<` entry+facing, `G` guard, `B` boss, `*` egg room, `S` stairs, `X` exit, `E` entry point
- [ ] `FloorDefinition` for floor 1 produces a `FloorMap` cell-for-cell identical to the current `FloorGenerator` output (safe migration — no visible change)
- [ ] Instantiating `FloorDefinition` with rows up to 19 chars wide and 15 rows tall compiles successfully
- [ ] `FloorDefinition` has no methods or computed properties — data only

### Outcome KPIs
- **Who**: Developer (Maartene)
- **Does what**: Authors a new floor layout without touching generation logic
- **By how much**: 5 of 5 floor definitions authored, zero FloorGenerator modifications
- **Measured by**: Compilation success + test pass on floor 1 data matching current output
- **Baseline**: Currently impossible — FloorGenerator has no data-authoring interface

### Technical Notes
- Pure Swift value type; `Sendable` required (matches FloorMap's conformance)
- Lives in `GameDomain` module (zero external imports)
- `[String]` character grid is the authoring format; `FloorRegistry` parses characters into `FloorGrid` cells and scans for landmark positions when constructing `FloorMap`
- The safe migration step (floor 1 only, identical topology) must be the first commit — no new floor topologies until all existing tests are green with the new format

---

## US-HM-02: FloorRegistry replaces FloorGenerator

### Problem
Maartene is a developer who needs the game to serve different floor layouts per floor number. They find it impractical that `FloorGenerator` is hardcoded — every call returns the same L-shape regardless of floor number.

### Who
- Developer + game engine | RulesEngine and Renderer need different floors per floor number | Zero API change at call sites

### Solution
A `FloorRegistry` stateless namespace in `GameDomain` with `floor(_ floorNumber: Int, config: GameConfig) -> FloorMap`. All `FloorGenerator.generate(floorNumber:config:)` call sites in `RulesEngine` and `Renderer` are replaced with `FloorRegistry.floor(_:config:)`.

### Domain Examples

#### 1: RulesEngine movement uses FloorRegistry for floor 2
Rowan is on floor 2. They move north. `RulesEngine.applyMove` calls `FloorRegistry.floor(2, config: state.config)`. The returned `FloorMap` has floor 2's T-junction grid. Movement is blocked by walls in the correct positions for that topology.

#### 2: Renderer uses FloorRegistry for dungeon view
The renderer renders floor 3. It calls `FloorRegistry.floor(3, config: state.config)`. The returned `FloorMap`'s grid drives the `DungeonFrameKey` computation. The first-person view shows the correct corridor ahead.

#### 3: Floor 1 via FloorRegistry — existing tests pass
All existing `TwoDFloorTests` and `MinimapTests` call `FloorGenerator.generate(floorNumber: 1, ...)` directly. `FloorRegistry.floor(1, ...)` returns an identical `FloorMap`. Tests continue to pass. (Tests that call `FloorGenerator` directly still pass because `FloorGenerator` is not removed.)

### UAT Scenarios (BDD)

#### Scenario: FloorRegistry returns correct FloorMap for floor 1 (regression)
```
Given FloorRegistry exists and floor 1 is registered
When  FloorRegistry.floor(1, config: .default) is called
Then  the returned FloorMap.grid.width == 15
And   the returned FloorMap.grid.height == 7
And   the returned FloorMap.entryPosition2D == Position(x: 7, y: 0)
And   the returned FloorMap.staircasePosition2D == Position(x: 7, y: 6)
And   the returned FloorMap.hasEggRoom == false
And   the returned FloorMap.hasBossEncounter == false
```

#### Scenario: FloorRegistry returns egg room on floor 2
```
Given FloorRegistry exists and floor 2 is registered with an egg room
When  FloorRegistry.floor(2, config: .default) is called
Then  the returned FloorMap.hasEggRoom == true
And   the returned FloorMap.eggRoomPosition2D is not nil
And   the egg room position is on a passable cell in floor 2's grid
```

#### Scenario: FloorRegistry returns boss + exit on floor 5
```
Given FloorRegistry exists and floor 5 is registered
When  FloorRegistry.floor(5, config: .default) is called
Then  the returned FloorMap.hasBossEncounter == true
And   the returned FloorMap.hasExitSquare == true
And   the returned FloorMap.hasEggRoom == false
```

#### Scenario: RulesEngine movement applies floor 2's grid (not floor 1's)
```
Given Ember is on floor 2 at the entry position
And   floor 2's grid has a passable cell at Position(x: 9, y: 1) that floor 1 does not
When  Ember moves north (forward while facing north) to Position(x: 9, y: 1)
Then  movement succeeds (playerPosition.y == 1)
```

#### Scenario: All existing floor navigation tests pass
```
Given the test suite (swift test)
When  FloorGenerator call sites in RulesEngine and Renderer are replaced with FloorRegistry
Then  all tests in TwoDFloorTests, MinimapTests, FloorNavigationTests pass
```

### Acceptance Criteria
- [ ] `FloorRegistry.floor(_ floorNumber: Int, config: GameConfig) -> FloorMap` compiles in `GameDomain`
- [ ] `RulesEngine.applyMove` uses `FloorRegistry.floor` (not `FloorGenerator.generate`)
- [ ] `RulesEngine.applySpecial` uses `FloorRegistry.floor` (not `FloorGenerator.generate`)
- [ ] `Renderer.renderDungeon` uses `FloorRegistry.floor` (not `FloorGenerator.generate`)
- [ ] `FloorRegistry.floor(1, config: .default)` returns a `FloorMap` identical to `FloorGenerator.generate(floorNumber: 1, config: .default)`
- [ ] `swift test` passes with zero failures after substitution

### Outcome KPIs
- **Who**: Developer (Maartene) and game engine (RulesEngine, Renderer)
- **Does what**: Game serves distinct floor data per floor number at runtime
- **By how much**: 5 floors × 1 correct FloorMap each = 5/5 floor lookups correct
- **Measured by**: `swift test` green; in-game each floor returns its own topology
- **Baseline**: Currently 5/5 floors return identical L-shape

### Technical Notes
- `FloorRegistry` is `public enum` (stateless namespace), same pattern as `FloorGenerator` and `RulesEngine`
- `FloorGenerator` is not deleted in this story — retained so direct test calls still compile
- `FloorRegistry` must be `Sendable`-safe (pure functions, value returns only)
- Dependency rule: `FloorRegistry` is in `GameDomain`, zero imports from other modules

---

## US-HM-03: Floor label moved to top border

### Problem
Maartene is a developer who needs to free row 2 of the right panel for minimap content. They find it frustrating that the current "Floor N/M" label at row 2 overwrites the top row of the minimap, hiding the entry cell landmark for any floor whose entry is at the top.

### Who
- Developer + player | Dungeon screen, right panel, row 1 (top border) | Need to see full minimap from row 2

### Solution
Embed the floor label in the top border (row 1) of the right-panel segment. The `drawChrome` method writes a different top-border string in `.dungeon` mode that includes the label. Row 2 is free for minimap content.

### Domain Examples

#### 1: Floor 1 in dungeon mode — label in top border
Rowan is on floor 1. The top border at row 1 reads: `┌──────────────────────────────────────────────────────┬── Floor 1/5 ──────┐`. The minimap starts at row 2 with the entry cell visible.

#### 2: Floor 5 — label updates correctly
Rowan reaches floor 5. The top border label reads "Floor 5/5". The boss antechamber minimap starts at row 2 unobstructed.

#### 3: Combat screen — no floor label in top border
Rowan enters combat. The top border uses plain `─` fill with no label. Only `.dungeon` mode shows the floor label.

### UAT Scenarios (BDD)

#### Scenario: Floor label appears in the top border row 1 in dungeon mode
```
Given Ember is on floor 3 in dungeon mode
When  the screen renders
Then  the top border (row 1) in the right-panel segment (cols 61-79) contains "Floor 3/5"
And   row 2 col 61 is written by the minimap (not by the label)
```

#### Scenario: Floor label updates when floor number changes
```
Given Ember advances from floor 2 to floor 3
When  the dungeon screen renders on floor 3
Then  the top border contains "Floor 3/5"
And   the top border does not contain "Floor 2/5"
```

#### Scenario: Floor label is absent from combat screen top border
```
Given Ember is in combat mode on floor 2
When  the screen renders
Then  row 1 cols 61-79 do not contain "Floor"
```

### Acceptance Criteria
- [ ] In `.dungeon` screen mode, row 1 cols 61-79 contain the string "Floor N/M" where N = current floor
- [ ] In all other screen modes, row 1 cols 61-79 contain only `─` border characters (no floor label)
- [ ] The floor label is not written to row 2 in dungeon mode
- [ ] The label fits within the 19-char right-panel segment (max length "Floor 5/5" = 11 chars including leading/trailing spaces — fits within 19)

### Outcome KPIs
- **Who**: Player (Rowan)
- **Does what**: Reads current floor number without losing minimap row visibility
- **By how much**: Row 2 of right panel = 100% minimap content, 0% label bleed
- **Measured by**: Test assertion that row 2 col 61 has minimap content, not label text
- **Baseline**: Currently row 2 right panel is partially overwritten by label on some floors

### Technical Notes
- `drawChrome` currently writes the same top border unconditionally; it needs to know the current screen mode and floor number, or a separate method is called from `renderDungeon`
- One approach: move label rendering into `renderDungeon` after the chrome is drawn, targeting row 1 directly. DESIGN wave decides the exact approach.

---

## US-HM-04: Minimap renders floors of any supported size

### Problem
Maartene is a developer who needs the minimap to correctly render floors with different widths and heights. They find it risky that some test helpers hardcode the minimap formula with `height - 1 = 6` (height=7 assumption), which will produce wrong row assertions for any floor taller than 7.

### Who
- Developer | Minimap renderer and test helpers | Dynamic floor dimensions, no hardcoded height/width constants

### Solution
Confirm the minimap render loop already uses `floor.grid.height` and `floor.grid.width` (it does — lines 611-626 of Renderer.swift). Update test helpers that hardcode `2 + (6 - y)` to use `2 + (floor.grid.height - 1 - y)` instead, where `floor` is retrieved from `FloorRegistry`.

### Domain Examples

#### 1: Floor 1 (15×7) — existing position formula still correct
Test helper computes `screenRow = 2 + (7 - 1 - 0) = 8` for y=0. Same as current. Entry cell at row 8, col 68. All existing assertions hold.

#### 2: Floor 3 (19×10) — taller floor
Test helper computes `screenRow = 2 + (10 - 1 - 0) = 11` for y=0. Entry cell is now at row 11, not row 8. Minimap extends from row 2 (y=9) down to row 11 (y=0). Width 19 means col = 61 + 0 to 61 + 18 = col 79. No overflow.

#### 3: Floor 5 (13×8) — narrower and slightly taller
Entry at y=0: `screenRow = 2 + (8 - 1 - 0) = 9`. Width 13 means cols 61-73 used (cols 74-79 empty). Minimap fits within the right panel.

### UAT Scenarios (BDD)

#### Scenario: Floor 1 minimap renders entry cell at correct screen position
```
Given Ember is on floor 1 (grid height=7) in dungeon mode
When  the minimap renders
Then  a minimap cell write occurs at screen row 8, col 68 (entry cell x=7, y=0)
And   the write contains the player facing indicator (^ > v <)
```

#### Scenario: A floor with height=10 renders its entry cell 3 rows lower than height=7
```
Given floor 3 has grid height=10
And   floor 3's entry is at (x=9, y=0)
When  the minimap renders for floor 3
Then  the entry cell is written at screen row 2 + (10 - 1 - 0) = 11
And   no minimap content is written above row 2 or below row 16
```

#### Scenario: A 19-wide floor has no minimap cell written beyond col 79
```
Given floor 2 has grid width=19
When  the minimap renders for floor 2
Then  all minimap writes are at cols 61-79
And   no write occurs at col 80 or beyond
```

### Acceptance Criteria
- [ ] `Renderer.renderMinimap` loop bounds use `floor.grid.width` and `floor.grid.height` (no magic constants 15 or 7)
- [ ] For a floor with `height=H`, the southernmost row (y=0) renders at screen row `2 + (H - 1)`
- [ ] For a floor with `width=W`, the easternmost column (x=W-1) renders at screen col `61 + (W - 1)` ≤ 79
- [ ] Existing `MinimapTests` pass (with test helpers updated to use dynamic height if needed)
- [ ] No minimap write occurs outside rows 2-16 or cols 61-79

### Outcome KPIs
- **Who**: Developer (test maintainability) + Player (correct minimap)
- **Does what**: Minimap accurately represents any floor topology up to 19×15
- **By how much**: 5/5 floors render at correct screen coordinates
- **Measured by**: Automated tests for each floor's entry cell screen position
- **Baseline**: Currently only height=7 width=15 is correct; other sizes would render at wrong positions or clip

### Technical Notes
- The render loop in `Renderer.swift` lines 611-626 already uses `floor.grid.height` and `floor.grid.width` — this is already correct
- The change required is in the tests that hardcode `2 + (6 - y)` (e.g. `MinimapTests.swift` comments and `minimapCharAt` helper)
- No Renderer source change needed for the loop itself — only for the label and any constant references

---

## US-HM-05: Five distinct handcrafted floor layouts

### Problem
Rowan is a player progressing through Ember's Escape. They find it boring that floors 1-5 all look identical — the same L-shaped corridor every time. There is no spatial progression, no sense of a dungeon with different areas.

### Who
- Player (Rowan) | Navigating 5 floors in sequence | Wants each floor to feel like a different place

### Solution
Five `FloorDefinition` constants are authored in `GameDomain`, one per floor. Each has a distinct grid topology, correct landmark positions, and correct game-rule flags (egg room, boss, exit per floor rules).

### Domain Examples

#### 1: Floor 2 (T-junction wide) — Rowan finds the egg on a new branch
Rowan enters floor 2. The minimap shows a wide T-junction. The egg room symbol (*) is on the west branch. Rowan navigates west, finds the egg, then returns to the main corridor to find the staircase at the north end.

#### 2: Floor 4 (room-and-hall) — Rowan navigates an open room
Rowan enters floor 4. The minimap shows a large open room in the center of the floor. The egg room is in the northeast corner. The guard is at the south entrance to the room. The staircase is in the northwest.

#### 3: Floor 5 (boss antechamber) — Rowan faces the Head Warden in a compact space
Rowan enters floor 5. The minimap is noticeably smaller and more compact than previous floors. No egg room (*) symbol. The exit (X) is at the north end. The boss (B) is at the center. Rowan must pass through the boss to reach the exit.

### UAT Scenarios (BDD)

#### Scenario: Floor 2 has a distinct topology from floor 1
```
Given floors 1 and 2 are defined in FloorRegistry
When  FloorRegistry.floor(1, config: .default) and FloorRegistry.floor(2, config: .default) are called
Then  floor1.grid.width != floor2.grid.width OR floor1.grid.height != floor2.grid.height
      OR the passable cell sets differ
```

#### Scenario: Floors 2, 3, 4 each have an egg room at a valid position
```
Given floors 2, 3, and 4 are defined in FloorRegistry
When  each FloorMap is retrieved
Then  each FloorMap.hasEggRoom == true
And   each FloorMap.eggRoomPosition2D is not nil
And   the egg room position is on a passable cell in its respective floor's grid
```

#### Scenario: Floor 5 has boss encounter, exit, no egg, no staircase
```
Given floor 5 is defined in FloorRegistry
When  FloorRegistry.floor(5, config: .default) is called
Then  floorMap.hasBossEncounter == true
And   floorMap.hasExitSquare == true
And   floorMap.hasEggRoom == false
And   floorMap.encounterPosition2D is nil (boss uses bossEncounterPosition2D)
```

#### Scenario: All 5 floors have entry positions on passable cells
```
Given all 5 floor definitions are registered
When  each FloorMap is retrieved
Then  for each floor: floor.grid.cell(x: floor.entryPosition2D.x, y: floor.entryPosition2D.y).isPassable == true
```

#### Scenario: No floor exceeds 19 wide or 15 tall
```
Given all 5 floor definitions are registered
When  each FloorMap is retrieved
Then  floor.grid.width <= 19 for all floors
And   floor.grid.height <= 15 for all floors
```

### Acceptance Criteria
- [ ] 5 `FloorDefinition` constants exist (one per floor number 1-5)
- [ ] Floor 1's topology matches the current `FloorGenerator` L-shape (regression: existing tests pass)
- [ ] Floors 2, 3, 4 each have `hasEggRoom == true` and a non-nil, passable egg room position
- [ ] Floor 5 has `hasBossEncounter == true`, `hasExitSquare == true`, `hasEggRoom == false`
- [ ] No two floors have identical grid dimensions AND identical passable cell topology
- [ ] All landmark positions on all floors are on passable cells
- [ ] All grid widths ≤ 19 and heights ≤ 15
- [ ] `swift test` passes for all floor-related tests

### Outcome KPIs
- **Who**: Player (Rowan)
- **Does what**: Experiences spatial variety across the 5-floor dungeon
- **By how much**: 5 of 5 floors have visually distinct minimap shapes
- **Measured by**: Automated test confirming distinct topologies; developer visual inspection
- **Baseline**: Currently 5/5 floors are visually identical

### Technical Notes
- Floor layouts are pure Swift `[String]` literals — no external data format
- All 5 definitions live in `Sources/GameDomain/HandcraftedFloors.swift` or inline in `FloorRegistry`
- Floor 1 definition must produce a `FloorMap` identical to `FloorGenerator` output — this is verified by AC-HM-02-A before new floors are added
- DESIGN wave decides the exact character grid patterns for floors 2-5 — requirements specify shapes (T-junction, zigzag, room-and-hall, boss antechamber) but not the exact string arrays
