# ADR-003: First-Person Dungeon Rendering Approach

**Date**: 2026-04-02
**Status**: Accepted
**Author**: Morgan (Solution Architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

Dragon Escape requires a first-person 3D dungeon view rendered in ASCII/character art in a terminal. The player moves on a square grid with step movement and 90-degree turns. The view must show walls ahead, corridor openings to the left and right, and a sense of depth as the corridor extends forward.

Three rendering approaches were evaluated. The feasibility spike from the DISCOVER wave (DEC-06, spike 1) asks whether the grid can support Dash pass-through — this is a domain/rules question, not a rendering question. The rendering approach is independent of how Dash works on the grid.

---

## Decision

**Pre-computed depth-zone rendering using an ASCII art lookup table indexed by dungeon view state.**

The dungeon view state is a tuple: `(wallAhead: Bool, wallLeft: Bool, wallRight: Bool, openingLeft: Bool, openingRight: Bool, depth: Int)` where `depth` is the number of open cells visible ahead (capped at 4 zones).

A lookup table (or a switch/pattern-match structure) maps each unique state to a pre-authored ASCII art frame. The frame is emitted verbatim to the TUI layer.

---

## Alternatives Considered

### Option A: Ray-Casting (Wolfenstein/DOOM style)
Column-by-column wall distance computation. Each column of the viewport casts a ray through the 2D grid. Wall height (or in terminal terms, wall density/character selection) is inversely proportional to distance.

Trade-offs:
- **Positive**: Smooth perspective. Works with any grid geometry. Accurate depth per column.
- **Negative**: Floating-point computation per column per frame (80 columns = 80 ray casts per tick at 30 Hz = 2400 ray casts/second). Overkill for a jam — no profiling needed to know this is excessive.
- **Negative**: Terminal cells are fixed-width characters, not pixels. Ray-casting maps naturally to pixel columns, not character columns. The character art of "wall at distance 2" is not a scaled-down version of "wall at distance 1" — they look different in ASCII. The output would require post-processing to convert floating-point distances to character art anyway.
- **Negative**: More complex to implement correctly in a 4-day jam. Ray-casting has known implementation pitfalls (fisheye correction, texture mapping artifacts).
- Rejected: computational overhead and implementation complexity exceed jam benefit. The visual output is character art, not pixel art — ray-casting's continuous distance model does not add value.

### Option B: Pre-Computed Depth-Zone Lookup Table (chosen)
Enumerate all meaningful view states. Author ASCII art frames for each. At render time, query the grid for the 5 cells ahead (1 ahead for immediate wall, up to 4 ahead for depth), 1 cell left, 1 cell right. Map to frame. Output.

View states:
```
Zone 1 (wall immediately ahead): corridor ends
Zone 2 (wall 2 cells ahead):     medium corridor
Zone 3 (wall 3 cells ahead):     long corridor
Zone 4+ (4+ cells ahead):        maximum depth / vanishing point
× left wall / left opening
× right wall / right opening
= up to 4 × 2 × 2 = 16 distinct frames
```

Plus special frames: left-only turn, right-only turn, T-junction, four-way junction. Total: ~20-25 distinct frames.

Trade-offs:
- **Positive**: Zero per-frame computation beyond a grid lookup (O(1) per render). Runs trivially fast.
- **Positive**: Frames are ASCII strings — authorable, inspectable, unit-testable (snapshot tests).
- **Positive**: Visual quality is entirely under the developer's control. Can be authored to feel atmospheric.
- **Positive**: Implementation is straightforward: query grid cells, select frame, output string. No floating-point.
- **Positive**: Well-established approach for dungeon crawlers (Wizardry, Bard's Tale, Eye of the Beholder all use this model).
- **Negative**: Limited to the pre-authored view states — complex diagonal corridors or unusual geometry are not representable. For a grid-based dungeon with square corridors, this is not a limitation.
- **Negative**: ~20-25 ASCII art frames to author. Not a coding problem — a content authoring task. Manageable for a solo developer in 4 days.
- Accepted.

### Option C: Procedural ASCII Line Drawing
Compute wall edges procedurally: given wall distances, draw trapezoid outlines using `/`, `\`, `|`, `_` characters. No pre-authored frames.

Trade-offs:
- **Positive**: Dynamic — handles any corridor geometry.
- **Negative**: Terminal character sets are not designed for geometric line drawing. Diagonal lines in `/ \ |` look crude and inconsistent. Box-drawing characters (U+2500) are orthogonal only.
- **Negative**: The output would look significantly less atmospheric than pre-authored art. The developer's mockup shows a clearly hand-crafted perspective view — this approach cannot produce that style.
- Rejected: visual quality does not match the developer's mockup aesthetic; character geometry is too crude for the intended atmosphere.

---

## Consequences

### Positive
- Frame rendering is a table lookup — testable as a pure function `(ViewState) -> String`
- Frame art is authorable incrementally: the walking skeleton needs only 1-2 frames (wall ahead, open corridor); more frames added in subsequent slices
- No dependency on floating-point math in the rendering path
- Lookup table approach is self-documenting: each frame is visually identifiable by its key

### Negative
- ~20-25 ASCII art frames to author (content authoring effort, not coding)
- Grid lookup depth is capped at 4 zones — longer corridors render as "maximum depth" (a deliberate design choice that also simplifies authoring)
- Adding truly novel geometry (circular rooms, diagonal walls) would require new frames — not a jam concern

### Implementation Note for Software Crafter

The ViewState query function should look 5 cells ahead in the player's facing direction and 1 cell each side. The frame selection logic is pure and belongs in the `Renderer` module (not `GameDomain`). ASCII art frames are stored as `String` constants in a dedicated `DungeonFrames` namespace within `Renderer`. Frame authoring is the developer's creative task during the GREEN phase.
