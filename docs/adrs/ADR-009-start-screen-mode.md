# ADR-009: Start Screen Implementation via ScreenMode.startScreen
**Status**: Accepted
**Date**: 2026-04-03
**Feature**: game-polish-v1

---

## Context

US-P01 requires a start screen that appears before the dungeon on launch. The screen must
show the game title, narrative hook, key bindings, and "any key to begin" prompt. It must
not show the dungeon, status bar, minimap, or thoughts panel.

The existing architecture dispatches all rendering through `ScreenMode` (in GameDomain),
which the `Renderer` uses as a strategy selector. `GameState.initial()` sets the starting
`screenMode`.

Three implementation approaches were considered:

**Option A** — New `case startScreen` in `ScreenMode`. `GameState.initial()` starts
with `.startScreen`. `Renderer` adds a new strategy branch. Dismiss via any keypress
transitions to `.dungeon` through `RulesEngine.applyConfirmOverlay()`.

**Option B** — Renderer-internal flag `var hasShownStartScreen = false`. Renderer checks
the flag before any other render and shows the start screen on first call. Any subsequent
call proceeds normally.

**Option C** — New `NarrativeEvent.gameStart` case. Start screen rendered as a narrative
overlay. Dismiss via `confirmOverlay` (same as all narrative events).

---

## Decision

**Option A is adopted.**

`ScreenMode` gains `case startScreen`. `GameState.initial(config:)` sets `screenMode: .startScreen`.
`RulesEngine.applyConfirmOverlay()` transitions `.startScreen → .dungeon` on any non-quit keypress.
`Renderer.render(_:)` gains a new case that calls `renderStartScreen()` without chrome.

---

## Consequences

**Positive**:
- Follows the established pattern — ScreenMode is the project's documented strategy dispatch
  mechanism (CLAUDE.md). Adding one case is a zero-surprise extension.
- `GameState.screenMode == .startScreen` is observable in tests — tests can verify initial
  state and post-keypress transition.
- The start screen holds for any number of frames while `screenMode == .startScreen`;
  no special frame-counting is needed.
- Renderer can render the start screen with no chrome by simply not calling `drawChrome()` —
  clean and intentional.

**Negative**:
- `ScreenMode` grows by one case. All existing switch statements that exhaust `ScreenMode`
  must add a `.startScreen` branch. The compiler enforces exhaustiveness, so omissions are
  build errors, not runtime bugs.

---

## Alternatives Considered

### Option B: Renderer-internal flag

Rejected because:
- Mutable state in the Renderer violates the project's principle that the Renderer is a
  stateless consumer of GameState.
- The start-screen-shown flag is not resettable on restart — `GameState.initial()` does
  a full reset (INT-04), but a Renderer flag would persist across restarts.
- Not testable: a test cannot inspect whether the Renderer has shown the start screen.

### Option C: NarrativeEvent.gameStart

Rejected because:
- `NarrativeEvent` overlays render _over_ the dungeon chrome (rows 2–16) with the status
  bar, thoughts panel, and border still visible. The start screen must replace the entire
  terminal. These are fundamentally different rendering modes.
- Using a narrative event for the start screen would require the Renderer to special-case
  it anyway, defeating the purpose of sharing the NarrativeEvent pathway.

---

## "Any Key" Dismissal Implementation Note

US-P01 requires "any key to begin" (not just Space/Enter). Implementation options:

1. `RulesEngine.applyConfirmOverlay()` triggers on `.startScreen` for `confirmOverlay`
   command; separately, `GameLoop` converts any non-`.none` command to `.confirmOverlay`
   while `state.screenMode == .startScreen`.

2. A broader match: `applyConfirmOverlay` matches any GameCommand when screenMode is
   `.startScreen`.

The crafter chooses whichever is simpler. The architectural constraint is: the `.startScreen
→ .dungeon` transition must be triggered by a GameCommand processed through RulesEngine,
not by a Renderer state change.
