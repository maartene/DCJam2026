Feature: Terminal size guard
  # Covers AC-5 (terminal too small warning)
  # Driving port: ws://localhost:3000/game — first message from client carries terminal dimensions

  Background:
    Given the bridge server is running on localhost port 3000
    And the DCJam2026 binary is available on PATH

  Scenario: Server warns when terminal is too narrow
    When I open a WebSocket connection reporting dimensions 79 cols × 25 rows
    Then I receive a text message containing "too small"
    And no DCJam2026 process is spawned

  Scenario: Server warns when terminal is too short
    When I open a WebSocket connection reporting dimensions 80 cols × 24 rows
    Then I receive a text message containing "too small"
    And no DCJam2026 process is spawned

  Scenario: Server accepts minimum valid dimensions
    When I open a WebSocket connection reporting dimensions 80 cols × 25 rows
    Then a DCJam2026 process is spawned
    And I receive ANSI output (no warning message)

  Scenario: Server accepts larger than minimum dimensions
    When I open a WebSocket connection reporting dimensions 120 cols × 40 rows
    Then a DCJam2026 process is spawned
    And I receive ANSI output (no warning message)
