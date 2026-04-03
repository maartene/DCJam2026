# Walking Skeleton — Ember's Escape (dcjam2026-core)
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Quinn (Acceptance Test Designer — DISTILL wave)

---

## Definition

The walking skeleton is the thinnest end-to-end slice of the game loop that delivers observable player value and is demo-able to stakeholders.

**Litmus test**: Can a player accomplish their goal and see the result?

For Ember's Escape: Can a player spawn, encounter a guard, Dash through, reach stairs, descend, and die if HP hits 0?

---

## Scope

Stories: US-01, US-02, US-04, US-11

Deliberately excluded from the skeleton (added in Slice 1 and 2):
- Egg discovery narrative event (US-07)
- Special attack (US-03)
- Brace parry timing mechanics (US-05) — invulnerability window, cooldown, Special bonus
- Milestone upgrades (US-08)
- Boss encounter (US-09)
- Exit patio win (US-10)

---

## User Journey

```
Ember spawns on Floor 1
  → Status bar shows: HP full, Dash [2], Special [empty], Egg [inactive]
  
Ember encounters the first guard
  → Screen transitions to combat mode
  → Dash, Brace, Special are shown in the action list
  
Ember selects Dash
  → Ember advances 3 squares forward
  → Dash charge decrements to 1
  → Encounter ends — screen returns to dungeon navigation
  
Ember reaches the staircase
  → Steps onto staircase
  → Floor counter increments to 2
  → Ember placed at Floor 2 entry point
  
Ember's HP reaches 0 (from taking unbraced hits in too many encounters)
  → Death screen appears
  → Restart option presented
```

This journey is entirely observable, demo-able to a stakeholder, and fully contained within `GameDomain` with zero terminal I/O.

---

## Test File

`Tests/DCJam2026Tests/WalkingSkeletonTests.swift`

**First enabled scenario** (runs immediately):

```
WS-01: Ember's HP is full when a new run begins
```

This scenario tests `GameState.initial(config:)` — the first thing the crafter must implement.

All subsequent walking skeleton scenarios are `.disabled("not yet implemented")` and are enabled one at a time.

---

## Driving Port Invocations

All walking skeleton tests call into `GameDomain` through these public entry points:

| Test Action | Driving Port Call |
|-------------|------------------|
| Ember spawns | `GameState.initial(config: GameConfig.default)` |
| Ember Dashes | `RulesEngine.apply(command: .dash, to: state, deltaTime: 0.0)` |
| Ember steps onto stairs | `RulesEngine.apply(command: .move(.forward), to: state, deltaTime: 0.0)` |
| Ember takes a fatal unbraced hit | `RulesEngine.apply(command: .none, to: state, deltaTime: config.enemyAttackInterval + 0.1)` |
| Floor is generated | `FloorGenerator.generate(floorNumber:config:)` |

No internal component is called directly. All behavior is exercised through the public surface of `GameDomain`.

---

## Stakeholder Demo Script

After the walking skeleton is green, a stakeholder can run:

```
swift test --filter WalkingSkeletonTests
```

All 13 scenarios passing means: "Ember can spawn, encounter a guard, Dash through, traverse floors, and die. The core loop works."

This is the definition of done for Slice 0.
