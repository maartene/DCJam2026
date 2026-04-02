# Prioritization — Dragon Escape
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Luna (Product Owner — DISCUSS wave)

---

## Prioritization Principles

Three criteria govern every prioritization decision for this feature:

1. **Jam deadline is absolute.** A partial Slice 0 that submits beats a complete Slice 2 that does not.
2. **Dash is the irreducible core.** Any story that directly enables or proves the Dash mechanic is highest priority. (DEC-01)
3. **Jam rules are a hard gate.** Stories that satisfy jam requirements (stat modification, death condition, combat encounter) cannot slip past Slice 2 regardless of polish state.

---

## Story Priority Table

| Priority | Story | Slice | Rationale |
|----------|-------|-------|-----------|
| 1 | US-02: Dash — Pass Through | 0 | The game's reason to exist. If this is not working, nothing else matters. |
| 2 | US-01: Game Start UI Legibility | 0 | The entire "tutorial" is the UI state. Without this, Dash teaching fails. |
| 3 | US-04: Floor Structure and Descent | 0 | Without floors, there is no game to play. |
| 4 | US-11: Death Condition | 0 | Hard jam rule. Fail state is required. |
| 5 | US-07: Egg Discovery | 1 | Primary emotional beat. Defines the game's core goal. |
| 6 | US-10: Exit Patio | 1 | Win condition. Without this, the game cannot be completed. |
| 7 | US-05: Brace Action | 1 | Completes the action set. Required for option-starved window to make sense. |
| 8 | US-06: Special Charge Meter | 1 | Prerequisite for US-03. Player must see charge building before Special fires. |
| 9 | US-03: Special Attack | 2 | Power beat. Strong jam showpiece. Jam stat-modification partially served by upgrades (US-08 primary). |
| 10 | US-08: Milestone Upgrades | 2 | Satisfies jam stat-modification rule. Developer's stated preference. |
| 11 | US-09: Boss Encounter | 2 | Climactic encounter. Jam requires a combat encounter — confirmed by earlier encounters. Boss is the narrative peak. |

---

## If Time Runs Short: Cut Sequence

If Day 4 is not available, cut in this order (last to first):

1. **Cut first**: Boss encounter (US-09) — the game is completable without a boss; exit can be reached after defeating any regular enemy on Floor 5, or Floor 5 can be an empty corridor to the exit.
2. **Cut second**: Upgrade polish (Slice 3) — 6-8 upgrade pool can ship with 3-4 entries if tuning is incomplete.
3. **Cut third**: Special full-screen visual (part of US-03) — reduce to ASCII border + distinct text if full-screen interrupt is not feasible (fallback from DEC-06 spike).
4. **Never cut**: US-01, US-02, US-04, US-07, US-10, US-11. These are the game.

---

## Jam Compliance Map

| Jam Rule | Satisfied By | Slice |
|----------|-------------|-------|
| First-person exploration | Floor generation (US-04) | 0 |
| Step movement on square grid | Dash + navigation (US-02, US-04) | 0 |
| 90-degree turns | Navigation (US-04) | 0 |
| Player stat (HP bar) | Game start UI (US-01) | 0 |
| Combat or encounter mechanic | Dash encounter (US-02), Brace (US-05) | 0-1 |
| Win condition | Exit patio (US-10) | 1 |
| Death / fail condition | Death condition (US-11) | 0 |
| Stat modification mechanic | Milestone upgrades (US-08) | 2 |
| Theme: Dragons | Dragon vocabulary, narrative frame | throughout |
| Theme: Cleaning up the hero's mess | Egg narrative, exit text (US-07, US-10) | 1 |

All jam rules are satisfied by end of Slice 2.

---

## Risk-Adjusted Delivery Order (within each slice)

### Slice 0 internal order

1. US-04 first — the floor grid is the foundation everything else renders on top of
2. US-02 second — Dash requires the grid to exist
3. US-01 third — UI requires the game state to exist
4. US-11 fourth — death check requires HP state to exist

### Slice 1 internal order

1. US-06 first — Special charge display is a prerequisite for US-03 (Slice 2) and must be visible
2. US-05 second — Brace action requires encounter system from Slice 0
3. US-07 third — Egg discovery requires floor generation from Slice 0
4. US-10 fourth — Exit patio requires egg state (SA-04) to exist

### Slice 2 internal order

1. US-08 first — Upgrades require floor milestone events from Slice 0/1
2. US-03 second — Special attack requires charge meter from US-06 (Slice 1)
3. US-09 last — Boss requires encounter system + Dash blocking flag

---

## Dependency Graph

```
US-04 (floors)
  └── US-02 (Dash)
        └── US-01 (UI — shows dash state)
              └── US-11 (death — HP in UI)
                    └── US-05 (Brace — encounter complete)
                          └── US-06 (spec meter — visual)
                                └── US-07 (egg — requires floors 2-4)
                                      └── US-10 (exit — requires egg)
                                            └── US-03 (Special — requires spec meter)
                                                  └── US-08 (upgrades — requires floor milestones)
                                                        └── US-09 (boss — requires encounters + dash block)
```
