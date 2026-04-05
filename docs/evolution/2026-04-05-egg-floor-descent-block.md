# Evolution: egg-floor-descent-block

**Date**: 2026-04-05
**Feature ID**: egg-floor-descent-block
**Status**: COMPLETE

---

## Feature Summary

Block Ember from descending the staircase on the egg floor when the egg has not been collected, preventing a softlock where a player could reach the exit on floor 5 without the egg.

The fix is a targeted one-guard addition to `RulesEngine.applyMove` combined with a contextual thought from Ember when she faces the staircase from one tile away. No new overlays, no new screen modes — the rule is communicated through Ember's voice.

---

## Business Context

**Jam**: DCJam 2026
**Problem**: A player who missed the egg room on the egg floor could descend the staircase and reach floor 5's exit patio. Stepping on the exit without the egg silently softlocked them with no feedback and no way forward. This was the primary unfixable failure path in a jam entry.
**Solution scope**: Option B — block descent at the staircase of the egg floor. Ascending staircases are out of jam scope. The discuss wave originally framed this as a full narrative overlay on the exit square (`exit-without-egg`), but playtesting showed the staircase is a better and earlier intervention point.

---

## Key Implementation Decisions

### Decision 1: Block at the staircase, not the exit

The discuss wave (as `exit-without-egg`) designed an `exitWithoutEgg` NarrativeOverlay triggered on the floor 5 exit square. During implementation the team shifted to blocking at the staircase on the egg floor. This is an earlier and cleaner intervention: once the player has descended without the egg, backtracking requires ascending (out of jam scope). Blocking at descent keeps the player on the floor that has the egg.

### Decision 2: Silent block in RulesEngine — one guard

In `RulesEngine.applyMove`, inside the staircase descent block, added:

```swift
if floor.hasEggRoom && !state.hasEgg { return state }
```

No new `ScreenMode`, no new `NarrativeEvent`. The state is returned unchanged — the move is silently absorbed. Ember's thought delivers the feedback.

### Decision 3: Thought triggers from one tile away, not on the staircase tile

Initial implementation triggered the thought when Ember landed on the staircase tile. This created a movement trap: the player had to move forward (which would be blocked), making the game appear unresponsive. The fix (commit `f935dda`) changed `EmberThoughts.dungeonThought` to check whether the player's **one-step-ahead position** (in facing direction) equals the staircase position. The thought fires at approach, not on contact. The player sees the refusal before attempting the move.

### Decision 4: Fix pre-existing hasEgg inversion in EmberThoughts

While wiring the staircase thought, a pre-existing bug was found: the `hasEgg=true` branch returned "I need to find it" and the `hasEgg=false` branch returned the "I have it!" thought — inverted. This was corrected in commit `ece9016`: `hasEgg=true` now returns "I have it! Now find the way out." and `hasEgg=false` returns "I need to find it."

---

## Delivery Execution

Four commits, all on the `main` branch:

| Commit | Message | Purpose |
|---|---|---|
| `21e82ce` | fix(rules-engine): block staircase descent on egg floor when egg not collected | Core RulesEngine guard |
| `ece9016` | fix(ember-thoughts): show refusal thought at staircase without egg; fix hasEgg inversion | Thought logic + inversion fix |
| `2088012` | fix(rules-engine): land Ember on staircase tile when descent blocked without egg | Intermediate — Ember lands on staircase tile when blocked |
| `f935dda` | fix(ember-thoughts): trigger staircase refusal from one tile away, not on tile | Final approach — thought at one tile away to avoid movement trap |

---

## Files Modified

| File | Change |
|---|---|
| `Sources/GameDomain/RulesEngine.swift` | Added `hasEggRoom && !hasEgg` descent guard |
| `Sources/GameDomain/EmberThoughts.swift` | Added staircase approach thought; fixed hasEgg inversion |
| `Tests/DCJam2026Tests/FloorNavigationTests.swift` | New tests for blocked descent |
| `Tests/DCJam2026Tests/EmberThoughtsTests.swift` | New tests for staircase thought and hasEgg correction |

---

## Test Results

All Swift tests pass after implementation. No regressions.

---

## Relationship to discuss/exit-without-egg

The discuss wave artifacts (journey maps, UAT scenarios, acceptance criteria) were created under `docs/feature/exit-without-egg/` when the solution was scoped as a NarrativeOverlay on the exit square. The implemented solution diverges in mechanism (staircase block vs. exit overlay) but shares the same root problem and emotional arc. The UX journey artifacts retain lasting value as documentation of the design decision path and are migrated to `docs/ux/exit-without-egg/`.

---

## Lessons Learned

### 1. Intervention point matters more than intervention mechanism

Blocking at the staircase (before the player leaves the floor) is a structurally better solution than a NarrativeOverlay at the exit (after the player has left). When a player is softlocked, the fix should be placed as early in the causal chain as possible — not at the moment of failure.

### 2. Movement trap is a distinct failure mode from visual feedback absence

The first implementation placed the thought trigger on the staircase tile. This meant: move forward → land on staircase → see thought → move forward again → silently blocked. The player experienced two moves to one feedback cycle and perceived the first block as a bug. Triggering from one tile away collapses this to: approach staircase → see thought → move blocked as expected. One action, one feedback cycle.

### 3. Bug-adjacent code deserves inspection during targeted fixes

The hasEgg inversion in EmberThoughts was live but invisible during normal play (players rarely have the egg and read the thought at the same moment). It was caught only because the staircase thought work required reading the hasEgg branching code. Targeted fixes should include a quick read of surrounding logic.
