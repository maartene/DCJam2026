# Wave Decisions — Game Polish v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)

---

## Purpose

This file records decisions made during the DISCUSS wave and open decisions that must be resolved
by the developer or DESIGN wave before implementation. It is the authoritative record of choices
that affect multiple stories.

---

## Decisions Made in DISCUSS Wave

### WAVE-DEC-01: Q Key Removal

**Decision**: Q and Shift-Q are removed from the quit key mapping. ESC is the sole quit key.
**Rationale**: Confirmed playtest issue. Q is adjacent to WASD and causes accidental exits.
**Confirmed by**: docs/NOTES.md (playtest note), developer request in feature brief.
**Affects**: US-P02, InputHandler.swift

---

### WAVE-DEC-02: Transient Overlay Duration

**Decision**: Brief overlays (SHIELDED, SCORCHED, SWOOSH) auto-clear after approximately
0.75 seconds, which is 23 frames at 30Hz.
**Rationale**: Short enough to not interrupt play; long enough to read a single word.
**Note**: Exact frame count (23) is a starting suggestion. Developer may tune during implementation.
**Affects**: US-P06, US-P07

---

### WAVE-DEC-03: Content Source for Egg and Win Screens

**Decision**: Spike2 (`spikes/spike2-narrative-overlay.swift`) is the authoritative content
reference for egg discovery and win screen narrative text.
**Rationale**: Developer identified spike2 as the target in the feature brief. Spike2 content
is confirmed as production-quality narrative.
**Affects**: US-P03, US-P04

---

### WAVE-DEC-04: Color Thresholds for HP Bar

**Decision**: HP >= 40% of maxHP: green. HP < 40%: yellow. HP < 20%: red.
**Rationale**: Matches feature brief specification. Thresholds are inclusive at the boundary
(40% HP = green, not yellow; 20% HP = yellow, not red).
**Affects**: US-P05a

---

### WAVE-DEC-05: Minimap Color Per Cell, Not Per Row

**Decision**: Minimap color is applied per-cell with a reset after each character.
**Rationale**: Row-at-a-time string building cannot support per-cell coloring without
either pre-building per-cell ANSI strings or switching to per-cell writes.
**Affects**: US-P05c, Renderer.renderMinimap()
**Design decision required**: Whether to refactor renderMinimap() to per-cell writes or
build pre-colored ANSI strings per row. Both achieve the requirement. DESIGN wave chooses.

---

## Open Decisions — Developer Must Confirm Before Implementation

### OPEN-01: Brace Parry Success Overlay Word

**Question**: What dragon-themed word should appear when a brace parry succeeds?
**Suggestion from DISCUSS wave**: SHIELDED!
**Alternatives**: GUARDED! / DEFLECTED! / HELD!
**Constraint**: Single word, all caps, exclamation mark. Must fit in the main view area (78 cols).
**Decision**: SHIELDED!
**Affects**: US-P06a acceptance criteria

---

### OPEN-02: Brace Hit-Taken Overlay Word

**Question**: What dragon-themed word should appear when an enemy hit lands without an active parry window?
**Suggestion from DISCUSS wave**: SCORCHED!
**Alternatives**: BURNED! / STRUCK! / OUCH!
**Constraint**: Single word, all caps, exclamation mark.
**Decision**: STRUCK!
**Affects**: US-P06b acceptance criteria

---

### OPEN-03: Dash Feedback Overlay Word

**Question**: What dragon-themed word should appear when Ember dashes through a guard?
**Suggestion from DISCUSS wave**: SWOOSH!
**Alternatives**: SURGE! / BURST! / LUNGE!
**Constraint**: Single word, all caps. May include a prefix punctuation mark (~ or *) if desired.
**Decision**: SWOOSH!
**Affects**: US-P07 acceptance criteria

---

## Open Design Decisions — DESIGN Wave

### OPEN-04: Transient Overlay Mechanism (IC-03)

**Question**: How should auto-clearing transient overlays (brace feedback, dash feedback)
be represented in the codebase?

**Option A (Preferred — testable)**:
Add a `transientOverlay: TransientOverlay?` field to `GameState`.
`TransientOverlay` is an enum with associated frame-countdown value.
`RulesEngine` sets it; `Renderer` reads it; `RulesEngine.advance()` decrements the countdown.
Allows unit testing of overlay lifetime.

**Option B (Simpler)**:
Add new `NarrativeEvent` cases (`.braceSuccess`, `.braceFail`, `.dashFeedback`).
Add a frame countdown in `Renderer` only.
Simpler but mixes timing logic into the Renderer and reduces testability.

**Constraint**: Mechanism must not require player input to dismiss.
Mechanism must have priority rules: death screen beats SCORCHED; existing NarrativeEvent
overlays are unaffected.

**Decision**: ___________________ (DESIGN wave records here)
**Affects**: US-P06, US-P07

---

### OPEN-05: Brace Outcome Signal in RulesEngine (IC-03 — required for US-P06)

**Question**: How does RulesEngine communicate parry outcome (success or failure) to the Renderer?

Currently: `RulesEngine.apply()` updates `GameState.specialCharge` on parry success and
`GameState.hp` on hit. Neither change is a named event — Renderer cannot distinguish
"parry success" from "hp just happened to increase", nor "unbraced hit" from any other
hp decrease.

**Required**: A named signal that:
- Fires when an enemy attack resolves
- Indicates whether the parry window was active (success) or not (failure)
- Is consumed within ~23 frames and then cleared

**This is satisfied by OPEN-04 (transient overlay mechanism) if the mechanism includes
both the overlay identity AND the frame countdown.**

**Decision**: ___________________ (DESIGN wave records here after resolving OPEN-04)
**Affects**: US-P06

---

## Decision Log (Chronological)

| ID | Date | Decision | Made By |
|----|------|----------|---------|
| WAVE-DEC-01 | 2026-04-03 | Q key removed; ESC retained | DISCUSS wave (from feature brief) |
| WAVE-DEC-02 | 2026-04-03 | Transient overlay duration: ~23 frames (0.75s) | DISCUSS wave |
| WAVE-DEC-03 | 2026-04-03 | Spike2 is authoritative content reference | DISCUSS wave (from feature brief) |
| WAVE-DEC-04 | 2026-04-03 | HP color thresholds: 40% and 20% | DISCUSS wave (from feature brief) |
| WAVE-DEC-05 | 2026-04-03 | Minimap: per-cell color | DISCUSS wave |
| OPEN-01 | — | Brace parry success word | Awaiting developer |
| OPEN-02 | — | Brace hit-taken word | Awaiting developer |
| OPEN-03 | — | Dash word | Awaiting developer |
| OPEN-04 | — | Transient overlay mechanism | Awaiting DESIGN wave |
| OPEN-05 | — | Brace outcome signal in RulesEngine | Awaiting DESIGN wave |
