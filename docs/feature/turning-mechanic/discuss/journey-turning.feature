Feature: Turning Mechanic
  As Ember navigating the dungeon
  I want to turn left and right in 90-degree increments
  So that I can orient myself and move relative to my facing direction

  Background:
    Given the game is running in dungeon screen mode
    And Ember is on floor 2 with 100 HP
    And Ember's position is 3

  # ---------------------------------------------------------------------------
  # STEP 1: Default facing on floor entry
  # ---------------------------------------------------------------------------

  Scenario: Ember starts a new floor facing North by default
    Given Ember has just entered floor 2
    Then Ember's facing direction is North
    And the minimap player marker shows "○^"
    And the minimap Facing label shows "N"

  # ---------------------------------------------------------------------------
  # STEP 2: Turn left
  # ---------------------------------------------------------------------------

  Scenario: Ember turns left from North to face West
    Given Ember is facing North
    When Ember presses the turn-left key
    Then Ember's facing direction is West
    And the minimap player marker shows "○<"
    And the minimap Facing label shows "W"

  Scenario: Ember turns left from West to face South
    Given Ember is facing West
    When Ember presses the turn-left key
    Then Ember's facing direction is South
    And the minimap player marker shows "○v"
    And the minimap Facing label shows "S"

  Scenario: Ember turns left from South to face East
    Given Ember is facing South
    When Ember presses the turn-left key
    Then Ember's facing direction is East
    And the minimap player marker shows "○>"
    And the minimap Facing label shows "E"

  Scenario: Ember turns left from East to face North
    Given Ember is facing East
    When Ember presses the turn-left key
    Then Ember's facing direction is North
    And the minimap player marker shows "○^"
    And the minimap Facing label shows "N"

  Scenario: Four left turns return Ember to original facing
    Given Ember is facing North
    When Ember presses the turn-left key 4 times
    Then Ember's facing direction is North

  # ---------------------------------------------------------------------------
  # STEP 3: Turn right
  # ---------------------------------------------------------------------------

  Scenario: Ember turns right from North to face East
    Given Ember is facing North
    When Ember presses the turn-right key
    Then Ember's facing direction is East
    And the minimap player marker shows "○>"
    And the minimap Facing label shows "E"

  Scenario: Ember turns right from East to face South
    Given Ember is facing East
    When Ember presses the turn-right key
    Then Ember's facing direction is South
    And the minimap player marker shows "○v"
    And the minimap Facing label shows "S"

  Scenario: Four right turns return Ember to original facing
    Given Ember is facing North
    When Ember presses the turn-right key 4 times
    Then Ember's facing direction is North

  # ---------------------------------------------------------------------------
  # STEP 4: Movement is facing-relative
  # ---------------------------------------------------------------------------

  Scenario: Moving forward while facing North advances position
    Given Ember is facing North at position 3
    When Ember presses the move-forward key
    Then Ember's position is 4

  Scenario: Moving backward while facing North retreats position
    Given Ember is facing North at position 3
    When Ember presses the move-backward key
    Then Ember's position is 2

  Scenario: Moving forward while facing South retreats position
    Given Ember is facing South at position 3
    When Ember presses the move-forward key
    Then Ember's position is 2

  Scenario: Moving backward while facing South advances position
    Given Ember is facing South at position 3
    When Ember presses the move-backward key
    Then Ember's position is 4

  Scenario: Moving forward while facing East advances position
    Given Ember is facing East at position 3
    When Ember presses the move-forward key
    Then Ember's position is 4

  Scenario: Moving forward while facing West retreats position
    Given Ember is facing West at position 3
    When Ember presses the move-forward key
    Then Ember's position is 2

  # ---------------------------------------------------------------------------
  # STEP 5: Minimap always reflects current facing
  # ---------------------------------------------------------------------------

  Scenario: Minimap caret is correct for each cardinal direction
    Given Ember is facing East
    Then the minimap player marker shows "○>"

  Scenario: Minimap updates immediately after a turn
    Given Ember is facing North
    When Ember presses the turn-right key
    Then the minimap player marker shows "○>" on the next rendered frame

  # ---------------------------------------------------------------------------
  # STEP 6: Turning allowed during combat
  # ---------------------------------------------------------------------------

  Scenario: Ember can turn during a combat encounter
    Given Ember is in a combat encounter
    And Ember is facing North
    When Ember presses the turn-right key
    Then Ember's facing direction is East
    And the combat encounter is still active
    And Ember's HP is unchanged

  Scenario: Movement remains locked during combat regardless of facing
    Given Ember is in a combat encounter facing East
    When Ember presses the move-forward key
    Then Ember's position is unchanged
    And a movement-locked state is active

  # ---------------------------------------------------------------------------
  # EDGE: Keyboard bindings — both A/D and Arrow Left/Right work
  # ---------------------------------------------------------------------------

  Scenario: Arrow Left key triggers turn-left
    Given Ember is facing North
    When Ember presses the Arrow Left key
    Then Ember's facing direction is West

  Scenario: Arrow Right key triggers turn-right
    Given Ember is facing North
    When Ember presses the Arrow Right key
    Then Ember's facing direction is East

  # ---------------------------------------------------------------------------
  # EDGE: No resource cost for turning
  # ---------------------------------------------------------------------------

  Scenario: Turning does not consume dash charges
    Given Ember has 2 dash charges
    When Ember presses the turn-left key
    Then Ember has 2 dash charges

  Scenario: Turning does not reduce HP
    Given Ember has 100 HP
    When Ember presses the turn-right key
    Then Ember has 100 HP
