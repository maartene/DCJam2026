# Evolution: gameplay-fixes-polish

**Date**: 2026-04-04
**Feature ID**: gameplay-fixes-polish
**Status**: COMPLETE

---

## Feature Summary

Three targeted gameplay fixes and polish items that close the loop on combat clarity, boss identity, and map readability.

**US-GPF-01** — Guards are now permanently cleared after being defeated by a Special attack. The player no longer re-triggers combat when walking back through a cell where an enemy was killed. Cleared positions reset on floor descent, so each new floor starts fresh.

**US-GPF-02** — The final boss is renamed from "DRAGON WARDEN" to "HEAD WARDEN" and given a new ASCII figure (human armoured warden) and a new Thoughts line reflecting Ember's personal motivation. The original dragon-warden framing was narratively inconsistent.

**US-GPF-03** — A 7-entry minimap legend is rendered in the right panel (dungeon screen only) so players can identify all symbols without guessing.

---

## Business Context

**Jam**: DCJam 2026
**Problem**: Playtesting identified three friction points: (1) re-fighting cleared guards was confusing and punishing, (2) the boss name and art did not fit the game's narrative, and (3) the minimap had no legend, making symbols opaque to first-time players.
**Solution**: Minimal targeted fixes — no new systems, no scope creep. All three items are submittable-entry requirements.

---

## Delivery Execution — Completed Steps

All 30 roadmap steps across 3 user stories completed on 2026-04-04. Every step followed the TDD RED-GREEN-COMMIT cycle.

### US-GPF-01: Guard Cleared After Defeat

| Step | Name | Outcome |
|---|---|---|
| 01-01 | Add `clearedEncounterPositions` to `GameState` | PASS |
| 01-02 | RulesEngine records cleared position on Special kill | PASS |
| 01-03 | RulesEngine skips combat trigger for cleared positions | PASS |
| 01-04 | Cleared set resets on floor descent | PASS |
| 01-05 | Renderer minimap shows `.` for cleared cells | PASS |

### US-GPF-02: Head Warden Boss

| Step | Name | Outcome |
|---|---|---|
| 02-01 | Rename boss to "HEAD WARDEN" in Renderer.swift | PASS |
| 02-02 | Replace cat ASCII art with human armoured warden figure | PASS |
| 02-03 | Update boss Thoughts line | PASS |

### US-GPF-03: Minimap Legend

| Step | Name | Outcome |
|---|---|---|
| 03-01 | Render 7-entry legend in right panel (rows 9-15, cols 61-79) | PASS |
| 03-02 | Legend visible in dungeon screen mode only | PASS |
| 03-03 | `^` symbol uses bold bright white ANSI matching minimap player symbol | PASS |

---

## Key Decisions

- **Cleared set on `GameState`** — pure value type, carries no behaviour. `RulesEngine` reads and writes it via the standard state-transformation pattern. No new protocols or adapters required.
- **Reset on floor descent** — cleared encounters are floor-scoped. Persisting across floors would require a more complex data structure and offers no gameplay benefit within the jam scope.
- **Minimap legend placement** — right panel rows 9-15 (cols 61-79) chosen as consistently empty space in the dungeon screen layout. Legend is suppressed in combat, narrative, and upgrade screens to avoid visual collision.
- **Boss rename only** — "HEAD WARDEN" required changes to Renderer only (`Renderer.swift`). `GameDomain` has no knowledge of the boss name; the name is a presentation concern. No ADR required.

---

## Lessons Learned

### 1. Cleared-position guard prevents a class of test ambiguity

When the cleared-position set was introduced, several existing combat tests became ambiguous about whether the player was entering a cleared or active encounter cell. Explicitly seeding `clearedEncounterPositions` in test fixtures eliminated the ambiguity and improved test readability. Including cleared-state in test setup should be standard practice for any test that involves player movement into an encounter cell.

### 2. ASCII art in source code — keep it short and vertical

The replacement warden ASCII art is 9 lines tall. Longer art would push it out of the combat screen bounds. Authoring directly in the Swift string literal worked cleanly because the art is narrow and static. If art grows beyond ~12 lines or needs variants, a lookup table (as used for dungeon frames) would be warranted.

---

## Test Results

| Category | Count | Status |
|---|---|---|
| Total Swift tests | 282 | All PASS |
| New tests (GPF-01 cleared-position logic) | included in 282 | PASS |
| New tests (GPF-03 legend render) | included in 282 | PASS |
| Regression | 0 failures | PASS |

---

## Implementation Artifacts (Permanent — in repo)

| Artifact | Location |
|---|---|
| `GameState` cleared positions field | `Sources/GameDomain/GameState.swift` |
| RulesEngine cleared-position logic | `Sources/GameDomain/RulesEngine.swift` |
| Boss name, art, and Thoughts | `Sources/Renderer/Renderer.swift` |
| Minimap legend render | `Sources/Renderer/Renderer.swift` |
