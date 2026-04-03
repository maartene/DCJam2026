# Requirements — Game Polish v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)

---

## Summary

7 user stories addressing playtest-confirmed issues in Ember's Escape.
All stories are brownfield (the game exists; no walking skeleton needed).
Requirements are solution-neutral — implementation decisions belong to the DESIGN wave.

---

## Requirements by Story

### REQ-P01: Start Screen

**Problem statement**: Players launch the game with no context, no controls knowledge, and
no narrative frame before the dungeon begins.

**Requirement**: When the game launches, a start screen must be displayed before the dungeon.
The start screen must show the game title, a narrative hook, all key bindings, and a prompt to
begin. Any key press must dismiss it and enter the dungeon.

**Constraints**:
- Must not show the dungeon, status bar, minimap, or thoughts panel
- Must list ESC as the quit key (not Q)
- Must fit in the standard 80×25 terminal

**Out of scope**: Animation, countdown timers, high score display

---

### REQ-P02: Remove Q as Quit Key

**Problem statement**: Q is adjacent to WASD. Pressing it during play terminates the game
with no confirmation and no recovery. Confirmed playtest issue.

**Requirement**: The Q key and Shift-Q key must produce no game action in any game state.
ESC must remain the sole quit key.

**Constraints**:
- ESC quit behavior must be unchanged
- No confirmation dialog required (game jam scope)
- Start screen must show ESC as quit before Q is removed (sequencing: US-P01 ships with US-P02)

**Out of scope**: Confirmation prompt before quit

---

### REQ-P03: Egg Pickup Screen Content

**Problem statement**: The existing egg discovery overlay is functional but underdelivers on
the emotional beat — the moment the player's mission crystallises.

**Requirement**: The egg discovery overlay content must be revised to:
- Show ASCII egg art (5-line centered art from spike2)
- Show "~ My egg. ~" or equivalent title in bright yellow
- Show "Warm. Alive. Still here." (or equivalent) in white
- Include a dimmed flavour line (dragon inner voice)
- Show "[ press any key ]" prompt
- Require a keypress to dismiss (no auto-clear)

**Reference**: `spikes/spike2-narrative-overlay.swift` → `showEggOverlay()`

**Constraints**:
- No change to NarrativeEvent enum or ScreenMode — content change only
- Must render within the existing 78-column main view area (rows 2–16)

---

### REQ-P04: Win Screen Content

**Problem statement**: The win screen delivers statistics instead of emotional resolution.
The tone is mismatched with the game's narrative arc (earned relief, not triumph).

**Requirement**: The win screen must be revised to:
- Show "The sky." as the headline in bold bright cyan
- Show "Open. Endless. Yours." beneath it
- Show a starfield ASCII art block (dots and asterisks)
- Include narrative lines from spike2's exit overlay ("But you are free.")
- Show floors cleared and HP remaining as a summary block
- Show "[ Press R to play again ]" prompt

**Reference**: `spikes/spike2-narrative-overlay.swift` → `showExitOverlay()`

**Constraints**:
- No change to ScreenMode.winState or win condition logic
- Stat summary must be retained (floors cleared, HP remaining)

---

### REQ-P05a: HP Bar Color

**Problem statement**: The HP bar is monochrome. Players cannot assess danger state without
reading the numeric fill count.

**Requirement**: The HP bar fill must change color dynamically:
- At or above 40% of maxHP: green (ANSI 32)
- Below 40% and at or above 20%: yellow (ANSI 33)
- Below 20%: red (ANSI 31)

Color transitions must apply in the same render frame as the HP change.
All colored ANSI sequences must be followed by a reset code.

---

### REQ-P05b: Charge and Cooldown Color

**Problem statement**: Cooldown timers and the Special charge meter are monochrome.
The Special-ready moment — a high emotional beat — is visually undifferentiated.

**Requirement**:
- When `specialIsReady == true`: SPEC label and bar must render in bold bright cyan (ANSI 96 + 1)
- When special is charging (not ready): SPEC bar renders in dim cyan (ANSI 36)
- When Dash cooldown is active: cooldown timer text renders in yellow (ANSI 33)
- When Brace is on cooldown: BRACE label renders in yellow (ANSI 33)
- All colored sequences must end with ANSI reset

---

### REQ-P05c: Minimap Color

**Problem statement**: The minimap renders all characters in the same color.
Threats, goals, and walls are indistinguishable at a glance.

**Requirement**: Each landmark type on the minimap must render in a distinct color:
- Player (^, >, v, <): bold bright white (ANSI 97 + 1)
- Guard (G): bright red (ANSI 91)
- Boss (B): bold bright red (ANSI 91 + 1)
- Egg uncollected (*): bright yellow (ANSI 93)
- Egg collected (e): dim yellow (ANSI 33)
- Staircase (S): bright cyan (ANSI 96)
- Exit (X): bold bright cyan (ANSI 96 + 1)
- Entry (E): dim cyan (ANSI 36)
- Walls (#): dark gray (ANSI 90)
- Passable (.) : default / no color code

Each character write must be followed by a color reset.

---

### REQ-P06: Brace Feedback Overlays

**Problem statement**: The outcome of a Brace action (parry success or hit taken) is not
communicated to the player. Players report not knowing if Brace worked.

**Requirement**:
- When an enemy attack resolves while `braceWindowActive == true` (successful parry):
  A brief overlay must render containing a dragon-themed "parry success" word.
  Suggestion: **"SHIELDED!"** — developer must confirm before implementation.
  Overlay color: bright cyan. Sub-line confirms scales deflected the blow.

- When an enemy attack resolves while `braceWindowActive == false` (no active window):
  A brief overlay must render containing a dragon-themed "hit taken" word.
  Suggestion: **"SCORCHED!"** — developer must confirm before implementation.
  Overlay color: bright red. Sub-line confirms the hit got through.

- Both overlays must auto-clear after approximately 0.75 seconds (23 frames at 30Hz).
  No player input required to dismiss them.

- Exception: if the hit would kill the player (hp <= 0 after damage), the death screen
  takes priority. The SCORCHED overlay must not render.

**Design decision required (IC-03)**: A new brace outcome signal is needed in GameState
to surface parry results to the Renderer. DESIGN wave must choose the approach.
See `shared-artifacts-registry.md` SA-P08.

---

### REQ-P07: Dash Feedback Overlay

**Problem statement**: Dashing through a guard changes the dungeon view, but there is no
visual confirmation that the Dash action itself occurred. Players cannot distinguish a dash
from a normal move.

**Requirement**: When a Dash resolves successfully (`recentDash == true`):
- A brief overlay must render containing a dragon-themed dash word.
  Suggestion: **"SWOOSH!"** — developer must confirm before implementation.
  Overlay color: bold white.
- A sub-line must describe the dash in dragon vocabulary (e.g., "Wings snap. You tear through.").
- The overlay must auto-clear after approximately 0.75 seconds (23 frames at 30Hz).
  No player input required.
- The overlay must not render when dashCharges == 0 (dash was not executed).

**Note**: `recentDash` already exists in `GameState`. The transient overlay persistence
mechanism (23-frame countdown) is the new requirement. Same mechanism as REQ-P06.

---

## Vocabulary Decision List

The following overlay words are SUGGESTIONS and must be confirmed by the developer before
implementation. Developer may choose any dragon-appropriate term.

| Overlay | Suggested word | Alternatives |
|---------|---------------|--------------|
| Brace parry success | SHIELDED! | GUARDED! / DEFLECTED! / HELD! |
| Brace hit taken | SCORCHED! | BURNED! / STRUCK! / OUCH! |
| Dash | SWOOSH! | SURGE! / BURST! / LUNGE! |

Developer: please record your choices in `docs/feature/game-polish-v1/discuss/wave-decisions.md`.

---

## Out of Scope

These items from `docs/NOTES.md` are acknowledged but not addressed in this wave:
- **Graphics pass** (improve dungeon ASCII art frames): no clear acceptance criterion;
  belongs in a separate discovery session.
