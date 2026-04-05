# ADR-019: Minimap Legend — Floor Height Capped at 7 Rows

**Date**: 2026-04-04
**Status**: Accepted
**Feature**: handcrafted-maps
**Author**: Morgan (nw-solution-architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

The minimap legend (ADR-015) occupies rows 10–16 of the right panel (cols 61–79). Per ADR-018 (revised), the floor label is written at row 2, cols 61–79, and the minimap starts at row 3. For a floor of height H, the minimap occupies rows 3 to `3 + H - 1`.

Right-panel row layout:
```
row 2      : floor label
rows 3–9   : minimap (up to 7 rows)
rows 10–16 : legend (7 entries: ^ > v < G B * S X E)
row 17     : separator
```

Legend occupies rows 10–16 (7 entries). For the legend to never overlap the minimap, the minimap must end by row 9:

```
3 + H - 1 ≤ 9
H ≤ 7
```

Allowing floors taller than 7 rows would require either suppressing the legend, relocating it dynamically, or accepting garbled overlap. Dynamic relocation degrades (fewer than 7 entries fit) for tall floors and adds layout arithmetic.

---

## Decision

**Cap all handcrafted floor heights at 7 rows.** The maximum map size is 19×7.

`FloorDefinition` grids authored by the developer must not exceed 7 rows. With this constraint, the minimap always fits within rows 3–9, and the legend at rows 10–16 is never obstructed — no conditional, no layout arithmetic, no runtime check.

---

## Alternatives Considered

### Option A: Height cap at 7 rows (chosen)

- Positive: The legend is always fully visible. No conditional code.
- Positive: No layout arithmetic in `renderDungeon` — the constraint is an authoring rule, not a runtime rule.
- Positive: Simpler implementation: remove the `if floor.grid.height <= N { drawMinimapLegend() }` guard entirely.
- Positive: Width is unconstrained at 19 (full right-panel interior). Varying widths provide layout variety within the 7-row cap.
- Negative: 7-row maximum limits vertical corridor depth. Horizontal layouts (wide corridors, east-west branches) must replace very tall layouts.
- Negative: Earlier design specified floors 2–5 with heights 9–12; those specifications are now superseded. Height is no longer a differentiator — width and topology shape (T, Z, room) provide the perceived distinctness instead.
- Accepted at jam scope: developer preference is simplicity over conditional suppression logic.

### Option B: Conditional legend suppression when floor height > 7

Wrap `drawMinimapLegend()` in `if floor.grid.height <= 7 { ... }`.

- Positive: Allows taller floors (up to whatever fits before the separator).
- Negative: Legend is absent on any floor taller than 7 rows. Jam judges on later floors lose the legend entirely.
- Negative: Adds a conditional path that requires a dedicated acceptance test to verify.
- Rejected: more complex than a static authoring constraint with no user experience benefit.

### Option C: Shift legend dynamically below the minimap

Compute legend start row as `max(10, 3 + floor.grid.height + 1)`.

- Positive: Legend always present.
- Negative: For a floor of height 10, legend starts at row 14 — only 3 entries fit before row 17. Nearly useless.
- Negative: Layout arithmetic must guard against writing into separator row 17.
- Deferred to post-jam.

### Option D: Shrink legend to available rows

Cap legend entries to `max(0, 16 - (3 + H - 1) - 1)` entries.

- Positive: Some legend always shown.
- Negative: Truncated entries are arbitrary — showing only the first 3 of 7 symbols is potentially more confusing than nothing.
- Rejected.

---

## Consequences

### Positive
- Legend is always fully visible on every floor — no per-floor conditional
- `renderDungeon` is simpler: `drawMinimapLegend()` is an unconditional call
- No overlap possible at any valid floor size (width up to 19, height up to 7)

### Negative
- Floor height variety is limited: all floors are 7 rows or fewer
- Floors 2–5 topology specifications in data-models.md must be revised to fit within 7 rows

### Note for Software Crafter

`drawMinimapLegend()` is called unconditionally in `renderDungeon` and renders at rows 10–16. No `if floor.grid.height <= N` guard is needed. The developer ensures all authored `FloorDefinition` grids have at most 7 rows; exceeding this is an authoring error, not a runtime error (jam scope).
