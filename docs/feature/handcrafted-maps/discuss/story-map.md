# User Story Map — handcrafted-maps

**Feature**: handcrafted-maps
**Date**: 2026-04-04

<!-- markdownlint-disable MD024 -->

## Scope Assessment: PASS — 5 stories, 2 contexts, estimated 2–3 days

---

## Story Map Backbone (User Activities)

```
DEFINE           REGISTER          RENDER           NAVIGATE         VALIDATE
floor layouts    floors in         floor label      new floor        backwards
as Swift data    FloorRegistry     in top border    topology         compat
─────────────────────────────────────────────────────────────────────────────
US-HM-01         US-HM-02          US-HM-03         US-HM-04         US-HM-05
FloorDefinition  FloorRegistry     Move label       Minimap uses     Existing
struct +         replaces          to top border    dynamic grid     tests pass
5 floor data     FloorGenerator    row 1            dimensions       with new
                 call sites                                          floors
```

---

## Walking Skeleton

The thinnest end-to-end slice that produces a working, observable behavior:

**US-HM-01 + US-HM-02 (migration step only)**: the existing L-shaped corridor is expressed as a `FloorDefinition` character grid and wired through `FloorRegistry.floor(1, config:)`. The returned `FloorMap` is cell-for-cell identical to the current `FloorGenerator` output. All existing tests pass unchanged. The floor looks identical to the player before and after this step.

This slice is the safe migration gate. It is verifiable: run the existing test suite (`swift test`). Green = skeleton works. No new floor topologies are authored until this gate is green.

**Key constraint**: the player must never see a regression — floor 1 looks identical before and after the migration step.

---

## Release Slices

### Release 1 — Safe Migration (walking skeleton)
Convert the existing L-shaped corridor to the character-grid `FloorDefinition` format. Wire through `FloorRegistry`. All existing tests still pass. Player sees no change. This is the migration gate — floors 2-5 are not authored until this release is green.

| Story | Title | Outcome |
|-------|-------|---------|
| US-HM-01 | FloorDefinition data type | Developer can express floor topology as `[String]` character grid |
| US-HM-02 | FloorRegistry replaces FloorGenerator (floor 1 only) | Floor 1 served from character grid; zero regression; all tests green |

### Release 2 — Display
Move floor label to top border. Minimap uses dynamic dimensions.

| Story | Title | Outcome |
|-------|-------|---------|
| US-HM-03 | Floor label in top border | Row 2 freed; wider maps can render without label overlap |
| US-HM-04 | Minimap renders dynamic-sized floors | Player sees full shape of each floor on minimap |

### Release 3 — Distinct Floors
All 5 floors have distinct layouts. Player journey complete.

| Story | Title | Outcome |
|-------|-------|---------|
| US-HM-05 | 5 distinct floor layouts | Floors 1-5 have different shapes, correct landmarks |

---

## Dependencies

```
US-HM-01 ──► US-HM-02 ──► US-HM-04
                    │
                    └──► US-HM-05
US-HM-03 (independent — purely a rendering change)
```

`US-HM-03` can be developed in parallel with `US-HM-01/02`.
`US-HM-04` requires `US-HM-02` (dynamic dimensions only matter when floors vary in size).
`US-HM-05` requires `US-HM-02` (floors need to be registered before they can be distinct).
