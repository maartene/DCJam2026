<!-- markdownlint-disable MD024 -->
# User Stories — Game Polish v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)

---

## US-P01: Start Screen

### Problem
Ember (player) launches Ember's Escape and is immediately dropped into the dungeon with no context.
They find it disorienting to understand the story, the controls, and the quit key when nothing
is explained before play begins.

### Who
- First-time player | Launching the binary cold | Wants to know what to do before the first step

### Solution
A start screen renders before the dungeon on first launch. It shows the game title, a one-paragraph
narrative hook, and all key bindings. Player must press any key to enter the dungeon.

### Domain Examples

#### 1: First Launch — Clean Orientation
Maartene launches `swift run` for the first time. The terminal clears and shows "Ember's Escape" at
the top, "DCJam 2026" beneath it, a two-sentence story hook, and a neat controls table listing
W/S/A/D, 1/2/3, and ESC to quit. They read it in 5 seconds and press W.

#### 2: Returning Player — Skip Quickly
Alex has played three times. They launch again, see the start screen, and press Space immediately
to skip to the dungeon. The start screen does not block or delay — any key dismisses it.

#### 3: Player Hunts for Quit Key
Sam doesn't know how to quit. They read the start screen controls list and see "ESC: Quit".
They remember this throughout the session. Q is not listed anywhere.

### UAT Scenarios (BDD)

See `journey-game-polish.feature` — Scenarios: "Player sees start screen on launch before the
dungeon", "Player dismisses start screen and enters the dungeon"

### Acceptance Criteria
- [ ] Title "Ember's Escape" appears on first frame after launch
- [ ] "DCJam 2026" appears beneath the title
- [ ] A narrative hook referencing the egg and the hero is present
- [ ] All key bindings listed: W/S, A/D, 1, 2, 3, ESC quit
- [ ] Q is not mentioned as a key anywhere on the start screen
- [ ] "[ Press any key to begin ]" prompt is visible
- [ ] Any key press transitions to the dungeon at Floor 1
- [ ] Dungeon shows full HP (green), 2 Dash charges, empty Special on transition

### Outcome KPIs
- **Who**: First-time player launching the game
- **Does what**: Reads controls before first dungeon step
- **By how much**: 100% of players can name the quit key before pressing any key
- **Measured by**: Playtest observation (can player name ESC as quit before first move?)
- **Baseline**: 0% (no start screen; Q/ESC undiscoverable without reading README)

### Technical Notes
- Requires `ScreenMode.startScreen` (new enum case in `GameDomain/ScreenMode.swift`)
- `GameState.initial()` must start with `screenMode: .startScreen`
- Renderer needs a `renderStartScreen()` strategy branch
- Start screen renders in the full 80×25 layout (no chrome needed — full clear)
- No minimap, no status bar, no thoughts panel on this screen

---

## US-P02: Remove Q as Quit Key

### Problem
Ember (player) is fighting a guard, pressing WASD to navigate, and accidentally presses Q.
They find it deeply frustrating that the game quits mid-run without warning, losing all progress.

### Who
- Active player | Mid-combat or mid-navigation | Pressing keys near WASD

### Solution
Q and Shift-Q are removed from the quit key mapping in InputHandler. ESC remains the sole quit key.
The start screen (US-P01) informs players of this change.

### Domain Examples

#### 1: Combat Accident
Yuki is fighting the Dragon Warden on Floor 5 with 20 HP. They reach for S to move back and
clip Q. Before the fix: game quits. After the fix: Q does nothing. Session continues.

#### 2: Exploration Accident
Carlos is turning left (A) and hits Q instead. Before: quit. After: nothing. He barely notices.

#### 3: Deliberate Quit via ESC
Maartene wants to stop playing. They press ESC. Game exits cleanly with terminal restored.

### UAT Scenarios (BDD)

See `journey-game-polish.feature` — Scenarios: "Player presses Q during dungeon navigation — no quit",
"Player presses ESC to quit — game exits cleanly", "Player presses Q during combat — no quit"

### Acceptance Criteria
- [ ] Pressing Q during dungeon navigation produces no observable effect
- [ ] Pressing Q during combat produces no observable effect
- [ ] Pressing Q on the start screen produces no observable effect (or dismisses start screen like any other key — acceptable if start screen treats "any key" as dismiss)
- [ ] Pressing ESC at any screen (except start screen's "any key" handler) exits the game
- [ ] Terminal is restored cleanly after ESC quit (cursor visible, raw mode off)

### Outcome KPIs
- **Who**: Players navigating with WASD in any game state
- **Does what**: Never accidentally quit by pressing Q
- **By how much**: 0 accidental quits via Q in playtest sessions (was: confirmed issue every playtest)
- **Measured by**: Playtest observation — note any quit events and their cause
- **Baseline**: Known accidental quit issue reported in docs/NOTES.md

### Technical Notes
- Change is in `Sources/App/InputHandler.swift` → `mapKey()` private method
- Remove or comment out the `case UInt8(ascii: "q"), UInt8(ascii: "Q"):` quit branch
- ESC alone (count == 1, buf[0] == 0x1B) must remain as quit
- Regression risk: none to game logic; only affects InputHandler
- README.md controls section should be updated to remove Q and show ESC

---

## US-P03: Egg Pickup Screen — Narrative Revision

### Problem
Ember (player) enters the egg room and sees a narrative overlay, but the current text is functional
rather than emotionally resonant. They find it underwhelming as the emotional centrepiece of the run —
the moment the mission crystallises.

### Who
- Player | Floors 2–4, upon entering the egg room for the first time this run | Has been building to this

### Solution
The egg discovery overlay content is revised to match the spike2 prototype narrative:
ASCII egg art, the title "~ My egg. ~" in bright yellow, "Warm. Alive. Still here." in white,
and a dimmed flavour line. The `[ press any key ]` prompt retains player agency.

### Domain Examples

#### 1: Relief Beat Lands
Maartene has been playing 8 minutes, lost 40 HP, and used both Dash charges. They enter a side room
and the egg screen fires. They see the ASCII egg, read "Warm. Alive. Still here." and pause.
The emotion shifts from tension to relief. They press a key and keep going.

#### 2: Screen Appears Only Once
Alex finds the egg on Floor 3. The overlay fires. They continue to Floor 5, die, restart.
On the new run, the egg screen fires again on Floor 2. No carry-over from the previous run.

#### 3: Player Reads Before Moving
Sam enters the egg room on Floor 4. They read the full overlay (4 seconds). Nothing auto-advances.
They press Space when ready. The dungeon resumes with EGG [*] in bright yellow in the status bar.

### UAT Scenarios (BDD)

See `journey-game-polish.feature` — Scenarios: "Egg pickup screen shows spike2-style narrative
content", "Egg pickup screen dismisses on keypress and egg status updates"

### Acceptance Criteria
- [ ] Overlay contains ASCII egg art (5-line .-.  /   \  | o o | | ^ | \___/ style)
- [ ] Title line contains "My egg" rendered in bright yellow (ANSI 93)
- [ ] "Warm. Alive. Still here." renders in bright white
- [ ] A flavour line is present in dimmed style
- [ ] "[ press any key ]" prompt is visible and required to dismiss
- [ ] Overlay does not auto-clear — player must press a key
- [ ] After dismissal, EGG symbol (*) in status bar renders in bright yellow

### Outcome KPIs
- **Who**: Player entering the egg room for the first time in a run
- **Does what**: Pauses at the egg screen (reads it rather than immediately dismissing)
- **By how much**: Average dwell time > 2 seconds in playtest
- **Measured by**: Playtest observation (stopwatch on time between overlay appear and keypress)
- **Baseline**: Current overlay — unknown dwell time; anecdotally skipped quickly

### Technical Notes
- Change is in `Sources/App/Renderer.swift` → `narrativeContent(.eggDiscovery)`
- No structural change to `NarrativeEvent.eggDiscovery` or `ScreenMode`
- ASCII egg art from spike2: 5 lines, centered
- Color requires ANSI codes in the rendered strings — must use TUIOutputPort color calls
  or embed ANSI escapes directly (matching spike2 approach)

---

## US-P04: Win Screen — Narrative Revision

### Problem
Ember (player) reaches the exit with the egg and sees "ESCAPED!" followed by statistics.
They find it anticlimactic — the emotional arc promises earned relief, but the screen delivers
a results menu instead.

### Who
- Player | Floor 5, exit square, egg in hand | Has earned the right to a moment

### Solution
The win screen content is revised to match spike2's exit overlay: "The sky." headline in bold
bright cyan, starfield ASCII art, narrative lines from the exit overlay, then the stat summary.
The screen holds until R is pressed.

### Domain Examples

#### 1: Full Win — Narrative Lands
Maartene clears Floor 5, steps onto the exit. "The sky. Open. Endless. Yours." They read it.
The starfield dots feel like breathing out. They press R to play again with a smile.

#### 2: Win After Taking Heavy Damage
Yuki exits with 8 HP. The win screen shows the narrative, then beneath it: "HP remaining: 8".
The fragility is acknowledged without interrupting the emotional beat.

#### 3: No Egg — Exit Blocked
Sam reaches the exit without the egg. The game does not show the win screen — existing rule
(INT-01: win requires hasEgg == true AND at exit square) blocks it. This story does not change
that rule.

### UAT Scenarios (BDD)

See `journey-game-polish.feature` — Scenario: "Win screen shows narrative-first content matching
spike2 exit overlay"

### Acceptance Criteria
- [ ] "The sky." headline renders in bold bright cyan
- [ ] "Open. Endless. Yours." renders beneath it
- [ ] Starfield art block (asterisks and dots) is present
- [ ] "But you are free." narrative line is present
- [ ] Floors cleared count is displayed (e.g., "Floors cleared: 5")
- [ ] HP remaining count is displayed
- [ ] "[ Press R to play again ]" prompt is visible
- [ ] Screen does not auto-clear; holds until R is pressed

### Outcome KPIs
- **Who**: Player who has just won the game
- **Does what**: Reads the win screen before pressing R
- **By how much**: Average dwell time > 3 seconds in playtest
- **Measured by**: Playtest observation
- **Baseline**: Current "ESCAPED!" screen — anecdotally dismissed immediately

### Technical Notes
- Change is in `Sources/App/Renderer.swift` → `renderWinScreen()`
- Reference: `spikes/spike2-narrative-overlay.swift` → `showExitOverlay()`
- Stat summary (floors, HP) is retained below the narrative block
- Color requires ANSI bright cyan for headline — same approach as egg screen

---

## US-P05: Color Improvements — Status Bar and Minimap

### Problem
Ember (player) is in combat with low HP and cannot tell at a glance how close to death they are.
Special charge reads the same whether empty or full. Minimap threats blend into walls.
They find it cognitively taxing to track state under pressure because all elements look the same.

### Who
- Player | Any game state where status bar or minimap is visible | Under pressure, time-sensitive decisions

### Solution
The HP bar fill color changes dynamically based on health percentage. The Special meter and
charge labels use bold/bright color when ready, dim when not. Minimap landmark characters
render in distinct colors (threats red, goal yellow, exits cyan, walls gray).

### Domain Examples

#### 1: HP Danger Recognition
Carlos has 18 HP. He glances at the status bar and sees red fill. No math needed.
He knows he's in danger and times his Brace more carefully.

#### 2: Special-Ready Recognition
Yuki's Special charge fills up mid-Floor 3. The SPEC label and bar suddenly render in bold
bright cyan. She notices immediately and uses it on the next encounter.

#### 3: Minimap Navigation
Maartene is on Floor 3, unsure where the guard is. She glances at the minimap and sees
a bright red "G" two squares up. No squinting. She decides to Brace first.

### UAT Scenarios (BDD)

See `journey-game-polish.feature` — Scenarios: HP Color (3 scenarios), Special Color (2 scenarios),
Cooldown Color (2 scenarios), Minimap Color (5 scenarios)

### Acceptance Criteria

**HP Bar:**
- [ ] HP >= 40% of maxHP: fill characters render in green (ANSI 32)
- [ ] HP < 40% and >= 20%: fill characters render in yellow (ANSI 33)
- [ ] HP < 20%: fill characters render in red (ANSI 31)
- [ ] Color transitions happen in the same frame the HP value crosses the threshold
- [ ] ANSI reset code follows every colored segment — no color bleed to adjacent elements

**Charge/Cooldown:**
- [ ] SPEC label and bar render in bold bright cyan (ANSI 96 + 1) when specialIsReady == true
- [ ] SPEC bar renders in dim cyan when charging (not ready)
- [ ] Dash cooldown timer text renders in yellow (ANSI 33) when cooldown active
- [ ] BRACE label renders in yellow when braceCooldownTimer > 0

**Minimap:**
- [ ] Player character (^, >, v, <) renders in bold bright white (ANSI 97 + 1)
- [ ] Guard character (G) renders in bright red (ANSI 91)
- [ ] Boss character (B) renders in bold bright red (ANSI 91 + 1)
- [ ] Uncollected egg character (*) renders in bright yellow (ANSI 93)
- [ ] Staircase character (S) renders in bright cyan (ANSI 96)
- [ ] Exit character (X) renders in bold bright cyan (ANSI 96 + 1)
- [ ] Wall character (#) renders in dark gray (ANSI 90)
- [ ] Each character is followed by a color reset to prevent bleed

### Outcome KPIs
- **Who**: Player navigating the dungeon under any level of health/charge pressure
- **Does what**: Makes combat decisions faster by reading color instead of character values
- **By how much**: No player in playtest expresses confusion about HP state or Special readiness
- **Measured by**: Playtest — track "I didn't know I was that low" comments (target: 0)
- **Baseline**: Current playtest — monochrome status bar; state only readable by character counts

### Technical Notes
- HP color: extend `drawStatusBar()` in `Renderer.swift` — wrap hpBar string in ANSI color
- Special color: wrap specBar string and "SPEC" label in ANSI based on `state.specialIsReady`
- Brace cooldown color: wrap braceCooldownStr in ANSI based on `state.braceOnCooldown`
- Minimap color: `renderMinimap()` builds rows as strings — refactor to per-cell writes OR
  build pre-colored row strings using ANSI per character
- All ANSI codes must be followed by reset (`\e[0m`) to prevent bleed

---

## US-P06: Brace Feedback Overlays

### Problem
Ember (player) activates Brace and watches the enemy attack. Whether the parry worked or failed
is invisible — the player's attention is on the first-person view, not the Special meter.
They find it disorienting to not know if their defensive action succeeded.

### Who
- Player | In combat encounter | Just pressed 2 (Brace) and is waiting for the outcome

### Solution
Two brief auto-clearing overlays communicate brace outcomes: "SHIELDED!" on successful parry
(enemy attacked during window), "SCORCHED!" on unbraced hit (no active window). Both auto-clear
after ~0.75s (23 frames at 30Hz) with no player input required.

Note: The exact words "SHIELDED!" and "SCORCHED!" are suggestions for developer review.
See `journey-game-polish.yaml` vocabulary_additions for alternatives.

### Domain Examples

#### 1: Successful Parry
Maartene presses 2 (Brace). 0.3s later, the guard attacks. "SHIELDED!" flashes in bright cyan.
0.75s later it clears. Maartene sees the SPEC meter gained charge. She understands the mechanic.

#### 2: Failed Parry — Hit Taken
Yuki presses 2 (Brace) too late. The window expires. 0.8s later, the guard attacks.
"SCORCHED!" flashes in bright red. 0.75s later it clears. HP bar shows yellow (she dropped below
40%). She knows she missed the timing and plans better next time.

#### 3: Hit That Kills Player
Carlos has 5 HP. The guard attacks, no window active. The hit deals 20 damage.
HP drops to 0. The death screen shows immediately — SCORCHED! does NOT appear because the player
is dead and the death screen takes priority.

### UAT Scenarios (BDD)

See `journey-game-polish.feature` — Scenarios: "Successful parry shows SHIELDED feedback overlay",
"Successful parry overlay clears and Special meter shows bonus charge",
"Unbraced hit shows SCORCHED feedback overlay",
"SCORCHED overlay does not appear when player has already died",
"HP bar updates to new color threshold after SCORCHED overlay clears"

### Acceptance Criteria
- [ ] When enemy attacks during braceWindowActive == true: overlay renders containing "SHIELDED!" (or confirmed word)
- [ ] SHIELDED overlay is rendered in bright cyan
- [ ] SHIELDED overlay auto-clears after approximately 0.75 seconds (no keypress needed)
- [ ] After SHIELDED clears, SPEC meter reflects the +15% bonus (braceSpecialBonus from GameConfig)
- [ ] When enemy attacks and braceWindowActive == false: overlay renders containing "SCORCHED!" (or confirmed word)
- [ ] SCORCHED overlay is rendered in bright red
- [ ] SCORCHED overlay auto-clears after approximately 0.75 seconds
- [ ] When the hit would kill the player (hp <= 0), death screen renders instead of SCORCHED
- [ ] HP bar color updates to reflect new value when SCORCHED overlay clears

### Outcome KPIs
- **Who**: Player who just pressed Brace in a combat encounter
- **Does what**: Immediately understands whether the parry succeeded or failed
- **By how much**: 0 playtest comments of "I don't know if my Brace did anything"
- **Measured by**: Playtest observation — track "mechanic confusion" comments
- **Baseline**: Current playtest — brace outcome invisible; player only sees Special meter change

### Technical Notes
- Requires a new brace outcome signal — see SA-P08 in shared-artifacts-registry.md (IC-03)
- DESIGN wave must decide: `transientOverlay: TransientOverlay?` in GameState vs. new NarrativeEvent cases
- Overlay mechanism must auto-clear by frame count (e.g., 23 frames) without player input
- Priority: resolve IC-03 before implementation begins
- Both overlay words are flagged as developer suggestions — confirm before implementation

---

## US-P07: Dash Feedback Overlay

### Problem
Ember (player) presses 1 (Dash) and the dungeon view shows a new position. But the Dash itself
is invisible — there is no moment of "I just did that powerful thing." They find it hard to tell
the difference between walking and dashing from a visual standpoint.

### Who
- Player | In combat encounter | Just pressed 1 (Dash) with at least 1 charge

### Solution
When Dash resolves (GameState.recentDash == true), a brief auto-clearing overlay renders over
the dungeon or combat view: "SWOOSH!" with a one-line dragon-vocabulary sub-line.
Auto-clears after ~0.75s (23 frames) with no player input required.

Note: "SWOOSH!" is a suggestion for developer review. See vocabulary_additions in
`journey-game-polish.yaml` for alternatives (SURGE!, BURST!, LUNGE!).

### Domain Examples

#### 1: Dash Through a Guard
Maartene is in combat, presses 1. "SWOOSH!" flashes bold white for 0.75 seconds.
She sees "Wings snap. You tear through the guard." below it. The dungeon resumes.
She feels the verb. She knows she dashed.

#### 2: Dash While Exploring (Corridor)
Alex dashes through a guard in the corridor on Floor 2. The overlay fires.
She now recognizes the action as distinct from walking — even though the view just shifted.

#### 3: Cannot Dash With 0 Charges
Carlos has 0 Dash charges. He presses 1. Nothing happens — existing rule blocks the dash.
No SWOOSH overlay fires. No confusion.

### UAT Scenarios (BDD)

See `journey-game-polish.feature` — Scenarios: "Dash shows SWOOSH feedback overlay",
"Dash overlay clears and dash charge is decremented",
"Dash overlay does not appear when Dash has no charges"

### Acceptance Criteria
- [ ] When GameState.recentDash == true: overlay renders containing "SWOOSH!" (or confirmed word)
- [ ] Overlay includes a sub-line in dragon vocabulary ("Wings snap. You tear through.")
- [ ] Overlay renders in bold white
- [ ] Overlay auto-clears after approximately 0.75 seconds (no keypress needed)
- [ ] After overlay clears, Dash charge count in status bar is one less than before the dash
- [ ] When dashCharges == 0, no Dash overlay fires (dash was not executed)

### Outcome KPIs
- **Who**: Player who just executed a Dash in any context
- **Does what**: Immediately recognizes the Dash as a distinct, powerful action
- **By how much**: 0 playtest comments of "did I dash or just move?"
- **Measured by**: Playtest observation — track navigation confusion
- **Baseline**: Current: recentDash flag sets Thoughts flavor text only (not prominent enough)

### Technical Notes
- `GameState.recentDash` already exists and is set by `RulesEngine` on successful dash
- recentDash is cleared after one tick — overlay must persist for ~23 frames independently
- Same transient overlay mechanism as US-P06 — design once, use for both
- DESIGN wave decision: frame counter owned by GameState (preferred — testable) or Renderer
- Overlay word is flagged as developer suggestion — confirm before implementation
