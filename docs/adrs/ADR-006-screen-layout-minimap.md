# ADR-006: Screen Layout Redesign for 2D Minimap

**Date**: 2026-04-02
**Status**: Accepted
**Author**: Morgan (Solution Architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

The turning mechanic (WD-09) requires a dedicated 2D minimap region. The existing screen layout uses all 25 rows and 80 columns. The minimap cannot be an inline text string — it needs a grid-shaped area large enough to display an 11×7 cell grid.

The existing screen regions:
- Rows 1, 17, 20, 25: chrome (borders, separators)
- Rows 2-16: main view (dungeon / combat / overlays) — 15 rows × 78 cols interior
- Row 18: status bar
- Row 19: controls hint
- Rows 21-24: Thoughts (4 display rows)

The minimap requires a minimum of 11 columns × 7 rows for the cell grid. Additional rows/columns are needed for labels (floor number, facing indicator).

The terminal is fixed at 80×25 (CLAUDE.md constraint). No scrolling. No alternate screen resizing.

Quality attributes:
- The minimap must be legible at 80×25 resolution (WD-01: orientation is the primary UX concern)
- The dungeon view must remain visually effective as a first-person perspective view
- The status bar and basic controls hint must remain visible at all times

---

## Decision

**Vertical split: dungeon view left (cols 2-59), minimap panel right (cols 61-79). Controls hint removed (moved to start screen, future feature). Thoughts retains 4 display rows.**

New screen layout:

```
Row 1:      ┌──────────────────────────────────────────────────┬─────────────────┐
Rows 2-16:  │ dungeon view (58 cols × 15 rows interior)        │ minimap panel   │
            │                                                  │ (19 cols × 15)  │
Row 17:     ├──────────────────────────────────────────────────┴─────────────────┤
Row 18:     │ status bar (HP / EGG / DASH / BRACE / SPEC)                        │
Row 19:     ├─Thoughts───────────────────────────────────────────────────────────┤
Rows 20-23: │ Ember's thoughts (4 rows)                                          │
Row 24:     │                                                                    │
Row 25:     └────────────────────────────────────────────────────────────────────┘
```

Column positions:
- Col 1: left border `│`
- Cols 2-59: dungeon view interior (58 chars)
- Col 60: vertical divider `│`
- Cols 61-79: minimap panel interior (19 chars)
- Col 80: right border `│`

Row 17 chrome: the divider at col 60 is closed with `┴` at row 17 (T-junction bottom), joining the full-width horizontal separator. The top border at row 1 has a `┬` at col 60.

Minimap panel layout within rows 2-16 (15 rows, 19 cols):
- Row 2: floor label `Floor N/M`
- Row 3: blank
- Rows 4-10: 7-row minimap grid (11 chars wide, left-aligned)
- Row 11: blank
- Row 12: `Facing: ^` or appropriate caret
- Rows 13-16: blank / future use

Thoughts: retains 4 display rows (rows 20-23). Row 19 is the Thoughts separator (`├─Thoughts──...──┤`). The original 4-row Thoughts budget is fully preserved.

Controls hint: removed from the dungeon screen entirely. Key bindings will be shown on a start screen (planned as a separate polish feature). The row previously used for controls is reclaimed by Thoughts.

---

## Alternatives Considered

### Option A: Minimap Below the Dungeon View (horizontal stack)

Reduce the dungeon view to 8 rows (rows 2-9). Place the minimap in rows 10-16 (7 rows × 78 cols).

Trade-offs:
- Positive: Minimap uses the full 78-column width — very readable.
- Negative: 8 rows is insufficient for the first-person dungeon view. The existing frame art uses 15 rows. Reducing to 8 rows means discarding 7 rows of perspective art. The cramped dungeon view would harm immersion and require re-authoring all frames at 8 rows tall.
- Negative: The game's primary view (first-person dungeon) is degraded to serve the minimap. The minimap is a navigation aid; the dungeon view is the experience.
- Rejected: Dungeon view degradation is unacceptable.

### Option B: Minimap Replacing the Thoughts Panel

Use rows 21-24 (4 rows × 78 cols interior) for the minimap, removing Thoughts entirely.

Trade-offs:
- Positive: No dungeon view reduction. Minimap has 78-column width.
- Negative: 4 rows accommodate a 4-row grid at most. The floor grid is 7 rows tall. A 4-row minimap would truncate the grid or require scaling, making it harder to read.
- Negative: Thoughts provides narrative flavor — key to the game's dragon identity and emotional tone. Removing it entirely degrades the game quality significantly.
- Rejected: Grid too short, narrative loss too significant.

### Option C: Minimap as an Overlay (toggle with a key)

The minimap is not always visible. Player presses a key (e.g., M) to show/hide it. The dungeon view and Thoughts remain unchanged.

Trade-offs:
- Positive: No layout change required. No reduction in any region.
- Negative: Defeats the purpose of WD-01 (orientation is primary UX concern). If the minimap requires a keypress to show, players will neglect it. The caret indicator must be visible at all times — the player should never need to ask "which way am I facing?"
- Negative: Adds a modal state (minimap visible/hidden) with no game-mechanical benefit.
- Rejected: Does not meet WD-01.

### Option D: Vertical Split (chosen)

- Positive: Dungeon view retains 15 rows (full perspective view height). Only width is reduced: 78 → 58 chars.
- Positive: Minimap is always visible, always current, in a dedicated panel.
- Positive: 58-column dungeon view is still wide enough for readable ASCII art frames. The perspective view must be re-authored at 58 chars, but the structure (depth/left/right walls) is preserved.
- Negative: Dungeon frame art must be re-authored. This is a content task, not a coding task.
- Negative: Loss of 1 Thoughts row (4 → 3). Flavor text is still present; only one line is lost.
- Accepted.

---

## Consequences

### Positive
- Minimap always visible: player always knows their facing and position
- Dungeon view retains full 15-row height: perspective art is not degraded
- Thoughts retains 4 display rows: no loss of flavor text capacity
- Vertical divider clearly separates the two regions

### Negative
- All 52 dungeon frame strings must be re-authored at 58-char width (was 78). Content task.
- The chrome drawing function (`drawChrome()`) requires a `┬` at row 1 col 60, a `│` divider in rows 2-16 col 60, and a `┴` at row 17 col 60.

### Note for Software Crafter

AC-05-8 (controls hint row) is removed from scope — the controls hint is no longer part of the dungeon screen. Key bindings will appear on a future start screen.

The `drawChrome()` function in `Renderer.swift` must be updated:
- Top border: insert `┬` at col 60 (within the 78-char interior → char index 59)
- Side bars for rows 2-16: also draw `│` at col 60
- Row 17 separator: insert `┴` at col 60 position
- The `drawThoughts` helper targets rows 20-23 (4 rows) — same count as before, row numbers unchanged from original
- A new `drawMinimapPanel(_ state: GameState)` private method handles the right panel (cols 61-79, rows 2-16)

The status bar (row 18) and Thoughts separator (row 19) are unchanged from the original row assignments.
