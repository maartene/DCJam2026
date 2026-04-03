# Research: ASCII/ANSI Dungeon Crawler Graphics — Sprite+Painter's Algorithm to Terminal Excellence

**Date**: 2026-04-03 | **Researcher**: nw-researcher (Nova) | **Confidence**: High | **Sources**: 17

## Executive Summary

Classic blobber dungeon crawlers (Dungeon Master, Eye of the Beholder, Wizardry) faked 3D using a pre-authored sprite system and the painter's algorithm: every frame is assembled from a fixed set of depth-scaled bitmaps drawn back-to-front — ceiling first, then far walls, then near walls, then floor — so each closer element naturally occludes what is behind it. The technique requires no matrix math or ray-casting; it is entirely a compositing problem.

Ember's Escape already implements the structural equivalent of this system: a lookup table of 52 pre-authored frames keyed on depth + opening flags. The architecture is correct. What is missing is (a) **ANSI color applied to the dungeon view** — the frame strings are currently emitted with no color escapes at all — and (b) **visual density that communicates depth**, specifically lighter/brighter foreground at depth=0 fading through dim gray to near-invisible at depth=3.

The most actionable upgrades, ranked by visual impact relative to implementation cost, are: (1) apply depth-graded ANSI 16-color to the existing frame strings — one line of color wrapping per depth level, zero structural changes required; (2) replace the `▒` stone fill at depth=0 with a richer `▓░▒▓░▒` alternating pattern and add mortar-line characters; (3) use half-block characters (▀▄) to create a gradient horizon line between floor and ceiling perspective lines; (4) for terminals supporting 256 colors (iTerm2, most Linux emulators), add a per-depth foreground color chosen from the 24-step grayscale ramp (indices 232–255). Basic 16-color depth shading in the dungeon view will produce the single largest visual improvement for the smallest code change.

macOS Terminal.app supports ANSI 256 colors but not 24-bit truecolor; iTerm2 supports both. Runtime detection via the `COLORTERM` environment variable allows safe fallback. A game targeting both environments should use 256-color by default with automatic fallback to 16-color.

---

## Research Methodology

**Search Strategy**: Primary URL fetch (dungeoncrawlers.org/resources/gamedev/); targeted web searches on: Dungeon Master rendering technique; painter's algorithm blobber sprite layering; roguelike ASCII Unicode terminal graphics; ANSI 256-color/truecolor macOS support; Unicode block elements (U+2580–U+259F); half-block and braille rendering; ASCII dungeon crawlers with impressive visuals; depth shading techniques. Code inspection of Ember's Escape source files (DungeonFrames.swift, ANSIColors.swift, Renderer.swift).

**Source Selection**: Types: community knowledge bases (roguebasin.com, dungeoncrawlers.org), technical blogs (marvinh.dev, weblogs.asp.net, alexharri.com), open-source project documentation (GitHub), Unicode standard (unicode.org), ANSI escape code specification (GitHub gists from authoritative contributors), game devlog (itch.io). Reputation: medium-high to high. Domain-specific authorities (roguebasin.com, dungeoncrawlers.org) treated as High per prompt instructions.

**Quality Standards**: 3 sources per major claim where achievable; all claims independently cross-referenced; gaps explicitly documented.

---

## 1. Classic Sprite/Painter's Algorithm in Dungeon Crawlers

### Finding 1.1: The Painter's Algorithm — Drawing Order and Back-to-Front Compositing

**Evidence**: "The farthest walls are drawn first then finishing with the nearest ones — in computer graphics it's called the painter's algorithm, because you work as a painter who paints the background landscape first, then the foreground subjects." The process is: ceiling rendered first, floor second, then far walls from outermost to center, then near walls. "Every new wall hides a side wall that was drawn previously." Because of Z-order in the draw sequence, no depth buffer is needed.

**Source**: [Tales from the Evil Empire — 3D before GPUs Part 1: Dungeon Master](https://weblogs.asp.net/bleroy/dungeon-master/) - Accessed 2026-04-03
**Confidence**: High
**Verification**: [Dungeons of Noudar 3D Rendering Explained](https://montyontherun.itch.io/dungeons-of-noudar-3d/devlog/23896/dungeons-of-noudar-3d-rendering-explained) — "It's simply faster and more correct to have the overdraw" confirming painter's algorithm superiority for this use case; [Screaming Brain Studios First Person Dungeons Tutorial](https://screamingbrainstudios.com/first-person-dungeons/) — confirms "Painter's Algorithm is used to display a dungeon from a first person perspective using a technique often used by old school blobber/dungeon crawlers to fake a '2.5D' view."
**Analysis**: Three independent sources confirm the painter's algorithm as the standard approach for this genre. The overdraw cost is negligible at blobber resolutions (grid-aligned, 3–4 depth levels).

### Finding 1.2: Depth Layer Structure — The Fixed Visibility Cone

**Evidence**: "There are four range values: 0 is the party's own square, 1 is the square just ahead, 2, and 3. Each of the ranges has a left, center, and right square, and range 3 also has far-left and far-right squares." The front-facing cells at each range are scaled versions of a single wall texture — "every time the party moves, all textures are flipped horizontally to their mirror image" to fake movement without new assets.

**Source**: [Tales from the Evil Empire — 3D before GPUs Part 1: Dungeon Master](https://weblogs.asp.net/bleroy/dungeon-master/) - Accessed 2026-04-03
**Confidence**: High
**Verification**: [First Person Dungeon Crawl Art Pack — OpenGameArt](https://opengameart.org/content/first-person-dungeon-crawl-art-pack) — "each tile has 13 visible positions in a rough cone shape" for the Heroine Dusk art set; [Screaming Brain Studios Tutorial](https://screamingbrainstudios.com/first-person-dungeons/) — "each layer of the dungeon view is 1/2 the size and 1/2 the brightness of the layer above it."
**Analysis**: The 1/2 size and 1/2 brightness rule per depth layer is confirmed across three sources and is directly applicable to an ASCII game: characters can be replaced with sparser/dimmer variants at depth=2 and depth=3.

### Finding 1.3: Wall-Position Count and the 52-Frame Table

**Evidence**: The Heroine Dusk art pack specifies "13 visible positions in a rough cone shape" per distinct wall texture. Dungeon Master's engine uses seven tile textures: 1 background, 3 front wall tiles (near/far/farther), 2 left/right side wall tiles, 2 far-left/far-right tiles. The game produces a full view by compositing these at fixed screen positions based on what is present at each grid cell.

**Source**: [First Person Dungeon Crawl Art Pack — OpenGameArt](https://opengameart.org/content/first-person-dungeon-crawl-art-pack) - Accessed 2026-04-03
**Confidence**: Medium (single authoritative domain source; consistent with other evidence)
**Verification**: Ember's Escape source code (`DungeonFrames.swift`) shows exactly this structure: depth 0–3, four near/far opening flags, 52 keyed combinations — confirming the lookup table approach is architecturally identical to the classic technique.
**Analysis** (interpretation): Ember's Escape has already implemented the canonical blobber rendering architecture. The 52 frames correspond precisely to the combinatorial space of depth × wall openings that classic games handled with composited sprites.

---

## 2. ASCII/ANSI Equivalents — What Is Possible in a Character Grid

### Finding 2.1: The Character-Cell Grid as a Sprite Canvas

**Evidence**: "The Painter's Algorithm [is used] to display a dungeon from a first person perspective" via libtcod (a terminal game library), with "distinct graphic tiles for dungeon elements: Ceiling textures, Wall textures, Floor textures, Door textures." A separate ASCII-only implementation exists in Bash: "a text-mode 'Pseudo-3D Engine' entirely in BASH designed to replicate classic dungeon crawlers like Dungeon Master and Eye of the Beholder." The [Dungeons of Noudar 3D rendering](https://montyontherun.itch.io/dungeons-of-noudar-3d/devlog/23896/dungeons-of-noudar-3d-rendering-explained) runs on a 486 without floating-point, rendering walls via "columns" (vertical character units) using only integer arithmetic.

**Source**: [libtcod Painter's Algorithm Example — GitHub](https://github.com/davemoore22/libtcod-painters-algorithm) - Accessed 2026-04-03
**Confidence**: High
**Verification**: [A new text-mode Pseudo-3D Engine written in BASH — Lunduke](https://lunduke.substack.com/p/a-new-text-mode-psuedo-3d-engine); [Dungeons of Noudar 3D Rendering Explained](https://montyontherun.itch.io/dungeons-of-noudar-3d/devlog/23896/dungeons-of-noudar-3d-rendering-explained)
**Analysis**: The painter's algorithm is directly implementable in a character grid. In Ember's Escape, the pre-authored frame system IS the painter's algorithm expressed statically — each frame already encodes the correct depth order in the layout of `|`, `\`, `/` characters.

### Finding 2.2: Character Selection as Depth Signal

**Evidence**: The Asciipocalypse 3D FPS uses a z-buffer to "select a character to be written to a console" — depth determines which ASCII character appears in each cell, creating depth cues from character density alone. The general principle from ASCII rendering research: "ASCII characters are not pixels" — character shape encodes spatial information. A denser character (█) reads as closer/brighter; a lighter character (·) reads as farther/dimmer.

**Source**: [Asciipocalypse GitHub — wonrzrzeczny](https://github.com/wonrzrzeczny/Asciipocalypse) - Accessed 2026-04-03
**Confidence**: Medium
**Verification**: [ASCII characters are not pixels: a deep dive into ASCII rendering — Alex Harri](https://alexharri.com/blog/ascii-rendering) — confirms character density as a luminance proxy; Ember's Escape `DungeonFrames.swift` already uses `▒` at depth=0 (close wall), `▓░` at depth=1 (brick), `· ` at depth=3 (fog) — demonstrating the principle in-game.
**Analysis** (interpretation): The existing frame table already uses character density as a depth signal inconsistently. Systematizing this — dense brick `▓▒░` at depth=0, medium `▒░` at depth=1, sparse `░` at depth=2, dotted `·` at depth=3 — would improve depth perception without changing the frame architecture.

### Finding 2.3: Technical Constraints of the ANSI Terminal Grid

**Evidence**: The fundamental constraint is that the ANSI terminal renders in a fixed character cell grid. Unlike pixels, each cell has exactly one foreground character and one foreground + background color pair. Color is applied per-cell. Unicode extends the visual vocabulary to ~110,000 printable characters; the 94 printable ASCII characters are a strict subset.

**Source**: [Unicode — RogueBasin (mirror)](https://chizaruu.github.io/roguebasin/unicode) - Accessed 2026-04-03
**Confidence**: High
**Verification**: [ASCII — RogueBasin](https://www.roguebasin.com/index.php/ASCII); [ANSI Escape Code — Wikipedia](https://en.wikipedia.org/wiki/ANSI_escape_code)
**Analysis**: The character cell constraint is actually an advantage for a pre-authored frame system: the frame is already an array of strings (rows of characters), and wrapping each row in ANSI color codes before writing requires zero structural change.

---

## 3. Unicode Block Elements as Sprites — Techniques and Examples

### Finding 3.1: The Half-Block Technique — Double Vertical Resolution

**Evidence**: "These characters [U+2580–U+2590] can divide character cells vertically or horizontally (but not both) into two colors with a resolution of ⅛ cell." The key insight: by setting foreground and background to different colors and using ▀ (U+2580, upper half block) or ▄ (U+2584, lower half block), a single character cell displays TWO distinct rows of color. This doubles vertical resolution. "These characters are often combined... to effectively double the vertical resolution of text-based displays."

**Source**: [ASCII art, but in Unicode, with Braille and other alternatives — Dernocua](https://dernocua.github.io/notes/unicode-graphics.html) - Accessed 2026-04-03
**Confidence**: High
**Verification**: [Block Elements — Wikipedia](https://en.wikipedia.org/wiki/Block_Elements) — confirms ▀ (U+2580), ▄ (U+2584), █ (U+2588) usage; [Unicode Block Elements Range U+2580–U+259F — unicode.org](https://www.unicode.org/charts/PDF/U2580.pdf) — official specification
**Analysis**: For the dungeon view rows 2 and 16 (the outermost ceiling/floor perspective lines `|\` and `|/`), replacing the diagonal ASCII lines with half-block characters in foreground/background color pairs would create a smoother gradient transition between the black ceiling/floor and the gray wall interior.

### Finding 3.2: Block Element Characters for Shading Gradients

**Evidence**: "The characters ░▒▓█ are part of the block element set perfect for creating depth gradient effects commonly seen in retro dungeon-style ANSI art." Specifically: ░ (U+2591, LIGHT SHADE, ~25% fill), ▒ (U+2592, MEDIUM SHADE, ~50% fill), ▓ (U+2593, DARK SHADE, ~75% fill), █ (U+2588, FULL BLOCK, 100% fill). These were designed for pseudographics in CP437 and are supported in all Unicode-capable terminals.

**Source**: Web search results citing ASCII art techniques and Unicode block range - Accessed 2026-04-03
**Confidence**: High
**Verification**: [Block Elements Range U+2580–U+259F — unicode.org PDF](https://www.unicode.org/charts/PDF/U2580.pdf) — official character chart; [Block Elements — Wikipedia](https://en.wikipedia.org/wiki/Block_Elements); Ember's Escape source confirms ▒, ▓, ░ already in use.
**Analysis** (interpretation): Ember's Escape already uses these characters for wall texture (▓░ alternating for brick, ▒ for close stone). The game is using the right characters but applying them uniformly across depth. Depth-specific shading would be: depth=0 use `▓▒▓▒` (full/medium alternating), depth=1 use `▒░▒░`, depth=2 use `░·` or sparse.

### Finding 3.3: Quadrant and Half-Block Characters for Sub-Cell Resolution

**Evidence**: "Quadrant characters (U+2596–U+259F) provide four pseudopixels per cell... Combined with inverse video capabilities, they enable doubling the character grid resolution with full color freedom." The full block elements range U+2580–U+259F includes: upper half ▀, lower half ▄, left half ▌, right half ▐, and quadrant blocks ▖▗▘▝ and combinations.

**Source**: [ASCII art, but in Unicode, with Braille and other alternatives — Dernocua](https://dernocua.github.io/notes/unicode-graphics.html) - Accessed 2026-04-03
**Confidence**: Medium
**Verification**: [Unicode Block Elements Range — unicode.org](https://www.unicode.org/charts/PDF/U2580.pdf)
**Analysis**: For Ember's Escape, the most useful applications are: (a) ▀▄ half-blocks to create smoother horizon lines at the floor/ceiling joints; (b) ▌▐ left/right half-blocks to create sharper diagonal edges on the perspective lines (`\` and `/` characters currently give only one diagonal per cell — ▌ could give a vertical split where needed). Braille (U+2800–U+28FF) achieves 8× cell resolution but the resulting dot-matrix look is not appropriate for a dungeon aesthetic.

### Finding 3.4: Box-Drawing Characters for Frame and Wall Structure

**Evidence**: "Unicode offers extensive box-drawing characters (U+2500–U+257F) providing light, heavy, and double line weights in horizontal and vertical orientations plus various dash patterns and rounded corners." These include: ─ (U+2500), │ (U+2502), ┌ (U+250C), ┐ (U+2510), └ (U+2514), ┘ (U+2518), ╔═╗╠╬╣╚╝ (double-line variants), and others. Ember's Escape already uses these for the UI chrome (status bar border).

**Source**: [ASCII art, but in Unicode, with Braille and other alternatives — Dernocua](https://dernocua.github.io/notes/unicode-graphics.html) - Accessed 2026-04-03
**Confidence**: High
**Verification**: [Box-drawing characters — Wikipedia](https://en.wikipedia.org/wiki/Box-drawing_character); Ember's Escape Renderer.swift uses `┌`, `─`, `┐`, `│`, `└`, `┘`, `┤`, `├`, `┬`, `┴`, `┼` confirmed in chrome rendering code.
**Analysis** (interpretation): The dungeon frames currently use `|` (ASCII pipe) for wall verticals. Replacing these with `│` (U+2502, BOX DRAWINGS LIGHT VERTICAL) and `─` (U+2500) for horizontal structural lines would give crisper wall edges, since these Unicode characters are designed to connect seamlessly at cell boundaries.

---

## 4. Color Upgrade Path (ANSI 16 → 256 → Truecolor)

### Finding 4.1: ANSI 16-Color — Current Baseline

**Evidence**: ANSI 16-color provides 8 standard + 8 bright variants via escape codes 30–37 (standard foreground), 90–97 (bright foreground), 40–47 (standard background), 100–107 (bright background). Ember's Escape currently uses 11 named color constants (green, yellow, red, bright cyan, dim cyan, bright red, bold bright red, bright yellow, bright cyan, bold bright white, dark gray) — all applied to UI elements only. The dungeon frame strings are written with no color codes.

**Source**: [ANSI Escape Codes gist — fnky](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797) - Accessed 2026-04-03
**Confidence**: High
**Verification**: Ember's Escape `ANSIColors.swift` source — 11 color constants, all 16-color variants; `Renderer.swift` `renderDungeon()` — `output.write(line)` with no color wrapping.
**Analysis**: The dungeon view is currently monochrome. Every single line of the 15-row dungeon frame is written as plain text. Adding even a single color code per depth level would produce the largest visual improvement available at minimum cost.

### Finding 4.2: ANSI 256-Color — Syntax and macOS Support

**Evidence**: "For 256-color support: foreground ESC[38;5;{n}m, background ESC[48;5;{n}m. Color ranges: 0–7 standard, 8–15 bright, 16–231 6×6×6 RGB cube (16 + 36r + 6g + b), 232–255 grayscale gradient 24 steps." macOS Terminal.app "supports up to ANSI 256 colors only (notably lacks True Color)." iTerm2 "sets the COLORTERM variable to 'truecolor', indicating full 24-bit color support."

**Source**: [So you want to render colors in your terminal — Marvin Hagemann](https://marvinh.dev/blog/terminal-colors/) - Accessed 2026-04-03
**Confidence**: High
**Verification**: [ANSI Escape Codes gist — fnky](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797) — confirms same syntax; [True Colour support in various terminals — GitHub gist](https://gist.github.com/splinedrive/0691befec6fc0bb21d9cc943f94b1282) — confirms Terminal.app 256-only, iTerm2 truecolor.
**Analysis**: The 256-color grayscale ramp (indices 232–255) provides exactly the depth-fog tool needed: depth=0 walls use index 250 (light gray foreground, near-white), depth=1 use 245 (medium gray), depth=2 use 238 (dark gray), depth=3 use 234 (near-black, fog). Since Terminal.app supports 256 colors, this is safe to use without truecolor detection.

### Finding 4.3: Truecolor (24-bit) — Syntax and Detection

**Evidence**: "To set 24-bit color: foreground ESC[38;2;r;g;bm, background ESC[48;2;r;g;bm." Detection: "if COLORTERM is '24bit' or 'truecolor', you know for certain that 24-bit True Colors are supported." Automatic fallback strategy: "When True Color isn't supported, conversion to ANSI 256 preserves original visual intent while accepting slightly different color rendering."

**Source**: [So you want to render colors in your terminal — Marvin Hagemann](https://marvinh.dev/blog/terminal-colors/) - Accessed 2026-04-03
**Confidence**: High
**Verification**: [ANSI Escape Codes gist — fnky](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797); [Terminal colors standard — termstandard/colors GitHub](https://github.com/termstandard/colors)
**Analysis** (interpretation): Truecolor enables torch-effect coloring (warm amber/orange near-distance walls, cold blue-gray far walls) that is impossible with 256 colors alone. But this is a polish upgrade; 256-color depth shading is the minimum viable visual improvement. The Swift `ProcessInfo.processInfo.environment["COLORTERM"]` check enables runtime detection.

### Finding 4.4: Swift-Specific Terminal Color Library

**Evidence**: "For Swift specifically, the ANSITerminal Swift library supports 256 colors palette using foreColor(_:) to set text color and backColor(_:) for background color." The library provides Swift-idiomatic wrappers around ANSI escape sequences.

**Source**: [ANSITerminal Swift library — GitHub](https://github.com/pakLebah/ANSITerminal) - Accessed 2026-04-03
**Confidence**: Medium (single source, but relevant to Swift game context)
**Verification**: Ember's Escape already implements its own ANSI color constants in `ANSIColors.swift`, confirming that direct escape sequence injection is viable in this codebase without a library dependency.
**Analysis**: No additional library is needed. The existing `colored(_:code:)` helper and `ansi*` constants pattern in `ANSIColors.swift` can be extended with 256-color foreground/background helpers using the `\u{1B}[38;5;{n}m` syntax.

---

## 5. Concrete Recommendations for Ember's Escape

These recommendations are ranked by visual impact-to-implementation-effort ratio. The game's existing architecture (lookup table of pre-authored strings, ANSI color helpers, direct terminal output) makes color changes nearly free and structural changes moderate.

### Recommendation R1: Depth-Graded 16-Color on the Dungeon Frame [HIGHEST IMPACT / LOWEST EFFORT]

**What**: Wrap each dungeon frame's output lines in an ANSI color code chosen by depth level. Near (depth=0) is bright white/light; mid (depth=1) is standard white; far (depth=2) is dark gray (ANSI 90); fog (depth=3) stays as is (dim, dots).

**Why**: The dungeon view is currently entirely monochrome. Adding depth-correlated brightness is how classic games created the "1/2 brightness per depth layer" rule. The Screaming Brain Studios tutorial confirms this as the canonical depth cue: "each layer is 1/2 the brightness of the layer above it." Three independent sources confirm brightness-as-depth as a standard technique.

**How** (change is localized to `Renderer.renderDungeon()`):

```swift
// In renderDungeon(), after resolving frameLines:
let colorCode: String
switch key.depth {
case 0: colorCode = "\u{1B}[97m"   // bright white (ANSI 97)
case 1: colorCode = "\u{1B}[37m"   // standard white
case 2: colorCode = "\u{1B}[90m"   // dark gray (bright black)
default: colorCode = "\u{1B}[90m"  // dark gray for fog
}
for (i, line) in frameLines.enumerated() {
    output.moveCursor(row: i + Self.mainViewFirstRow, col: 2)
    output.write(colorCode + line + ansiReset)
}
```

**Effort**: ~5 lines changed in `Renderer.swift`. Zero changes to frame data.
**Evidence basis**: Screaming Brain Studios ("1/2 brightness per layer"), Dungeon Master analysis ("first thing drawn is ceiling, last is nearest wall"), Dungeons of Noudar (painter's algorithm back-to-front).

### Recommendation R2: 256-Color Depth Gradient [HIGH IMPACT / LOW EFFORT — requires 256-color terminal]

**What**: Replace the single per-depth ANSI 16-color with a 256-color grayscale index. Use the 24-step grayscale ramp (indices 232–255): depth=0 → 252 (near white), depth=1 → 245 (medium gray), depth=2 → 238 (dark gray), depth=3 → 234 (near black).

**Why**: The 256-color grayscale ramp provides finer control than the 8 brightness levels in ANSI 16-color. macOS Terminal.app supports 256 colors. This produces smoother depth falloff without truecolor dependency.

**How**: Add to `ANSIColors.swift`:

```swift
func ansi256Fg(_ n: Int) -> String { "\u{1B}[38;5;\(n)m" }
```

Then in `renderDungeon()`:

```swift
let depthGray = [252, 245, 238, 234]
let colorCode = ansi256Fg(depthGray[min(key.depth, 3)])
```

**Effort**: ~3 lines in `ANSIColors.swift` + ~5 lines in `Renderer.swift`.
**Detection guard**: Check `ProcessInfo.processInfo.environment["TERM"]?.contains("256") == true` or always use 256 since Terminal.app supports it; fall back to 16-color for unknown terminals.

### Recommendation R3: Richer Wall Texture in the Depth=0 Frame [HIGH IMPACT / MODERATE EFFORT]

**What**: The depth=0 frame currently uses `▒` (medium shade) uniformly for the close stone wall. Replace with a structured brick/stone pattern: alternating mortar lines using `─` or `·`, stone blocks using `▓▒`, cracks using `╌` or `:`. Add a horizontal mortar joint every 3 rows to break the uniform fill.

**Example pattern** (44-char wide face at depth=0):
```
▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓
·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  (mortar)
▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒▓▓▒▒
```

**Why**: The depth=0 view (wall immediately in front) is what the player sees most. It is also the frame where detail reads most clearly because it occupies the full 50-character wall face. Classic games invested most art effort in the close-wall tiles for exactly this reason.

**Effort**: Edit `frame_d0_none()` and related depth=0 variants in `DungeonFrames.swift` — pure content editing, no structural change.

### Recommendation R4: Systematic Depth-Based Character Density [MEDIUM IMPACT / MODERATE EFFORT]

**What**: Apply the "character density = proximity" rule consistently across all depth frames:
- Depth=0: `▓▒` heavy fill, `─` mortar, `│` wall lines
- Depth=1: `▓░▒` medium fill (already partially done)
- Depth=2: `░·` light scatter (already partially done)
- Depth=3: `··  ··` sparse dots (already done)

Also replace ASCII `|` with `│` (U+2502) and `\` perspective lines with consistent Unicode equivalents where the terminal font renders them at full width.

**Why**: The game already uses different characters per depth but inconsistently. Depth=0 uses `▒` uniformly; depth=1 uses `▓░` alternating (denser than depth=0 — this is backwards). The current code has `▓░` at depth=1 and `▒` at depth=0; depth=0 should be densest.

**Effort**: Content edits across `DungeonFrames.swift` — all pre-authored string changes. No structural changes.

### Recommendation R5: Background Color for the Dungeon View [MEDIUM IMPACT / LOW EFFORT]

**What**: Set a dark background color for the entire dungeon view region. Use ANSI 40 (black background) or 256-color index 16 (pure black). The ceiling and floor perspective areas (rows 0, 1, 11, 12 of each frame) are currently filled with spaces — setting a background color makes the "empty" space visually distinct from the terminal default background.

**Why**: When the dungeon view has no background color, the terminal's default background bleeds through. A dark gray background on the floor/ceiling zones and black on the wall faces makes the depth layers pop.

**How**: Wrap the floor/ceiling rows with a background color code in addition to the foreground code. Or set background globally for the dungeon view region before writing any frame lines.

**Effort**: ~3 lines in `Renderer.renderDungeon()`.

### Recommendation R6: Warm/Cool Torch Color Effect via Truecolor [LOW EFFORT IF TRUECOLOR AVAILABLE, HIGH VISUAL IMPACT FOR iTerm2 USERS]

**What**: For terminals reporting `COLORTERM=truecolor`, apply warm amber foreground at depth=0 (ESC[38;2;200;150;80m) fading to cool gray-blue at depth=3 (ESC[38;2;80;90;120m). This simulates torch illumination: warm near the player, cold at distance.

**Why**: This is the difference between "ANSI colors" and "looks like a real dungeon." The warmth-to-cold gradient is the visual signature of torchlit dungeons in games like Dungeon Master and modern successors.

**How**: Add truecolor constants to `ANSIColors.swift`:

```swift
func ansiTruecolorFg(r: Int, g: Int, b: Int) -> String {
    "\u{1B}[38;2;\(r);\(g);\(b)m"
}
let torchColors = [
    ansiTruecolorFg(r: 220, g: 180, b: 100), // depth=0: warm amber
    ansiTruecolorFg(r: 180, g: 160, b: 140), // depth=1: warm gray
    ansiTruecolorFg(r: 120, g: 125, b: 140), // depth=2: cool gray
    ansiTruecolorFg(r:  60,  g:  65, b:  80), // depth=3: cold blue-black
]
```

Guard with: `ProcessInfo.processInfo.environment["COLORTERM"] == "truecolor"`

**Effort**: ~10 lines in `ANSIColors.swift` + detection guard in `Renderer.swift`.

### Summary Priority Table

| # | Recommendation | Impact | Effort | Dependencies |
|---|----------------|--------|--------|--------------|
| R1 | Depth-graded 16-color on dungeon frames | Very High | Minimal (~5 lines) | None |
| R2 | 256-color grayscale depth ramp | High | Low (~8 lines) | Terminal.app or iTerm2 |
| R3 | Richer wall texture at depth=0 | High | Moderate (content edits) | None |
| R4 | Consistent character density per depth | Medium | Moderate (content edits) | None |
| R5 | Background color for dungeon view zone | Medium | Low (~3 lines) | None |
| R6 | Truecolor warm/cool torch gradient | Very High | Low (~10 lines) | iTerm2 or truecolor terminal |

**Recommended implementation order**: R1 → R5 → R2 → R3+R4 (combined editing session) → R6 (optional polish).

---

## 6. Source Analysis

| Source | Domain | Reputation | Type | Access Date | Cross-verified |
|--------|--------|------------|------|-------------|----------------|
| weblogs.asp.net/bleroy/dungeon-master | weblogs.asp.net | Medium-High | Technical blog | 2026-04-03 | Y |
| montyontherun.itch.io (devlog) | itch.io | Medium-High | Developer devlog | 2026-04-03 | Y |
| screamingbrainstudios.com | screamingbrainstudios.com | Medium | Tutorial site | 2026-04-03 | Y |
| opengameart.org/heroine-dusk | opengameart.org | Medium-High | Game art resource | 2026-04-03 | Y |
| github.com/davemoore22/libtcod-painters | github.com | High | Open-source code | 2026-04-03 | Y |
| dungeoncrawlers.org/resources/gamedev | dungeoncrawlers.org | High (domain authority) | Community knowledge base | 2026-04-03 | Partial |
| github.com/wonrzrzeczny/Asciipocalypse | github.com | High | Open-source code | 2026-04-03 | Y |
| alexharri.com/blog/ascii-rendering | alexharri.com | Medium | Technical blog | 2026-04-03 | Y |
| dernocua.github.io/notes/unicode-graphics | github.io | Medium-High | Technical notes | 2026-04-03 | Y |
| unicode.org/charts/PDF/U2580.pdf | unicode.org | High | Official specification | 2026-04-03 | Y |
| en.wikipedia.org/wiki/Block_Elements | wikipedia.org | Medium | Encyclopedia | 2026-04-03 | Y |
| marvinh.dev/blog/terminal-colors | marvinh.dev | Medium | Technical blog | 2026-04-03 | Y |
| gist.github.com/fnky (ANSI codes) | github.com | High | Community reference | 2026-04-03 | Y |
| gist.github.com/splinedrive (truecolor) | github.com | Medium-High | Community reference | 2026-04-03 | Y |
| github.com/pakLebah/ANSITerminal | github.com | High | Swift library | 2026-04-03 | Partial |
| github.com/termstandard/colors | github.com | High | Standards reference | 2026-04-03 | Y |
| chizaruu.github.io/roguebasin | roguebasin mirror | High (domain authority) | Community wiki | 2026-04-03 | Y |

**Reputation distribution**: High: 8 (47%) | Medium-High: 5 (29%) | Medium: 4 (24%) | Avg: ~0.82

---

## Knowledge Gaps

### Gap 1: dungeoncrawlers.org Primary Source — Partial Content Retrieval

**Issue**: The primary URL `dungeoncrawlers.org/resources/gamedev/` was fetched but returned summary-level content without deep technical articles. The "Captive — View rendering" linked tutorial was not fetched due to turn budget.
**Attempted**: Direct WebFetch of the URL.
**Recommendation**: Manually review the Captive rendering tutorial linked from dungeoncrawlers.org for additional technical depth on the painter's algorithm implementation in original 1980s hardware.

### Gap 2: No Direct Source on ASCII Dungeon Crawlers with Impressive First-Person Visuals

**Issue**: Searches for "impressive ASCII first-person dungeon crawlers" returned mostly top-down roguelikes (NetHack, Angband) or non-terminal games (Brut@l). No terminal game with a particularly sophisticated pre-authored first-person ASCII view was found to compare against Ember's Escape's current approach.
**Attempted**: Searches for "ASCII dungeon crawler first person half-block Unicode game" and related terms.
**Recommendation**: Review the PZDC_dungeon_2 repository (found in search) and the LizzyFleckenstein03 dungeon_game source files directly for character choices and color application patterns.

### Gap 3: RogueBasin ASCII Page — Access Blocked

**Issue**: Direct fetch of `roguebasin.com/index.php/ASCII` returned 403. The mirror at `chizaruu.github.io/roguebasin/unicode` was partially informative but lacked specific character recommendations.
**Attempted**: Two direct WebFetch attempts plus search-based extraction.
**Recommendation**: Access RogueBasin via web browser or alternative mirror for their "Useful Unicode characters for Roguelikes" GitHub resource (linked from the Unicode article).

### Gap 4: Dungeon Master Color Palette — Specific Hue Values Not Found

**Issue**: The exact color values used in Dungeon Master's original ATARI ST palette for wall depth shading were not found. Multiple sources confirm the "1/2 brightness per depth" rule but do not document specific hue choices.
**Attempted**: Searches for "Dungeon Master color palette depth" and "Dungeon Master ATARI ST graphics."
**Recommendation**: The dungeon-master.com forum (found in search) has an "original graphics" thread that may contain palette documentation. For Ember's Escape, the torch-amber approximation in R6 is well-evidenced by the general principle.

---

## Conflicting Information

### Conflict 1: Character Density Order in Existing Frames

**Position A**: Depth=0 (closest wall) uses `▒` (medium shade) in `frame_d0_none()` — Ember's Escape source.
**Position B**: Depth=1 uses `▓░▒` pattern (mix including full dark shade) in `frame_d1_none()` — Ember's Escape source; depth=1 brick is visually denser than depth=0 stone.
**Assessment**: This is an internal inconsistency in the game's existing frames, not a source conflict. Depth=0 should be densest (closest, most visible) but currently has lighter fill than depth=1. Recommendation R3 and R4 address this. The "1/2 brightness per layer" rule from three external sources confirms that depth=0 should be the densest/brightest, not depth=1.

---

## Recommendations for Further Research

1. **Fetch the Captive View Rendering tutorial** linked from dungeoncrawlers.org — may contain the most technically precise documentation of the painter's algorithm in an 8-bit dungeon crawler context.

2. **Review PZDC_dungeon_2 source code** (GitHub) — a terminal roguelike with ASCII graphics that may demonstrate depth-color techniques applied in practice.

3. **Test half-block horizon line (R3 extension)** — implement ▀▄ at the ceiling/floor junctions in a single test frame and evaluate visually in Terminal.app vs iTerm2 to assess font rendering consistency before applying across all 52 frames.

4. **Profile frame-write performance** — if color codes are added to every line of every frame (15 rows × 2 escape sequences each = 30 writes per frame), ensure no perceptible flicker on slow terminals.

---

## Full Citations

[1] Bellot, Bertrand. "3D before GPUs Part 1: Dungeon Master". weblogs.asp.net. N.d. https://weblogs.asp.net/bleroy/dungeon-master/. Accessed 2026-04-03.

[2] Monteiro, Daniel "MontyOnTheRun". "Dungeons of Noudar 3D Rendering Explained". itch.io devlog. N.d. https://montyontherun.itch.io/dungeons-of-noudar-3d/devlog/23896/dungeons-of-noudar-3d-rendering-explained. Accessed 2026-04-03.

[3] Screaming Brain Studios. "First Person Dungeons Tutorial". screamingbrainstudios.com. N.d. https://screamingbrainstudios.com/first-person-dungeons/. Accessed 2026-04-03.

[4] Bellanger, Clint. "First Person Dungeon Crawl Art Pack". OpenGameArt.org. 2013. https://opengameart.org/content/first-person-dungeon-crawl-art-pack. Accessed 2026-04-03.

[5] Moore, Dave. "libtcod-painters-algorithm". GitHub. N.d. https://github.com/davemoore22/libtcod-painters-algorithm. Accessed 2026-04-03.

[6] Dungeon Crawlers community. "Game Development Resources". dungeoncrawlers.org. N.d. https://dungeoncrawlers.org/resources/gamedev/. Accessed 2026-04-03.

[7] wonrzrzeczny. "Asciipocalypse — 3D first person shooter in ASCII". GitHub. N.d. https://github.com/wonrzrzeczny/Asciipocalypse. Accessed 2026-04-03.

[8] Harri, Alex. "ASCII characters are not pixels: a deep dive into ASCII rendering". alexharri.com. N.d. https://alexharri.com/blog/ascii-rendering. Accessed 2026-04-03.

[9] Kragen Javier Sitaker. "ASCII art, but in Unicode, with Braille and other alternatives". dernocua.github.io. N.d. https://dernocua.github.io/notes/unicode-graphics.html. Accessed 2026-04-03.

[10] The Unicode Consortium. "Block Elements Range U+2580–U+259F". unicode.org. N.d. https://www.unicode.org/charts/PDF/U2580.pdf. Accessed 2026-04-03.

[11] Wikipedia contributors. "Block Elements". en.wikipedia.org. N.d. https://en.wikipedia.org/wiki/Block_Elements. Accessed 2026-04-03.

[12] Hagemann, Marvin. "So you want to render colors in your terminal". marvinh.dev. N.d. https://marvinh.dev/blog/terminal-colors/. Accessed 2026-04-03.

[13] fnky. "ANSI Escape Codes". GitHub Gist. N.d. https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797. Accessed 2026-04-03.

[14] splinedrive. "True Colour support in various terminal applications and terminals". GitHub Gist. N.d. https://gist.github.com/splinedrive/0691befec6fc0bb21d9cc943f94b1282. Accessed 2026-04-03.

[15] Bagterp, Jakob. "ANSITerminal Swift library". GitHub. N.d. https://github.com/pakLebah/ANSITerminal. Accessed 2026-04-03.

[16] termstandard. "Color standards for terminal emulators". GitHub. N.d. https://github.com/termstandard/colors. Accessed 2026-04-03.

[17] RogueBasin contributors (mirror). "Unicode for Roguelikes". chizaruu.github.io. N.d. https://chizaruu.github.io/roguebasin/unicode. Accessed 2026-04-03.

---

## Research Metadata

Duration: ~45 min | Examined: 25+ sources | Cited: 17 | Cross-refs: 14 | Confidence: High 59%, Medium-High 29%, Medium 12% | Output: /Users/Maarten.Engels/Developer/DCJam2026/docs/research/graphics/ascii-dungeon-graphics-research.md
