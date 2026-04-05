# ADR-016: Multi-line String Character-Grid Format for Handcrafted Floor Definitions

**Date**: 2026-04-04
**Status**: Accepted
**Feature**: handcrafted-maps
**Author**: Morgan (nw-solution-architect — DESIGN wave)
**Deciders**: Maarten Engels (developer)

---

## Context

The `handcrafted-maps` feature requires a way to express five distinct floor layouts as static data so the developer can author them without modifying generation algorithm code. `FloorGenerator` currently mixes data (hardcoded positions and passability logic) with construction logic, making it impossible to author different layouts per floor without changing the algorithm.

A data format is needed that:
- Expresses both the floor topology (passable/impassable cells) and all landmark positions in a single artifact
- Requires zero runtime I/O (jam constraint: `GameDomain` has no I/O)
- Is readable to a human looking at the source code
- Is maintainable by a solo developer under jam time pressure
- Requires no new Swift Package dependencies

The format choice has downstream consequences for how `FloorDefinitionParser` scans for landmark positions and how `FloorRegistry` constructs `FloorMap` values.

---

## Decision

**`"""` multi-line string**: a single Swift multi-line string literal where each line is one row of the grid. Each `Character` encodes both the passability and landmark type of that cell. The `"""` block is split on `"\n"` at parse time by `FloorDefinitionParser` to obtain the per-row strings.

```swift
let floor1 = FloorDefinition(grid: """
    ######S########
    ######.########
    ######.########
    ##*....G.######
    ######.########
    ######.########
    ######^########
    """)
```

Swift strips common leading whitespace from `"""` blocks, so indenting the literal inside a function or enum body produces clean rows with no leading spaces.

The `FloorDefinition` type stores the raw multi-line string and the `FloorDefinitionParser` splits it into rows using `.split(separator: "\n")` before scanning.

Character vocabulary:
- `#` = wall (impassable)
- `.` = floor (passable, empty)
- `^`/`>`/`v`/`<` = player entry with facing (passable)
- `E` = entry (no facing, default north)
- `G` = guard encounter (passable)
- `B` = boss encounter (passable)
- `*` = egg room (passable)
- `S` = staircase (passable)
- `X` = exit (passable)

Row 0 = south (y=0); row `count - 1` = north (y = height - 1). Column index = x. This matches the existing `FloorGrid` coordinate convention (origin south-west).

---

## Alternatives Considered

### Option E: `"""` multi-line string (chosen)

```swift
let floor1 = FloorDefinition(grid: """
    ######S########
    ######.########
    ##*....G.######
    ######^########
    """)
```

- Positive: The entire floor topology is visible as a single visual block in the Swift source — the developer literally sees the map layout when reading the code.
- Positive: More compact than `[String]`: no array brackets, no per-row quotes, no trailing commas. Authoring a 19-row floor requires 19 lines, not 19 quoted-and-comma-separated string literals.
- Positive: Swift strips common leading whitespace from `"""` blocks — the literal can be indented inside an enum/function body without polluting the row content with spaces.
- Positive: Zero dependencies — `String` and `String.split` are in the Swift standard library.
- Positive: The `.split(separator: "\n")` step in `FloorDefinitionParser` is a single standard-library call — no custom parsing required.
- Negative: `FloorDefinitionParser` must call `.split(separator: "\n")` before scanning rows. This is a one-liner, not a meaningful cost.
- Negative: A trailing blank line in the `"""` block would produce an empty row. The developer must ensure no trailing newline after the last row of cells (standard `"""` usage with the closing `"""` on its own line avoids this).
- Accepted. Developer preference is ease of authoring; the visual map block is the clearest authoring experience.

### Option D: `[String]` character grid

```swift
let floor1 = FloorDefinition(rows: [
    "######^########",
    "######.########",
    "##*....G.######",
    "######S########",
])
```

- Positive: No split step — each string is already one row.
- Positive: Per-row comments are easy to attach inline.
- Negative: More syntactic ceremony: array brackets, per-row quote pairs, trailing commas. Authoring a tall floor is visually noisier.
- Negative: Less visually map-like: the surrounding `["`, `",`, and `"]` break the spatial reading of the layout.
- Rejected: `"""` is simpler for the author (developer preference stated explicitly).

### Option A: Separate arrays for passability and landmark positions

```swift
struct FloorDefinition {
    let passable: Set<Position>
    let entry: Position
    let staircase: Position?
    let egg: Position?
    // ...
}
```

- Positive: Explicit field names; no parsing required.
- Negative: The passable cell set and landmark positions are maintained separately — editing the layout requires updating two data structures in sync. For a 15×7 grid, the passable set requires enumerating ~15 positions explicitly. Error-prone under jam pressure.
- Negative: Not visually inspectable without rendering the set. The developer cannot "see" the floor topology by reading the data.
- Rejected: Visual inspectability and single-artifact authoring were higher priority than avoiding a one-time parse.

### Option B: JSON / Property List file (loaded at runtime)

```json
{ "rows": ["######^########", "##*....G.######", ...] }
```

- Positive: Could be edited with any text editor without recompiling.
- Negative: Requires `Foundation` framework for JSON/Plist parsing — not available in `GameDomain` without breaking the zero-external-dependency constraint.
- Negative: Requires file I/O at runtime — violates `GameDomain` zero-I/O invariant.
- Negative: Adds file-not-found runtime failure modes; `.dungeon` rendering would need error handling.
- Rejected.

### Option C: 2D `[[Bool]]` grid (passability only) + separate landmark struct

Split passability from landmarks entirely:

```swift
struct FloorDefinition {
    let cells: [[Bool]]   // [y][x], true = passable
    let entry: Position
    // etc.
}
```

- Positive: Passability and positions are typed — no parsing.
- Negative: Authoring a 15×7 grid as `[[Bool]]` is verbose (105 values) and visually unreadable.
- Negative: Layout errors (wrong landmark position for the cell layout) are invisible.
- Rejected: Inferior developer experience compared to character grid.

### Option B (originally D): `[String]` character grid — see new Option D above.

---

## Consequences

### Positive
- `FloorDefinition` is a single-field struct (`grid: String`) — trivially `Sendable`
- A new floor topology requires exactly one `"""` block change — no algorithm modification (KPI-HM-05)
- Visual layout review is possible directly in the Swift source — the `"""` block reads as the floor map
- Authoring is less ceremonious than `[String]`: no array brackets, no per-row quotes, no trailing commas
- `FloorDefinitionParser` is a stateless, pure-function scanner — straightforward to test and reason about

### Negative
- `FloorDefinitionParser` must call `.split(separator: "\n")` before scanning rows — a one-liner cost
- Equal-length row validation is a developer-authoring responsibility (no runtime enforcement at jam scope). A mismatched row length produces wrong `FloorGrid` widths silently.
- A trailing newline in the `"""` block would produce a spurious empty row. Closing `"""` on its own line (the standard Swift style) prevents this.

### Note for Software Crafter

`FloorDefinition(grid:)` stores a raw `String`. `FloorDefinitionParser` calls `grid.split(separator: "\n")` to obtain per-row `Substring` values before scanning. The `"""` block is authored with north at the top (first line) and south at the bottom (last line), which is visually natural. The parser maps `splitResult[i]` to `y = (height - 1) - i`, so `splitResult[0]` (the northernmost line in the string) becomes `y = height - 1` and `splitResult[height - 1]` (the southernmost line) becomes `y = 0`. Column index maps directly to x. `#` maps to `isPassable: false`; all other vocabulary characters map to `isPassable: true`. The first occurrence of each landmark character determines its `Position`.
