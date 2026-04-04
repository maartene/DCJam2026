# NOTES

## TODO
- [ ] BUG, Major: After defeating guard, he does not leave
- [ ] the boss should be a "bigger warden", not a cat. We're cleaning up after the human's mess, so the boss should be a bad a$$ human
- [ ] polish: legend for minimap (what do the symbols mean?)

## In progress
- [ ] Web build???

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


## Raspberry PI Runbook
### Prep steps
1. [X] Install Ubuntu (22.04 or 24.04 LTS ARM64) — fresh install as planned
2. [X] Install Swift 6.3 — follow swift.org instructions for Ubuntu ARM64
3. [X] Install Node.js 20 — via NodeSource or nvm
4. [X] Install Docker — for the final deployment phase (step 03-01)
5. [ ] Install cloudflared — Cloudflare Tunnel client

Smoke test after setup:
- [X] swift --version   # should show 6.3
- [X] node --version    # should show v20.x
- [X] docker --version
- [X] The native Swift build on the RPi takes under a minute, so once the code is
done you just git pull && swift build -c release and you're ready to run.
Docker comes later in step 03-01.

