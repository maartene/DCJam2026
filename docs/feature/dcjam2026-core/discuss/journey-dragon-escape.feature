# Journey: Dragon Escape
# Feature: dcjam2026-core
# Date: 2026-04-02
# Author: Luna (Product Owner — DISCUSS wave)
#
# One Gherkin feature per journey step.
# These are journey-level scenarios, not implementation tests.
# They trace the emotional and mechanical arc from game start to exit.

Feature: Dragon Escape — journey from start to exit patio

  Background:
    Given Ember is a young dragon trapped in the dungeon
    And the hero has already fled
    And the egg is somewhere on one of floors 2 through 4

  # ============================================================
  # STEP 1: Game Start
  # ============================================================

  Scenario: Ember reads her situation at game start
    Given Ember has just started a new game
    When the first-person dungeon view loads
    Then Ember sees her HP bar at full
    And Ember sees DASH charges showing 2
    And Ember sees SPEC charge meter showing empty
    And Ember sees the narrative prompt about the hero and the missing egg

  # ============================================================
  # STEP 2: First Encounter — Dash Teaching Moment
  # ============================================================

  Scenario: Ember uses Dash on the first encounter without being told to
    Given Ember is on Floor 1
    And Ember has 2 Dash charges available
    And Ember's Special charge meter is empty
    When Ember enters a square adjacent to a guard
    Then the encounter action list shows Dash as available
    And the encounter action list shows Special as unavailable
    When Ember selects Dash
    Then Ember passes through the guard's square without stopping
    And Ember advances one step further into the dungeon
    And the combat log reads with dragon vocabulary such as "you surge past the guard"
    And Ember's Dash charge count decreases to 1

  Scenario: Ember cannot use Special on the first encounter
    Given Ember is on Floor 1
    And Ember's Special charge meter is empty
    When Ember enters a square adjacent to an enemy
    Then Special is shown in the action list but is not selectable
    And no tutorial text explains why
    And Dash is shown as the ready option

  # ============================================================
  # STEP 3: Option-Starved Window (intentional)
  # ============================================================

  Scenario: Ember braces when both Dash charges are depleted
    Given Ember has 0 Dash charges remaining
    And the Dash cooldown is counting down
    And Ember's Special charge is below activation threshold
    When Ember enters a square adjacent to an enemy
    Then the action list shows only Brace as available
    When Ember selects Brace
    Then Ember absorbs reduced damage
    And the combat log uses dragon vocabulary such as "you lower your wings"
    And the Dash cooldown countdown remains visible in the status bar

  Scenario: Ember's Dash charges replenish after the cooldown period
    Given Ember has 0 Dash charges
    And the Dash cooldown reaches zero
    Then Ember's Dash charge count increases by 1
    And the Dash indicator in the status bar updates immediately

  # ============================================================
  # STEP 4: Floor Descent
  # ============================================================

  Scenario: Ember descends to the next floor via stairs
    Given Ember is on Floor 1
    And Ember has reached the staircase square
    When Ember steps onto the stairs
    Then the floor counter increments to Floor 2
    And a floor transition message is displayed
    And Ember's position is set to the Floor 2 entry point

  # ============================================================
  # STEP 5: Special Charge Accumulation (Regular Floors)
  # ============================================================

  Scenario: Ember's Special charge meter fills over time on regular floors
    Given Ember is on a regular floor (floors 2 through 4)
    And Ember's Special charge meter started at 0
    When enough time passes
    Then the Special charge meter shows a non-zero value
    And the meter is visible and readable in the status bar

  # ============================================================
  # STEP 6: Milestone Upgrade Choice
  # ============================================================

  Scenario: Ember chooses an upgrade at a milestone
    Given Ember has just cleared a milestone floor
    When the milestone upgrade prompt appears
    Then Ember sees exactly 3 upgrade options drawn from the upgrade pool
    And each option is described with a dragon-appropriate label and a mechanical effect
    When Ember selects one upgrade
    Then the selected upgrade effect is applied to Ember immediately
    And the dungeon view resumes
    And no other upgrade from the same prompt is applied

  Scenario: Ember's Dash cooldown is reduced by a Dash-cooldown upgrade
    Given Ember has selected the Dash cooldown reduction upgrade at a milestone
    Then Ember's Dash cooldown time is shorter for the rest of the run
    And the reduced cooldown is reflected in the status bar

  # ============================================================
  # STEP 7: Egg Discovery — Relief Beat
  # ============================================================

  Scenario: Ember discovers the egg and experiences the named narrative moment
    Given the egg is placed on one of floors 2 through 4
    And Ember has not yet found the egg this run
    When Ember enters the egg room
    Then a full-screen or large-text narrative event fires immediately
    And the event text is distinct from any standard item pickup text
    And the screen holds — Ember must press a key to continue
    And after confirmation, the EGG indicator activates in the status bar
    And the dungeon view resumes with EGG shown as held

  Scenario: The egg cannot appear on Floor 1
    Given a new run is generated
    Then no egg room is placed on Floor 1

  Scenario: The egg cannot appear on Floor 5
    Given a new run is generated
    Then no egg room is placed on Floor 5

  # ============================================================
  # STEP 8: Special Attack — Badass Beat
  # ============================================================

  Scenario: Ember unleashes the Special attack and experiences the power beat
    Given Ember's Special charge meter is full
    And Ember is in an encounter
    When Ember selects Special
    Then a full-screen or ASCII-bordered event interrupts the normal dungeon display
    And the event text uses dragon-specific combat vocabulary such as fire, roar, or breath
    And the enemy is defeated or heavily damaged
    And after the event, Ember's Special charge meter resets to 0
    And the display returns to normal dungeon view

  Scenario: Ember cannot use Special on the very first enemy encounter
    Given Ember has just started a new game
    When Ember reaches the first enemy encounter on Floor 1
    Then Ember's Special charge meter is empty
    And Special is not selectable in the action list

  # ============================================================
  # STEP 9: Boss Encounter
  # ============================================================

  Scenario: Ember cannot Dash through the boss on Floor 5
    Given Ember is on Floor 5
    And Ember has at least 1 Dash charge available
    When Ember enters the boss encounter
    Then Dash is shown as unavailable in the action list
    And a message explains that the guardian cannot be passed
    And Ember must use Brace and Special to defeat the boss

  # ============================================================
  # STEP 10: Exit Patio — Final Relief Beat
  # ============================================================

  Scenario: Ember reaches the exit patio with the egg and experiences earned relief
    Given Ember is on Floor 5
    And Ember is carrying the egg
    When Ember steps onto the exit square
    Then a full-screen narrative event fires with the exit patio description
    And the text is slow and deliberate — not a score flash
    And the text references the egg, the hero, and the journey
    And Ember must press a key to confirm
    And after confirmation, the win state is declared

  Scenario: Ember cannot win by reaching the exit without the egg
    Given Ember is on Floor 5
    And Ember is not carrying the egg
    When Ember steps onto the exit square
    Then the exit is blocked or Ember receives a message indicating the egg must be retrieved first
    And the win state is not declared
