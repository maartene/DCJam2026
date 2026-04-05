# NOTES

## TODO
- [ ] Egg and Exit visual are not centered
- [ ] Discuss softlock: try and leave without the egg. Bad ending?

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
- [X] Dash moves 2 squares ahead. 3 brings you too close to the stairs in one turn. Thats confusing.
- [X] Egg should remove from (mini)map after picking it up.
- [X] When reaching the patio, the night sky is not visible. Fix: use the one from the narrative spike (spike2-narrative-overlay.swift)
- [X] Bug: dash always move you in the north direction, should be in the facing direction
