# US-EWE-01: Ember's Refusal at the Exit Without the Egg

## Problem

Ember is a young dragon who has fought through five dungeon floors to reclaim her stolen egg and escape. She finds it devastating to arrive at the exit patio — cold air, open stars, freedom visible — and be met with absolute silence. The game currently does nothing when she steps onto the exit square without the egg. There is no feedback, no forward path, and no way to understand what went wrong. The player is softlocked with no information and no agency.

## Who

- Dragon on a desperate rescue mission | Floor 5, exit square reached | Egg not yet collected (hasEgg = false) | Driven by urgency, not exploration curiosity

## Solution

Add a `NarrativeEvent.exitWithoutEgg` case. When Ember steps onto the exit square without the egg, a full-screen narrative overlay fires. Ember, in her own voice, refuses to leave. The player confirms ("turn back") and is returned to dungeon mode standing on the exit square — free to backtrack and find the egg. The existing win path (hasEgg = true → .exitPatio → .winState) is untouched.

## Domain Examples

### 1: Ember reaches exit on first attempt — egg is on floor 3 (missed)

Ember fought through floors 1-5 without visiting floor 3's egg room. She steps onto the 'X' square. The `.exitWithoutEgg` overlay fires. Text: "THE PATIO LIES OPEN / Cold wind. Stars. / But the egg. / Ember's claws lock on the stone." She reads it, presses Space. She is back in the dungeon, standing on the exit square. She turns south, descends through floor 4 back to floor 3, finds the egg room, collects the egg. She climbs back to floor 5, steps onto the exit again. This time `.exitPatio` fires. She wins.

### 2: Ember reaches exit, dismisses overlay, re-steps on exit (still no egg)

After confirming the overlay, Ember steps backward off the exit square and then forward again — she forgot she needed to descend. She is still in `.dungeon` mode, `hasEgg` is still `false`. The overlay fires again. Identical content. She confirms again. No edge case, no inconsistency.

### 3: Ember reaches exit with egg — win path unaffected (regression)

On a different run, Ember collected the egg on floor 2. She reaches floor 5's exit square. `hasEgg = true`. The `.exitPatio` overlay fires (existing behaviour). She confirms. `.winState`. Nothing about the `.exitWithoutEgg` branch interferes.

## UAT Scenarios (BDD)

### Scenario: Ember steps onto exit without egg — overlay fires

```gherkin
Given Ember is on floor 5 in dungeon mode
And state.hasEgg is false
And Ember's position is one cell north of the exit square
When Ember moves forward onto the exit square
Then screenMode is .narrativeOverlay(event: .exitWithoutEgg)
And playerPosition equals exitPosition2D
```

### Scenario: Overlay displays Ember's refusal in dragon vocabulary

```gherkin
Given screenMode is .narrativeOverlay(event: .exitWithoutEgg)
When the Renderer renders the current state
Then the screen contains "THE PATIO LIES OPEN"
And the screen contains the word "egg"
And the controls hint reads "Space / Enter: turn back"
And the screen does not contain "collect", "item", "you need", or "tutorial"
```

### Scenario: EmberThoughts reflects the egg crisis during overlay

```gherkin
Given screenMode is .narrativeOverlay(event: .exitWithoutEgg)
When EmberThoughts.thought(for: state) is called
Then the returned string mentions both the egg and the sky (or freedom)
And the string is in first-person Ember voice
```

### Scenario: Confirming overlay returns to dungeon on exit square

```gherkin
Given screenMode is .narrativeOverlay(event: .exitWithoutEgg)
And playerPosition is the exit square
When the player sends GameCommand.confirmOverlay
Then screenMode is .dungeon
And playerPosition remains equal to exitPosition2D
And movement commands are processed normally
```

### Scenario: Re-stepping exit without egg re-triggers overlay

```gherkin
Given Ember confirmed the overlay and is in dungeon mode on the exit square
And state.hasEgg is false
When Ember moves off the exit square and back onto it
Then screenMode becomes .narrativeOverlay(event: .exitWithoutEgg) again
```

### Scenario: Win path unchanged — regression guard

```gherkin
Given state.hasEgg is true
And Ember moves onto the exit square on floor 5
Then screenMode is .narrativeOverlay(event: .exitPatio)
And NOT .narrativeOverlay(event: .exitWithoutEgg)
And confirming the overlay transitions to .winState
```

## Acceptance Criteria

- [ ] `RulesEngine.applyMove` checks `hasEgg` before triggering any overlay at exit square: false → `.exitWithoutEgg`, true → `.exitPatio`
- [ ] `NarrativeEvent` enum has `.exitWithoutEgg` case; all switch sites on `NarrativeEvent` are exhaustive (compiler-enforced)
- [ ] `Renderer.renderNarrativeOverlay` handles `.exitWithoutEgg` with overlay text and "Space / Enter: turn back" controls hint
- [ ] `EmberThoughts.narrativeThought` returns an egg-and-sky-referencing first-person thought for `.exitWithoutEgg`
- [ ] `RulesEngine.applyConfirmOverlay` handles `.exitWithoutEgg` → `.dungeon` (player remains on exit square)
- [ ] Re-stepping exit without egg (after overlay dismissed) re-triggers the overlay
- [ ] Existing `.exitPatio` win path produces `.winState` when `hasEgg = true` — no regression
- [ ] No tutorial text in overlay content — mechanical rule implied by Ember's refusal, not stated explicitly

## Outcome KPIs

- **Who**: Players who reach floor 5's exit square during a run where `hasEgg = false`
- **Does what**: Receive contextual feedback and resume movement without restarting
- **By how much**: 100% of such players (0 softlocked states in test runs)
- **Measured by**: Manual playtesting — reach exit without egg, verify overlay fires and movement resumes
- **Baseline**: Currently 0% — all such players are softlocked

## Technical Notes

- **NarrativeEvent enum** — add `.exitWithoutEgg` case. Swift enum exhaustiveness enforces all switch sites: `RulesEngine.applyConfirmOverlay`, `Renderer.renderNarrativeOverlay`, `EmberThoughts.narrativeThought`. All three must be updated in the same commit.
- **RulesEngine.applyMove** — the existing guard `if state.hasEgg { → .exitPatio }` becomes: `if state.hasEgg { → .exitPatio } else { → .exitWithoutEgg }`. The current fall-through (silent no-op) is replaced.
- **No new ScreenMode case needed** — `.narrativeOverlay` is reused. No architecture change.
- **Confirm handler** — `.exitWithoutEgg` confirm must return `.dungeon` (not `.winState`). Confirm for `.exitPatio` returns `.winState` (unchanged).
- **Player position** — player stays on exit square after confirming. No teleport, no floor change.
- **Overlay text constraint** — no direct statement of the rule ("you need the egg"). Ember's refusal implies it. Consistent with the "no tutorial text" policy.
- **Test file** — new test file `ExitWithoutEggTests.swift` covering all 6 UAT scenarios.
