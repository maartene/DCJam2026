# ADR-018: Floor Label at Row 2, Right Panel, in renderDungeon

**Date**: 2026-04-04
**Status**: Accepted
**Feature**: handcrafted-maps
**Author**: Morgan (nw-solution-architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

The floor label " Floor N/M " is currently written by `Renderer.renderDungeon` at row 2, cols `(80 - label.count)` to 79. Row 2 is the top row of the minimap panel. This overwrites the topmost row of the minimap, making any landmark in the topmost grid row invisible when the label occupies that position.

With the introduction of five handcrafted floors, the minimap must have row 2 unobstructed. The floor label must move to a different row.

Available locations in the right panel:
- Row 1 (top border) — box-drawing border, currently all `─` in the right-panel segment
- Row 2 — immediately below the top border, currently the first minimap row
- Rows 9–15 — currently used by the minimap legend

The label fits within 19 chars (max " Floor 5/5 " = 11 chars with spaces). Floor state (`state.currentFloor`, `state.config.maxFloors`) is already available in `renderDungeon`.

---

## Decision

**Write the floor label at row 2, cols 61–79, directly in `renderDungeon()`.** The minimap then starts at row 3 instead of row 2, costing one height row (see ADR-019 for the resulting height cap at 6 rows).

`drawChrome()` signature is unchanged. No parameter threading required. The label is written with a single `moveCursor` + `write` call inside `renderDungeon`, immediately before the minimap is drawn. In all other screen modes, row 2 of the right panel is not written by `renderDungeon` — it remains blank or is overwritten by whatever that mode renders.

---

## Alternatives Considered

### Option A: Row 2 right-panel label in renderDungeon (chosen)

- Positive: `drawChrome()` signature is unchanged — no refactor, no call-site updates elsewhere.
- Positive: Floor state is already available in `renderDungeon` — the label write is a two-line addition with no threading.
- Positive: Isolated to one method — easy to find, easy to delete, no hidden coupling.
- Positive: Simpler implementation: fewer changed call sites, fewer moved responsibilities.
- Negative: Minimap starts at row 3 instead of row 2 — costs 1 height row. Combined with the 6-row cap from ADR-019, floors are at most 6 rows tall. Acceptable at jam scope.
- Accepted.

### Option B: Embed label in row 1 right-panel segment via drawChrome parameter

Extend `drawChrome(floorLabel: String? = nil)`. When non-nil, the row 1 segment (cols 61-79) embeds the label centered, padded with `─`.

- Positive: `drawChrome` owns all row 1 writes — single responsibility.
- Positive: Label in row 1 frees row 2 for minimap, preserving full minimap height.
- Negative: `drawChrome` signature changes — every call site must be reviewed even with a default parameter.
- Negative: The label is now routed through a general-purpose chrome method, adding indirection for a feature-specific piece of state.
- Negative: For a jam game with a single developer, threading a parameter through a chrome utility method is unnecessary complexity.
- Rejected: row 2 placement is simpler with no meaningful user experience difference.

### Option C: Move label to row 17 separator segment

- Positive: Row 17 is also mostly `─` fill in the right-panel segment.
- Negative: Row 17 contains the `┴` T-junction at col 60 — embedding text adjacent to a T-junction is visually awkward.
- Negative: Row 17 is the bottom of the dungeon region — the label is more naturally associated with the top-of-panel.
- Rejected.

---

## Consequences

### Positive
- `drawChrome()` requires no modification — signature and all existing call sites remain unchanged
- Floor label placement is a localized two-line change inside `renderDungeon`
- Minimap row 2 is now the label row — consistent, predictable location in dungeon mode
- No dual-write risk; no ordering dependency between drawChrome and renderDungeon

### Negative
- Minimap starts at row 3 (not row 2). Combined with the row 17 separator, the usable minimap area is rows 3–8, giving a maximum floor height of 6. See ADR-019.

### Note for Software Crafter

In `renderDungeon`, before drawing the minimap, add:
```
output.moveCursor(row: 2, col: 61)
output.write(" Floor \(state.currentFloor)/\(state.config.maxFloors) ")
```
No changes to `drawChrome`. The minimap rendering starts at row 3 (update the starting row constant/offset in the minimap draw loop).
