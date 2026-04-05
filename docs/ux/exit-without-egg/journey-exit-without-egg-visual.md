# Journey Visual: Ember Reaches the Exit Without the Egg

## Personas

**Ember** — a young dragon on a desperate, single-shot mission. She is not a "user". She is an animal in a building that stole her child. Every moment without the egg is a wound. The egg is not a collectible; it is the reason she is alive.

**The Player** — a jam player, likely in a 10-20 minute session. They may have forgotten whether they picked up the egg. They may have explored in the wrong order. They arrive at the exit and expect *something* to happen.

---

## Journey Flow: Softlock Scenario (Current State — Broken)

```
[Floor 1-3: Descent]      [Floor 4: Egg Room]       [Floor 5: Exit Patio]
       |                         |                           |
  Ember fights              Ember could visit            Ember steps onto
  through guards            egg room — or skip it        exit square 'X'
       |                         |                           |
  Feels: urgent            Feels: discovered              Feels: ???
  focused                  or confused                    
       |                         |                           |
  Sees: dungeon grid        Sees: eggDiscovery          Sees: NOTHING
  status bar                narrative overlay            No overlay
                            OR plain floor tile          No feedback
                                                         No way forward
                                                              |
                                                         SOFTLOCK
                                                    Player is stuck on
                                                    exit square with
                                                    no feedback and
                                                    no clear action
```

Emotional arc (broken): Urgent → Hopeful → Confused → **Frustrated/Abandoned**

The player has no idea if this is a bug or a feature. The game has taught them (via NarrativeOverlay) that important things trigger overlays. Silence here reads as a crash.

---

## Journey Flow: Proposed Fix — Feedback + Backtrack (Target State)

```
[Floor 1-4: Descent]      [Floor 4: Egg Room MISSED]  [Floor 5: Exit Patio]
       |                         |                           |
  Ember navigates           Player does NOT visit        Player steps onto
  guards & encounters       egg room (hasEgg=false)      exit square 'X'
       |                                                      |
                                                         NarrativeOverlay fires:
                                                         .exitWithoutEgg event
                                                              |
                                                         Ember REFUSES to leave
                                                         (in dragon vocabulary)
                                                              |
                                                         Overlay dismissed:
                                                         player returns to
                                                         .dungeon mode ON the
                                                         exit square
                                                              |
                                                    Player can now backtrack
                                                    freely (movement works as
                                                    normal from exit square)
                                                              |
                                                    Player finds egg on floor 4
                                                    (or 2, 3 — wherever it is)
                                                              |
                                                    Player returns to exit
                                                    with hasEgg=true
                                                              |
                                                    .exitPatio overlay fires
                                                         (win condition)
```

Emotional arc (fixed): Urgent → Near-victory → **Crushing realisation** → Determined → Triumphant

The emotional dip at "Ember refuses" is intentional and appropriate. This IS a crisis moment. Ember has come this far and cannot leave without her egg. The player should feel that weight — but never feel lost about what to do next.

---

## TUI Mockup: exitWithoutEgg Narrative Overlay

```
+------------------------------------------------------------------------------+
|                                                                              |
|                                                                              |
|                                                                              |
|                                                                              |
|                        THE PATIO LIES OPEN                                  |
|                                                                              |
|              Cold wind. Stars. Freedom, just one wingbeat away.             |
|                                                                              |
|              But the egg.                                                    |
|                                                                              |
|              Ember's claws lock on the stone. Her wings half-open           |
|              and then fold back. She cannot leave it here. She will         |
|              not leave it here.                                              |
|                                                                              |
|              The dungeon waits behind her.                                  |
|                                                                              |
|                                                                              |
|                         [ Space / Enter: turn back ]                        |
|                                                                              |
+------------------------------------------------------------------------------+
| HP: ■■■■■■□□    EGG: --    DASH: ◆◆    BRACE: ready    SPEC: ████░         |
+----------------------[ controls: Space / Enter: turn back ]------------------+
|--Thoughts-------------------------------------------------------------------+
| I can see the sky. But the egg is still in there.                           |
| I will not leave without it.                                                 |
+------------------------------------------------------------------------------+
```

### Design Notes

- Vocabulary is dragon-first: "wingbeat", "claws", "scales" — not "exit" or "leave".
- Ember REFUSES — this is her choice, not the system blocking her. Agency matters for tone.
- Confirms with "turn back" — not "ok" or "continue". The language matches the act.
- EGG status bar shows `--` (no egg) — the mini-status bar is the only explicit "you don't have the egg" signal. The overlay does not say "you need the egg". Ember's voice implies it.
- No tutorial text. The player infers the rule from Ember's refusal.

---

## TUI Mockup: After Overlay Dismissed — Back in Dungeon

```
+------------------------------------------------------------------------------+
|                         [dungeon view — floor 5]                            |
|                         [Ember is AT the exit square, facing south]         |
|                                                                              |
|              [minimap shows exit patio position, no egg marker]             |
|                                                                              |
+------------------------------------------------------------------------------+
| HP: ■■■■■■□□    EGG: --    DASH: ◆◆    BRACE: ready    SPEC: ████░         |
+--[ W/S: move  A/D: turn  1: dash  2: brace  3: special  Q: quit ]----------+
|--Thoughts-------------------------------------------------------------------+
| My egg is still out there. I came too far to stop now.                      |
+------------------------------------------------------------------------------+
```

### Key Point

After the overlay, the player is in `.dungeon` mode, standing on the exit square. Normal movement keys work — they can walk backward (south, in the floor 5 layout) and retrace their path. There is no lock, no countdown, no penalty. Just the dungeon.

---

## Error Paths

| Error Path | What Happens | Player Experience |
|---|---|---|
| Player steps on exit, hasEgg=false | .exitWithoutEgg overlay fires | Ember refuses — player is redirected |
| Player dismisses overlay and steps back onto exit (still no egg) | Overlay fires again | Consistent — Ember always refuses |
| Player backtracks but egg room was on a floor they cannot re-enter | Cannot happen — all floors reachable via backtracking (no one-way gates pre-exit) | N/A |
| Player has egg and steps on exit | .exitPatio overlay fires (existing win path) | Unchanged — existing flow |

---

## Emotional Arc: Target State

| Journey Step | Ember's Emotional State | Player's Emotional State |
|---|---|---|
| Floor 1-4 descent | Determined, wary | Engaged, learning mechanics |
| Missing the egg room | Unaware — no signal until exit | Possibly unaware too |
| Stepping onto exit square (no egg) | Halted — desperate | Surprised, then realising |
| Reading overlay | Aching — Ember's refusal resonates | Empathy + understanding of the rule |
| Backtracking into dungeon | Resolved — she knows what to do | Clear goal: find the egg |
| Finding the egg | Fierce joy | Relief + renewed urgency |
| Returning to exit with egg | Triumphant | Satisfaction — the journey meant something |

The emotional dip (overlay moment) is not a punishment. It is the story's climax. The player's backtrack is the hero's return.
