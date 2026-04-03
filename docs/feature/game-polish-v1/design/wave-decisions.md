# Wave Decisions — DESIGN wave
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Morgan (Solution Architect — DESIGN wave)

---

## Purpose

This file records decisions made during the DESIGN wave. It resolves all OPEN items from
the DISCUSS wave (`docs/feature/game-polish-v1/discuss/wave-decisions.md`) and records
new design-specific decisions.

---

## OPEN-04 Resolution: Transient Overlay Mechanism

**Decision**: Option A — `transientOverlay: TransientOverlay?` field in `GameState`.

**Rationale**:
- Frame countdown is part of observable game state; it belongs in GameDomain where it is
  testable by injecting deltaTime into `RulesEngine.apply()`.
- RulesEngine is the only component that knows when a parry outcome or dash fires. Setting
  the overlay at the same site that computes the outcome is logically cohesive.
- Option B (NarrativeEvent cases + countdown in Renderer) was rejected because it conflates
  full-screen keypress-dismissed overlays with sub-screen auto-clearing feedback — two
  architecturally distinct concerns. It also moves timing logic into the presentation layer,
  making the mechanic untestable without a running terminal.

**Impact**: New `TransientOverlay` type in GameDomain. New field on `GameState`. No changes
to `NarrativeEvent`. See `data-models.md` for full type specification.

---

## OPEN-05 Resolution: Brace Outcome Signal in RulesEngine

**Decision**: Resolved by OPEN-04. The `TransientOverlay` enum cases carry the parry outcome.

Specifically:
- `applyEnemyAttackTick()` in RulesEngine sets `.braceSuccess(framesRemaining: 23)` when
  `braceWasActive == true` and the enemy attack timer fires.
- `applyEnemyAttackTick()` sets `.braceHit(framesRemaining: 23)` when `braceWasActive == false`
  and the attack fires, and `newHP > 0`.
- Fatal hit case: `transientOverlay = nil`, `screenMode = .deathState`.

The Renderer reads `state.transientOverlay` each frame. It renders the appropriate overlay
word when the field is non-nil and the current screenMode is `.dungeon` or `.combat`.

---

## DESIGN-DEC-01: New ScreenMode Case for Start Screen

**Decision**: Add `case startScreen` to `ScreenMode` in `GameDomain/ScreenMode.swift`.

**Rationale**: The ScreenMode enum is the project's established dispatch mechanism for renderer
strategy selection (per CLAUDE.md). Adding `.startScreen` follows the existing pattern exactly
and requires zero new infrastructure. The alternative — handling start screen via a Renderer
flag or a NarrativeEvent case — would violate the established pattern and create an inconsistency.

**Impact**: `ScreenMode.swift` gains one case. `GameState.initial()` starts with `.startScreen`.
`RulesEngine.applyConfirmOverlay()` handles the `.startScreen → .dungeon` transition.

---

## DESIGN-DEC-02: Start Screen Dismissal via Existing `confirmOverlay` Command

**Decision**: Any non-quit keypress while in `.startScreen` triggers the `.startScreen → .dungeon`
transition. The `confirmOverlay` GameCommand is used as the dispatch signal.

**Rationale**: The start screen must respond to "any key" (AC: P01-AC-07). The simplest
implementation: `RulesEngine.applyConfirmOverlay()` already has a `guard case .narrativeOverlay`
check. Extending it to also handle `.startScreen` adds one branch with no new commands.
For keys that do not currently produce `confirmOverlay` (e.g., W, A, D), the GameLoop
can translate any non-`.none` command to `.confirmOverlay` when `screenMode == .startScreen`,
keeping the domain rule simple. Alternatively, `applyConfirmOverlay` can match on any
GameCommand when screenMode is `.startScreen`. The crafter chooses the simpler implementation.

**Impact**: `RulesEngine.applyConfirmOverlay()` gains a new case branch.

---

## DESIGN-DEC-03: Minimap Refactored to Per-Cell Writes

**Decision**: `Renderer.renderMinimap()` is refactored from row-at-a-time string building
to per-cell `moveCursor + write(colorCode + char + reset)` calls (WAVE-DEC-05 confirmed this
approach; DESIGN wave chooses per-cell writes over pre-colored row strings).

**Rationale**: Per-cell writes are self-documenting: each cell is an independent unit with
its own color code and reset. The alternative (pre-colored row strings built with ANSI per
character) produces the same output but is harder to read and more error-prone for reset
placement. Both achieve the AC. Per-cell writes are the safer choice.

**Impact**: `renderMinimap()` method body is rewritten. The number of terminal write calls
increases from ~7 (one per row) to up to 105 (15 cells × 7 rows), but each frame is already
a full redraw — this has no observable performance impact at 30Hz.

---

## DESIGN-DEC-04: ANSI Color Constants Centralized in ANSIColors.swift

**Decision**: A new file `Sources/App/ANSIColors.swift` holds all ANSI color constant strings
and a `colored(_:code:)` helper function. No raw `"\u{1B}["` escape literals appear in
`Renderer.swift` directly.

**Rationale**: Color codes are used in at least five methods (`drawStatusBar`, `renderMinimap`,
`renderNarrativeOverlay`, `renderWinScreen`, transient overlay layer). Centralizing prevents
copy-paste errors and makes a future color-theme change a single-file edit.

**Impact**: New file in App module. Does not affect GameDomain. Does not affect the public API.

---

## DESIGN-DEC-05: Overlay Word Text Owned by Renderer

**Decision**: The display strings "SHIELDED!", "STRUCK!", "SWOOSH!" and their sub-lines live
in `Renderer.swift` (or a Renderer companion), not in `TransientOverlay` or any GameDomain type.

**Rationale**: Display text is a presentation concern. The domain records _what happened_
(parry success, parry miss, dash) as a named enum case. The Renderer decides _how to express_
that event in the terminal. This keeps GameDomain free of language/vocabulary choices and
allows the crafter to change the overlay words without touching domain logic.

The confirmed words (from wave-decisions.md OPEN-01/02/03) are:
- Parry success: SHIELDED!
- Hit taken: STRUCK!
- Dash: SWOOSH!

---

## Decisions NOT Changed From DISCUSS Wave

The following DISCUSS wave decisions are accepted as-is:

| ID | Decision |
|----|---------|
| WAVE-DEC-01 | Q and Shift-Q removed; ESC sole quit key |
| WAVE-DEC-02 | Transient overlay duration: 23 frames (~0.75s at 30Hz) |
| WAVE-DEC-03 | Spike2 is authoritative content reference for egg/win screens |
| WAVE-DEC-04 | HP thresholds: 40% inclusive (green), 20% inclusive (yellow), below 20% (red) |
| WAVE-DEC-05 | Minimap: per-cell color |

---

## Decision Log (Chronological — DESIGN wave additions)

| ID | Date | Decision | Made By |
|----|------|----------|---------|
| OPEN-04 | 2026-04-03 | Transient overlay: GameState field (Option A) | DESIGN wave (Morgan) |
| OPEN-05 | 2026-04-03 | Brace signal: resolved by TransientOverlay enum cases | DESIGN wave (Morgan) |
| DESIGN-DEC-01 | 2026-04-03 | Start screen via ScreenMode.startScreen | DESIGN wave (Morgan) |
| DESIGN-DEC-02 | 2026-04-03 | Start screen dismissal via confirmOverlay command | DESIGN wave (Morgan) |
| DESIGN-DEC-03 | 2026-04-03 | Minimap: per-cell writes chosen over pre-colored strings | DESIGN wave (Morgan) |
| DESIGN-DEC-04 | 2026-04-03 | ANSI colors centralized in ANSIColors.swift | DESIGN wave (Morgan) |
| DESIGN-DEC-05 | 2026-04-03 | Overlay display words owned by Renderer, not GameDomain | DESIGN wave (Morgan) |
