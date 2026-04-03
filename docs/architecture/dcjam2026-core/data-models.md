# Data Models — Ember's Escape (dcjam2026-core)
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Morgan (Solution Architect — DESIGN wave)

All models are **value types** (`struct` or `enum`) unless noted. No classes in the domain. All mutable only at the boundary of `RulesEngine.apply(...)` — the result is a new value.

---

## GameState

The single source of truth for all game variables. Passed as an immutable snapshot from loop tick to renderer.

| Field | Type | Initial Value | Notes |
|-------|------|--------------|-------|
| `hp` | `Int` | `GameConfig.maxHP` | Clamped to [0, maxHP]. Death at 0. |
| `maxHP` | `Int` | `GameConfig.maxHP` | Modified by upgrades |
| `dashCharges` | `Int` | `2` | Cap: `dashChargeCap`. Modified by upgrades. |
| `dashChargeCap` | `Int` | `2` | Raised by upgrade |
| `specialCharge` | `Double` | `0.0` | Range [0.0, 1.0]. Full at 1.0. |
| `hasEgg` | `Bool` | `false` | Set true on egg room entry |
| `currentFloor` | `Int` | `1` | Range [1, maxFloors] |
| `playerPosition` | `Position` | floor entry point | `Position(row: Int, col: Int)` |
| `playerFacing` | `Direction` | `.north` | `.north .south .east .west` |
| `currentFloorMap` | `FloorMap` | generated | Current floor layout |
| `activeEncounter` | `EncounterModel?` | `nil` | Non-nil when in combat |
| `activeUpgrades` | `[Upgrade]` | `[]` | Persists for run duration |
| `thoughtsLog` | `ThoughtsLog` | empty | Append-only dragon thoughts |
| `timerModel` | `TimerModel` | all cooldowns 0 | Dash cooldowns + special charge tracking |
| `screenMode` | `ScreenMode` | `.dungeon` | Drives renderer strategy selection |
| `upgradeChoices` | `[Upgrade]?` | `nil` | Non-nil during upgrade prompt |
| `config` | `GameConfig` | default | Tuning constants |

---

## GameConfig

All tunable constants. Single source of truth for balancing values. Allows injection for testing.

| Constant | Default | Meaning |
|----------|---------|---------|
| `dashCooldownSeconds` | `45.0` | Seconds per charge to replenish |
| `dashStartingCharges` | `2` | Charges at game start |
| `dashStartingChargeCap` | `2` | Max charges before upgrades |
| `specialChargeRatePerSecond` | `0.008` | ~125s to full charge at default rate |
| `maxHP` | `100` | Starting and max HP |
| `maxFloors` | `5` | 3 (min viable) to 5 (target) |
| `braceDefenseMultiplier` | `0.4` | Incoming damage × multiplier when bracing |
| `upgradePoolSize` | `8` | Total pool of distinct upgrades |
| `upgradeChoiceCount` | `3` | Options shown per milestone |

---

## FloorMap

| Field | Type | Notes |
|-------|------|-------|
| `floorNumber` | `Int` | 1–5 |
| `grid` | `[[Cell]]` | 2D array. Cell is `enum`: `.wall .floor .door` |
| `entryPosition` | `Position` | Player spawns here |
| `staircasePosition` | `Position?` | Nil on final floor |
| `exitPosition` | `Position?` | Non-nil on final floor only |
| `eggRoomPosition` | `Position?` | Non-nil on exactly one floor in range 2–4 |
| `encounters` | `[Position: EncounterModel]` | Enemy positions |
| `isEggFloor` | `Bool` | Derived: `eggRoomPosition != nil` |

**Floor generation constraints** (enforced by `FloorGenerator`):
- Floor 1: `eggRoomPosition == nil`, low enemy density
- Floors 2–4: exactly one has `eggRoomPosition != nil`
- Floor 5: `eggRoomPosition == nil`, `exitPosition != nil`, contains boss encounter
- All floors: staircase reachable from entry (connectivity guaranteed)

---

## EncounterModel

| Field | Type | Notes |
|-------|------|-------|
| `id` | `UUID` | Unique per encounter instance |
| `enemyName` | `String` | Dragon-vocabulary enemy name |
| `maxHP` | `Int` | Enemy health |
| `currentHP` | `Int` | Enemy current health |
| `attackDamagePerSecond` | `Double` | Real-time damage rate |
| `isBossEncounter` | `Bool` | SA-11. True only for Floor 5 boss. Blocks Dash. |

---

## TimerModel

| Field | Type | Notes |
|-------|------|-------|
| `dashCooldowns` | `[Double]` | Per-charge remaining seconds. Count = `dashChargeCap`. 0 = charge ready. |
| `specialCharge` | `Double` | Mirrors `GameState.specialCharge`. Updated by `advance(delta:)`. |

`TimerModel.advance(delta: Double) -> TimerModel` — pure function. Decrements cooldowns, clamps at 0, increments special charge, clamps at 1.0.

---

## UpgradePool

| Upgrade ID | Name (dragon-language) | Effect |
|------------|----------------------|--------|
| `UP-01` | Swift Passage | Dash cooldown −10s |
| `UP-02` | Third Wind | Dash charge cap +1 |
| `UP-03` | Ancient Scales | Max HP +20 |
| `UP-04` | Ember's Fury | Special charge rate ×1.25 |
| `UP-05` | Ironhide | `braceDefenseMultiplier` −0.1 (more defense) |
| `UP-06` | Surging Current | Dash cooldown −15s (stronger version; pool contains at most one of UP-01 or UP-06) |
| `UP-07` | Breath Reserve | Second dash cooldown −5s (asymmetric reduction) |
| `UP-08` | Dragon's Patience | Special charge rate ×1.5 (replaces UP-04 if both would be drawn) |

**Draw rules**:
- Draw 3 from remaining pool (excluding already-selected upgrades)
- UP-01 and UP-06 are mutually exclusive (both reduce dash cooldown; pool offers at most one per run draw)
- UP-04 and UP-08 similarly mutually exclusive
- Pool of 8; max 3 milestones in a 5-floor run; max 3 upgrades total (one per milestone)

**Milestone triggers** (floor transitions):
- After Floor 2 descent: first upgrade prompt
- After Floor 4 descent: second upgrade prompt
- After Floor 3 descent (only in 5-floor runs): optional third prompt if time permits — design detail for crafter

---

## ThoughtsLog

| Field | Type | Notes |
|-------|------|-------|
| `entries` | `[(event: GameEvent, text: String)]` | Ordered. Newest last. |
| `maxVisible` | `Int` | 5 (configurable). Renderer shows last N entries. |

**Trigger events → sample text** (dragon vocabulary per REQ-10):

| Event | Sample Thought |
|-------|---------------|
| Floor 1 start | "These halls smell of human boots. I remember the light beyond." |
| Egg floor detected | "I can feel my egg on this floor!" |
| Egg discovered | "There you are. I've got you." |
| Dash used | "I surge past. He never lands a blow." |
| Brace used | "Scales up. I endure." |
| Special activated | "The fire rises from my chest — I cannot hold it." |
| Dash depleted | "Both charges gone. I must endure until I recover." |
| Boss encountered | "The guardian. It knows why I'm here." |
| Exit reached without egg | "I can't leave without my egg." |
| Exit reached with egg | "Finally. Light. We're going home." |

---

## ScreenMode

```
enum ScreenMode {
  case dungeon
  case combat(encounter: EncounterModel)
  case narrativeOverlay(event: NarrativeEvent)
  case upgradePrompt(choices: [Upgrade])
  case deathState
  case winState
}

enum NarrativeEvent {
  case eggDiscovery
  case specialAttack
  case exitPatio
}
```

The `Renderer` switches on `ScreenMode` to select the appropriate rendering strategy. All five modes produce visually distinct output (AC 13.1, 12.1, 3.1, 7.1, 10.1).

---

## GameCommand

```
enum GameCommand {
  case move(Direction)
  case dash
  case brace
  case special
  case confirmOverlay   // dismiss narrative overlay / confirm upgrade selection
  case selectUpgrade(Int)  // index 0–2 into upgradeChoices
  case restart
  case none
}

enum Direction {
  case forward, backward, turnLeft, turnRight
}
```

`RulesEngine.apply(_:to:deltaTime:) -> GameState` is the single transformation entry point. All game logic flows through this function. No side effects.

---

## Position

```
struct Position {
  let row: Int
  let col: Int
}
```

Grid coordinates. Origin `(0,0)` is top-left of floor map. `Direction` in the game world is relative to the player's facing — `FloorGenerator` maps `(position, facing, .forward)` to the next grid cell in the facing direction.
