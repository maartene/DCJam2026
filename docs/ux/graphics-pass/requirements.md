# Requirements — graphics-pass

**Feature**: graphics-pass
**Wave**: DISCUSS
**Date**: 2026-04-03
**Source**: `docs/research/graphics/ascii-dungeon-graphics-research.md` + `docs/CLAUDE.md`

---

## Context

Ember's Escape renders a first-person dungeon corridor using 52 pre-authored ASCII art frames
keyed on `DungeonFrameKey` (depth 0–3, nearLeft, nearRight, farLeft, farRight). All 15 rows of
each frame are currently written to the terminal with no ANSI color codes — the dungeon view is
entirely monochrome. The surrounding UI chrome (status bar, minimap, thoughts) already uses 11
ANSI 16-color constants defined in `ANSIColors.swift`.

The graphics pass applies four targeted changes to produce a depth-graded visual — brighter and
denser near the player, dimming and thinning toward depth=3 fog — while remaining within the
existing architecture (no new modules, no new dependencies, no structural changes to frame data).

---

## Requirement R2 — Dark background for the dungeon view zone

### What

Set ANSI background color 40 (black) for the entire dungeon view region before writing any frame
lines. The background code is emitted once per frame render, not per line. It is reset with
`\e[0m` after the last dungeon line so it does not bleed into the minimap or chrome.

### Why

Without a dark background the terminal's default background (typically white or light gray in
some themes) bleeds through the space characters in the ceiling and floor areas of each frame.
A uniform black background makes the dungeon panel visually distinct and ensures the foreground
depth colors (R1/R4) read correctly regardless of the player's terminal theme.

### Precise behavior

- Before the first `output.write(line)` in `renderDungeon()`, emit `\e[40m` (ANSI background
  black).
- After the last line of the frame, emit `\e[0m` (full reset).
- The minimap (cols 61–79) is written independently and must NOT inherit the background color.
- The background code must be part of the output stream produced by the looping write pattern
  already used for all terminal output (see `docs/CLAUDE.md` Terminal write rule).

### Files changed

- `Sources/App/Renderer.swift` — `renderDungeon()` method only (~3 lines added)

### Terminal compatibility

ANSI 40 (background black) is part of ANSI X3.64 and supported by every POSIX-compatible
terminal. No capability detection required.

### What it must NOT do

- Must not set a background on rows outside rows 2–16.
- Must not change any frame string content.
- Must not affect `renderMinimap()`, `drawStatusBar()`, or `drawThoughts()`.

---

## Requirement R1 — Depth-graded ANSI 16-color on dungeon frames

### What

Wrap each dungeon frame's output lines in a foreground color chosen by the frame's depth level.
The color is applied once per depth (one code wrapping all 15 lines), not per character.

| depth | meaning            | ANSI code | color name           |
|-------|--------------------|-----------|----------------------|
| 0     | wall right in front | `\e[97m`  | bright white         |
| 1     | wall one square ahead | `\e[37m` | standard white      |
| 2     | wall two squares ahead | `\e[90m` | dark gray (bright black) |
| 3     | fog / corridor continues | `\e[90m` | dark gray        |

### Why

Classic dungeon crawlers applied the rule "each depth layer is ~half the brightness of the layer
in front." This is the single largest visual improvement at lowest code cost: three lines of
color wrapping transform the monochrome view into a depth-graded corridor.

### Precise behavior

- After resolving `frameLines` in `renderDungeon()`, select the color code from the depth table
  above using `key.depth`.
- Prepend the color code to each line string before the `output.write()` call.
- Append `\e[0m` (full reset) after each line — this prevents color bleed if a subsequent write
  does not set its own color.
- The color wrapping must be applied AFTER R2's background is set (background is set once for
  the region; foreground is set per line).
- Existing frame strings must not be modified. The color is injected at the write site in
  `Renderer.swift` only.

### Files changed

- `Sources/App/Renderer.swift` — `renderDungeon()` method only (~5 lines added/changed)

### Terminal compatibility

ANSI 90 (bright black / dark gray), 37 (white), 97 (bright white) are standard ANSI 16-color
codes supported by macOS Terminal.app, iTerm2, and any POSIX-compatible terminal. No capability
detection required.

### What it must NOT do

- Must not modify `DungeonFrames.swift` frame strings.
- Must not apply color to minimap, chrome, status bar, or thoughts sections.
- Must not use 256-color or truecolor escape codes (that is R4's scope).

---

## Requirement R3 — Fix character density inversion in DungeonFrames

### What

Correct the backwards relationship between depth and character density in the existing frame
strings. Currently depth=0 uses `▒` (medium shade, ~50% fill) uniformly, while depth=1 uses
`▓░` alternating (denser on average than depth=0). This is visually inverted: the closest wall
appears lighter than the wall one square away.

The fix: update the fill characters in the depth=0 frame(s) so they are equal to or denser than
depth=1, and ensure depth=1 is denser than depth=2.

#### Target character density table

| depth | target characters | rationale |
|-------|-------------------|-----------|
| 0     | `▓▒` alternating (dense stone) | closest wall, maximum density |
| 1     | `▓░` alternating (medium brick) | current depth=1 — already correct, keep as-is |
| 2     | `░·` sparse (already in place)  | already correct, keep as-is |
| 3     | `·` fog dots (already in place) | already correct, keep as-is |

### Precise behavior

- In `frame_d0_none()`, replace `String(repeating: "▒", count: 50)` (the `stone` variable) with
  `String(repeating: "▓▒", count: 25)` — producing a 50-character `▓▒▓▒...` alternating pattern.
- All other frames at depth=0 (currently only `frame_d0_none()` is authored) follow the same
  rule if additional depth=0 frames are added.
- The wall face rows (rows 4–8 in `frame_d0_none()`) are the only rows changed; structural
  lines (`_`, `\`, `/`, `|`) remain unchanged.
- Row count and total character width (58 per row) must remain exactly the same after the change.

### Files changed

- `Sources/App/DungeonFrames.swift` — `frame_d0_none()` only, the `stone` variable definition

### Terminal compatibility

`▓` (U+2593) and `▒` (U+2592) are already present in the existing frames; no new Unicode code
points are introduced.

### What it must NOT do

- Must not change depth=1, depth=2, or depth=3 frame content.
- Must not alter row count, column count, or structural characters in any frame.

---

## Requirement R4 — 256-color grayscale depth ramp (with 16-color fallback)

### What

Upgrade the depth-graded foreground color (R1) to 256-color grayscale indices when the terminal
supports 256 colors, falling back to the ANSI 16-color codes from R1 for unknown terminals.

#### 256-color depth table

| depth | 256-color index | gray level | equivalent 16-color fallback |
|-------|----------------|-----------|------------------------------|
| 0     | 252            | near-white  | `\e[97m` bright white       |
| 1     | 245            | medium gray | `\e[37m` standard white     |
| 2     | 238            | dark gray   | `\e[90m` dark gray          |
| 3     | 234            | near-black  | `\e[90m` dark gray          |

256-color foreground syntax: `\e[38;5;{n}m`

### Detection

Detection uses the `TERM` environment variable at game startup (or first frame render):

```
let term = ProcessInfo.processInfo.environment["TERM"] ?? ""
let supports256 = term.contains("256color")
```

If `supports256` is true, use 256-color codes. Otherwise, use the 16-color codes from R1.
This is a one-time check. The result is stored as a boolean in `Renderer` (or passed in at
init time) and used in every `renderDungeon()` call.

### Why

macOS Terminal.app sets `TERM=xterm-256color`. iTerm2 sets `TERM=xterm-256color` and also
`COLORTERM=truecolor`. The 256-color grayscale ramp (indices 232–255) provides 24 distinct gray
levels versus the 8 effective brightness levels in ANSI 16-color, giving a smoother depth falloff.

### Precise behavior

- Add helper function to `ANSIColors.swift`:
  `func ansi256Fg(_ n: Int) -> String { "\u{1B}[38;5;\(n)m" }`
- `Renderer` detects 256-color support once and stores the result.
- `renderDungeon()` selects either the 256-color code or the 16-color fallback per depth.
- Fallback must be exactly the R1 codes (no functional regression on unsupported terminals).
- Reset after each line remains `\e[0m` in both paths.

### Files changed

- `Sources/App/ANSIColors.swift` — add `ansi256Fg(_:)` helper (~3 lines)
- `Sources/App/Renderer.swift` — terminal detection at init + color selection in
  `renderDungeon()` (~8 lines total)

### Terminal compatibility

256-color support is assumed when `TERM` contains `256color`. The fallback (R1 codes) ensures
the game remains fully playable on terminals that do not advertise 256-color support.

---

## Non-functional constraints (from `docs/CLAUDE.md`)

1. **Terminal write rule**: All terminal output must use the looping write pattern handling short
   writes and EINTR. The added ANSI escape sequences are string prefixes/suffixes injected before
   the existing `output.write()` calls — this satisfies the rule without any structural change.
2. **No external TUI libraries**: All color codes are raw escape strings. No new Swift package
   dependencies.
3. **ANSI reset discipline**: Every colored region must end with `\e[0m`. Each dungeon frame line
   is individually reset to prevent bleed into the minimap or subsequent writes.
4. **Screen layout unchanged**: Row/column coordinates for the dungeon view (rows 2–16, cols 2–59)
   are not modified.
5. **Dungeon view width**: Each frame row is 58 characters wide. ANSI escape codes are zero-width
   in the terminal; they do not affect the physical column position. The existing `visibleLength()`
   helper in `Renderer.swift` already strips ANSI sequences when counting printable width.
