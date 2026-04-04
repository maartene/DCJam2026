Feature: Gameplay Fixes and Polish

  Background:
    Given Ember is playing "Ember's Escape"
    And the dungeon has 5 floors
    And the boss is triggered by the SA-11 (hasBossEncounter) flag on the final floor

  # ---------------------------------------------------------------------------
  # FIX-1: Guard Removal After Defeat
  # ---------------------------------------------------------------------------

  Scenario: Guard disappears from minimap after being defeated
    Given Ember is on floor 2 in the dungeon view
    And the minimap shows "G" at the guard's position (7,2)
    When Ember defeats the guard (guard HP reaches 0)
    And the screen returns to dungeon mode
    Then the minimap shows "." at position (7,2)
    And no guard symbol "G" appears on that cell

  Scenario: Walking into a cleared guard cell does not trigger combat
    Given Ember has already defeated the guard on floor 2
    And Ember is standing at position (7,1) facing north
    When Ember moves forward into position (7,2)
    Then the screen stays in dungeon mode
    And no combat encounter is started

  Scenario: Guard re-trigger does not occur via Dash exit path
    Given Ember is in combat with the guard at (7,2)
    And Ember's special attack reduces guard HP to 0
    When the guard is defeated and the screen returns to dungeon mode
    And Ember later walks forward into position (7,2)
    Then no combat encounter is started
    And the encounter cell at (7,2) is treated as passable corridor

  Scenario: Cleared guard state resets on floor change
    Given Ember has defeated the guard on floor 2
    And Ember ascends the staircase to floor 3
    When Ember returns to floor 2 (if applicable) or a new run begins
    Then the guard on floor 3 is present and can trigger combat normally
    And no cleared-state bleeds between floors

  Scenario: Boss encounter on final floor is not affected by guard-clear logic
    Given Ember is on floor 5 (the final floor)
    And the boss encounter is at position (7,3) with hasBossEncounter=true
    When Ember has not yet fought the boss
    Then the minimap shows "B" at (7,3)
    And stepping onto (7,3) triggers boss combat

  # ---------------------------------------------------------------------------
  # FIX-2: Boss Art and Name Correction
  # ---------------------------------------------------------------------------

  Scenario: Boss combat screen shows "HEAD WARDEN" not "DRAGON WARDEN"
    Given Ember enters the boss encounter on the final floor
    When the combat screen renders
    Then the enemy name displayed is "HEAD WARDEN"
    And the ASCII art depicts a large armoured human figure
    And the ASCII art contains no cat ears, whiskers, or feline features

  Scenario: Boss thought text uses human-antagonist narrative
    Given Ember enters the boss encounter on the final floor
    When the combat screen renders the Thoughts region
    Then Ember's thought text conveys confronting the human warden who ordered the theft
    And the text uses dragon vocabulary consistent with DEC-04
    And the text does not reference "Dragon Warden"

  Scenario: Minimap symbol and colour for boss are unchanged
    Given Ember is on the final floor in dungeon mode
    When the minimap renders
    Then the boss position shows "B" in bold bright red
    And the legend entry for "B" reads "Boss"

  Scenario: Regular guard label is unaffected by boss name change
    Given Ember is on a non-final floor in combat with a regular guard
    When the combat screen renders
    Then the enemy name displayed is "DUNGEON GUARD"
    And the Thoughts region references a guard, not a warden

  # ---------------------------------------------------------------------------
  # FIX-3: Minimap Legend
  # ---------------------------------------------------------------------------

  Scenario: Legend appears in the right panel during dungeon navigation
    Given Ember is navigating the dungeon on any floor
    When the screen renders in dungeon mode
    Then a legend is visible in rows 9-16 of the right panel (cols 61-79)
    And the legend shows seven entries: You, Guard, Boss, Egg, Stairs, Entry, Exit
    And each legend entry uses the same colour as the corresponding minimap symbol

  Scenario: Legend symbol colours match minimap symbol colours
    Given the minimap legend is rendered
    Then the "^" entry in the legend uses bold bright white (same as the player indicator)
    And the "G" entry uses bright red (same as guard symbol)
    And the "B" entry uses bold bright red (same as boss symbol)
    And the "*" entry uses bright yellow (same as egg room symbol)
    And the "S" entry uses bright cyan (same as staircase symbol)

  Scenario: Legend does not overflow into the status bar separator
    Given the legend renders in rows 9-16 of the right panel
    When the last legend entry is written at row 16
    Then row 17 (the status bar separator) is not written to by the legend renderer

  Scenario: Legend is absent during combat, narrative overlay, and upgrade screens
    Given Ember is in a combat encounter
    When the screen renders in combat mode
    Then the right panel shows no minimap and no legend
    And the legend is not rendered outside of dungeon mode
