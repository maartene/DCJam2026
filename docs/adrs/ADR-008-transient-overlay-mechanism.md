# ADR-008: Transient Overlay Mechanism for Auto-Clearing Feedback
**Status**: Accepted
**Date**: 2026-04-03
**Feature**: game-polish-v1
**Resolves**: OPEN-04, OPEN-05 (wave-decisions.md)

---

## Context

US-P06 (Brace feedback) and US-P07 (Dash feedback) require brief visual overlays that
auto-clear after approximately 0.75 seconds (23 frames at 30Hz) without player input.

Three concerns must be addressed simultaneously:
1. RulesEngine must be able to signal which event occurred (parry success, parry miss, dash).
2. The overlay must persist for a known number of frames regardless of player input.
3. The persistence countdown must be testable without a running terminal.

The DISCUSS wave identified two candidate approaches (OPEN-04):

**Option A** — `transientOverlay: TransientOverlay?` field in `GameState`.
`TransientOverlay` is an enum with per-case `framesRemaining: Int`.
`RulesEngine` sets it when the event fires. `RulesEngine.advanceTimers()` decrements it
each tick and nils it at zero. `Renderer` reads it and renders the overlay word if non-nil.

**Option B** — New `NarrativeEvent` cases (`.braceSuccess`, `.braceFail`, `.dashFeedback`).
Frame countdown lives in `Renderer` only. Simpler GameDomain change, but mixes timing
logic into the presentation layer.

---

## Decision

**Option A is adopted.**

`TransientOverlay` is a new `public enum` in GameDomain with three cases, each carrying
`framesRemaining: Int`. `GameState` gains a single optional field `transientOverlay`.
`RulesEngine` owns the lifetime. `Renderer` is a read-only consumer.

---

## Consequences

**Positive**:
- Frame countdown is part of game state — fully testable via `RulesEngine.apply()` with
  injected deltaTime, no terminal required.
- RulesEngine is the single authority over when overlays fire and how long they live.
  Priority rules (death beats STRUCK) are enforceable in pure logic.
- `NarrativeEvent` stays clean — it represents exclusively keypress-dismissed full-screen
  events. The two overlay categories remain architecturally distinct.
- Renderer stays stateless — it reads `state.transientOverlay` and renders; it does not
  own a countdown timer.

**Negative**:
- `GameState` gains one more field. This is minor — `GameState` already has 14 fields
  and the new one follows the same functional-update pattern.
- `TransientOverlay` is a new file in GameDomain, adding a small amount of surface area.

---

## Alternatives Considered

### Option B: NarrativeEvent cases + Renderer countdown

Rejected because:
- `NarrativeEvent` overlays are full-screen, keypress-dismissed, and pause the dungeon.
  Transient overlays are sub-screen, auto-clearing, and do not pause play. Adding transient
  events to `NarrativeEvent` would misrepresent their semantics.
- The countdown would live in `Renderer`, making it invisible to tests. Any bug in overlay
  lifetime (too short, never clears) would require a running terminal to reproduce.
- If additional transient events are added post-jam, the Renderer timer would grow into
  an ad-hoc state machine.

### Option C: `recentDash` pattern extended to brace

`recentDash: Bool` already exists and clears on the next tick. Extend it with `recentParry: Bool`
and `recentHit: Bool`, and handle countdown in Renderer.

Rejected for the same reasons as Option B (Renderer owns countdown, untestable), plus the
one-tick lifetime of `recentDash` is too short for a 23-frame overlay — the Renderer would
need to read it on tick N and retain it for 22 more ticks independently, defeating the purpose
of having domain state.
