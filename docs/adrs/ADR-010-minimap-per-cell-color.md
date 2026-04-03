# ADR-010: Minimap Color via Per-Cell Writes
**Status**: Accepted
**Date**: 2026-04-03
**Feature**: game-polish-v1
**Resolves**: WAVE-DEC-05 design choice

---

## Context

US-P05c requires each minimap cell to render in a distinct ANSI color, with a reset code
after each character to prevent color bleed.

The current `renderMinimap()` builds each of the 7 grid rows as a plain `String(rowChars)`
and writes the whole row in one `output.write()` call. This approach cannot support per-cell
ANSI coloring without modification.

WAVE-DEC-05 confirmed that per-cell coloring is required but left the implementation
approach open for the DESIGN wave:

**Option A** — Per-cell writes: for each cell, call `output.moveCursor(row, col + x)`
then `output.write(colorCode + char + reset)`.

**Option B** — Pre-colored row strings: build each row as a concatenation of
`colorCode + char + reset` per cell, then write the whole row string in one call.

---

## Decision

**Option A (per-cell writes) is adopted.**

`renderMinimap()` is refactored to an inner loop: for each `(x, y)` cell, compute the
minimap character, look up its color code, call `output.moveCursor`, and call
`output.write(colorCode + char + reset)`.

---

## Consequences

**Positive**:
- Each cell's color code and reset are emitted as a paired unit — it is structurally
  impossible to emit a color without the subsequent reset.
- The code reads as: "for each cell, position cursor, write colored character." This matches
  the mental model and is easy to audit for correctness.
- Adding a new landmark type or changing a color requires editing one lookup, not a string
  concatenation.

**Negative**:
- Terminal write calls increase from 7 (one per row) to up to 105 (15 × 7 cells).
  However, `ANSITerminal` buffers all writes and flushes atomically once per frame.
  The additional overhead is negligible — the buffer grows by approximately 600 extra
  bytes per frame (ANSI codes), which is well within the 4096-byte pre-allocated capacity.

---

## Alternatives Considered

### Option B: Pre-colored row strings

Rejected because:
- A concatenated row string of `colorCode + char + reset` per cell is functionally equivalent
  but harder to read. The color and reset for any given cell are separated by intervening
  characters for adjacent cells.
- The reset placement is not enforced by structure — a developer building the row string
  could accidentally omit the reset for one cell without a compiler warning.
- Option A and Option B have identical runtime output; Option A is safer to maintain.

---

## Performance Note

The minimap panel is 15 columns wide and 7 rows tall (105 cells). At 30Hz, this is
3,150 moveCursor + write calls per second. Each write appends ~12 bytes (ESC code + char
+ reset) to the buffer. The buffer growth from minimap color is approximately 1,260 bytes
per frame — absorbed by the existing 4096-byte reservation in ANSITerminal. No performance
concern.
