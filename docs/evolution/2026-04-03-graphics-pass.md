# Evolution — graphics-pass

**Date**: 2026-04-03
**Feature ID**: graphics-pass
**Status**: Complete

---

## Feature Summary

The graphics pass applied targeted ANSI color enhancements to the first-person dungeon view of
Ember's Escape, transforming the monochrome ASCII corridor into a depth-graded visual. The goal
was maximum visual impact at minimum code cost before the DCJam 2026 submission, without
introducing new dependencies, restructuring the rendering architecture, or touching the 52
pre-authored ASCII frame strings beyond one targeted density fix.

The work was scoped to four requirements delivered in sequence, each building on the last:

1. Dark background (R2) — ensures a visually distinct dungeon panel on any terminal theme
2. 16-color depth grading (R1) — the single largest visual improvement: brighter near, darker far
3. Character density fix (R3) — corrects an inversion where depth=0 looked lighter than depth=1
4. 256-color grayscale ramp (R4) — smoother depth falloff on modern terminals with 16-color fallback

---

## Business Context

Ember's Escape is submitted to DCJam 2026. The jam evaluates entries partly on visual presentation
in addition to gameplay. The dungeon's first-person view is the dominant screen element and was
entirely monochrome prior to this pass. Even modest depth-graded color produces a significant
perceived quality improvement with low implementation risk — the pass required no new Swift
package dependencies, no changes to the game loop or domain layer, and no structural changes to
the existing frame lookup architecture.

---

## Steps Completed

| Step | Description | Commit |
|------|-------------|--------|
| 01-01 | Dark background `\e[40m` emitted once before dungeon frame lines in `renderDungeon()` | `0603f82` |
| 01-02 | Depth-graded ANSI 16-color foreground per frame depth (bright white → standard white → dark gray → dark gray) | `e578f27` |
| 01-03 | Fixed character density inversion in `frame_d0_none()` — `▒` → `▓▒` alternating | `162938f` |
| 01-04 | 256-color grayscale depth ramp (indices 252/245/238/234) with 16-color fallback; one-time TERM detection at `Renderer` init | `43921fe` |
| Refactor | L1-L2 cleanup, removed dead `buildMinimap` method | `07867f7` |
| Tests | Consolidate redundant tests per review (12→10) | `bf60323` |

All 229 tests pass after completion.

---

## Key Decisions

### ANSI 16-color baseline + 256-color as enhancement (DEC-GP-02)

R1 implements 16-color depth grading as the functional baseline. R4 adds 256-color on capable
terminals as a non-breaking enhancement. The 16-color codes remain the fallback and are never
removed. This layered approach ensures zero regression on any terminal that does not advertise
256-color support while providing a visibly smoother gradient on macOS Terminal.app and iTerm2.

### R5 half-block horizon characters deferred (DEC-GP-01)

Replacing the `\` and `/` horizon characters with half-block Unicode `▀` and `▄` was explicitly
deferred. The intent was to discover how far ANSI color alone could improve visual quality before
incurring the risk of structural frame string changes. The ANSI-only result was sufficient for the
jam submission.

### Color at write site, not in frame data (DEC-GP-06)

ANSI escape codes are injected in `Renderer.renderDungeon()` at the point of writing. Frame strings
in `DungeonFrames.swift` remain pure content (ASCII + block elements). Embedding color in frame
data would couple the color scheme to frame authoring, break the `pad()` width calculation, and
violate the existing architecture where all terminal-specific formatting lives in `Renderer`.

### Per-line resets rather than region-level reset (DEC-GP-07)

`\e[0m` is appended to each individual dungeon frame line. This is conservative: a region-level
reset at the end of all 15 lines would leave the terminal in a colored state if any partial write
or flush occurred between lines. Per-line resets satisfy the CLAUDE.md ANSI reset discipline.

### 256-color detection via TERM, not COLORTERM (DEC-GP-05)

Detection checks whether `TERM` contains `"256color"`. `COLORTERM=truecolor` (iTerm2) indicates
24-bit support, not 256-color; using it for 256-color detection would miss Terminal.app which sets
`TERM=xterm-256color` without setting `COLORTERM`. Detection is performed once at `Renderer` init
and stored as a boolean.

---

## Lessons Learned

**The lookup table frame architecture made color injection trivial.** Because frame strings are
pure content and rendering decisions live entirely in `Renderer`, adding depth-aware color required
only localized changes in one method. Any approach that embedded terminal codes in the frame strings
would have made this enhancement far more costly.

**Baseline first, enhancement second.** Implementing R1 (16-color) before R4 (256-color) meant R4
could be added without touching the fallback path. At no point was there a regression risk on
non-256-color terminals.

**Character density and color are complementary signals.** The R3 density fix was not visible before
R1/R2 were in place — the color grading made the density inversion obvious. Order of delivery
(color before density) made the bug self-revealing.

**Truecolor deferred correctly.** The 256-color grayscale ramp produces a visibly smooth depth
gradient on Terminal.app. Truecolor (warm amber / cool blue-gray torch effect) remains a viable
post-jam polish feature that can be layered on top of the R4 infrastructure without rework.
