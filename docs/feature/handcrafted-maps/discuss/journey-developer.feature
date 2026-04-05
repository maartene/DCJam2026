Feature: Developer authors a handcrafted floor
  As Maartene, the solo developer
  I want to express floor layouts as static Swift data
  So that I can create 5 distinct floors without touching generation logic

  Background:
    Given the FloorDefinition struct exists in GameDomain
    And FloorRegistry exists in GameDomain

  # ----- US-HM-01: FloorDefinition -----

  Scenario: FloorDefinition holds correct dimensions for floor 1
    Given Maartene creates a FloorDefinition with width=15 and height=7
    And   the grid is an L-shaped 15x7 Bool array
    When  the FloorDefinition is instantiated
    Then  floorDef.width equals 15
    And   floorDef.height equals 7

  Scenario: FloorDefinition grid is row-major — cell at (x=7, y=0) is passable
    Given Maartene creates a FloorDefinition where cells[0][7] is true (passable)
    When  the FloorDefinition is instantiated
    Then  floorDef.grid[0][7] equals true
    And   cells at x=0 y=0 equal false (wall)

  Scenario: FloorDefinition for a wider floor compiles without changes elsewhere
    Given Maartene creates a FloorDefinition with width=19 and height=10
    When  "swift build" runs
    Then  compilation succeeds with no errors

  Scenario: FloorDefinition for floor 5 has exit and boss, no egg
    Given Maartene creates a FloorDefinition with exitPosition=(6,7)
    And   bossEncounterPosition=(6,4)
    And   eggRoomPosition is nil
    When  the FloorDefinition is instantiated
    Then  floorDef.exitPosition equals Position(x:6, y:7)
    And   floorDef.bossEncounterPosition equals Position(x:6, y:4)
    And   floorDef.eggRoomPosition is nil

  # ----- US-HM-02: FloorRegistry -----

  Scenario: FloorRegistry.floor(1) returns the same grid as FloorGenerator.generate(1)
    Given FloorRegistry is registered with the floor 1 L-shape definition
    When  FloorRegistry.floor(1, config: .default) is called
    Then  the returned FloorMap has width=15 and height=7
    And   entry is at Position(x:7, y:0)
    And   staircase is at Position(x:7, y:6)
    And   hasEggRoom is false
    And   hasBossEncounter is false
    And   all cells match FloorGenerator.generate(1) cell-by-cell

  Scenario: FloorRegistry.floor(2) returns a FloorMap with an egg room
    Given FloorRegistry is registered with a floor 2 definition that has an egg room
    When  FloorRegistry.floor(2, config: .default) is called
    Then  the returned FloorMap.hasEggRoom is true
    And   eggRoomPosition2D is not nil
    And   the egg room position is on a passable cell

  Scenario: FloorRegistry.floor(5) returns a FloorMap with boss, exit, no egg
    Given FloorRegistry is registered with a floor 5 boss antechamber definition
    When  FloorRegistry.floor(5, config: .default) is called
    Then  the returned FloorMap.hasBossEncounter is true
    And   the returned FloorMap.hasExitSquare is true
    And   the returned FloorMap.hasEggRoom is false

  Scenario: swift test passes after replacing FloorGenerator call sites
    Given all FloorGenerator.generate call sites in RulesEngine and Renderer
          are replaced with FloorRegistry.floor
    When  "swift test" runs
    Then  all tests pass with zero failures

  # ----- US-HM-03: Floor label in top border -----

  Scenario: Floor label appears in top border row 1 in dungeon mode
    Given Ember is on floor 3 in dungeon screen mode
    When  the screen renders
    Then  row 1 cols 61-79 contain the text "Floor 3/5"
    And   row 2 cols 61-79 do not contain the text "Floor"

  Scenario: Floor label is absent from top border in combat mode
    Given Ember is in combat mode on floor 2
    When  the screen renders
    Then  row 1 cols 61-79 do not contain the text "Floor"

  Scenario: Floor label updates when floor number changes
    Given Ember advances from floor 2 to floor 3
    When  the dungeon screen renders on floor 3
    Then  row 1 right panel contains "Floor 3/5"
    And   row 1 right panel does not contain "Floor 2/5"
