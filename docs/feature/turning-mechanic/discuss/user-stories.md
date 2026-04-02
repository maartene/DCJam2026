<!-- markdownlint-disable MD024 -->
# User Stories: Turning Mechanic

---

## US-TM-01: CardinalDirection Domain Type

### Problem

Ember is a young dragon navigating a dungeon grid. Without a facing direction type in the domain, the game has no way to represent which way Ember is looking. Every subsequent turning and movement story depends on this type existing as a pure domain value.

### Who

- Ember (the player) | Navigating dungeon corridors | Needs a spatial model that includes facing

### Solution

Introduce `CardinalDirection` enum in `GameDomain` with four cases (`.north`, `.east`, `.south`, `.west`) and add `facingDirection: CardinalDirection` to `GameState`, initialised to `.north`. Add `withFacingDirection` functional updater.

### Domain Examples

#### 1: New game starts — default facing North
Ember starts Dragon Escape. `GameState.initial(config:)` is called. `gameState.facingDirection` is `.north`. No other values are valid at start.

#### 2: Staircase transition — facing carries over
Ember reaches the staircase on floor 1 facing East. After floor transition, `gameState.facingDirection` is still `.east`. The player's spatial orientation persists.

#### 3: Reset on restart
Ember dies and presses R. `GameState.initial(config:)` is called again. `gameState.facingDirection` resets to `.north`. All other state also resets per INT-04.

### UAT Scenarios (BDD)

#### Scenario: Initial facing direction is North
```gherkin
Given a new GameState is created with GameState.initial(config:)
Then gameState.facingDirection equals .north
```

#### Scenario: withFacingDirection produces a new state with updated facing
```gherkin
Given gameState.facingDirection is .north
When gameState.withFacingDirection(.east) is called
Then the returned state has facingDirection equal to .east
And the original state is unchanged
```

#### Scenario: All four cardinal directions are representable
```gherkin
Given the CardinalDirection enum
Then .north, .east, .south, and .west are all valid cases
And no other cases exist
```

### Acceptance Criteria

- [ ] `CardinalDirection` enum exists in `GameDomain` with `.north`, `.east`, `.south`, `.west`
- [ ] `GameState` has `facingDirection: CardinalDirection` field
- [ ] `GameState.initial(config:)` sets `facingDirection` to `.north`
- [ ] `GameState.withFacingDirection(_:)` returns a new state with the updated direction
- [ ] `CardinalDirection` conforms to `Sendable`

### Outcome KPIs

- **Who**: Developer / jam judges
- **Does what**: Verifies domain model supports four cardinal directions
- **By how much**: 100% of domain unit tests pass
- **Measured by**: Swift test suite
- **Baseline**: Field does not exist

### Technical Notes

- `GameDomain` has no external dependencies; `CardinalDirection` must be defined entirely within that module
- `GameState` is a pure value type (`struct`); no side effects in `withFacingDirection`
- `facingDirection` is not part of the combat model; no `EncounterModel` changes needed

---

## US-TM-02: RulesEngine Turn Command

### Problem

Ember needs to turn 90 degrees left or right. Without a `turn` command in the `GameCommand` enum and corresponding `RulesEngine` logic, pressing A or D has no effect and the jam rule is unmet.

### Who

- Ember (the player) | Mid-navigation in a dungeon corridor | Wants to face a new direction

### Solution

Add `GameCommand.turn(TurnDirection)` with `TurnDirection` enum (`.left`, `.right`). Implement turn resolution in `RulesEngine.apply(command:to:deltaTime:)` as a pure function: given current facing and turn direction, return new facing using a fixed rotation table.

### Domain Examples

#### 1: Ember turns left from North — now faces West
Ember is at floor 2, position 4, facing North. Presses A. `RulesEngine` receives `.turn(.left)`. New state: `facingDirection = .west`. Position unchanged.

#### 2: Ember turns right from West — now faces North
Ember is facing West. Presses D. `RulesEngine` receives `.turn(.right)`. New state: `facingDirection = .north`. Position unchanged.

#### 3: Four consecutive left turns return to original facing
Ember starts facing East. Presses A four times. Facing cycles: East → North → West → South → East. Final facing equals initial facing.

### UAT Scenarios (BDD)

#### Scenario: Turn left rotates facing counter-clockwise
```gherkin
Given Ember's facing direction is North
When RulesEngine processes GameCommand.turn(.left)
Then the resulting state has facingDirection equal to .west
And playerPosition is unchanged
```

#### Scenario: Turn right rotates facing clockwise
```gherkin
Given Ember's facing direction is North
When RulesEngine processes GameCommand.turn(.right)
Then the resulting state has facingDirection equal to .east
And playerPosition is unchanged
```

#### Scenario: Full rotation table is correct
```gherkin
Given each CardinalDirection and each TurnDirection
When RulesEngine processes the turn command
Then the resulting facingDirection matches the rotation table:
  North + left  → West
  West  + left  → South
  South + left  → East
  East  + left  → North
  North + right → East
  East  + right → South
  South + right → West
  West  + right → North
```

#### Scenario: Turning does not cost health, dash, or special
```gherkin
Given Ember has 75 HP, 2 dash charges, and 0.5 special charge
When RulesEngine processes GameCommand.turn(.left)
Then HP is 75
And dashCharges is 2
And specialCharge is 0.5
```

### Acceptance Criteria

- [ ] `TurnDirection` enum exists in `GameDomain` with `.left` and `.right`
- [ ] `GameCommand` has `case turn(TurnDirection)`
- [ ] `RulesEngine` handles `.turn` command
- [ ] Rotation table is correct for all 8 combinations (4 directions × 2 turn directions)
- [ ] Turn command is a pure function: same inputs always produce same output
- [ ] No HP, dash, or special change occurs on turn

### Outcome KPIs

- **Who**: Player / developer
- **Does what**: Invoke 90-degree turn in four directions via keyboard
- **By how much**: All 8 rotation combinations pass unit tests
- **Measured by**: Swift test suite
- **Baseline**: Command does not exist

### Technical Notes

- Rotation table: define once as a static lookup or switch in `RulesEngine`; never duplicate in `InputHandler` or `Renderer`
- `TurnDirection` and `GameCommand.turn` must conform to `Sendable`
- Turn is processed regardless of `screenMode` (including `.combat`)

---

## US-TM-03: Facing-Relative Movement Delta

### Problem

Currently `move(.forward)` always increments `playerPosition` by +1 regardless of direction. After turning, forward must mean "in the direction I am facing." Without this, the dungeon crawler movement model is broken and the jam's step-movement rule is violated.

### Who

- Ember (the player) | After turning to face a new direction | Wants W to mean "go the way I'm looking"

### Solution

Change `FloorMap` to a 2D grid and `GameState.playerPosition` to a 2D coordinate (`Position` with `x` and `y`). Modify `RulesEngine.apply(move:to:)` to resolve a `(dx, dy)` delta from `state.facingDirection` and apply it to the 2D position.

### Domain Examples

#### 1: Forward while facing North — advance toward staircase
Ember is at position 3, facing North. Presses W. Delta = +1. New position = 4. One square closer to the staircase on the current floor.

#### 2: Forward while facing South — retreat toward entry
Ember is at position 3, facing South. Presses W. Delta = -1. New position = 2. One square closer to entry. This is the correct "forward" when facing South.

#### 3: Backward while facing West — advance toward staircase
Ember is at position 3, facing West. Presses S (backward). Delta = +1 (backward of West = East = +1). New position = 4. Logically correct: pressing back while facing West moves toward East end.

### UAT Scenarios (BDD)

#### Scenario: Forward while facing North advances position
```gherkin
Given Ember is at position 3 facing North
When RulesEngine processes GameCommand.move(.forward)
Then Ember's position is 4
```

#### Scenario: Forward while facing South retreats position
```gherkin
Given Ember is at position 3 facing South
When RulesEngine processes GameCommand.move(.forward)
Then Ember's position is 2
```

#### Scenario: Forward while facing East advances position
```gherkin
Given Ember is at position 3 facing East
When RulesEngine processes GameCommand.move(.forward)
Then Ember's position is 4
```

#### Scenario: Forward while facing West retreats position
```gherkin
Given Ember is at position 3 facing West
When RulesEngine processes GameCommand.move(.forward)
Then Ember's position is 2
```

#### Scenario: Backward is inverse of forward for all facings
```gherkin
Given Ember is at position 3 facing South
When RulesEngine processes GameCommand.move(.backward)
Then Ember's position is 4
```

#### Scenario: Movement at boundary does not go negative
```gherkin
Given Ember is at position 0 facing South
When RulesEngine processes GameCommand.move(.forward)
Then Ember's position remains 0
```

### Acceptance Criteria

- [ ] `move(.forward)` applies delta `+1` when `facingDirection` is `.north` or `.east`
- [ ] `move(.forward)` applies delta `-1` when `facingDirection` is `.south` or `.west`
- [ ] `move(.backward)` applies the inverse delta
- [ ] Position is clamped to `[0, floorLength]` — no negative positions
- [ ] Existing encounter proximity rule (DISC-03) is still checked after delta is applied
- [ ] Win condition check (hasEgg + exitPosition) is still evaluated after each move

### Outcome KPIs

- **Who**: Player
- **Does what**: Navigate using W/S relative to current facing direction
- **By how much**: All 8 facing+direction combinations pass unit tests; no movement regression
- **Measured by**: Swift test suite + manual playtesting
- **Baseline**: Movement is currently absolute (always +1/-1)

### Technical Notes

- `FloorMap` changes to 2D; `playerPosition` changes to `Position(x:y:)` — this is the most impactful structural change in this feature
- `(dx, dy)` deltas: North=(0,+1), East=(+1,0), South=(0,-1), West=(-1,0)
- The delta lookup must read `state.facingDirection`; hardcoded deltas without facing check are a bug

---

## US-TM-04: Minimap Facing Indicator

### Problem

Ember needs to see which way she is facing at a glance. Without a facing indicator on the minimap, the player must mentally track their orientation — which is error-prone and frustrating, especially after multiple turns. This is the primary UX concern for the turning feature (WD-01).

### Who

- Ember (the player) | Any moment during dungeon exploration | Needs immediate confirmation of current facing

### Solution

Render the minimap as a 2D top-down grid in a dedicated screen region. The player is shown as a directional character (`^`, `>`, `v`, `<`) matching `GameState.facingDirection`. The screen layout must change to accommodate this region — exact placement is a DESIGN decision.

### Domain Examples

#### 1: Ember is facing North — minimap shows `○^`
Minimap string: `Floor 2:  [E...○^..G..*..S]  Facing: N`. Developer glances at row 21 and immediately knows: facing North, position 4 of 11.

#### 2: Ember turns West — minimap updates to `○<`
After pressing A from North, minimap string: `Floor 2:  [E...○<..G..*..S]  Facing: W`. Change is visible on the same rendered frame as the turn.

#### 3: Ember is at a different position facing East
Minimap string: `Floor 3:  [E.G..*..○>..S]  Facing: E`. Player is past the egg room, facing toward staircase.

### UAT Scenarios (BDD)

#### Scenario: Minimap shows caret for each cardinal direction
```gherkin
Given Ember is facing North
Then the minimap player marker in the Thoughts panel shows "○^"

Given Ember is facing East
Then the minimap player marker shows "○>"

Given Ember is facing South
Then the minimap player marker shows "○v"

Given Ember is facing West
Then the minimap player marker shows "○<"
```

#### Scenario: Minimap Facing label matches facingDirection
```gherkin
Given Ember is facing West
Then the minimap string contains "Facing: W"
```

#### Scenario: Minimap updates on same frame as turn
```gherkin
Given Ember is facing North
When RulesEngine processes turn(.right) and Renderer renders the new state
Then the minimap shows "○>" on that rendered frame
```

#### Scenario: Player marker still overrides landmark on same cell
```gherkin
Given Ember is at the egg room position facing East
Then the minimap shows "○>" at that position (not "*" or "e")
```

### Acceptance Criteria

- [ ] `buildMinimap` appends caret to `○` based on `state.facingDirection` (not hardcoded)
- [ ] `^` for `.north`, `>` for `.east`, `v` for `.south`, `<` for `.west`
- [ ] `Facing: N/S/E/W` label appended to minimap string after the cell array
- [ ] Minimap string length must still fit within 78 characters (row 21 interior width)
- [ ] Player marker `○{caret}` still overrides landmarks at same position
- [ ] No changes to screen layout — Thoughts panel rows 21-24 unchanged

### Outcome KPIs

- **Who**: Player / developer during playtesting
- **Does what**: Identify current facing direction within 2 seconds of glancing at minimap
- **By how much**: 100% of informal playtests show correct facing identification in ≤2 seconds
- **Measured by**: Developer playtesting observation
- **Baseline**: No facing indicator exists

### Technical Notes

- `buildMinimap` must read `state.facingDirection` directly; no cached copy
- The two-character player marker `○^` occupies one cell-width in the minimap array — treat `○` + caret as the marker for that cell position
- Minimap string format: `"Floor {N}:  [{cells}]  Facing: {N/S/E/W}"` — verify it fits 78 chars for maximum floor length

---

## US-TM-05: Turn Key Bindings (A/D + Arrow Left/Right)

### Problem

The turn commands exist in the domain, but Ember cannot trigger them — `InputHandler` does not map A, D, Arrow Left, or Arrow Right to `.turn`. Without these bindings, the feature is invisible to the player and the jam rule is unmet.

### Who

- Ember (the player) | At keyboard during dungeon exploration | Wants natural left/right key inputs to turn

### Solution

Add four key mappings to `InputHandler.mapKey`: A → `.turn(.left)`, D → `.turn(.right)`, Arrow Left (ESC [ D) → `.turn(.left)`, Arrow Right (ESC [ C) → `.turn(.right)`. Update the controls hint in `Renderer` to include `A/D: turn`.

### Domain Examples

#### 1: Ember presses A — turn left fires
Byte `0x61` ('a') arrives. `mapKey` returns `.turn(.left)`. `RulesEngine` updates `facingDirection` from North to West. Minimap shows `○<`.

#### 2: Ember presses Arrow Right — turn right fires
Escape sequence `0x1B 0x5B 0x43` arrives. `mapKey` returns `.turn(.right)`. `RulesEngine` updates `facingDirection` from North to East.

#### 3: Ember presses D then A rapidly — net no turn
Two separate keypoll cycles. First returns `.turn(.right)` (North → East). Second returns `.turn(.left)` (East → North). Final facing = North. Minimap correctly shows `○^`.

### UAT Scenarios (BDD)

#### Scenario: A key produces turn-left command
```gherkin
Given InputHandler receives byte 0x61 (lowercase 'a')
Then poll() returns GameCommand.turn(.left)
```

#### Scenario: D key produces turn-right command
```gherkin
Given InputHandler receives byte 0x64 (lowercase 'd')
Then poll() returns GameCommand.turn(.right)
```

#### Scenario: Arrow Left escape sequence produces turn-left
```gherkin
Given InputHandler receives bytes [0x1B, 0x5B, 0x44]
Then poll() returns GameCommand.turn(.left)
```

#### Scenario: Arrow Right escape sequence produces turn-right
```gherkin
Given InputHandler receives bytes [0x1B, 0x5B, 0x43]
Then poll() returns GameCommand.turn(.right)
```

#### Scenario: Controls hint includes turn instruction
```gherkin
Given the dungeon screen is rendered
Then row 19 contains "A/D: turn" or equivalent turn instruction
```

### Acceptance Criteria

- [ ] `InputHandler` maps `a`/`A` to `.turn(.left)`
- [ ] `InputHandler` maps `d`/`D` to `.turn(.right)`
- [ ] Arrow Left escape sequence (`ESC [ D`, 0x1B 0x5B 0x44) maps to `.turn(.left)`
- [ ] Arrow Right escape sequence (`ESC [ C`, 0x1B 0x5B 0x43) maps to `.turn(.right)`
- [ ] Existing W/S and Arrow Up/Down bindings are unchanged
- [ ] Dungeon controls hint updated to include `A/D: turn left/right`

### Outcome KPIs

- **Who**: Player
- **Does what**: Invoke turn using A/D keys or Arrow Left/Right
- **By how much**: 4 key-binding unit tests pass; developer can trigger turns during playtesting
- **Measured by**: Unit tests + playtesting
- **Baseline**: No turn key bindings exist

### Technical Notes

- Arrow Right = `ESC [ C` = bytes `[0x1B, 0x5B, 0x43]` — distinct from Arrow Up/Down already handled
- Arrow Left = `ESC [ D` = bytes `[0x1B, 0x5B, 0x44]`
- Case-insensitive: `a`/`A` and `d`/`D` both map to turn (mirrors existing W/w, S/s pattern)
- `InputHandler` is in `App` module; it imports `GameDomain` for `GameCommand`

---

## US-TM-06: Facing Persistence and Combat Turn Acceptance

### Problem

Two edge cases: (1) does `facingDirection` persist correctly across floor transitions, and (2) is the `.turn` command correctly blocked during combat? Without this, a player in combat could accidentally disorient themselves with no visual feedback of the change.

### Who

- Ember (the player) | Transitioning floors or mid-combat | Needs consistent facing behaviour in edge cases

### Solution

Two acceptance tests: one verifying `facingDirection` carries through `withCurrentFloor`, one verifying `RulesEngine` ignores `.turn` commands in `.combat` screenMode (facing unchanged, encounter unchanged).

### Domain Examples

#### 1: Facing persists through floor transition
Ember clears floor 2 while facing East. `withCurrentFloor(3)` is called. `gameState.facingDirection` is still `.east`. Player's spatial orientation is preserved.

#### 2: Turn attempted during combat — ignored
Ember is in `.combat(encounter: dungeonGuard)` facing North. Presses D. `RulesEngine` ignores the `.turn(.right)` command. `facingDirection` remains `.north`, `screenMode` still `.combat`, `encounter.enemyHP` unchanged.

#### 3: Movement still locked during combat after a turn
Ember turns East in combat. Presses W. Movement locked by DISC-03. Position unchanged. Combat encounter unchanged.

### UAT Scenarios (BDD)

#### Scenario: facingDirection persists through floor transition
```gherkin
Given gameState.facingDirection is .east
When gameState.withCurrentFloor(3) is called
Then the returned state has facingDirection equal to .east
```

#### Scenario: Turn command is ignored in combat screen mode
```gherkin
Given screenMode is .combat and facingDirection is .north
When RulesEngine receives GameCommand.turn(.right)
Then facingDirection remains .north
And screenMode is still .combat
And encounter.enemyHP is unchanged
```

#### Scenario: Movement is locked in combat regardless of facing
```gherkin
Given Ember is in combat at position 4, facing East
When RulesEngine processes GameCommand.move(.forward)
Then Ember's position remains 4
```

### Acceptance Criteria

- [ ] `withCurrentFloor` does not reset `facingDirection`
- [ ] `RulesEngine` ignores `.turn` commands when `screenMode == .combat` (facing does not change)
- [ ] Combat encounter state is unmodified when turn is attempted during combat
- [ ] Movement lock (DISC-03) still applies in combat

### Outcome KPIs

- **Who**: Developer
- **Does what**: Verify no regression in floor transition or combat interaction
- **By how much**: 3 edge-case unit tests pass
- **Measured by**: Swift test suite
- **Baseline**: Not tested (new edge cases introduced by turning feature)

### Technical Notes

- `withCurrentFloor` is a functional updater that only changes `currentFloor` — verify it does not touch `facingDirection`
- `RulesEngine` must add a guard: if `state.screenMode == .combat`, return `state` unchanged when processing `.turn`
- This story is a verification/acceptance story; the implementation may already be correct after US-TM-01..05
