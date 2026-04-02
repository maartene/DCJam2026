# Story Map: Turning Mechanic

## User: Ember (the player)
## Goal: Navigate dungeon corridors with full spatial awareness via 90-degree turns

---

## Backbone

| Activity 1 | Activity 2 | Activity 3 | Activity 4 |
|------------|------------|------------|------------|
| **Orient on entry** | **Turn to face new direction** | **Move relative to facing** | **Read minimap** |

---

## Story Map Table

| | Orient on entry | Turn to face new direction | Move relative to facing | Read minimap |
|---|---|---|---|---|
| **Walking Skeleton** | Facing initialises to North on floor entry | Turn left/right changes facingDirection (domain only) | Forward/backward movement uses facingDirection for grid delta | Minimap shows caret matching facing direction |
| **Release 1** | `withFacingDirection` functional updater on GameState | A/D + Arrow Left/Right mapped to `.turn(.left/.right)` in InputHandler | Arrow Up/Down + W/S still work; delta computed from facing | `Facing: N/S/E/W` label appended to minimap string |
| **Release 2** | facingDirection persists through floor transitions (stays facing same direction) | — | Backward movement correct when facing South/West | — |

---

### Walking Skeleton

The thinnest end-to-end slice that makes the jam rule technically satisfied:

1. `GameState.facingDirection` field exists, initialises to `.north`
2. `CardinalDirection` enum exists in GameDomain
3. `GameCommand.turn(TurnDirection)` case exists
4. `RulesEngine` processes `turn` command → updates `facingDirection`
5. `RulesEngine` processes `move(.forward)` → applies `facingDirection`-relative delta to `playerPosition`
6. `Renderer.buildMinimap` appends caret to player `○` marker

Delivers: player can turn and see facing on minimap. Jam rule satisfied.

### Release 1: Full keyboard binding + minimap label

Adds A/D and Arrow Left/Right key bindings, `Facing: N` label on minimap, `withFacingDirection` helper on GameState. Completes the UX — player can use all four turn inputs and read facing clearly.

### Release 2: Polish and edge cases

Facing persistence across floor transitions, correct backward movement for all facing directions, combat-mode turn acceptance test. Ensures no regression on existing movement behaviour.

---

## Scope Assessment: PASS

- 6 user stories (within 3-10 range)
- 2 bounded contexts: `GameDomain` (state + rules) and `App` (input + renderer)
- Estimated 2-3 days total effort
- Single independent user outcome: "player can orient themselves in the dungeon"

No split required.
