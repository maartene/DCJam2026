Feature: Session lifecycle — isolation and teardown
  # Covers AC-6 (session isolation) and AC-7 (clean teardown)
  # Driving port: ws://localhost:3000/game

  Background:
    Given the bridge server is running on localhost port 3000
    And the DCJam2026 binary is available on PATH

  # AC-6
  Scenario: Two concurrent sessions are fully isolated
    Given I open WebSocket connection A to "ws://localhost:3000/game"
    And I open WebSocket connection B to "ws://localhost:3000/game"
    When both connections receive initial ANSI output
    Then connection A and connection B receive data independently
    And the server has exactly 2 DCJam2026 processes running
    When I close connection A
    Then connection B continues to receive data
    And the server has exactly 1 DCJam2026 process running

  # AC-7
  Scenario: Game process exits cleanly within 2 seconds of tab close
    Given I open a WebSocket connection
    And a DCJam2026 process is running with known PID
    When I close the WebSocket connection
    Then within 2 seconds the process with that PID is no longer running
    And no zombie DCJam2026 processes remain

  # AC-7 (stress variant)
  Scenario: No zombie processes after 5 sequential sessions
    When I run 5 sequential sessions (connect, wait for output, close)
    Then after all sessions are closed, zero DCJam2026 processes are running
    And a new WebSocket connection can be opened immediately
