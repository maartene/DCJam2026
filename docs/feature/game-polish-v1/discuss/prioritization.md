# Prioritization — Game Polish v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)

---

## Prioritization Criteria

This is a game jam polish pass. Priority is determined by:
1. **Playtest pain severity** — confirmed issues that break the session
2. **Effort** — implementation complexity (lower effort = earlier in sprint)
3. **Emotional arc impact** — does it close a named gap in the emotional journey?
4. **Risk** — does it require new architecture vs. content change only?

---

## Priority Matrix

| Story | Pain Severity | Effort | Emotional Impact | Risk | Priority |
|-------|--------------|--------|-----------------|------|----------|
| US-P02 Remove Q | Critical (accidental quit confirmed) | Trivial (2 lines) | Safety — uninterrupted flow | Very Low | P0 — ship first |
| US-P01 Start Screen | High (no orientation) | Low (new ScreenMode case + renderer) | Orientation → confidence | Low | P1 |
| US-P05a HP Color | High (no urgency signal) | Low (color logic in drawStatusBar) | Anxiety signal works naturally | Very Low | P2 |
| US-P05b Charge/Cooldown Color | Medium (charges are visible, just flat) | Low (same pattern as HP) | Special-ready moment stands out | Very Low | P2 |
| US-P04 Win Screen | Medium (terse, tone mismatch) | Low (content change only) | Earned relief delivered | Very Low | P3 |
| US-P03 Egg Screen | Medium (functional but flat) | Low (content change only) | Relief beat resonates | Very Low | P3 |
| US-P05c Minimap Color | Medium (threats blend in) | Medium (per-cell color refactor) | Situational awareness | Medium | P4 |
| US-P07 Dash Overlay | Medium (verb not visible) | Medium (transient overlay mechanism) | Delight reinforced | Medium | P4 |
| US-P06 Brace Overlays | High (mechanic invisible) | Medium-High (new state signal needed) | Mechanic clarity, satisfaction | High (IC-03) | P4 — after IC-03 design |

---

## P0 — Ship Immediately (No Sprint Planning Needed)

**US-P02**: Remove Q as quit key.
- 2-line change in `InputHandler.mapKey()`
- Zero risk of regression
- Closes confirmed playtest pain point
- Should ship in the same commit that opens this sprint

---

## P1 — High Value, Low Risk (Sprint Start)

**US-P01**: Start screen
- Requires `ScreenMode.startScreen` (new enum case)
- Renderer needs a `renderStartScreen()` method
- GameState.initial() must start in `.startScreen` mode
- Introduces the ESC-as-quit information that justifies removing Q

---

## P2 — High Visual Impact, No Architecture (Sprint Middle)

**US-P05a + US-P05b**: HP and Charge color
- Both extend `drawStatusBar()` with ANSI color wrapping
- Same implementation pattern — batch in one session
- Zero new state fields required

---

## P3 — Content Updates (Sprint Middle)

**US-P04 + US-P03**: Win screen and Egg screen narrative revision
- Reference material is in `spikes/spike2-narrative-overlay.swift`
- Pure content change in `Renderer.renderWinScreen()` and `Renderer.narrativeContent(.eggDiscovery)`
- No structural changes

---

## P4 — Moderate Complexity (Sprint End, After Architecture Decisions)

**US-P05c**: Minimap color
- Row-at-a-time string building in `renderMinimap()` needs to become per-cell writes
- Medium refactor; no new state, but changes rendering approach
- Should be validated that ANSI reset is clean per-cell

**US-P07**: Dash overlay
- `recentDash` flag already exists
- Overlay mechanism (auto-clear after 23 frames) is new
- Design decision: frame counter in GameState or in Renderer?

**US-P06**: Brace overlays
- Requires new brace outcome signal (IC-03 in shared-artifacts-registry)
- DESIGN wave must decide: `transientOverlay` in GameState vs. NarrativeEvent cases
- Cannot be implemented until that decision is made and signal is in GameState
- Recommend: design US-P07 overlay mechanism first, reuse for US-P06

---

## Deferred / Out of Scope

- "Graphics pass: improve dungeon graphics" — open-ended art pass; not a polish story with a clear acceptance criterion. Belongs in a separate discovery.
