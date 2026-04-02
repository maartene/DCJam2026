# Acceptance Criteria: Turning Mechanic

Derived from UAT scenarios in user-stories.md. Each item is observable and testable.

---

## US-TM-01: CardinalDirection Domain Type

- [ ] AC-01-1: `CardinalDirection` enum exists in `GameDomain` with exactly `.north`, `.east`, `.south`, `.west`
- [ ] AC-01-2: `GameState` has `facingDirection: CardinalDirection` field
- [ ] AC-01-3: `GameState.initial(config:)` sets `facingDirection` to `.north`
- [ ] AC-01-4: `GameState.withFacingDirection(_:)` returns new state with updated direction; original state is unchanged
- [ ] AC-01-5: `CardinalDirection` and `TurnDirection` both conform to `Sendable`

---

## US-TM-02: RulesEngine Turn Command

- [ ] AC-02-1: `GameCommand.turn(.left)` from North produces `facingDirection == .west`
- [ ] AC-02-2: `GameCommand.turn(.right)` from North produces `facingDirection == .east`
- [ ] AC-02-3: Full rotation table (all 8 combinations) produces correct results
- [ ] AC-02-4: Turn command does not change `hp`, `dashCharges`, `specialCharge`, or `playerPosition`
- [ ] AC-02-5: Four consecutive turns in the same direction return to the original facing

---

## US-TM-03: 2D Floor Model and Facing-Relative Movement

- [ ] AC-03-1: `playerPosition` is a 2D coordinate (has `x` and `y` integer fields)
- [ ] AC-03-2: `move(.forward)` while facing `.north` produces `(dx: 0, dy: +1)`
- [ ] AC-03-3: `move(.forward)` while facing `.east` produces `(dx: +1, dy: 0)`
- [ ] AC-03-4: `move(.forward)` while facing `.south` produces `(dx: 0, dy: -1)`
- [ ] AC-03-5: `move(.forward)` while facing `.west` produces `(dx: -1, dy: 0)`
- [ ] AC-03-6: `move(.backward)` produces the inverse delta for all four facings
- [ ] AC-03-7: `playerPosition` is clamped to valid 2D floor grid bounds after any move
- [ ] AC-03-8: Existing encounter proximity check (DISC-03) is still applied after movement
- [ ] AC-03-9: Win condition (hasEgg + exitPosition) is still checked after movement

---

## US-TM-04: 2D Minimap with Facing Indicator

- [ ] AC-04-1: Minimap renders as a 2D top-down grid (not an inline text string)
- [ ] AC-04-2: Minimap is displayed in a dedicated screen region (exact position: DESIGN decision)
- [ ] AC-04-3: Player is shown as `^` when `facingDirection == .north`
- [ ] AC-04-4: Player is shown as `>` when `facingDirection == .east`
- [ ] AC-04-5: Player is shown as `v` when `facingDirection == .south`
- [ ] AC-04-6: Player is shown as `<` when `facingDirection == .west`
- [ ] AC-04-7: Player marker overrides landmarks (egg, guard, staircase) when on same cell
- [ ] AC-04-8: Minimap updates on the same render frame as turn and movement commands

---

## US-TM-05: Turn Key Bindings

- [ ] AC-05-1: `a` key (0x61) produces `GameCommand.turn(.left)`
- [ ] AC-05-2: `A` key (0x41) produces `GameCommand.turn(.left)`
- [ ] AC-05-3: `d` key (0x64) produces `GameCommand.turn(.right)`
- [ ] AC-05-4: `D` key (0x44) produces `GameCommand.turn(.right)`
- [ ] AC-05-5: Arrow Left escape sequence `[0x1B, 0x5B, 0x44]` produces `GameCommand.turn(.left)`
- [ ] AC-05-6: Arrow Right escape sequence `[0x1B, 0x5B, 0x43]` produces `GameCommand.turn(.right)`
- [ ] AC-05-7: Existing W/S/Arrow Up/Arrow Down bindings are unchanged
- [ ] AC-05-8: Dungeon controls hint (row 19) includes `A/D: turn left/right`

---

## US-TM-06: Facing Persistence and Combat Turn Blocking

- [ ] AC-06-1: `withCurrentFloor(_:)` does not reset `facingDirection`
- [ ] AC-06-2: `RulesEngine` ignores (discards) `.turn` commands when `screenMode == .combat`
- [ ] AC-06-3: Combat encounter state (enemy HP, attack timer) is unchanged when a turn command is attempted during combat
- [ ] AC-06-4: `facingDirection` does not change when turn is attempted during combat
- [ ] AC-06-5: Movement is still locked in combat regardless of `facingDirection`
