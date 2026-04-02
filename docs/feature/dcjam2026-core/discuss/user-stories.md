<!-- markdownlint-disable MD024 -->
# User Stories — Dragon Escape
**Feature**: dcjam2026-core
**Date**: 2026-04-02
**Author**: Luna (Product Owner — DISCUSS wave)

---

## US-01: Game Start — UI State Legibility

### Problem
Ember (the player controlling the dragon) launches the game with no prior knowledge of its mechanics. The only "tutorial" is the state of the UI. If the status bar does not clearly show that Dash is ready and Special is empty, the organic teaching moment (DEC-10) fails and the player does not understand which action to take on the first encounter.

### Who
- Young dragon, first-time player | Sees the game for the first time | Needs to understand available actions without being told

### Solution
Display a status bar at game start that legibly shows HP at full, Dash charges at 2, Special charge at 0 (empty), and EGG indicator as inactive.

### Domain Examples

#### 1: Happy Path — Ember reads her state at game start
Ember launches the game. The dungeon view appears. The status bar shows: HP [==========] 100%, DASH [2], SPEC [----------] empty, EGG [ ]. Before taking any action, Ember can read that she has 2 Dash charges and no Special charge available.

#### 2: Edge Case — Ember returns after a death and restarts
Ember died on Floor 3. She restarts. The status bar resets fully: Dash back to 2, Special back to 0, EGG indicator cleared, HP back to full. No carry-over from the previous run.

#### 3: Error Boundary — Special meter shows non-zero at start
If the Special charge starts at any value above 0, the organic Dash teaching moment breaks — the player might select Special on the first encounter. This must not happen. The Special meter must always initialize to 0.

### UAT Scenarios (BDD)

#### Scenario: Ember reads her full status at game start
```gherkin
Given Ember has just started a new game
When the dungeon view finishes loading
Then the status bar shows HP at full
And the DASH indicator shows 2 charges
And the SPEC meter shows 0 (empty)
And the EGG indicator shows inactive
```

#### Scenario: Ember sees Special is unavailable before the first encounter
```gherkin
Given Ember is at game start on Floor 1
And the SPEC meter shows 0
When Ember reaches the first enemy encounter
Then Special is shown in the action list but is not selectable
And no tutorial text is displayed explaining why
```

#### Scenario: Status bar resets correctly on restart after death
```gherkin
Given Ember died during a run with SPEC partially charged and EGG indicator active
When Ember selects restart
Then the status bar shows HP at full
And the DASH indicator shows 2
And the SPEC meter shows 0
And the EGG indicator shows inactive
```

### Acceptance Criteria
- [ ] HP bar displays at full on game start
- [ ] DASH indicator shows exactly 2 charges on game start
- [ ] SPEC meter shows 0 (empty) on game start — not partial, not full
- [ ] EGG indicator shows inactive on game start
- [ ] All five status bar elements are visible simultaneously
- [ ] After restart, all five elements reset to initial values

### Outcome KPIs
- **Who**: Players on their first encounter
- **Does what**: Select Dash without reading a tutorial
- **By how much**: 80%+ of first-encounter selections are Dash (not Brace or Special)
- **Measured by**: Playtester observation during jam testing
- **Baseline**: Without this UI, player selection is random or defaults to combat

### Technical Notes
- Depends on GameState initialization: dashCharges=2, specialCharge=0, hasEgg=false
- Status bar is always-visible overlay — must not be hidden during any screen state

---

## US-02: Dash — Pass Through Enemy Square

### Problem
Ember encounters a guard blocking her path. In a standard dungeon crawler, this means stopping to fight. Ember wants to pass through — not because combat is impossible, but because Dash is the primary verb (DEC-01) and stopping to fight is opt-in. If Dash does not work correctly as a pass-through locomotion mechanic, the game's core identity collapses.

### Who
- Dragon with 1+ Dash charges available | Mid-encounter on any floor (except boss) | Wants to advance without engaging

### Solution
Selecting Dash during an encounter passes Ember through the enemy square and advances her 3 squares forward in the dungeon. The encounter ends. Dash charge count decrements by 1.

### Domain Examples

#### 1: Happy Path — Ember Dashes through a guard on Floor 1
Ember has 2 Dash charges. A guard blocks the corridor. Ember selects Dash. The combat log reads: "You surge past the guard. He never lands a blow." Ember advances 3 squares forward. Dash charge count shows 1.

#### 2: Edge Case — Ember Dashes with exactly 1 charge remaining
Ember has 1 Dash charge (the other is on cooldown at 12 seconds remaining). An enemy appears. Ember Dashes. She passes through. Dash shows 0 charges. Cooldown indicator shows two active timers. The status bar is still legible.

#### 3: Error Boundary — Ember tries to Dash with 0 charges
Both Dash charges are on cooldown. Ember encounters an enemy. Dash shows in the action list but is not selectable. Ember is not forced into combat — she can select Brace and wait. The game does not crash or soft-lock.

### UAT Scenarios (BDD)

#### Scenario: Ember passes through a guard using Dash
```gherkin
Given Ember has at least 1 Dash charge available
And Ember is in an encounter with a regular enemy
When Ember selects Dash
Then Ember passes through the enemy's square
And Ember advances 3 squares forward in the dungeon
And the encounter ends
And Ember's Dash charge count decrements by 1
And the combat log shows dragon vocabulary such as "you surge past"
```

#### Scenario: Ember's position advances 3 squares on Dash
```gherkin
Given Ember is at position X in the dungeon
And Ember Dashes through an enemy
When the Dash action completes
Then Ember's position is X + 3 squares in the forward direction
```

#### Scenario: Dash is unavailable when both charges are depleted
```gherkin
Given Ember has 0 Dash charges
And both charges are on cooldown
When Ember enters an encounter
Then Dash is shown in the action list
And Dash is not selectable
And Brace is available
```

#### Scenario: Normal movement is locked in an encounter
```gherkin
Given Ember is adjacent to an enemy (in an active encounter)
When Ember attempts to take a normal step forward
Then the step action is not available
And only Dash, Brace, and Special are offered as actions
```

### Acceptance Criteria
- [ ] Dash action passes Ember through enemy square without triggering a blocking exchange
- [ ] Ember's position advances exactly 3 squares forward after a successful Dash
- [ ] Dash charge count decrements by 1 on use
- [ ] Combat log uses dragon vocabulary for Dash text
- [ ] Dash is unavailable (shown but not selectable) when charge count is 0
- [ ] Normal movement is locked when adjacent to an enemy
- [ ] The encounter ends after a successful Dash

### Outcome KPIs
- **Who**: Players in encounters on any regular floor
- **Does what**: Select Dash as their primary encounter response
- **By how much**: Dash is used in >60% of non-boss encounters across a typical run
- **Measured by**: Playtester observation and post-run notes
- **Baseline**: Standard dungeon crawlers: 0% evasion; all encounters are combat

### Technical Notes
- Depends on SA-01 (dashCharges), SA-02 (dashCooldown), SA-11 (bossFlag — Dash blocked only for boss)
- Advance-3-squares requires grid pathfinding: if 3 squares forward is blocked by a wall, behavior must be specified in DESIGN wave (advance to wall? stop at wall?)
- Pending feasibility spike: can the grid support pass-through as a distinct movement mode? (DEC-06 spike 1)

---

## US-03: Special Attack — Power Beat

### Problem
Ember has been managing her Dash charges and bracing through difficult windows. She has saved the Special charge. When she fires it, the moment must feel earned and spectacular — "badass" (DEC-03). A generic combat line or a score bump is not enough. The dragon's full power must be expressed in this moment.

### Who
- Dragon with Special charge at full | In an encounter | Wants the power fantasy moment

### Solution
When Special is activated, a full-screen or ASCII-bordered event fires with dramatic dragon-vocabulary text. The enemy is defeated or heavily damaged. The Special charge meter resets to 0.

### Domain Examples

#### 1: Happy Path — Ember fires Special against a regular guard
Ember's SPEC meter is full. An armored guard blocks her path. Ember selects Special. The screen clears to a full display: "YOU OPEN YOUR THROAT. Fire pours from you like a river reversing. The guard does not scream. He simply ends." Guard is defeated. SPEC meter resets to 0.

#### 2: Edge Case — Ember fires Special against the boss
During the boss fight on Floor 5, Ember's SPEC charges. She fires it. The full-screen event fires with boss-specific text. The boss takes significant damage. The power beat is the same mechanic — the narrative text is distinct from the regular-guard version.

#### 3: Error Boundary — Ember attempts Special when charge is not quite full
SPEC meter is at 90%. Ember selects Special. It is shown in the action list but is not selectable. No error message — it is simply greyed out, same as when charge is 0. The charge meter continues to fill.

### UAT Scenarios (BDD)

#### Scenario: Ember activates Special with a full charge meter
```gherkin
Given Ember's Special charge meter is full
And Ember is in an encounter
When Ember selects Special
Then a full-screen or ASCII-bordered visual event interrupts the dungeon display
And the event text uses dragon-specific vocabulary (fire, breath, roar, fang, or claw)
And the enemy is defeated or heavily damaged
And after the event, Ember's Special charge meter shows 0
And the dungeon view returns to normal
```

#### Scenario: Special fires dramatically different from normal Brace
```gherkin
Given Ember uses Brace in one encounter
And Ember uses Special in another encounter
When both events have completed
Then the Special visual event is visually distinct from the Brace text
And the Special event occupies a full screen area or an ASCII-bordered frame
And the Brace event shows as normal combat text in the log
```

#### Scenario: Special cannot be used at game start
```gherkin
Given Ember has just started a new game
When Ember reaches the first enemy encounter
Then Ember's Special charge is 0
And Special is shown in the action list but is not selectable
```

### Acceptance Criteria
- [ ] Full-screen or ASCII-bordered visual event fires on Special activation
- [ ] Special event text uses dragon vocabulary (at minimum one of: fire, breath, roar, fang, claw)
- [ ] Special event is visually distinct from Brace or standard combat text
- [ ] Enemy is defeated or takes significant damage after Special
- [ ] Special charge meter resets to 0 after use
- [ ] Special is not selectable when charge is below full
- [ ] Special cannot be activated on the first enemy encounter (charge starts at 0)

### Outcome KPIs
- **Who**: Players who successfully use the Special for the first time
- **Does what**: Describe the moment as "powerful" or "satisfying" in playtester notes
- **By how much**: 100% of playtesters mention the Special attack unprompted in post-session feedback
- **Measured by**: Post-session verbal debrief during jam playtesting
- **Baseline**: Current state: no special attack exists; no power beat moment in genre

### Technical Notes
- Depends on SA-03 (specialCharge), SA-11 (bossFlag for boss-specific text variant)
- Pending feasibility spike: can the TUI layer interrupt dungeon rendering for a full-screen event? (DEC-06 spike 2 and 3)
- Fallback if spike fails: ASCII border + CAPS text on the same screen (still distinct from normal combat)

---

## US-04: Floor Structure and Descent

### Problem
Ember needs to navigate through multiple floors to reach the exit. Without a working floor structure, there is no dungeon to escape. This story is the structural scaffold all other stories depend on.

### Who
- Dragon navigating a grid dungeon | On any floor | Wants to make progress toward the exit

### Solution
A navigable dungeon floor exists for each floor in the range 1 to N (3 minimum, 5 target). Stairs connect floors. Descending increments the floor counter. Each floor type enforces its generation constraints.

### Domain Examples

#### 1: Happy Path — Ember descends from Floor 1 to Floor 2
Ember clears the first corridor of Floor 1. She reaches the staircase. She steps onto it. Floor counter increments to 2. Floor 2 entry text appears: "Floor 2. The air changes." Ember is placed at the Floor 2 entry point.

#### 2: Edge Case — Ember descends on a minimum-viable 3-floor run
The run generates only 3 floors. Floor 1 is the starter. Floor 2 is regular (egg is here or Floor 3). Floor 3 contains the boss and exit. The staircase on Floor 2 leads directly to Floor 3. The run is completable.

#### 3: Error Boundary — Floor count below minimum
The game should never generate fewer than 3 floors. If floor generation produces 0 or 1 floors, the run must not start. A generation error state is shown instead (design detail for DESIGN wave).

### UAT Scenarios (BDD)

#### Scenario: Ember descends via stairs and floor counter increments
```gherkin
Given Ember is on Floor N (1 through 4 on a 5-floor run)
And Ember has reached the staircase square
When Ember steps onto the stairs
Then the floor counter increments to N + 1
And Ember's position is set to the entry point of floor N + 1
And a floor transition message is displayed
```

#### Scenario: Floor 1 has no egg room
```gherkin
Given a new run is generated
When Floor 1 is generated
Then no egg room exists on Floor 1
```

#### Scenario: Floor 5 contains the boss encounter and exit
```gherkin
Given a new run is generated with 5 floors
When Floor 5 is generated
Then Floor 5 contains a boss encounter
And Floor 5 contains the exit patio square
And Floor 5 does not contain an egg room
```

#### Scenario: Exactly one egg room exists in floors 2-4
```gherkin
Given a new run is generated
When floors 2 through 4 are generated
Then exactly one floor in the range 2-4 contains an egg room
And no other floor contains an egg room
```

### Acceptance Criteria
- [ ] Game generates between 3 and 5 floors per run
- [ ] Each floor is navigable (no inescapable dead ends before reaching stairs)
- [ ] Descending stairs increments floor counter and moves player to next floor entry point
- [ ] Floor 1 contains no egg room
- [ ] Exactly one floor in range 2–4 contains an egg room
- [ ] Floor 5 (or the final floor on a 3-floor run) contains the boss and exit
- [ ] Floor 5 contains no egg room

### Outcome KPIs
- **Who**: Developer during jam submission
- **Does what**: Submit a completable run (start to exit) before jam deadline
- **By how much**: 100% — the game must be completable for jam submission
- **Measured by**: Developer playtesting before submission
- **Baseline**: Current state: no game exists

### Technical Notes
- Depends on FloorMap generation (SA-05, SA-08, SA-09)
- Floor structure is the dependency anchor for US-02, US-05, US-07, US-09, US-10
- 3-floor minimum: Floor 3 takes the role of Floor 5 (boss + exit); Floors 2–3 split regular and boss roles

---

## US-05: Brace — Defensive Action in Option-Starved Window

### Problem
Ember has spent both Dash charges. The Special meter is not full. An enemy is adjacent. She cannot advance. She can only absorb the blow and wait. This is an intentional design tension (DISC-01) — the player's options are deliberately narrow. The Brace action must work correctly and communicate through dragon vocabulary that waiting is a dragon thing to do, not a failure state.

### Who
- Dragon with 0 Dash charges and non-full Special | In an active encounter | Must endure until Dash replenishes

### Solution
Brace is always available in an encounter. It reduces incoming damage. It uses dragon vocabulary. The Dash cooldown is visible so the player knows the wait is bounded.

### Domain Examples

#### 1: Happy Path — Ember braces once and Dash replenishes
Both Dash charges depleted. Enemy attacks. Ember selects Brace. "You lower your wings. The blow glances off your scales." Ember loses 8 HP instead of 15. Cooldown shows 22s. Next turn, cooldown hits 0, Dash shows [1]. Ember Dashes through.

#### 2: Edge Case — Ember braces multiple times in a difficult corridor
Ember faces two enemies in sequence. Both Dash charges used. She braces through 4 attacks before Dash replenishes. HP drops to 40%. She survives and Dashes through. The game did not soft-lock — Brace worked for an extended window.

#### 3: Error Boundary — Ember braces while at very low HP
Ember is at 5 HP. She braces. The enemy deals 8 damage. HP drops to 0. Death condition fires. Brace does not prevent death — it reduces damage. The player chose to brace knowing the risk.

### UAT Scenarios (BDD)

#### Scenario: Ember braces and takes reduced damage
```gherkin
Given Ember has 0 Dash charges and Special is not full
And Ember is in an encounter
When Ember selects Brace
Then Ember takes reduced damage (less than the unbraced amount)
And the combat log uses dragon vocabulary such as "you lower your wings" or "your scales absorb"
And the encounter continues (Ember is not forced out)
```

#### Scenario: Brace is always available in an encounter
```gherkin
Given Ember is in any encounter on any floor
Then Brace is shown as a selectable action
And Brace remains selectable regardless of Dash charge count or Special charge level
```

#### Scenario: Dash cooldown is visible during the Brace state
```gherkin
Given Ember has 0 Dash charges
And Ember braces through an enemy attack
When the brace action completes
Then the Dash cooldown remaining time is visible in the status bar
And the cooldown continues to tick down
```

### Acceptance Criteria
- [ ] Brace action is always available in encounters
- [ ] Brace reduces incoming damage to a value less than the unbraced default
- [ ] Brace combat text uses dragon vocabulary (wings, scales, endure)
- [ ] Dash cooldown indicator is visible during the Brace state
- [ ] Brace does not end the encounter — it absorbs one attack and leaves Ember in the encounter
- [ ] Death condition fires correctly if HP reaches 0 after a Brace

### Outcome KPIs
- **Who**: Players experiencing the option-starved window
- **Does what**: Choose Brace intentionally rather than abandon the run
- **By how much**: Players continue the run after the option-starved window in >70% of cases
- **Measured by**: Playtester observation
- **Baseline**: Without Brace, 0-Dash state is a soft-lock

### Technical Notes
- Depends on SA-01 (dashCharges), SA-06 (hp), SA-02 (cooldown display)
- Damage reduction amount is a design detail for DESIGN wave (tuning value)

---

## US-06: Special Charge Meter — Visual Readiness

### Problem
The Special attack is the game's power beat. Players must be able to anticipate when it is coming — the charge meter building toward full is itself part of the experience. If the meter is invisible or unreadable, the power beat loses its anticipation arc.

### Who
- Dragon navigating any floor | Watching the Special charge build | Needs to know when the power moment is approaching

### Solution
The Special charge meter is always visible in the status bar. It starts at 0. It fills over time. When full, it shows clearly as ready. The action list in encounters reflects the live charge state.

### Domain Examples

#### 1: Happy Path — Ember watches Special charge from 0 to full over two floors
At game start, SPEC shows [----------] (empty). After Floor 1 (2 minutes in), SPEC shows [====------] (40%). At the start of Floor 3, SPEC shows [==========] (full). Ember sees "READY" or the bar is filled. She knows the moment is near.

#### 2: Edge Case — Ember uses Special and the meter resets
Ember fires Special. The full-screen event plays. After it, SPEC shows [----------] (0 again). The meter begins refilling from 0. The cycle is clear.

#### 3: Error Boundary — Special charge rate is too fast
If Special charges fast enough to be full by the first encounter, the organic Dash teaching fails (DEC-10). The charge rate must be calibrated so this cannot happen. If a configuration error makes the rate too fast, the test for US-01 Scenario 3 will catch it.

### UAT Scenarios (BDD)

#### Scenario: Special charge meter is visible and starts at 0
```gherkin
Given Ember has just started a new game
Then the SPEC meter in the status bar shows 0 (empty)
And the SPEC meter is visible alongside the other status bar elements
```

#### Scenario: Special charge meter increases over time
```gherkin
Given Ember is on any floor
And the SPEC meter is below full
When enough time passes without Ember using Special
Then the SPEC meter shows a higher value than before
```

#### Scenario: Special charge meter shows full when ready
```gherkin
Given the SPEC meter has reached its maximum value
Then the SPEC meter display clearly indicates readiness (full bar or "READY" label)
And Special becomes selectable in encounter action lists
```

#### Scenario: Special charge meter resets to 0 after use
```gherkin
Given Ember has used the Special attack
When the Special event animation completes
Then the SPEC meter shows 0 (empty)
And Special is no longer selectable in encounter action lists
```

### Acceptance Criteria
- [ ] SPEC meter is visible in status bar from game start
- [ ] SPEC meter shows 0 at game start
- [ ] SPEC meter increases incrementally over time during play
- [ ] SPEC meter shows a distinct "full / ready" state when maximum value is reached
- [ ] SPEC meter resets to 0 after Special is used
- [ ] Special is not selectable in encounter action list when SPEC is below full
- [ ] Special is selectable in encounter action list when SPEC is full

### Outcome KPIs
- **Who**: Players on their first complete run
- **Does what**: Recognize when Special is about to become available without reading documentation
- **By how much**: 80%+ of playtesters can correctly identify "Special is almost ready" when shown a status bar at 80% charge
- **Measured by**: Playtester observation
- **Baseline**: Without visible meter, timing of Special is opaque

### Technical Notes
- Depends on SA-03 (specialCharge)
- Charge rate is a tuning parameter — calibration must guarantee charge < full at first encounter (see US-01, US-03)

---

## US-07: Egg Discovery — Relief Beat

### Problem
Ember has been navigating a hostile dungeon where her parent was killed and her egg was stolen. When she finds the egg, this is not a routine item pickup — it is the moment the mission becomes real (DEC-03). Without a dedicated narrative beat, the egg is just an item. The emotional weight of the moment is lost.

### Who
- Dragon who has navigated 1-3 regular floors | Enters the egg room | Needs the personal moment of recognition

### Solution
When Ember enters the egg room on Floors 2–4, a full-screen narrative event fires. The screen holds. The player must press to continue. The EGG indicator activates in the status bar afterward.

### Domain Examples

#### 1: Happy Path — Ember finds the egg on Floor 2
Ember rounds a corner. The screen transitions to the egg discovery event: "There. In a hollow carved from the dungeon wall — warm, pulse-lit, unmistakable. Your egg. You take it. It is heavier than you expected. It is not too late." Player presses any key. EGG indicator activates. Dungeon resumes.

#### 2: Edge Case — Ember finds the egg on Floor 4 (late in the run)
The egg is on Floor 4 this run. Ember has been on edge — the egg was not on Floor 2 or 3. Finding it late makes the relief sharper. The same narrative event fires. The moment is not diminished by appearing late.

#### 3: Error Boundary — Ember cannot reach the exit without the egg
Ember skips Floor 3 (impossible in grid design, but: even if egg room is behind a path she did not take). Win condition requires hasEgg == true. The exit prompt will block her. She must return for the egg.

### UAT Scenarios (BDD)

#### Scenario: Entering the egg room fires the narrative event
```gherkin
Given Ember is on a floor in the range 2 through 4
And Ember has not yet found the egg this run
When Ember enters the egg room square
Then a full-screen or large-text narrative event fires immediately
And the dungeon view is replaced by the narrative event display
And the event text is written in dragon narrative voice
And the event text is distinct from any standard room description or item pickup text
```

#### Scenario: Egg discovery requires player acknowledgment
```gherkin
Given the egg discovery narrative event is displayed
Then the screen holds — the dungeon does not resume automatically
When Ember presses any key
Then the narrative event closes
And the dungeon view resumes
And the EGG indicator activates in the status bar
```

#### Scenario: Egg room does not appear on Floor 1 or Floor 5
```gherkin
Given a new run is generated
Then Floor 1 contains no egg room
And Floor 5 contains no egg room
```

### Acceptance Criteria
- [ ] Entering the egg room triggers a full-screen or large-text narrative event
- [ ] Narrative event text is distinct from standard item pickup or room description text
- [ ] Screen holds until player presses a key
- [ ] EGG indicator activates in status bar after confirmation
- [ ] Egg room is not on Floor 1
- [ ] Egg room is not on Floor 5
- [ ] Egg room appears on exactly one floor in range 2–4 per run
- [ ] Win condition requires hasEgg == true

### Outcome KPIs
- **Who**: Players who reach the egg room
- **Does what**: Pause, read the full egg discovery text before pressing to continue
- **By how much**: 100% of playtesters read the text before pressing (no skipping the event)
- **Measured by**: Playtester observation — did they pause and read?
- **Baseline**: Without this: egg pickup is a one-line log entry; players miss the emotional beat

### Technical Notes
- Depends on SA-04 (hasEgg), SA-08 (eggRoomId), SA-05 (currentFloor)
- Pending feasibility spike: can TUI layer interrupt dungeon rendering for a full-screen event? (DEC-06 spike 2)
- Fallback: large bordered text box occupying most of the screen, not full-screen interrupt

---

## US-08: Milestone Upgrade Choice

### Problem
The jam requires at least one way to affect character stats (DEC-12 jam rule). Milestone upgrades are the developer's selected mechanism (DISC-02). The upgrade choice must feel like a dragon-appropriate power decision, not a generic RPG level-up screen.

### Who
- Dragon who has just cleared a milestone floor | Encounters the upgrade prompt | Wants to strengthen the escape

### Solution
At defined progression milestones, an upgrade prompt presents exactly 3 choices from a pool of 6–8 upgrades. The player picks one. It applies immediately. The dungeon resumes.

### Domain Examples

#### 1: Happy Path — Ember chooses Dash cooldown reduction
After clearing Floor 2, the milestone prompt appears: "Your body knows what it needs." Choices: (1) Keen lunges — Dash cooldown -5s, (2) Iron scales — Max HP +10, (3) Deep breath — Special charges 20% faster. Ember selects (1). From this point forward, Dash charges in ~40s instead of ~45s. The effect is reflected in the cooldown display.

#### 2: Edge Case — Ember reaches the second milestone
After Floor 3, a second upgrade prompt appears. The pool now excludes "Keen lunges" (already taken). Three different options appear. Ember selects "Second wind — gain 1 extra Dash charge cap." Dash now has a cap of 3. The status bar shows DASH [3].

#### 3: Error Boundary — Ember receives duplicate options
The same upgrade cannot appear twice in one prompt. If the pool is small (6 entries) and the player has already taken 3 upgrades, the remaining 3 are shown. The draw must not repeat already-chosen upgrades.

### UAT Scenarios (BDD)

#### Scenario: Upgrade prompt fires after clearing a milestone floor
```gherkin
Given Ember has just cleared a milestone floor
When the floor transition occurs
Then a milestone upgrade prompt appears before the next floor begins
And the prompt displays exactly 3 upgrade options
And each option shows its name and mechanical effect
```

#### Scenario: Ember selects an upgrade and it applies immediately
```gherkin
Given the milestone upgrade prompt is showing 3 options
When Ember selects one option
Then the selected upgrade effect applies to Ember immediately
And the dungeon view resumes
And the upgrade effect is visible in the status bar or gameplay behavior
```

#### Scenario: Dash cooldown upgrade reduces cooldown duration
```gherkin
Given Ember selected the Dash cooldown reduction upgrade at a milestone
Then when Ember uses Dash, the subsequent cooldown duration is shorter
Than it was before the upgrade was applied
```

#### Scenario: Selected upgrade does not appear again in future milestone prompts
```gherkin
Given Ember has already selected upgrade X
When a subsequent milestone prompt appears
Then upgrade X is not shown in the prompt options
```

### Acceptance Criteria
- [ ] Upgrade prompt fires at defined milestone floors
- [ ] Prompt displays exactly 3 options drawn from pool of 6–8
- [ ] Player selects one option; it applies immediately
- [ ] Upgrade effect persists for the rest of the run
- [ ] Upgrade names use dragon-appropriate language
- [ ] Dash cooldown reduction upgrade reduces actual cooldown time
- [ ] Dash charge cap increase upgrade raises the cap (visible in status bar)
- [ ] Already-selected upgrades are not offered again in the same run
- [ ] Jam stat-modification rule is satisfied by this mechanism

### Outcome KPIs
- **Who**: Developer (jam submission)
- **Does what**: Ship a game that satisfies the jam stat-modification rule
- **By how much**: 100% — jam rule compliance is binary
- **Measured by**: Jam rule checklist review before submission
- **Baseline**: Without this: jam rule violation = potential disqualification

### Technical Notes
- Depends on SA-10 (UpgradePool), SA-07 (activeUpgrades), SA-02 (dashCooldown effect)
- Pool design (6-8 entries with specific effects) is a design detail for DESIGN wave
- At minimum, pool must contain: Dash cooldown reduction, Dash charge cap increase (DEC-08)

---

## US-09: Boss Encounter — Dash Blocked

### Problem
On Floor 5, Ember must face the dungeon's guardian. The boss cannot be Dashed through — this is the one encounter that forces the player to fight (DEC-11, DISC-01). The boss must be telegraphed as exceptional so the player understands this is a rule exception, not a new rule.

### Who
- Dragon on Floor 5 | Encounters the boss guardian | Must use Brace and Special to win

### Solution
The boss encounter blocks the Dash action. The action list shows Dash as unavailable with a brief explanation. The player uses Brace and Special. After the boss is defeated, the path to the exit opens.

### Domain Examples

#### 1: Happy Path — Ember fires Special to defeat the boss
Ember enters the boss room on Floor 5. Dash shows as blocked: "The guardian holds the corridor. You cannot pass." Ember uses Special (fully charged after traversing 4 floors). The full-screen Special event fires. Boss takes heavy damage. Ember braces through the remaining attacks. Boss is defeated. Exit becomes reachable.

#### 2: Edge Case — Ember enters the boss encounter with 0 Special charge
Ember used Special on Floor 4. She faces the boss with only Brace. This is harder but not impossible — Brace + enough patience defeats the boss. The game does not soft-lock.

#### 3: Error Boundary — Ember tries to Dash through the boss
Ember selects Dash during the boss encounter. The game shows Dash as unavailable. No damage occurs. Ember's Dash charge is not consumed (attempt does not consume a charge). The encounter continues.

### UAT Scenarios (BDD)

#### Scenario: Dash is blocked during the boss encounter
```gherkin
Given Ember is on Floor 5
And Ember has entered the boss encounter
When Ember attempts to select Dash
Then Dash is shown in the action list but is not selectable
And a message is displayed explaining that the guardian cannot be passed
And Ember's Dash charge count is not decremented
```

#### Scenario: Boss can be defeated with Brace and Special
```gherkin
Given Ember is in the boss encounter
And Ember has not yet defeated the boss
When Ember uses Brace and Special repeatedly
Then eventually the boss is defeated
And the path to the exit square is unblocked
```

#### Scenario: Dash blocking applies only to the boss encounter
```gherkin
Given Ember is in any regular encounter (not boss)
Then Dash is available and selectable
And the boss encounter flag is false
```

### Acceptance Criteria
- [ ] Dash is shown but not selectable during the boss encounter
- [ ] A message explains the boss cannot be Dashed through
- [ ] Dash charge count is not decremented on a blocked Dash attempt
- [ ] Boss can be defeated using Brace and Special
- [ ] After boss is defeated, exit square becomes reachable
- [ ] Dash blocking applies only to the boss encounter (SA-11 flag-based, not floor-based)
- [ ] Boss is on Floor 5 (or the final floor on a 3-floor run)

### Outcome KPIs
- **Who**: Players reaching Floor 5
- **Does what**: Engage with Brace + Special in boss encounter (not abandon the run)
- **By how much**: 70%+ of players who reach Floor 5 complete the boss encounter
- **Measured by**: Playtester observation
- **Baseline**: Without a boss, the climax of the run is an empty corridor

### Technical Notes
- Depends on SA-11 (BossEncounterFlag), SA-01 (dashCharges), SA-03 (specialCharge)
- Boss HP and damage values are design details for DESIGN wave
- Boss defeat condition (HP-based or fixed-hit-count) is a design detail for DESIGN wave

---

## US-10: Exit Patio — Final Relief Beat

### Problem
Ember has found her egg and defeated the boss. She reaches the exit. This is the moment the game was built for. Standard dungeon crawlers show a score screen or a "level complete" banner. That is not what this game is. The exit must feel like earned relief — exhale, not triumph (DEC-03). If the exit is generic, the emotional arc collapses.

### Who
- Dragon carrying the egg | On Floor 5 | Steps onto the exit square — the journey is ending

### Solution
When Ember reaches the exit square with the egg, a full-screen narrative event fires. Pacing is slow. The player must press to continue. Win state is declared afterward.

### Domain Examples

#### 1: Happy Path — Ember exits with the egg after defeating the boss
Ember steps onto the exit patio. The screen shifts: "Light. Not the dungeon's cold lamps. Real light. Outside. You hold the egg against your chest. It is warm. You are warm. The hero made a mess of things. You cleaned it up." Player presses any key. "You escaped." Win state declared.

#### 2: Edge Case — Ember reaches the exit before finding the egg
Ember somehow reaches Floor 5 without picking up the egg (took a path that bypassed it — this should be impossible in a correct floor layout, but if the player somehow arrives at exit without egg). The exit is blocked: "You are not done here. The egg." Win state not declared. Player must return.

#### 3: Error Boundary — Win state triggers without egg somehow
If hasEgg is not correctly checked and the win state fires without the egg, this is a test failure. The acceptance criteria explicitly require hasEgg == true at win condition check.

### UAT Scenarios (BDD)

#### Scenario: Stepping onto exit with egg triggers final narrative event
```gherkin
Given Ember is on Floor 5
And Ember is carrying the egg (hasEgg == true)
When Ember steps onto the exit square
Then a full-screen narrative event fires with the exit patio description
And the event text is slow and deliberate
And the event references the egg, the hero, and the journey
And Ember must press a key to continue
```

#### Scenario: Win state is declared after exit event confirmation
```gherkin
Given the exit patio narrative event is displayed
When Ember presses any key to confirm
Then the win state is declared
And the game shows a final win screen
```

#### Scenario: Exit is blocked without the egg
```gherkin
Given Ember is on Floor 5
And Ember is not carrying the egg (hasEgg == false)
When Ember steps onto the exit square
Then the win state is not declared
And a message indicates the egg must be retrieved
```

### Acceptance Criteria
- [ ] Stepping onto exit square with egg triggers full-screen narrative event
- [ ] Event text references egg, hero, and journey (dragon-vocabulary voice)
- [ ] Screen holds until player presses a key
- [ ] Win state declared only when hasEgg == true AND player is at exit square
- [ ] Win state is not declared when hasEgg == false, regardless of player position
- [ ] Exit event is visually and narratively distinct from the egg discovery event (DEC-03)

### Outcome KPIs
- **Who**: Players who complete a full run
- **Does what**: Read the full exit text and experience the relief beat (pause, not skip)
- **By how much**: 100% of playtesters describe the ending as "relief" or "earned" in post-session notes
- **Measured by**: Post-session debrief — one open question: "How did the ending feel?"
- **Baseline**: Without this: "You win!" flash. No emotional resonance.

### Technical Notes
- Depends on SA-04 (hasEgg), SA-09 (exitPosition), SA-05 (currentFloor == 5)
- Win condition must check BOTH SA-04 and SA-09 simultaneously (critical integration checkpoint)
- Pending feasibility spike: full-screen TUI event (DEC-06 spike 2)

---

## US-11: Death Condition

### Problem
Ember's HP can reach 0. The jam requires a death/fail condition (DEC-12). When the dragon falls, the game must acknowledge it — in dragon vocabulary — and offer a restart. A crash or a silent reset is not acceptable.

### Who
- Dragon whose HP has dropped to 0 | At any point in the run | Sees the run end

### Solution
When HP reaches 0, a death screen fires with dragon-vocabulary text. The player is offered a restart.

### Domain Examples

#### 1: Happy Path — Ember dies on Floor 3 from consecutive attacks
Ember braces through 5 attacks in an option-starved window. HP drops to 0. Screen: "Your fire goes cold. The dungeon keeps its dead." Restart prompt appears. Ember chooses restart. Game resets to game start state.

#### 2: Edge Case — Ember dies on Floor 1 before the first Dash
HP starts at full. On the very first encounter, Ember selects Brace repeatedly (not Dash). Eventually HP drops to 0. Death fires. The restart returns her to Floor 1 with full HP and empty Special.

#### 3: Error Boundary — Death fires at exactly 0 HP, not below
If HP goes from 3 to -2 in one attack, the death condition fires at the point where HP <= 0. The display does not show negative HP. The death check fires on the damage application.

### UAT Scenarios (BDD)

#### Scenario: Death fires when HP reaches 0
```gherkin
Given Ember has HP greater than 0
When Ember takes damage that reduces HP to 0 or below
Then the death condition fires
And a death screen is displayed with dragon-vocabulary text
```

#### Scenario: Restart resets to initial game state
```gherkin
Given the death screen is showing
When Ember selects the restart option
Then the game resets to game start state
And HP is at full
And DASH shows 2 charges
And SPEC meter shows 0
And EGG indicator shows inactive
And currentFloor is 1
```

#### Scenario: Death is distinct from the win state
```gherkin
Given Ember has died
Then the death screen does not show a win message
And the death screen offers restart, not "continue"
```

### Acceptance Criteria
- [ ] Death condition fires when GameState.hp <= 0
- [ ] Death screen displays with dragon-vocabulary text (not generic "game over")
- [ ] Restart option is presented after death
- [ ] Selecting restart resets all game state to initial values
- [ ] Death screen is visually distinct from win state
- [ ] HP display does not show negative values

### Outcome KPIs
- **Who**: Developer (jam submission)
- **Does what**: Ship a game with a working death/fail condition
- **By how much**: 100% — jam rule compliance is binary
- **Measured by**: Jam rule checklist before submission
- **Baseline**: Without death: jam rule violation

### Technical Notes
- Depends on SA-06 (hp), SA-01, SA-03, SA-04, SA-05 (all reset on restart)
- Death check should fire immediately on damage application, not at end of turn
