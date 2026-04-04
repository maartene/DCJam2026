# Wave Decisions — Gameplay Fixes and Polish (DISCUSS)

**Feature ID**: gameplay-fixes-polish
**Wave**: DISCUSS
**Date**: 2026-04-04
**Status**: Complete — ready for DESIGN wave handoff

---

## Prior Wave Consultation Checklist

| File | Status | Notes |
|------|--------|-------|
| docs/project-brief.md | not found | No project brief exists; game context sourced from CLAUDE.md and NOTES.md |
| docs/stakeholders.yaml | not found | No stakeholder file exists; developer is sole stakeholder |
| docs/architecture/constraints.md | not found | Constraints are in docs/CLAUDE.md (read and applied) |
| docs/feature/gameplay-fixes-polish/discover/ | not found | No prior DISCOVER wave; items are developer-defined |
| docs/CLAUDE.md | found | Read in full; all constraints applied |
| docs/NOTES.md | found | Read in full; confirmed all 3 items match developer's TODO list |

---

## Decisions Made in This Wave

### DEC-DISCUSS-01: JTBD Skipped

JTBD analysis was skipped per configuration (`jtbd: skip`). The three items are
developer-defined corrections to an existing feature, not feature discoveries
requiring job-story analysis. All items trace to the developer's own NOTES.md TODO list.

### DEC-DISCUSS-02: No Emotional Arc Produced

Emotional arc documentation was skipped per configuration (`interactive: low`).
The items are a bug fix, a design correction, and a polish improvement — not
a new user journey. The visual journey document records current-state vs.
desired-state behaviour, which is the appropriate lightweight substitute.

### DEC-DISCUSS-03: Guard Removal Requires GameState Change

The bug fix (US-GPF-01) cannot be resolved purely in the renderer. The root cause
is that `FloorMap.encounterPosition2D` is static and `GameState` carries no
record of cleared encounters. A new field in `GameState` is required.

**Constraint passed to DESIGN wave**: `FloorMap` must remain immutable
(struct, value type, ADR-002). The cleared-encounter state must live in `GameState`.
The specific data structure (e.g. `Set<Position>`, `Bool` flag, per-floor dictionary)
is a DESIGN wave decision.

### DEC-DISCUSS-04: Dash Bypass Does Not Clear the Encounter

Dash is explicitly defined as a movement escape mechanic, not a defeat mechanic
(game rule: DISC-03 — "only Dash exits encounters"). When a player Dashes out of
combat, the guard is bypassed, not defeated. The cleared-encounter flag must only
be set when `encounter.enemyHP <= 0`, not on Dash exit.

This is an observable, testable constraint captured in Scenario 3 of US-GPF-01.

### DEC-DISCUSS-05: Boss Name Change — "HEAD WARDEN"

The boss entity was previously named "DRAGON WARDEN" in the HUD. This was likely
a placeholder. The correct name, consistent with the game's human-antagonist
narrative, is "HEAD WARDEN". This name is specified as an AC item in US-GPF-02
and is a hard requirement, not a suggestion.

The word "DRAGON" must not appear in the boss's HUD label — it belongs to Ember,
not the enemy.

### DEC-DISCUSS-06: Boss ASCII Art Constraints (Design Wave Owns Final Art)

The DISCUSS wave specifies constraints on the boss art, not the final art itself:
- Must depict an upright human figure
- Must not contain cat ears (`/\___/\` ear pattern)
- Must not contain whiskers or feline facial features
- Should read as "large" and "armoured" (formidable jailer aesthetic)

The DESIGN wave (solution-architect) owns the final art. These constraints are
non-negotiable; the execution is flexible.

### DEC-DISCUSS-07: Legend in Right Panel, Rows 9-16

The minimap occupies rows 2-8 of the right panel (cols 61-79). Rows 9-16 are
currently unused in dungeon mode. The legend fits exactly into rows 9-16
(7 entries, 7 rows) with row 17 as the protected status-bar separator.

This layout was chosen to avoid disrupting any other UI region and to keep
the legend co-located with the minimap it explains.

### DEC-DISCUSS-08: Legend Shows 7 Symbols (Not All 10)

The minimap uses 10 distinct characters. The legend shows 7:
`^ (You), G (Guard), B (Boss), * (Egg), S (Stairs), E (Entry), X (Exit)`.

Omitted from legend: `>/<` facing variants (implied by `^`), `e` (egg collected —
the egg room colour shift is self-explanatory after first encounter), `#`/`.`
(wall/floor — universal dungeon shorthand).

This decision keeps the legend compact and focused on tactically useful information.

---

## Scope Assessment

**3 stories | 2 bounded contexts (GameDomain, Renderer) | ~2.5 days estimated**

All stories are right-sized per Elephant Carpaccio criteria. No splitting required.
Stories are independent and can be delivered in any order (recommended: GPF-01 first).

---

## Handoff Package Summary

| Artifact | Path |
|----------|------|
| Journey visual (current vs. desired) | docs/feature/gameplay-fixes-polish/discuss/journey-gameplay-fixes-visual.md |
| Journey schema (YAML) | docs/feature/gameplay-fixes-polish/discuss/journey-gameplay-fixes.yaml |
| Gherkin scenarios | docs/feature/gameplay-fixes-polish/discuss/journey-gameplay-fixes.feature |
| Story map | docs/feature/gameplay-fixes-polish/discuss/story-map.md |
| User stories (all 3) | docs/feature/gameplay-fixes-polish/discuss/user-stories.md |
| DoR validation | docs/feature/gameplay-fixes-polish/discuss/dor-validation.md |
| Wave decisions (this file) | docs/feature/gameplay-fixes-polish/discuss/wave-decisions.md |

All 3 stories have passed DoR. Handoff to DESIGN wave is unblocked.
