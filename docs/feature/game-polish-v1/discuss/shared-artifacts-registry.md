# Shared Artifacts Registry — Game Polish v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)

---

## Purpose

This registry tracks every shared data artifact (game state fields, enums, renderer signals) used
across the polish user stories. It identifies which stories read from and write to each artifact,
and flags integration risks.

---

## Registry

### SA-P01: ScreenMode (enum)

| Property | Value |
|----------|-------|
| Source of truth | `Sources/GameDomain/ScreenMode.swift` |
| Current cases | `.dungeon`, `.combat`, `.narrativeOverlay`, `.upgradePrompt`, `.deathState`, `.winState` |
| Change required | Add `.startScreen` case |
| Read by | `Renderer.render()` — switch on screenMode |
| Written by | `RulesEngine.apply()` on game start, `GameState.initial()` |
| Stories | US-P01 (Start Screen) |
| Risk | Adding `.startScreen` without handling in Renderer will crash the switch. Must add rendering case. |

---

### SA-P02: GameState.hp / GameState.config.maxHP

| Property | Value |
|----------|-------|
| Source of truth | `Sources/GameDomain/GameState.swift` |
| Type | `Int` / `Int` |
| Change required | None — data already present |
| Read by | `Renderer.drawStatusBar()` (HP bar fill calculation) |
| Written by | `RulesEngine.apply()` on combat damage |
| Stories | US-P05a (HP Bar Color) |
| Integration | HP percentage = `Double(hp) / Double(config.maxHP)`. Thresholds: < 0.20 = red, < 0.40 = yellow, else green. |
| Risk | Low. Existing fill calculation can be extended with color selection. |

---

### SA-P03: GameState.specialCharge / GameState.specialIsReady

| Property | Value |
|----------|-------|
| Source of truth | `Sources/GameDomain/GameState.swift` |
| Type | `Double` (0.0–1.0), computed `Bool` |
| Change required | None |
| Read by | `Renderer.drawStatusBar()` — specBar rendering |
| Written by | `RulesEngine.apply()` — passive charge gain, brace bonus, special use |
| Stories | US-P05b (Charge/Cooldown Color) |
| Risk | Color must reset after each segment — no ANSI bleed to adjacent status elements. |

---

### SA-P04: GameState.timerModel.activeCooldownDuration / GameState.braceOnCooldown

| Property | Value |
|----------|-------|
| Source of truth | `Sources/GameDomain/GameState.swift`, `TimerModel.swift` |
| Type | `Double`, `Bool` |
| Change required | None |
| Read by | `Renderer.drawStatusBar()` — dashCooldownStr, braceCooldownStr |
| Written by | `RulesEngine.apply()` / `TimerModel.advance(delta:)` |
| Stories | US-P05b (Charge/Cooldown Color) |
| Risk | braceCooldownStr already built in drawStatusBar — apply color wrapper around existing string. |

---

### SA-P05: GameState.hasEgg

| Property | Value |
|----------|-------|
| Source of truth | `Sources/GameDomain/GameState.swift` |
| Type | `Bool` |
| Change required | None |
| Read by | `Renderer.drawStatusBar()` — eggSymbol; `Renderer.minimapChar()` |
| Written by | `RulesEngine.apply()` on egg room entry |
| Stories | US-P03 (Egg Screen content), US-P05c (Minimap color — egg symbol) |
| Risk | Low. eggSymbol already conditional on hasEgg. |

---

### SA-P06: GameState.recentDash

| Property | Value |
|----------|-------|
| Source of truth | `Sources/GameDomain/GameState.swift` |
| Type | `Bool` |
| Change required | None |
| Read by | `Renderer.dungeonThoughts()` — already reads recentDash for thought flavor |
| Written by | `RulesEngine.apply()` — set true on dash, cleared next tick |
| Stories | US-P07 (Dash Feedback Overlay) |
| Integration | Renderer already reads this flag. Extend to show SWOOSH overlay when true. |
| Risk | recentDash is cleared after one tick — overlay must persist for ~23 frames. Renderer needs its own frame counter OR a new transient state field. |

---

### SA-P07: GameState.braceWindowActive (computed: braceWindowTimer > 0)

| Property | Value |
|----------|-------|
| Source of truth | `Sources/GameDomain/GameState.swift` |
| Type | `Bool` (computed) |
| Change required | None |
| Read by | `RulesEngine` — determines parry outcome; Renderer will need to read outcome result |
| Written by | `RulesEngine.apply()` on Brace command |
| Stories | US-P06 (Brace Feedback Overlays) |
| Risk | The parry outcome (success or failure) is computed in RulesEngine but is not currently surfaced to the Renderer. A new state signal is required. |

---

### SA-P08: Brace Outcome Signal (NEW — to be designed)

| Property | Value |
|----------|-------|
| Source of truth | To be determined in DESIGN wave |
| Type | Not yet defined |
| Change required | New field or enum case required |
| Read by | Renderer (to select overlay: SHIELDED or SCORCHED) |
| Written by | RulesEngine when enemy attack resolves |
| Stories | US-P06a (Parry success), US-P06b (Hit taken) |
| Options | Option A: `transientOverlay: TransientOverlay?` in GameState with frame countdown. Option B: NarrativeEvent cases `.braceSuccess` / `.braceFail`. |
| Risk | DESIGN wave decision. Requirement: must be cleared after ~23 frames without requiring player input. |
| Constraint | Must not trigger if hp <= 0 after the hit (death screen takes priority). |

---

### SA-P09: NarrativeEvent.eggDiscovery (existing content)

| Property | Value |
|----------|-------|
| Source of truth | `Sources/GameDomain/NarrativeEvent.swift`, `Renderer.narrativeContent()` |
| Type | `NarrativeEvent` enum case |
| Change required | Update narrative text in `Renderer.narrativeContent(.eggDiscovery)` |
| Reference | `spikes/spike2-narrative-overlay.swift` → `showEggOverlay()` |
| Stories | US-P03 (Egg Pickup Screen) |
| Risk | Low. Content change only — no structural change to enum or ScreenMode. |

---

### SA-P10: ScreenMode.winState (existing renderer)

| Property | Value |
|----------|-------|
| Source of truth | `Sources/App/Renderer.swift` → `renderWinScreen()` |
| Change required | Update content of `renderWinScreen()` to match spike2 exit overlay tone |
| Reference | `spikes/spike2-narrative-overlay.swift` → `showExitOverlay()` |
| Stories | US-P04 (Win Screen) |
| Existing data | `state.currentFloor`, `state.hp` — already rendered; retain in summary block |
| Risk | Low. Renderer change only. |

---

### SA-P11: InputHandler key mapping

| Property | Value |
|----------|-------|
| Source of truth | `Sources/App/InputHandler.swift` → `mapKey()` |
| Change required | Remove `UInt8(ascii: "q")` and `UInt8(ascii: "Q")` from quit branch |
| Stories | US-P02 (Remove Q as Quit Key) |
| Risk | Low risk for code. Medium communication risk: existing players who know Q will need to see the start screen to learn ESC. |

---

### SA-P12: Minimap character rendering

| Property | Value |
|----------|-------|
| Source of truth | `Sources/App/Renderer.swift` → `minimapChar()`, `renderMinimap()` |
| Change required | Wrap each character write in the appropriate ANSI color code + reset |
| Stories | US-P05c (Minimap Color) |
| Risk | Medium. renderMinimap builds a full row string and calls write() once per row. Color codes require per-character output or grouped by cell type — row-at-a-time string building needs refactoring to per-cell writes, OR the whole row is built as a pre-colored ANSI string. |

---

## Dependency Graph

```
US-P01 (Start Screen)
  depends on: SA-P01 (add ScreenMode.startScreen)
  blocks nothing else

US-P02 (Remove Q)
  depends on: SA-P11 (InputHandler)
  prerequisite: SA-P01 (start screen must list ESC before Q is removed)

US-P03 (Egg Screen Content)
  depends on: SA-P09 (existing NarrativeEvent.eggDiscovery)
  no new dependencies

US-P04 (Win Screen Content)
  depends on: SA-P10 (existing ScreenMode.winState)
  no new dependencies

US-P05a (HP Color)
  depends on: SA-P02 (hp, maxHP)

US-P05b (Charge/Cooldown Color)
  depends on: SA-P03 (specialCharge), SA-P04 (timerModel, braceCooldown)

US-P05c (Minimap Color)
  depends on: SA-P12 (minimap rendering refactor)

US-P06 (Brace Feedback)
  depends on: SA-P07 (braceWindowActive), SA-P08 (NEW brace outcome signal)
  SA-P08 is an integration checkpoint requiring DESIGN wave decision

US-P07 (Dash Feedback)
  depends on: SA-P06 (recentDash)
  secondary: SA-P08-style transient overlay mechanism (same mechanism as US-P06)
```

---

## Integration Checkpoints

| ID | Risk | Description | Wave |
|----|------|-------------|------|
| IC-01 | Medium | `ScreenMode.startScreen` must be handled in Renderer switch or build fails | DESIGN |
| IC-02 | Medium | Minimap row-at-a-time write needs per-cell color — refactor approach needed | DESIGN |
| IC-03 | High | Brace outcome signal does not exist — design required before US-P06 can be implemented | DESIGN |
| IC-04 | Low | ANSI color reset must close every colored segment to prevent bleed in status bar | DESIGN |
| IC-05 | Low | Start screen must be shown before Q removal (US-P01 ships before US-P02 or same sprint) | DESIGN |
