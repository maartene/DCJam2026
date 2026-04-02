# Journey: Turning Mechanic — Visual Map

## Persona

**Ember** — the player character and the developer testing navigation. A young dragon exploring a dungeon to recover a stolen egg. Ember needs spatial awareness to navigate efficiently and reach the egg before running out of health.

---

## Emotional Arc

| Phase | State | Notes |
|-------|-------|-------|
| Start | Curious / slightly disoriented | Ember enters a new floor; the corridor ahead could branch in any direction |
| Middle | Engaged / in control | Ember turns, sees a new perspective, updates mental map |
| End | Confident / oriented | Ember knows exactly where north is, where the egg room is, and which way to go |

Arc pattern: **Discovery Joy** — Curious → Exploring → Oriented

---

## Journey Flow

```
[Enter floor]  ──>  [Face default: North]  ──>  [Move forward / look ahead]
  Feels: curious      Sees: minimap ^            Sees: dungeon frame
  Key: none           Key: W / Arrow Up          Key: W / Arrow Up

        |
        v (corridor branches OR player wants to explore)

[Decide to turn]  ──>  [Press A or Arrow Left]  ──>  [Facing updates: West]
  Feels: oriented        Resolves in <1 frame          Minimap caret: <
  Knows: turn = safe     No health cost                Controls bar updated

        |
        v

[Move in new direction]  ──>  [Minimap shows new path]  ──>  [Reach target room]
  Key: W (now = West)          ○< on minimap                  Egg/Staircase/Exit
  Feels: in control             Old path still visible         Feels: accomplished

```

---

## Error Paths

```
[Turn at encounter boundary]
  Situation: player is adjacent to enemy; movement is locked by existing rule
  Turn: ALLOWED (turning is always permitted; does not cost a resource)
  Minimap: updates to new facing
  Movement: still locked (existing DISC-03 rule; only Dash exits)

[Player presses D then A rapidly]
  Net result: facing unchanged (South → West → South = no net turn)
  Minimap: reflects current facing accurately after each keypress
  Feels: snappy, no disorientation

[Player turns at depth=0 (wall right in front)]
  After turn: dungeon frame re-renders from new facing
  New frame key: may show depth=3 (long corridor) or depth=0 (new wall)
  Feels: immediate feedback that turning revealed something new

[Unknown key during exploration]
  Existing behaviour: .none command; no state change
  Turning keys that aren't mapped: same — no state change, no error shown
```

---

## TUI Mockups

### Step 1: Starting state — facing North

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                    [dungeon view — corridor straight ahead]                  │
│                                                                              │
│                                 |      |                                     │
│                                 |      |                                     │
│                                 |      |                                     │
│                                  \    /                                      │
│                                   \  /                                       │
│                                    \/                                        │
│                                                                              │
│                                                               Floor 2/5      │
├──────────────────────────────────────────────────────────────────────────────┤
│ HP [██████████] EGG [ ]  (1)DASH[2]  (2)BRACE  (3)SPEC[░░░░░░░░]           │
│ W/S: fwd/back   A/D: turn left/right   1: Dash   2: Brace   3: Special      │
├─Thoughts─────────────────────────────────────────────────────────────────────┤
│ Floor 2:  [E...○^..G..*..S]  Facing: N                                      │
│                 E=entry  G=guard  *=egg  S=stairs  X=exit                   │
│ Cold stone, ash, the smell of old magic. Something moves ahead.             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
  Keys: W=fwd  S=back  A=turn left  D=turn right
  Arrow Up=fwd  Arrow Down=back  Arrow Left=turn left  Arrow Right=turn right
```

### Step 2: Player presses A — now facing West

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                  [dungeon view — side corridor or wall]                      │
│                    (new DungeonFrameKey computed from facing West)           │
│                                                                              │
│                        ___________________________                           │
│                       |                           |                          │
│                       |___________________________|                          │
│                                                                              │
│                                                               Floor 2/5      │
├──────────────────────────────────────────────────────────────────────────────┤
│ HP [██████████] EGG [ ]  (1)DASH[2]  (2)BRACE  (3)SPEC[░░░░░░░░]           │
│ W/S: fwd/back   A/D: turn left/right   1: Dash   2: Brace   3: Special      │
├─Thoughts─────────────────────────────────────────────────────────────────────┤
│ Floor 2:  [E...○<..G..*..S]  Facing: W                                      │
│                 E=entry  G=guard  *=egg  S=stairs  X=exit                   │
│ Cold stone, ash, the smell of old magic. Something moves ahead.             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Key changes in Step 2:**
- Minimap player marker changes from `○^` to `○<`
- `Facing: W` label updates
- Dungeon view re-renders with new DungeonFrameKey for West-relative depth

### Step 3: Player presses W — moves West (forward in new facing)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                  [dungeon view — moved one square West]                      │
│                    depth recalculated relative to West-facing position       │
│                                                                              │
├──────────────────────────────────────────────────────────────────────────────┤
│ HP [██████████] EGG [ ]  (1)DASH[2]  (2)BRACE  (3)SPEC[░░░░░░░░]           │
│ W/S: fwd/back   A/D: turn left/right   1: Dash   2: Brace   3: Special      │
├─Thoughts─────────────────────────────────────────────────────────────────────┤
│ Floor 2:  [E....○<.G..*..S]  Facing: W                                      │
│                 E=entry  G=guard  *=egg  S=stairs  X=exit                   │
│ Deeper now. The air is thicker, heavier. My claws find the floor.           │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Facing Indicator Key

| Facing | Caret | Cardinal |
|--------|-------|----------|
| North  | `^`   | N        |
| East   | `>`   | E        |
| South  | `v`   | S        |
| West   | `<`   | W        |

Player marker on minimap: `○` + caret character, e.g. `○^`, `○>`, `○v`, `○<`

---

## Integration Points

1. `GameState.facingDirection` (new field) — source of truth for all facing-dependent rendering
2. `GameCommand.turn(.left/.right)` (new case) — consumed by RulesEngine and InputHandler
3. `RulesEngine.apply(command:to:)` — resolves `turn` into new `facingDirection`; resolves `move(.forward/.backward)` with facing-relative grid delta
4. `Renderer.buildMinimap` — reads `facingDirection` to produce directional player marker
5. `InputHandler.mapKey` — maps A/D and Arrow Left/Right to `.turn`
6. `DungeonFrameKey` — used as-is; `nearLeft/Right/farLeft/Right` remain relative to current facing (depth already facing-relative in the new model)
