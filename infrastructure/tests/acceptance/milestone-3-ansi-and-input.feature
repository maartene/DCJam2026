Feature: ANSI output integrity and keyboard input
  # Covers AC-2, AC-3, AC-4 (partial — byte-level only; visual rendering is @manual)
  # Driving port: ws://localhost:3000/game

  Background:
    Given the bridge server is running on localhost port 3000
    And the DCJam2026 binary is available on PATH
    And I have an open WebSocket connection with 80×25 dimensions

  # AC-2, AC-3 (byte-level)
  Scenario: W key byte reaches game and produces a response
    Given I have received the initial ANSI output (start screen)
    When I send the byte for key "Enter" (0x0D) to start the game
    And I wait for the dungeon view ANSI frame
    When I send the byte for key "w" (0x77)
    Then I receive a new ANSI frame within 500 milliseconds

  Scenario: All primary game keys produce ANSI responses
    Given I have received the dungeon view frame
    When I send each of the following keys in sequence with 100ms gaps:
      | key   | byte |
      | w     | 0x77 |
      | a     | 0x61 |
      | s     | 0x73 |
      | d     | 0x64 |
    Then each key produces a new ANSI frame response

  # AC-4 (byte-level — ANSI structure check, not visual rendering)
  Scenario: Game output contains valid ANSI escape sequences
    Given I have received the initial ANSI output
    Then the received bytes contain ESC character (0x1B)
    And the received bytes contain CSI sequences (0x1B 0x5B)
    And the received bytes do not contain the null byte 0x00 in text positions

  # AC-4 (visual rendering — must be verified manually in browser)
  @manual
  Scenario: xterm.js renders box-drawing characters without corruption
    Given the game is running in a browser with xterm.js
    When the dungeon view is displayed
    Then box-drawing characters (┌ ─ │ ┐ └ ┘) are visually correct
    And 256-colour ANSI codes produce correct colours
    And no ghost cursor is visible during rendering

  @manual
  Scenario: Start screen loads in browser within timing targets
    Given the bridge server is running
    When a judge opens the URL in Chrome, Firefox, or Safari
    Then the page loads within 3 seconds
    And the game start screen is visible within 2 seconds of WebSocket connection
    And no download or install prompt appears
