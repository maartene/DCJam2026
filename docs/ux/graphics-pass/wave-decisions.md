# Wave Decisions — graphics-pass

**Feature**: graphics-pass
**Wave**: DISCUSS
**Date**: 2026-04-03

This document records the key scoping and design decisions made during the DISCUSS wave.
It is the authoritative reference for why certain approaches were chosen and others deferred.

---

## DEC-GP-01: R5 (half-block horizon characters) deferred

**Decision**: R5 — replacing diagonal ASCII characters `\` and `/` at the horizon line with
half-block Unicode characters `▀` and `▄` — is explicitly out of scope for this graphics pass.

**Rationale**: The user's stated intent is to discover how far ANSI color alone can take the
visual quality before introducing non-ASCII Unicode layout changes. The half-block technique
requires modifying the structural characters in `DungeonFrames.swift` frame strings, which is a
higher-risk content change than the targeted color additions in R1/R2/R4. Deferring R5 keeps
the blast radius of this pass entirely in `Renderer.swift` (for R1/R2/R4) and a single variable
in `DungeonFrames.swift` (for R3).

**Deferred to**: Post-jam polish pass, if the ANSI-only result is insufficient.

---

## DEC-GP-02: ANSI 16-color first, 256-color as enhancement (not replacement)

**Decision**: R1 implements ANSI 16-color depth grading as the baseline. R4 upgrades to 256-color
on capable terminals. The 16-color codes remain as the fallback path and are not removed.

**Rationale**: The game targets both macOS Terminal.app and generic SSH/POSIX terminals.
Terminal.app is known to support 256 colors, but the research confirmed that `TERM=xterm-256color`
is the reliable detection signal rather than `COLORTERM`. Layering R4 on top of R1 (rather than
replacing R1) ensures zero regression on any terminal that does not advertise 256-color support.

---

## DEC-GP-03: Truecolor (24-bit) warm/cool torch effect deferred

**Decision**: R6 from the research (warm amber at depth=0, cool blue-gray at depth=3 via
truecolor escape codes) is out of scope for this pass.

**Rationale**: Truecolor requires iTerm2 or an equivalent emulator and a `COLORTERM=truecolor`
detection guard. The grayscale approach in R4 achieves a meaningful depth gradient without
color temperature and works on Terminal.app. Truecolor torch color is a post-jam polish feature
that can be layered on top of R4 without reworking the existing architecture.

---

## DEC-GP-04: R3 scope limited to `frame_d0_none()`

**Decision**: The character density fix (R3) applies only to `frame_d0_none()`. Other depth=0
variant frames (e.g., nearLeft, nearRight) are not authored yet; if they are added in the future
the R3 principle (`▓▒` alternating for depth=0 wall face) applies to them at authoring time.

**Rationale**: Only `frame_d0_none()` exists in the current frame table for depth=0. Applying
R3 to non-existent frames is not meaningful. This keeps the change small and reviewable.

---

## DEC-GP-05: 256-color detection via TERM, not COLORTERM

**Decision**: R4 detects 256-color support by checking whether `TERM` contains `"256color"`,
not by checking `COLORTERM`.

**Rationale**: `COLORTERM=truecolor` indicates 24-bit support (iTerm2). Checking `COLORTERM`
for 256-color detection would be incorrect — `COLORTERM` is absent in Terminal.app despite
Terminal.app supporting 256 colors. `TERM=xterm-256color` is the standard signal for 256-color
support and is set by both Terminal.app and iTerm2.

---

## DEC-GP-06: Color wrapping at write site, not in frame data

**Decision**: ANSI color codes are applied in `Renderer.renderDungeon()` at the point of writing,
not stored in the frame strings in `DungeonFrames.swift`.

**Rationale**: Frame strings must remain pure content (ASCII + block elements). Embedding color
codes in frame strings would make the strings terminal-dependent, break the `pad()` width
calculation (which counts bytes not visible characters), and couple the color scheme to the frame
authoring. The `Renderer` layer is the correct place for terminal-specific formatting decisions,
consistent with the existing architecture (all other color code injection happens in `Renderer`).

---

## DEC-GP-07: Per-line reset (`\e[0m`) rather than region-level reset

**Decision**: `\e[0m` is appended to each individual dungeon frame line rather than emitted
once after all 15 lines.

**Rationale**: The CLAUDE.md constraint requires that every colored region ends with a reset to
prevent color bleed. If the reset were only at the end of all 15 lines, any partial write or
flush between lines (which the looping write pattern may produce) could leave the terminal in a
colored state. Per-line resets are conservative and safe.
