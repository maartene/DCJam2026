Feature: Player navigates a floor that feels hand-designed
  As Rowan, a dungeon-crawl player
  I want each floor to have a distinct layout
  So that I experience spatial variety and a sense of dungeon depth

  Background:
    Given FloorRegistry returns distinct FloorMaps for floors 1 through 5

  # ----- US-HM-04: Minimap dynamic dimensions -----

  Scenario: Floor 1 minimap entry cell renders at the correct screen position
    Given Ember is on floor 1 in dungeon mode
    And   floor 1 has grid height=7 and entry at Position(x:7, y:0)
    When  the minimap renders
    Then  a write occurs at screen row 8 col 68
    And   that write contains the player facing indicator

  Scenario: A floor with height=10 renders its southernmost row lower than height=7
    Given floor 3 has grid height=10 and entry at y=0
    And   Ember is on floor 3 in dungeon mode
    When  the minimap renders
    Then  the entry cell is written at screen row 11 (= 2 + 10 - 1 - 0)
    And   no minimap write occurs above row 2 or below row 16

  Scenario: A 19-wide floor produces no minimap write beyond col 79
    Given floor 2 has grid width=19
    And   Ember is on floor 2 in dungeon mode
    When  the minimap renders
    Then  all minimap writes in rows 2-16 are within cols 61-79
    And   no write occurs at col 80 or beyond

  # ----- US-HM-05: Five distinct floors -----

  Scenario: Each floor from 1 to 5 has at least one passable cell at its entry position
    Given all 5 floors are registered in FloorRegistry
    When  each FloorMap is retrieved
    Then  for each floor the entry position is on a passable cell

  Scenario: Floors 2, 3, and 4 each have exactly one egg room at a passable position
    Given floors 2, 3, and 4 are registered
    When  each FloorMap is retrieved
    Then  each FloorMap.hasEggRoom is true
    And   each eggRoomPosition2D is not nil
    And   each egg room position is on a passable cell

  Scenario: Floor 5 has a boss encounter and exit, no egg room and no staircase
    Given floor 5 is registered as a boss antechamber
    When  FloorRegistry.floor(5, config: .default) is called
    Then  the FloorMap.hasBossEncounter is true
    And   the FloorMap.hasExitSquare is true
    And   the FloorMap.hasEggRoom is false

  Scenario: No two floors share identical grid dimensions and entry position
    Given all 5 floors are registered
    When  each pair of floors is compared
    Then  no two floors have identical width AND identical height AND identical entry position

  Scenario: All floors are within the 19-wide by 15-tall terminal constraint
    Given all 5 floors are registered
    When  each FloorMap is retrieved
    Then  each floor.grid.width is 19 or less
    And   each floor.grid.height is 15 or less

  # ----- Integration: game rules fire at correct positions -----

  Scenario: Egg discovery fires at the egg room position on floor 2
    Given Ember is on floor 2 one step away from the egg room position
    And   Ember has not yet collected the egg
    When  Ember moves onto the egg room position
    Then  the screen mode transitions to narrativeOverlay(.eggDiscovery)

  Scenario: Guard encounter fires at the encounter position on floor 3
    Given Ember is on floor 3 one step away from the encounter position
    When  Ember moves onto the encounter position
    Then  the screen mode transitions to .combat with a non-boss encounter

  Scenario: Boss encounter fires at the boss encounter position on floor 5
    Given Ember is on floor 5 one step away from the boss encounter position
    When  Ember moves onto the boss encounter position
    Then  the screen mode transitions to .combat with a boss encounter

  Scenario: Exit triggers win condition on floor 5 when Ember carries the egg
    Given Ember is on floor 5 one step away from the exit position
    And   Ember has the egg
    When  Ember moves onto the exit position
    Then  the screen mode transitions to narrativeOverlay(.exitPatio)
