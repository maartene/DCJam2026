# Player Journey — Enter a Floor That Feels Distinct

**Persona**: Rowan, first-time DCJam player, used to roguelikes, has played ~15 minutes.
**Goal**: Progress through the dungeon and feel that each floor is a different place.
**Emotional arc**: Curious (new floor, what shape is this?) → Oriented (minimap reveals layout) → Engaged (distinct topology requires different navigation) → Rewarded (staircase found, floor cleared)

---

## Journey Flow

```
TRIGGER: Rowan steps onto the staircase and the upgrade prompt appears.
  "Floor 2 of 5. What awaits?"
        |
        v
[1. ENTER NEW FLOOR]
  - Upgrade chosen, screen transitions to .dungeon
  - Ember spawns at entry cell of floor 2
  - First-person view shows a wall ahead (topology-specific)
  - Minimap shows a different shape from floor 1
        |
        v  FEEL: "This doesn't look like floor 1. Something changed."
        |
[2. READ THE MINIMAP]
  - Minimap (top-right, rows 2-8) shows the full floor outline
  - Floor label "Floor 2/5" visible in top border
  - Legend (rows 9-15) still present for symbol reference
  - Distinct shape: longer corridor, room to the east, egg room marker (*)
        |
        v  FEEL: "I can see the shape. There's an egg here — I need to find it."
        |
[3. NAVIGATE THE DISTINCT TOPOLOGY]
  - Different corridor lengths mean different turn counts before landmark
  - A wider floor (up to 19 wide) has longer approaches
  - Player builds spatial model of the floor
        |
        v  FEEL: "Floor 1 was a quick L. This is longer — feels like deeper dungeon."
        |
[4. REACH LANDMARKS]
  - Egg room found and egg collected (floors 2-4)
  - Guard encountered at intended position
  - Staircase reached
        |
        v  FEEL: "Floor cleared. I learned this layout. On to floor 3."
        |
[5. FLOOR 5 — DISTINCT BOSS FLOOR]
  - No egg room. Exit visible on minimap (X).
  - Boss encounter at a different position from regular guards.
  - Short, tense layout — final confrontation feel.
        |
        v  FEEL: "This is different. Smaller, more threatening. Final floor energy."
```

---

## Emotional Annotations

| Step | Dominant Feeling | Risk if missing |
|------|-----------------|-----------------|
| 1 — enter | Curiosity | All floors same shape → boredom by floor 2 |
| 2 — read minimap | Orientation | Player lost without readable map |
| 3 — navigate | Engagement | Long uniform corridors → tedium |
| 4 — landmarks | Reward | Egg room at wrong position → confusion ("is there even an egg?") |
| 5 — floor 5 | Tension | Boss floor same shape as floor 3 → anticlimax |

---

## TUI Mockup — Floor 1 vs Floor 3 Minimap Comparison

Floor 1 (entry floor, L-shape, 15×7):
```
Right panel rows 2-8, cols 61-79:
  col: 61                    79
  row 2:  # # # # # # # E # # # # # # # # # # #
  row 3:  # # # # # # # . # # # # # # # # # # #
  row 4:  # # # # # # # G # # # # # # # # # # #
  row 5:  # # * . . . . . # # # # # # # # # # #
  row 6:  # # # # # # # . # # # # # # # # # # #
  row 7:  # # # # # # # . # # # # # # # # # # #
  row 8:  # # # # # # # S # # # # # # # # # # #
```

Floor 3 (T-junction, 19×10, uses full panel width):
```
Right panel rows 2-11, cols 61-79:
  row 2:  # # # # # # # E # # # # # # # # # # #
  row 3:  # # # # # # # . # # # # # # # # # # #
  row 4:  # # # # # # # . # # # # # # # # # # #
  row 5:  . . . . . . . . . . . . . . . . . . .  (T-arm spans full width)
  row 6:  # # # # # # # . # # # # # # # # # # #
  row 7:  # # # # # # # G # # # # # # # # # # #
  row 8:  # # # # # # # . # # # # # # # # # # #
  row 9:  # # # # # # # . # # # # # # # # # # #
  row 10: # # # # # # # . # # # # # # # # # # #
  row 11: # # # # # # # S # # # # # # # # # # #
```

Player notes: "Floor 3 is taller and has a full-width corridor. Different shape, different feel."

---

## Floor Identity Summary (5 Floors)

| Floor | Shape concept | Egg room | Guard pos | Staircase pos | Distinct feel |
|-------|--------------|----------|-----------|---------------|---------------|
| 1 | L-shape (15×7) | No | (7,2) | (7,6) | Short intro, quick orientation |
| 2 | T-junction wide (19×10) | Yes (2,5) | (7,4) | (9,9) | First egg floor, lateral branches |
| 3 | Zigzag corridor (17×12) | Yes (16,6) | (8,3) | (8,11) | Forced turns, deep approach |
| 4 | Room-and-hall (19×13) | Yes (15,6) | (9,6) | (9,12) | Open room, feels spacious then tight |
| 5 | Boss antechamber (13×8) | No | N/A | N/A | Short, compressed, boss at center |
