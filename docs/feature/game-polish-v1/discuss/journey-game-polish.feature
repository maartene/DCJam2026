# Feature: Game Polish v1 — Ember's Escape
# Author: Luna (Product Owner — DISCUSS wave)
# Date: 2026-04-03
# Persona: Ember (player character and UX actor)
# Journey step: Full session, launch through win

Feature: Game polish — orientation, feedback, and color improvements

  Background:
    Given the game is built and executable on an ANSI-capable terminal
    And the terminal is at least 80 columns × 25 rows

  # ---------------------------------------------------------------------------
  # POLISH-01: Start Screen
  # ---------------------------------------------------------------------------

  Scenario: Player sees start screen on launch before the dungeon
    Given Ember has just launched the Ember's Escape binary
    When the first frame renders
    Then a start screen is displayed instead of the dungeon view
    And the start screen shows the title "Ember's Escape"
    And the start screen shows the subtitle "DCJam 2026"
    And the start screen shows a narrative hook referencing the egg
    And the start screen lists all key bindings: W/S move, A/D turn, 1 Dash, 2 Brace, 3 Special, ESC quit
    And the prompt "[ Press any key to begin ]" is visible
    And Q is not mentioned as a key binding anywhere on the start screen

  Scenario: Player dismisses start screen and enters the dungeon
    Given the start screen is displayed
    When Ember presses any key (e.g., W, Space, Enter)
    Then the dungeon renders at Floor 1
    And the status bar shows full HP in green, 2 Dash charges, and an empty Special meter

  # ---------------------------------------------------------------------------
  # POLISH-02: Remove Q as Quit Key
  # ---------------------------------------------------------------------------

  Scenario: Player presses Q during dungeon navigation — no quit
    Given Ember is navigating the dungeon on Floor 1
    When Ember presses the Q key
    Then the game continues running without interruption
    And the dungeon view is still displayed on the next frame

  Scenario: Player presses ESC to quit — game exits cleanly
    Given Ember is navigating the dungeon
    When Ember presses the ESC key
    Then the game exits
    And the terminal is restored to its original state (cursor visible, raw mode off)

  Scenario: Player presses Q during combat — no quit
    Given Ember is in a combat encounter
    When Ember presses the Q key
    Then the combat screen remains active
    And no game state is changed

  # ---------------------------------------------------------------------------
  # POLISH-03: Egg Pickup Screen — Narrative Revision
  # ---------------------------------------------------------------------------

  Scenario: Egg pickup screen shows spike2-style narrative content
    Given Ember is on a floor that contains the egg room (Floors 2–4)
    And Ember has not yet collected the egg
    When Ember moves onto the egg room square
    Then a full-screen narrative overlay renders
    And the overlay contains an ASCII art egg (5-line .-.  art)
    And the title line contains "My egg" rendered in bright yellow
    And the overlay contains the phrase "Warm. Alive. Still here."
    And a flavour line is present in dimmed style
    And the prompt "[ press any key ]" is visible
    And the overlay does not auto-clear

  Scenario: Egg pickup screen dismisses on keypress and egg status updates
    Given the egg pickup overlay is displayed
    When Ember presses any key
    Then the dungeon view resumes
    And the EGG indicator in the status bar shows the egg symbol (*)
    And the EGG indicator is rendered in bright yellow

  # ---------------------------------------------------------------------------
  # POLISH-04: Win Screen — Narrative Revision
  # ---------------------------------------------------------------------------

  Scenario: Win screen shows narrative-first content matching spike2 exit overlay
    Given Ember has collected the egg
    And Ember has reached the exit square on Floor 5
    When the win state renders
    Then the win screen shows "The sky." in bold bright cyan
    And the win screen shows "Open. Endless. Yours."
    And a starfield ASCII art block is present (asterisks and dots)
    And a narrative line "But you are free." is present
    And the floors cleared count is displayed
    And the HP remaining count is displayed
    And the prompt "[ Press R to play again ]" is visible

  # ---------------------------------------------------------------------------
  # POLISH-05a: HP Bar Color
  # ---------------------------------------------------------------------------

  Scenario: HP bar is green when health is full or above 40%
    Given Ember has 100 HP out of 100 maximum HP
    When the status bar renders
    Then the HP bar fill characters are rendered in green (ANSI 32)

  Scenario: HP bar turns yellow when health drops below 40%
    Given Ember has 35 HP out of 100 maximum HP
    When the status bar renders
    Then the HP bar fill characters are rendered in yellow (ANSI 33)

  Scenario: HP bar turns red when health drops below 20%
    Given Ember has 15 HP out of 100 maximum HP
    When the status bar renders
    Then the HP bar fill characters are rendered in red (ANSI 31)

  Scenario: HP color boundary at exactly 40%
    Given Ember has 40 HP out of 100 maximum HP
    When the status bar renders
    Then the HP bar fill characters are rendered in green (at or above threshold)

  Scenario: HP color boundary at exactly 20%
    Given Ember has 20 HP out of 100 maximum HP
    When the status bar renders
    Then the HP bar fill characters are rendered in yellow (at or above lower threshold)

  # ---------------------------------------------------------------------------
  # POLISH-05b: Cooldown and Charge Color
  # ---------------------------------------------------------------------------

  Scenario: Special meter renders in bold bright cyan when ready
    Given Ember's special charge is at 1.0 (full)
    When the status bar renders
    Then the SPEC label and bar are rendered in bold bright cyan
    And the bar shows all fill characters (no empty segments)

  Scenario: Special meter renders in dim cyan while charging
    Given Ember's special charge is at 0.5 (half)
    When the status bar renders
    Then the SPEC bar is rendered in dim cyan (not bold, not bright)

  Scenario: Dash cooldown timer renders in yellow when active
    Given one Dash charge has been used and is on cooldown
    And the cooldown remaining is 32 seconds
    When the status bar renders
    Then the cooldown value "(cd=32s)" is rendered in yellow

  Scenario: Brace label renders in yellow when on cooldown
    Given Ember used Brace 0.5 seconds ago and the 1.5s cooldown is still active
    When the status bar renders
    Then the "(2)BRACE" label is rendered in yellow

  # ---------------------------------------------------------------------------
  # POLISH-05c: Minimap Color
  # ---------------------------------------------------------------------------

  Scenario: Player position renders in bold bright white on minimap
    Given Ember is at position (7, 3) on Floor 1
    When the minimap panel renders (cols 61–79)
    Then Ember's position indicator (^, >, v, or <) is rendered in bold bright white

  Scenario: Guard position renders in bright red on minimap
    Given a dungeon guard occupies a square visible on the minimap
    When the minimap panel renders
    Then the G character for the guard is rendered in bright red

  Scenario: Egg square renders in bright yellow on minimap before pickup
    Given the egg room is on the current floor
    And Ember has not collected the egg
    When the minimap panel renders
    Then the * character for the egg is rendered in bright yellow

  Scenario: Wall cells render in dark gray on minimap
    Given the floor has wall cells visible in the minimap panel
    When the minimap panel renders
    Then wall characters (#) are rendered in dark gray (ANSI 90)

  Scenario: Staircase renders in bright cyan on minimap
    Given the current floor has a staircase
    When the minimap panel renders
    Then the S character is rendered in bright cyan

  # ---------------------------------------------------------------------------
  # POLISH-06a: Brace Parry Success Overlay
  # ---------------------------------------------------------------------------

  Scenario: Successful parry shows SHIELDED feedback overlay
    Given Ember is in a combat encounter with a dungeon guard
    And Ember pressed Brace and the parry window is active (braceWindowActive == true)
    When the enemy attacks during the parry window
    Then a brief overlay renders containing "SHIELDED!" (or developer-confirmed dragon word)
    And a sub-line confirms the scales turned the blow aside
    And the overlay is rendered in bright cyan
    And the overlay auto-clears after approximately 0.75 seconds (23 frames at 30Hz)
    And no keypress is required to dismiss the overlay

  Scenario: Successful parry overlay clears and Special meter shows bonus charge
    Given the SHIELDED overlay was displayed
    When the overlay auto-clears
    Then the dungeon or combat view is restored
    And the SPEC bar in the status bar reflects the +15% Special bonus

  # ---------------------------------------------------------------------------
  # POLISH-06b: Brace Hit-Taken (Failure) Overlay
  # ---------------------------------------------------------------------------

  Scenario: Unbraced hit shows SCORCHED feedback overlay
    Given Ember is in a combat encounter
    And Ember did not press Brace (braceWindowActive == false)
    When the enemy attacks
    Then a brief overlay renders containing "SCORCHED!" (or developer-confirmed dragon word)
    And a sub-line confirms the hit got through
    And the overlay is rendered in bright red
    And the overlay auto-clears after approximately 0.75 seconds

  Scenario: SCORCHED overlay does not appear when player has already died
    Given the enemy attack reduces Ember's HP to 0 or below
    When the hit resolves
    Then the death screen is shown instead of the SCORCHED overlay

  Scenario: HP bar updates to new color threshold after SCORCHED overlay clears
    Given Ember had 45 HP before the hit
    And the enemy deals 10 damage reducing HP to 35 (below 40%)
    When the SCORCHED overlay clears
    Then the HP bar fill is rendered in yellow

  # ---------------------------------------------------------------------------
  # POLISH-07: Dash Feedback Overlay
  # ---------------------------------------------------------------------------

  Scenario: Dash shows SWOOSH feedback overlay
    Given Ember is in a combat encounter with a dungeon guard
    And Ember has at least 1 Dash charge
    When Ember presses 1 (Dash)
    Then a brief overlay renders containing "SWOOSH!" (or developer-confirmed dragon word)
    And a sub-line describes the dash action in dragon vocabulary
    And the overlay auto-clears after approximately 0.75 seconds
    And no keypress is required to dismiss the overlay

  Scenario: Dash overlay clears and dash charge is decremented
    Given the SWOOSH overlay was displayed
    When the overlay auto-clears
    Then the dungeon view is restored
    And the Dash charge count in the status bar is one less than before

  Scenario: Dash overlay does not appear when Dash has no charges
    Given Ember has 0 Dash charges
    When Ember presses 1 (Dash)
    Then the Dash is not executed (existing rule: cannot Dash with 0 charges)
    And no SWOOSH overlay renders
