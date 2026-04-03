# User Story Map — Game Polish v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)

---

## Scope Assessment: PASS — 7 stories, 2 bounded contexts (InputHandler + Renderer/GameDomain), estimated 4–6 days total

All stories are independently deliverable. No story depends on another being complete first
(IC-05 is a sequencing preference, not a hard dependency). Walking skeleton ships US-P02 first
as the lowest-risk change.

---

## User Activity Backbone (Horizontal Spine)

```
LAUNCH        NAVIGATE        FIGHT (Brace/Dash)        FIND EGG        WIN
  |               |                   |                     |              |
Start screen  Colored UI          Feedback overlays     Egg screen     Win screen
              status bar          SHIELDED / SCORCHED   (narrative)    (narrative)
              minimap color       SWOOSH
Remove Q      HP color
```

---

## Story Map Grid

### Activity 1: Launch

| User Task | Walking Skeleton | Release 1 |
|-----------|-----------------|-----------|
| See game title and controls before playing | US-P01 Start Screen | — |
| Not accidentally quit while pressing WASD | US-P02 Remove Q as Quit | — |

### Activity 2: Navigate Dungeon

| User Task | Walking Skeleton | Release 1 |
|-----------|-----------------|-----------|
| Read HP state at a glance without mental math | US-P05a HP Bar Color | — |
| See at-a-glance whether Special is ready | US-P05b Charge/Cooldown Color | — |
| Read minimap landmarks without squinting | US-P05c Minimap Color | — |

### Activity 3: Fight (Brace/Dash)

| User Task | Walking Skeleton | Release 1 |
|-----------|-----------------|-----------|
| Know immediately when a Brace worked or failed | US-P06 Brace Feedback Overlays | — |
| See the Dash as an event, not just a position change | US-P07 Dash Feedback Overlay | — |

### Activity 4: Find the Egg

| User Task | Walking Skeleton | Release 1 |
|-----------|-----------------|-----------|
| Feel the egg discovery as a named relief beat | US-P03 Egg Pickup Screen | — |

### Activity 5: Win

| User Task | Walking Skeleton | Release 1 |
|-----------|-----------------|-----------|
| Feel the win as earned exhale, not just a stats screen | US-P04 Win Screen | — |

---

## Walking Skeleton

The minimum end-to-end slice that delivers a meaningfully improved play experience:

1. **US-P02** — Remove Q as quit key (safety fix; no new features)
2. **US-P01** — Start screen (orientation; introduces ESC as quit to replace Q)
3. **US-P05a** — HP bar color (highest-visibility improvement; no new state)

These three stories together close the most critical playtest issues (accidental quit,
no orientation, flat visuals) with the lowest implementation risk.

---

## Release Slicing

All 7 stories ship in a single polish pass — they are small, independent, and collectively
constitute the "game-polish-v1" feature. Suggested implementation order within the sprint:

| Order | Story | Reason |
|-------|-------|--------|
| 1 | US-P02 | Smallest change; critical safety fix; no new rendering |
| 2 | US-P01 | Start screen requires new ScreenMode case; ships with ESC-to-quit info |
| 3 | US-P05a | HP color; extends existing drawStatusBar; low risk |
| 4 | US-P05b | Charge/cooldown color; same pattern as US-P05a |
| 5 | US-P04 | Win screen content update; no new architecture |
| 6 | US-P03 | Egg screen content update; no new architecture |
| 7 | US-P05c | Minimap color; medium-complexity refactor of row rendering |
| 8 | US-P07 | Dash overlay; reuses recentDash flag; needs transient overlay mechanism |
| 9 | US-P06 | Brace overlays; needs new state signal (IC-03); most complex |

Note: US-P06 and US-P07 share an overlay mechanism. If that mechanism is designed for US-P07,
US-P06 can reuse it. Consider batching them in the same implementation session.

---

## Stories Not In Scope

The following items from docs/NOTES.md are noted but deferred:
- "Graphics pass: improve dungeon graphics" — out of scope for this polish wave; no user story created.
