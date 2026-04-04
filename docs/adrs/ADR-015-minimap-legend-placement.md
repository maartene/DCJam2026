# ADR-015: Minimap Legend in Right Panel Rows 9-15

**Status**: Accepted
**Date**: 2026-04-04
**Feature**: gameplay-fixes-polish
**Resolves**: DEC-DISCUSS-07, DEC-DISCUSS-08

---

## Context

The minimap (right panel, cols 61-79, rows 2-8) uses 10 distinct characters with
per-cell ANSI colouring (ADR-010). There is no legend. New players and jam judges
cannot determine what "G", "B", "*", "S", "E", or "X" mean without guessing.

The right panel layout is:
```
Row 1   ┌─────────────────────┐
Row 2   │ minimap row 0       │
...     │ ...                 │
Row 8   │ minimap row 6       │
Row 9   │ (unused)            │
...     │ ...                 │
Row 16  │ (unused)            │
Row 17  ├─────────────────────┤  ← separator (must not be overwritten)
Row 18  │ status bar          │
```

Rows 9-16 are currently unused in dungeon mode. A 7-entry legend fits exactly in
rows 9-15 with row 16 as a blank buffer and row 17 protected.

---

## Decision

A `drawMinimapLegend()` helper is added to `Renderer`. It is called exclusively from
`renderDungeon`, ensuring the legend never appears in combat, narrative, upgrade,
death, or win modes.

**Layout**:
- Entries at rows 9-15 (one per row), cols 61-79.
- Row 16: blank (buffer before separator).
- Row 17: separator — NOT written to by the legend.

**7 legend entries** (DEC-DISCUSS-08 — 3 omitted symbols are self-explanatory):

| Row | Symbol | Colour | Label |
|-----|--------|--------|-------|
| 9 | `^` | `ansiBoldBrightWhite` | `You` |
| 10 | `G` | `ansiBrightRed` | `Guard` |
| 11 | `B` | `ansiBoldBrightRed` | `Boss` |
| 12 | `*` | `ansiBrightYellow` | `Egg` |
| 13 | `S` | `ansiBrightCyan` | `Stairs` |
| 14 | `E` | `ansiDimCyan` | `Entry` |
| 15 | `X` | `ansiBoldBrightCyan` | `Exit` |

Symbol colours reuse `minimapColor(for:)` — single source of truth for symbol-to-colour
mapping. Labels are plain text (no ANSI colour applied to the text portion).

---

## Consequences

**Positive**:
- New players immediately understand all tactically relevant minimap symbols.
- Co-located with the minimap it explains — no context switching.
- Reuses existing colour constants — zero risk of colour mismatch between legend and map.
- The `drawMinimapLegend` call is confined to `renderDungeon` — legend never bleeds into
  other screen modes.
- Row 17 separator is structurally protected: the legend writes to rows 9-15 only.

**Negative**:
- Adds 7 additional `moveCursor` + `write` calls per dungeon frame. At 30 Hz, this is
  210 additional calls/second. Each is buffered and flushed atomically — negligible
  overhead consistent with the ADR-010 per-cell performance analysis.

---

## Alternatives Considered

### Alternative: Render legend below the status bar (rows 21-24, Thoughts region)

Rejected. The Thoughts region is already used for Ember's internal monologue, which is
a narrative feature. A legend there would compete with story text and break the
established role of that region.

### Alternative: Render legend as a header above the minimap (row 1, right panel)

Rejected. Row 1 is the top chrome border — overwriting it would corrupt the box drawing.

### Alternative: Show 10 entries (all minimap symbols)

Rejected per DEC-DISCUSS-08. `>/<` facing variants are implied by `^`; `e` (egg
collected) and `#`/`.` (wall/floor) are universal dungeon shorthand. Showing all 10
would add noise without tactical value and risks overflowing into row 17.
