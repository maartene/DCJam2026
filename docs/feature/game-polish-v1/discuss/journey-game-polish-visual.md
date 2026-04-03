# Journey Visual: Game Polish v1 — Ember's Escape
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)
**Source**: Playtest feedback (docs/NOTES.md), spike2-narrative-overlay.swift, docs/CLAUDE.md

---

## Context: Brownfield Polish Pass

Ember's Escape already exists as a playable game. This DISCUSS wave addresses a focused set of polish
items surfaced by playtest feedback. The journey below maps the complete player session, annotating
where each polish item intervenes and what emotional gap it closes.

---

## Emotional Arc — Before vs After Polish

```
BEFORE POLISH (playtest problems marked):

EMOTION
  HIGH |                                                   [BADASS?]      [RELIEF?]
       |                                                       *               *
  MED  |          *         *           *           *
       |     *
  LOW  |  *   [OOPS! quit]          [eh? brace?]  [did that work?]
       |      accidental q          no feedback    no dash feedback
       +----+----+--------+--------+--------+--------+--------+-------->
           GAME  FL1       FL2      FL3      EGG     FL5      WIN
           START

AFTER POLISH (target state):

EMOTION
  HIGH |                                                     [BADASS]       [EARNED RELIEF]
       |                                                         *                 *
       |                             *           *           *       *         *
  MED  |           *           *         *   *                         *
       |      *         *   *
  LOW  |  [START]
       |  (title sets
       |   the tone)
       +----+----+--------+--------+--------+--------+--------+--------+-------->
          START   FL1      FL2      FL3     EGG      BOSS    WIN+EXIT
         Screen  [learn]  [grow]  [tension] SCREEN  BRACE   SCREEN
                                            relief   DASH
                                                    FEEDBACK
```

Key emotional waypoints after polish:
- **Start screen**: Ember wakes to the story. Title + controls before confusion. Orientation = calm, not lost.
- **Brace parry success ("SHIELDED!")**: Player now notices the mechanic worked. Satisfaction spike.
- **Brace parry failure ("SCORCHED!")**: Player understands they took a hit. Recalibrates without confusion.
- **Dash feedback ("SWOOSH!")**: The primary verb is now visible. Delight reinforced each use.
- **Egg pickup screen**: Full narrative beat from spike2. Relief is felt, not just a status toggle.
- **HP color shift**: Anxiety rises naturally as HP enters yellow/red zone. No text needed.
- **Win screen**: Expanded from terse "ESCAPED!" to a narrative beat matching spike2's exit overlay tone.

---

## Journey Map: Full Session with Polish Items Annotated

```
+-------------------------------------------------------------------------+
| STEP 1: LAUNCH                                                          |
|                                                                         |
|  Player types: swift run (or launches binary)                           |
|                                                                         |
|  BEFORE: Game immediately shows dungeon. Controls unknown.              |
|  AFTER:  [POLISH-01] Start screen appears first.                        |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                                                                   |  |
|  |              D R A G O N   E S C A P E                           |  |
|  |                   DCJam 2026                                      |  |
|  |                                                                   |  |
|  |      The hero has fled. Your egg is still in there.              |  |
|  |      You are Ember. Go get it back.                              |  |
|  |                                                                   |  |
|  |   Controls:                                                       |  |
|  |     W/S       Move forward / back                                |  |
|  |     A/D       Turn left / right                                  |  |
|  |     1         Dash through a guard (costs 1 charge)              |  |
|  |     2         Brace (opens a parry window)                       |  |
|  |     3         Special (requires full charge meter)               |  |
|  |     ESC       Quit                                               |  |
|  |                                                                   |  |
|  |                   [ Press any key to begin ]                     |  |
|  |                                                                   |  |
|  +-------------------------------------------------------------------+  |
|                                                                         |
|  Emotional beat: ORIENTATION — story is clear, controls are known.     |
|  Quit key: ESC (not Q) — [POLISH-02] Q no longer triggers quit.        |
+-------------------------------------------------------------------------+
                             |
                             v
+-------------------------------------------------------------------------+
| STEP 2: DUNGEON NAVIGATION (Floors 1–5)                                |
|                                                                         |
|  Player navigates the corridor. Status bar is always visible.           |
|                                                                         |
|  [POLISH-05a] HP bar color:                                             |
|    HP >= 40%  :  green  "HP [██████████] 100%"                         |
|    HP  < 40%  :  yellow "HP [████░░░░░░]  38%"                         |
|    HP  < 20%  :  red    "HP [██░░░░░░░░]  17%"                         |
|                                                                         |
|  [POLISH-05b] Cooldown/Charge visual prominence:                        |
|    Dash on cooldown: cooldown timer rendered in dim/yellow              |
|    Special ready:    "SPEC" label + bar rendered bold/bright cyan       |
|    Special not ready: dim rendering                                     |
|                                                                         |
|  [POLISH-05c] Minimap color:                                            |
|    Wall cells (#): dim gray                                             |
|    Player (^>v<): bright white + bold                                   |
|    Guard/Boss (G/B): bright red                                         |
|    Egg (*): bright yellow                                               |
|    Stairs (S) / Exit (X): bright cyan                                   |
|    Entry (E): dim cyan                                                  |
|                                                                         |
|  Emotional beat: SITUATIONAL AWARENESS — state is legible at a glance  |
+-------------------------------------------------------------------------+
                             |
                             v
+-------------------------------------------------------------------------+
| STEP 3: COMBAT — BRACE WINDOW                                           |
|                                                                         |
|  Player presses 2 (Brace). 0.5s parry window opens.                    |
|                                                                         |
|  CASE A — Successful parry (enemy attacks during window):               |
|  [POLISH-06a] Brief overlay renders across combat view:                 |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                                                                   |  |
|  |               *** SHIELDED! ***                                  |  |
|  |          Your scales turn the blow aside.                        |  |
|  |       Special meter charges from the impact.                     |  |
|  |                                                                   |  |
|  +-------------------------------------------------------------------+  |
|                                                                         |
|  Overlay clears after ~0.75s or on next input. No player action needed. |
|                                                                         |
|  CASE B — Failed parry (no active window when enemy hits):              |
|  [POLISH-06b] Brief overlay renders:                                    |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                                                                   |  |
|  |               *** SCORCHED! ***                                  |  |
|  |            That one got through your guard.                      |  |
|  |                                                                   |  |
|  +-------------------------------------------------------------------+  |
|                                                                         |
|  Overlay clears after ~0.75s. HP bar updates with new color.            |
|  Emotional beat: CLARITY — player understands the mechanic outcome.    |
+-------------------------------------------------------------------------+
                             |
                             v
+-------------------------------------------------------------------------+
| STEP 4: COMBAT — DASH                                                   |
|                                                                         |
|  Player presses 1 (Dash). Movement happens in same tick.               |
|  BEFORE: Dungeon view changes but nothing signals the dash verb.        |
|                                                                         |
|  [POLISH-07] After dash resolves, brief overlay renders:                |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                                                                   |  |
|  |                      ~ SWOOSH! ~                                 |  |
|  |         Wings snap. You tear through the guard.                  |  |
|  |                                                                   |  |
|  +-------------------------------------------------------------------+  |
|                                                                         |
|  Overlay clears after ~0.75s. Dungeon view resumes.                     |
|  Emotional beat: DELIGHT — "I am the verb"                             |
|  Note: recentDash flag already exists in GameState — overlay can use it.|
+-------------------------------------------------------------------------+
                             |
                             v
+-------------------------------------------------------------------------+
| STEP 5: EGG PICKUP SCREEN                                               |
|                                                                         |
|  Player enters egg room. Full-screen narrative overlay fires.           |
|  BEFORE: Already implemented as narrativeOverlay(.eggDiscovery)         |
|  AFTER:  [POLISH-03] Content revised to match spike2 tone.             |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                                                                   |  |
|  |               ~ My egg. ~                                        |  |
|  |                                                                   |  |
|  |                    .-.                                           |  |
|  |                   /   \                                          |  |
|  |                  | o o |                                         |  |
|  |                  |  ^  |                                         |  |
|  |                   \___/                                          |  |
|  |                                                                   |  |
|  |         Warm. Alive. Still here.                                 |  |
|  |                                                                   |  |
|  |    "They almost had you. Almost."                                |  |
|  |                                                                   |  |
|  |                 [ press any key ]                                |  |
|  |                                                                   |  |
|  +-------------------------------------------------------------------+  |
|                                                                         |
|  Emotional beat: ACTUAL RELIEF — mission half-complete.                |
+-------------------------------------------------------------------------+
                             |
                             v
+-------------------------------------------------------------------------+
| STEP 6: WIN SCREEN                                                      |
|                                                                         |
|  Player steps onto exit square with egg. Win state fires.              |
|  BEFORE: Terse "ESCAPED!" + stats.                                     |
|  AFTER:  [POLISH-04] Full narrative beat matching spike2's exit tone.  |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                                                                   |  |
|  |               The sky.                                           |  |
|  |          Open. Endless. Yours.                                   |  |
|  |                                                                   |  |
|  |           *    .  *       .                                      |  |
|  |      .         .              .                                  |  |
|  |           .    *       .                                         |  |
|  |      *        .    .       *                                     |  |
|  |                                                                   |  |
|  |    "Home is a long flight from here.                             |  |
|  |     But you are free."                                           |  |
|  |                                                                   |  |
|  |           Floors cleared: N  |  HP remaining: N                  |  |
|  |                                                                   |  |
|  |                 [ Press R to play again ]                        |  |
|  |                                                                   |  |
|  +-------------------------------------------------------------------+  |
|                                                                         |
|  Emotional beat: EARNED RELIEF — exhale, not fist-pump.               |
+-------------------------------------------------------------------------+
```

---

## Key Binding Change Map

| Key | Before | After | Reason |
|-----|--------|-------|--------|
| `q` / `Q` | Quit game | No action (or remapped) | Too close to WASD; playtest accidents |
| `ESC` | Quit game | Quit game (retained) | Safe distance from WASD |
| Space/Enter | Confirm overlay | Confirm overlay (retained) | |
| `r` / `R` | Restart | Restart (retained) | |

Note: Start screen introduces controls to new players. ESC-to-quit must be shown there.

---

## ANSI Color Palette (Status Bar)

All colors use existing ANSI codes already present in spike2 and ANSITerminal.swift.

| Element | State | ANSI Sequence | Rationale |
|---------|-------|---------------|-----------|
| HP bar fill | >= 40% | `\e[32m` bright green | Healthy |
| HP bar fill | < 40% | `\e[33m` yellow | Caution |
| HP bar fill | < 20% | `\e[31m` red | Danger |
| HP label "HP" | any | `\e[1m` bold | Always stands out |
| Dash cooldown timer | active | `\e[33m` yellow | Readiness pending |
| Dash charges | ready | `\e[1m` bold white | Ready state |
| SPEC label + bar | ready | `\e[96m\e[1m` bold bright cyan | Power available |
| SPEC bar | charging | `\e[36m` dim cyan | Building up |
| BRACE label | on cooldown | `\e[33m` yellow | On cooldown |
| EGG symbol `*` | hasEgg=true | `\e[93m` bright yellow | Has egg — warm |
| Minimap: player | — | `\e[97m\e[1m` bold white | Most important |
| Minimap: guard/boss | — | `\e[91m` bright red | Threat |
| Minimap: egg | not collected | `\e[93m` bright yellow | Goal |
| Minimap: stairs/exit | — | `\e[96m` bright cyan | Destination |
| Minimap: walls | — | `\e[90m` dark gray | Background |
| Minimap: entry | — | `\e[36m` dim cyan | Origin |

---

## Overlay Duration Model

Brace and Dash feedback overlays are brief (non-blocking — auto-clear):

| Overlay | Trigger | Duration | Dismissal |
|---------|---------|----------|-----------|
| SHIELDED! | Successful parry | ~0.75s (23 frames at 30Hz) | Auto-clears; no keypress needed |
| SCORCHED! | Hit lands, no window | ~0.75s | Auto-clears |
| SWOOSH! | Dash resolves | ~0.75s | Auto-clears |
| Egg pickup | Enters egg room | Until keypress | Player must dismiss |
| Win screen | Reaches exit | Until R pressed | Player must dismiss |
| Start screen | Launch | Until any key | Player must dismiss |

Auto-clearing overlays require a timer field in GameState or a frame counter in the Renderer.
Suggest: new `NarrativeEvent` cases or a `transientOverlay: TransientOverlay?` field in GameState.

---

## Integration Checkpoints

| Polish Item | Shared Artifact | Source of Truth | Existing? |
|-------------|----------------|-----------------|-----------|
| Remove Q | InputHandler.mapKey | InputHandler.swift | Yes — Q mapped to shouldQuit |
| Start screen | ScreenMode | ScreenMode.swift | No — new case .startScreen needed |
| Win screen (revised) | ScreenMode.winState | Renderer.renderWinScreen | Partial — exists, needs content update |
| Egg pickup (revised) | NarrativeEvent.eggDiscovery | Renderer.narrativeContent | Partial — exists, needs content update |
| HP color | GameState.hp, GameState.config.maxHP | GameState.swift | Yes — data exists, color logic missing |
| Cooldown/charge color | GameState.timerModel, specialCharge, braceOnCooldown | GameState.swift | Yes — data exists, color logic missing |
| Minimap color | FloorMap, GameState.playerPosition | Renderer.minimapChar | Yes — character logic exists, color missing |
| Brace success overlay | GameState.braceWindowActive (new: parry outcome) | RulesEngine | Partial — window exists; outcome not surfaced to Renderer |
| Brace failure overlay | GameState.hp change event | RulesEngine | No — needs new state signal |
| Dash overlay | GameState.recentDash | GameState.swift | Yes — recentDash already exists |
