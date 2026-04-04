Feature: Infrastructure integration checkpoints
  # Docker smoke test and deployment health checks
  # Covers devops/ci-cd-pipeline.md smoke test + AC-8 (game logic unchanged)

  # AC-8
  Scenario: Swift package tests still pass
    Given the DCJam2026 Swift package is present
    When I run "swift test"
    Then all tests pass with exit code 0

  Scenario: Docker image builds successfully
    Given the deploy/Dockerfile is present
    And the web/ directory contains server.js and index.html
    When I run "docker build --platform linux/arm64 -t embers-escape-test -f deploy/Dockerfile ."
    Then the build exits with code 0
    And the image "embers-escape-test" exists locally

  Scenario: Docker container starts and serves the page
    Given the Docker image "embers-escape-test" exists
    When I run "docker run -d --name bridge-test -p 3001:3000 embers-escape-test"
    And I wait 3 seconds for startup
    Then HTTP GET "http://localhost:3001" returns status 200
    And the response body contains "xterm"
    When I stop and remove the container "bridge-test"
    Then the container is removed cleanly

  @manual
  Scenario: Cloudflare Tunnel exposes the service publicly
    Given the Docker container is running on the Raspberry Pi
    And cloudflared tunnel is running
    When a judge opens the public tunnel URL in a browser
    Then the game start screen is visible
    And the WebSocket connection is established over WSS (TLS)
