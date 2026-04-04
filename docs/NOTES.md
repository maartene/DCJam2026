# NOTES

## TODO

## In progress

## Done
- [X] Discuss step: polish: 
    Polish wishes:
    - [X] remove `q` as key to exit screen: its too close to WASD keys and very easy to accidentaly click (playtest result)
    - [X] add a start streen, that also includes play instructions like key bindings
    - [X] add a win screen (spike2 contains a nice mockup)
    - [X] add a egg pickup screen (spike2 contains a nice mockup)
    - [X] add more color to the game. for instance, the important things like cooldowns, charge meter / special ready should stand out more. HP bar green with plenty of health, yellow below 40%, red below 20%. Minimap should use color to make landmarks stand out more
    - [X] brace requires feedback when succesful (you now only see the charge meter change, but thats not where your attention is). Maybe use an overlay that says "***Blocked***" (or the dragon equivalent) or "**OUCH**" when you fail to block a hit?
    - [X] an overley when dashing that says something like __ZOOM__ (but a better Dragon word) because its difficult to see otherwise. 
    - [X] an overlay when you use the SPECIAL.
- [X] Discuss: graphics pass: improve dungeon graphics
- [X] Web build???
- [X] BUG, Major: After defeating guard, he does not leave
- [X] the boss should be a "bigger warden", not a cat. We're cleaning up after the human's mess, so the boss should be a bad a$$ human
- [X] polish: legend for minimap (what do the symbols mean?)



## Raspberry PI Runbook
### Prep steps
1. [X] Install Ubuntu (22.04 or 24.04 LTS ARM64) — fresh install as planned
2. [X] Install Swift 6.3 — follow swift.org instructions for Ubuntu ARM64
3. [X] Install Node.js 20 — via NodeSource or nvm
4. [X] Install Docker — for the final deployment phase (step 03-01)
5. [X] Install cloudflared — Cloudflare Tunnel client

Smoke test after setup:
- [X] swift --version   # should show 6.3
- [X] node --version    # should show v20.x
- [X] docker --version
- [X] The native Swift build on the RPi takes under a minute, so once the code is
done you just git pull && swift build -c release and you're ready to run.
Docker comes later in step 03-01.

Step 0 — Verify Swift works natively (do this first)
  cd ~/DCJam2026
  git pull
  swift build -c release
  .build/release/DCJam2026
  You should see the game start screen. If yes, Docker is just packaging.

  ---
  Step 1 — Build and run with Docker
  docker build --platform linux/arm64 -t embers-escape -f infrastructure/deploy/Dockerfile .
  docker compose -f infrastructure/deploy/docker-compose.yml up -d
  curl http://localhost:3000   # should return the HTML page

  ---
  Step 2 — Expose via Cloudflare Tunnel

  Quick (no account needed, URL valid ~24h — fine for judging):
  cloudflared tunnel --url http://localhost:3000
  It prints a *.trycloudflare.com URL — that's your public game URL.

  For a persistent URL tied to your domain, see docs/architecture/zero-download-
  deployment/deployment/deployment-architecture.md for the persistent tunnel
  setup.

  ---
  Step 3 — Smoke test

  Open the tunnel URL in Chrome, Firefox, and Safari. You should see the game in
   the browser, fully playable.

  ---
  To stop:
  docker compose -f infrastructure/deploy/docker-compose.yml down


