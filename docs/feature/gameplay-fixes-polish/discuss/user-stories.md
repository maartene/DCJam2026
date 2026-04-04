<!-- markdownlint-disable MD024 -->
# User Stories — Gameplay Fixes and Polish

---

## US-GPF-01: Guard Cleared After Defeat

### Problem

Ember (the player) defeats a dungeon guard in combat, returns to dungeon navigation,
and immediately sees the guard symbol still present on the minimap. Walking back
into that cell triggers a fresh combat encounter — the guard has reset with full HP.
The player finds it game-breaking to re-fight cleared enemies, and confusing that
the minimap provides false information about dungeon state.

### Who

- Ember's player: a jam judge or player on their first run through floors 1-4
- Context: navigating a cleared corridor after a successful fight
- Motivation: explore freely after overcoming an obstacle

### Solution

When a guard's HP reaches 0 (by any means: Dash, Special, or sustained damage),
record the encounter cell as cleared in the game state. Cleared cells do not
trigger combat on re-entry and render as passable corridor on the minimap.

### Domain Examples

#### 1: Standard defeat via Brace-and-wait
Kai fights the guard at (7,2) on floor 2. After three enemy attacks (two braced,
one landed), the guard's HP reaches 0. Kai returns to the dungeon view. Walking
forward into (7,2) shows no combat screen — Kai passes through freely.

#### 2: Instant kill via Special
Sakura enters the boss fight at (7,3) on floor 5. She has a full Special charge.
She fires immediately — 60 damage reduces the boss HP from 120 to 60. She
continues fighting. Eventually the boss falls. She is returned to the dungeon view.
The "B" symbol is gone from (7,3) on the minimap.

#### 3: Defeat via Dash
Tomás enters the guard encounter at (7,2) on floor 3. He uses Dash immediately —
the guard takes no hit but Tomás escapes past the guard (Dash exits the encounter
and advances position by 3 squares). The encounter is NOT marked as cleared because
the guard was not defeated — only bypassed. The "G" symbol remains on the minimap.
If Tomás returns to (7,2) from the other side, combat triggers again.

### UAT Scenarios (BDD)

#### Scenario: Cleared guard cell shows corridor on minimap
```
Given Kai is on floor 2 in dungeon mode
And the minimap shows "G" at position (7,2)
When Kai defeats the guard (enemy HP reaches 0)
And the screen returns to dungeon mode
Then the minimap shows "." at position (7,2)
And the "G" symbol is no longer visible on the minimap
```

#### Scenario: Walking into a cleared cell does not trigger combat
```
Given Kai has defeated the guard at (7,2) on floor 2
And Kai is at position (7,1) facing north
When Kai moves forward
Then the game remains in dungeon mode
And Kai's position is (7,2)
And no combat encounter begins
```

#### Scenario: Dash bypasses the guard but does not clear the cell
```
Given Tomás is in combat with the guard at (7,2) on floor 3
And Tomás has at least 1 Dash charge
When Tomás uses Dash
Then the game returns to dungeon mode
And the minimap still shows "G" at position (7,2)
And Tomás's position has advanced past the guard cell
```

#### Scenario: Guard-cleared state resets on floor change
```
Given Kai has cleared the guard on floor 2
And Kai ascends the staircase to floor 3
When the game generates floor 3
Then the guard on floor 3 is present and combat triggers normally at its position
And cleared state from floor 2 does not affect floor 3
```

#### Scenario: Boss cleared after defeat removes "B" symbol
```
Given Sakura is on floor 5 (final floor)
And the minimap shows "B" at position (7,3)
When Sakura defeats the boss (boss HP reaches 0)
And the screen returns to dungeon mode
Then the minimap shows "." at position (7,3)
```

### Acceptance Criteria

- [ ] Enemy HP reaching 0 marks the encounter cell as cleared in game state
- [ ] A cleared cell renders as "." on the minimap (not "G" or "B")
- [ ] Walking into a cleared cell does not enter combat mode
- [ ] Dash (escaping without kill) does NOT clear the encounter cell
- [ ] Cleared state is per-floor and resets when the current floor increments
- [ ] Both regular guard (floor 1-4) and boss (floor 5, SA-11 flag) follow the same clear logic

### Outcome KPIs

- **Who**: any player who completes a combat encounter
- **Does what**: proceeds through a cleared corridor without re-entering combat
- **By how much**: 0 instances of re-triggered combat on a cleared cell
- **Measured by**: manual playtest — defeat guard, walk back through cell, observe no combat
- **Baseline**: currently 100% of re-visits trigger combat (bug)

### Technical Notes

- `GameState` needs a new field to track cleared encounter positions for the
  current floor. DESIGN wave owns the implementation choice (e.g. `Set<Position>`,
  optional position flag, or a boolean on EncounterModel).
- `FloorMap` must remain immutable (struct + value semantics per ADR-002).
- The clearing event must be triggered in `RulesEngine` at the point where
  `encounter.enemyHP <= 0` causes a `.dungeon` screen-mode transition.
- `minimapChar(at:floor:state:)` in `Renderer` must consult the cleared set
  before returning "G" or "B".
- `applyMove` in `RulesEngine` must check the cleared set before entering combat.
- Dash guard in `applyDash` already returns to `.dungeon` without killing the guard —
  ensure it does NOT set the cleared flag.

### Dependencies

- No external dependencies.
- Blocks: nothing (can be delivered independently).
- Enables: cleaner foundation for any future multi-guard or respawn mechanics.

---

## US-GPF-02: Head Warden Boss — Art, Name, Narrative

### Problem

Ember's player reaches the final floor and enters the boss encounter. The combat
screen labels the enemy "DRAGON WARDEN" and renders ASCII art depicting a cat face
with pointed ears and whiskers. The game's entire premise is that humans stole
Ember's egg — the antagonists are human wardens. The cat art severs narrative
coherence at the climactic moment of the game, confusing jam judges about the
story's meaning.

### Who

- Ember's player: any player who reaches floor 5
- Context: the final, highest-stakes combat encounter
- Motivation: a satisfying climax that pays off the "reclaim the egg from humans" narrative

### Solution

Replace the cat ASCII art with a large armoured human figure. Rename the enemy
"HEAD WARDEN". Update the combat thought text to reflect the personal confrontation
with the human responsible for the theft.

### Domain Examples

#### 1: Judge reaches the boss for the first time
Hiroshi (a DCJam 2026 judge) plays through 4 floors, reads the narrative ("stolen by
humans"), and reaches floor 5. The combat screen opens showing a stern armoured human
figure under the label "HEAD WARDEN". The thought text says something like "The Head
Warden. The one who gave the order." Hiroshi's understanding of the story is confirmed
and the boss feels like a meaningful payoff.

#### 2: Player reads the thought text during combat
During the boss fight, Emre checks the Thoughts region at the bottom of the screen.
The text conveys Ember's anger toward this specific human — not generic wariness.
It uses dragon vocabulary (as per DEC-04) and does not reference "Dragon Warden"
or any feline metaphor.

#### 3: Minimap symbol is unchanged
Fatima is on floor 5 in dungeon mode. She consults the minimap and sees "B" in bold
red at the boss position. The legend (if US-GPF-03 is also shipped) shows "B = Boss".
The minimap symbol is unaffected by the art change.

### UAT Scenarios (BDD)

#### Scenario: Boss combat screen shows HEAD WARDEN label
```
Given a player enters the boss encounter on floor 5
When the combat screen renders
Then the enemy name line shows "HEAD WARDEN"
And the enemy name does not contain "DRAGON WARDEN" or "DRAGON"
```

#### Scenario: Boss ASCII art depicts a human figure
```
Given a player enters the boss encounter on floor 5
When the combat screen renders the ASCII art section
Then the art contains no cat ears (no "/\___/\" ear pattern)
And the art contains no whiskers or feline facial features
And the art reads as an upright armoured human figure
```

#### Scenario: Boss thought text uses human-antagonist framing
```
Given a player enters the boss encounter on floor 5
When the Thoughts region renders
Then the text conveys confrontation with the human who ordered the egg theft
And the text uses dragon vocabulary (consistent with DEC-04)
And the text does not use the phrase "Dragon Warden"
```

#### Scenario: Regular guard encounter is unaffected
```
Given a player is in combat with a regular guard on floor 1-4
When the combat screen renders
Then the enemy name shows "DUNGEON GUARD"
And the guard ASCII art is unchanged
And the Thoughts region references a guard, not a warden
```

#### Scenario: Boss minimap symbol and colour are unchanged
```
Given a player is on floor 5 in dungeon mode
When the minimap renders
Then the boss position shows "B" in bold bright red
And the symbol and colour are identical to before this change
```

### Acceptance Criteria

- [ ] Boss enemy name in combat HUD is "HEAD WARDEN" (not "DRAGON WARDEN")
- [ ] Boss ASCII art contains no feline features and reads as an armoured human
- [ ] Boss combat thought text references a human antagonist, uses dragon vocabulary
- [ ] Regular guard name ("DUNGEON GUARD"), art, and thoughts are unchanged
- [ ] Boss minimap symbol "B" and bold-bright-red colour are unchanged

### Outcome KPIs

- **Who**: any player or judge who reaches floor 5
- **Does what**: understands the boss is the human head warden from the game's narrative
- **By how much**: zero narrative incoherence signals in the boss encounter
- **Measured by**: playtest observation — does the reviewer comment on "the cat boss"?
- **Baseline**: current art causes visible narrative confusion (noted in NOTES.md)

### Technical Notes

- Changes are confined to `Renderer.buildCombatFrame` (art array + enemyName string)
  and `Renderer.combatThoughts` (isBossEncounter branch).
- No domain model changes required. `EncounterModel.isBossEncounter` flag is unchanged.
- The final ASCII art is a design decision owned by the DESIGN wave. This story
  specifies the constraint (human, armoured, no feline features) not the exact art.
- Total change scope: ~15-20 lines in `Renderer.swift`.

### Dependencies

- No external dependencies.
- Independent of US-GPF-01 and US-GPF-03.

---

## US-GPF-03: Minimap Legend

### Problem

Ember's player navigates the dungeon using the minimap in the right panel. The
minimap uses 10 distinct characters with colour coding, but there is no legend.
New players and jam judges cannot tell what "G", "B", "*", "S", "E", or "X" mean
without guessing or accidental discovery. Key tactical information (guard locations,
egg room, exit) may be missed entirely.

### Who

- Ember's player: first-time player or jam judge evaluating the game
- Context: any dungeon floor in dungeon-navigation mode
- Motivation: understanding the minimap well enough to make navigation decisions

### Solution

Render a compact legend in rows 9-16 of the right panel (cols 61-79), directly
below the minimap. Each line shows the minimap symbol (in its minimap colour)
followed by a plain-text label. Seven entries cover all tactically important symbols.

### Domain Examples

#### 1: Judge sees the minimap on floor 1
Hiroshi opens the game, presses a key, and is in the dungeon. He glances at the
right panel. Above row 9 he sees the floor grid. Below row 9 he sees:
`^  You`, `G  Guard`, `B  Boss`, `*  Egg`, `S  Stairs`, `E  Entry`, `X  Exit`.
He immediately understands that the "G" ahead of him is a guard he needs to fight
or dash past.

#### 2: Player on floor 2 with egg room present
Sakura is on floor 2. The minimap shows a bright-yellow "*" on a branch corridor.
The legend confirms: `*  Egg`. She knows to detour to collect her egg before
ascending.

#### 3: Final floor — exit symbol appears
Tomás reaches floor 5 with the egg. He sees "X" in bold cyan on the minimap.
The legend confirms: `X  Exit`. He navigates toward it.

### UAT Scenarios (BDD)

#### Scenario: Legend renders in the right panel during dungeon mode
```
Given a player is in dungeon navigation mode on any floor
When the screen renders
Then rows 9-16 of cols 61-79 contain the minimap legend
And the legend shows exactly 7 entries: You, Guard, Boss, Egg, Stairs, Entry, Exit
```

#### Scenario: Legend symbol colours match minimap symbol colours
```
Given the legend is visible in the right panel
Then the "^" legend entry is rendered in bold bright white
And the "G" legend entry is rendered in bright red
And the "B" legend entry is rendered in bold bright red
And the "*" legend entry is rendered in bright yellow
And the "S" legend entry is rendered in bright cyan
```

#### Scenario: Legend does not corrupt the status bar separator at row 17
```
Given the legend renders 7 entries starting at row 9
When the last entry is written at row 16
Then row 17 (the horizontal separator) is not overwritten by legend content
And the separator renders correctly as "├─...─┤"
```

#### Scenario: Legend is not rendered outside dungeon mode
```
Given a player is in combat mode
When the screen renders
Then no legend content appears in the right panel
And the combat screen occupies the full main view as normal
```

#### Scenario: Legend remains readable when all 7 symbols are present on the floor
```
Given Sakura is on floor 2 (which has entry, staircase, guard, and egg room)
When the minimap and legend both render
Then each legend entry uses the same ANSI colour code as its counterpart on the minimap
And the legend text labels are in plain (uncoloured) terminal white
```

### Acceptance Criteria

- [ ] Legend appears in rows 9-16, cols 61-79 during `.dungeon` screen mode only
- [ ] Legend contains 7 entries: You (^), Guard (G), Boss (B), Egg (*), Stairs (S), Entry (E), Exit (X)
- [ ] Each symbol in the legend uses the same ANSI colour code as on the minimap
- [ ] Legend labels are plain text (no extra colour)
- [ ] Row 17 (status bar separator) is not written to by the legend
- [ ] Legend does not render in combat, narrative overlay, upgrade, death, or win modes

### Outcome KPIs

- **Who**: first-time players and jam judges
- **Does what**: correctly identify at least one minimap symbol on first encounter
- **By how much**: zero "what does this symbol mean?" confusion signals in playtest
- **Measured by**: informal playtest observation — does observer ask about minimap symbols?
- **Baseline**: currently all symbols require inference or experimentation

### Technical Notes

- Changes are confined to `Renderer.renderDungeon` or a new `drawMinimapLegend` helper.
- The legend renders only when `renderMinimap` is called (dungeon mode only).
- Each legend entry: `moveCursor(row: N, col: 61)` + write coloured symbol + plain label.
- ANSI colour codes are already defined in `ANSIColors.swift` — reuse existing constants.
- Total change scope: ~20-30 lines in `Renderer.swift`.

### Dependencies

- No external dependencies.
- Independent of US-GPF-01 and US-GPF-02.
- If US-GPF-01 ships first, the legend's "G" entry remains accurate for un-cleared guards
  and is simply absent (as ".") when the guard cell is cleared — no legend change needed.
