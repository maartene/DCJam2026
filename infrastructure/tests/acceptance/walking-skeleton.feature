Feature: Walking Skeleton — end-to-end browser session
  As a DCJam judge
  I want to open a URL and play Ember's Escape in my browser
  So that I can evaluate the game without installing anything

  # Driving port: ws://localhost:3000/game (WebSocket) + http://localhost:3000 (static page)
  # Test environment: server.js running locally with real DCJam2026 binary

  Background:
    Given the bridge server is running on localhost port 3000
    And the DCJam2026 binary is available on PATH

  # WS-1
  Scenario: Static page is served
    When I send HTTP GET to "http://localhost:3000"
    Then the response status is 200
    And the response body contains "xterm"
    And the response body contains "WebSocket"

  # WS-2
  Scenario: WebSocket connection spawns a game process
    When I open a WebSocket connection to "ws://localhost:3000/game"
    Then the connection is established
    And a DCJam2026 process is running on the server

  # WS-3
  Scenario: ANSI output flows from game to browser
    Given I have an open WebSocket connection
    When I wait up to 2 seconds for data
    Then I receive at least one binary WebSocket message
    And the message bytes contain an ANSI escape sequence (ESC character 0x1B)

  # WS-4
  Scenario: Keypress bytes reach the game
    Given I have an open WebSocket connection
    And I have received the start screen (ANSI output present)
    When I send the byte 0x0A (newline / Enter) over the WebSocket
    Then I receive a new ANSI frame within 500 milliseconds

  # WS-5
  Scenario: Closing WebSocket terminates the game process
    Given I have an open WebSocket connection
    And a DCJam2026 process was spawned with known PID
    When I close the WebSocket connection
    Then the DCJam2026 process with that PID is no longer running within 2 seconds
