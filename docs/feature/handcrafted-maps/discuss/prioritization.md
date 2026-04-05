# Prioritization — handcrafted-maps

**Feature**: handcrafted-maps
**Date**: 2026-04-04

---

## Delivery Sequence (Jam-Optimal)

Stories are sequenced for minimum risk and maximum early feedback. Each delivers a verifiable outcome before the next begins.

### Sequence

| Order | Story | Rationale | Verifiable outcome |
|-------|-------|-----------|-------------------|
| 1 | US-HM-01 FloorDefinition | Foundation — define the `[String]` character-grid data type before anything uses it | Compiles; `FloorDefinition` instances constructed in tests |
| 2 | US-HM-02 FloorRegistry — migration step (floor 1 only) | **Safe migration gate** — express existing L-shape as character grid, wire through FloorRegistry; all existing tests must pass before new floors are authored | `swift test` all-green; floor 1 topology identical; player sees no change |
| 3 | US-HM-03 Floor label in top border | Independent — no dependency on US-HM-02; frees row 2 before floors expand | Test: row 1 has label, row 2 does not |
| 4 | US-HM-04 Minimap dynamic dimensions | Test infrastructure — update helpers before floors 2-5 make them fail | Test: dynamic `screenRow` formula passes for height≠7 |
| 5 | US-HM-05 Five distinct floors | Payoff — author floors 2-5 using the new character-grid format; player experience complete | Visually distinct minimap shapes; all game-rule tests pass |

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Floor 1 regression after migration (movement tests fail) | Medium | High | Migration step (order 2) is a hard gate — `swift test` must be green before floors 2-5 are authored; verified by AC-HM-02-A |
| Character-grid parser extracts wrong Position for a landmark | Medium | High | AC-HM-01-B and AC-HM-02-A verify parsed positions match `FloorGenerator` output cell-for-cell |
| Minimap test helpers break for taller floors | High | Medium | Sequence: fix helpers (US-HM-04) before adding taller floors (US-HM-05) |
| Legend overlap on taller floors | Medium | Low | Documented in REQ-HM-04; truncation accepted for jam scope |
| Floor label character count overflow | Low | Low | Longest label "Floor 5/5" = 11 chars; 19-char panel; 8 chars of padding |
| AC-HM-02-D incomplete until floor 2 topology known | High | Low | Noted as sketch; other 4 AC scenarios for US-HM-02 are complete |

---

## Jam Scope Gate

Each story answers "Is this necessary for a submittable jam entry?":

| Story | Necessary? | Reasoning |
|-------|-----------|-----------|
| US-HM-01 | Yes | Required for all other stories |
| US-HM-02 | Yes | Game is unplayable with 5 identical floors |
| US-HM-03 | Yes | Floor label at row 2 breaks minimap for full-width floors |
| US-HM-04 | Yes | Without this, new floor sizes cause wrong minimap rendering |
| US-HM-05 | Yes | Core jam quality requirement — distinct floors are the feature |

All 5 stories pass the jam scope gate.
