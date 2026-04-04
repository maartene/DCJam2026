# ADR-014: Head Warden Boss — Name, ASCII Art, and Thought Text

**Status**: Accepted
**Date**: 2026-04-04
**Feature**: gameplay-fixes-polish
**Resolves**: DEC-DISCUSS-05, DEC-DISCUSS-06 — "DESIGN wave owns the final art"

---

## Context

The boss encounter (floor 5, `isBossEncounter == true`) renders under the name
"DRAGON WARDEN" and displays cat ASCII art (`/\___/\` ears, whisker lines).
The game's narrative positions Ember (a dragon) against human wardens who stole
her egg. The cat art severs narrative coherence at the climactic boss encounter.

Two decisions from the DISCUSS wave are binding:
- **DEC-DISCUSS-05**: The boss name must be "HEAD WARDEN". The word "DRAGON" must not
  appear in the boss HUD label.
- **DEC-DISCUSS-06**: Art constraints — upright human figure, no cat ears, no feline
  features, reads as "large" and "armoured".

The DESIGN wave owns the final art execution within those constraints.

---

## Decision

**Boss name**: `"HEAD WARDEN"` — replaces `"DRAGON WARDEN"` in `buildCombatFrame`.

**Boss ASCII art** — 8-line human armoured figure:

```
        .-""--.
       /  O  O \
       |  ---  |
       |  ___  |
        \     /
    .---'-----'---.
   /    |=====|    \
  /_____|_____|_____\
```

This art:
- Contains no `/\___/\` ear pattern.
- Contains no whiskers or feline features.
- Depicts an upright figure with a rounded helmet (`.-""--.`), stern face (`---`/`___`),
  and armoured torso (`|=====|`, `_____`).
- Reads as formidable and human.
- Is 8 lines — matching the existing boss art line count; no layout changes needed.

**Boss combat thought text**: The `isBossEncounter` branch in `combatThoughts` is
replaced with text that:
- Names or implies the Head Warden as the human responsible for the egg theft.
- Uses dragon vocabulary (consistent with DEC-04).
- Does not contain the phrase "Dragon Warden".

Example (informative, not prescriptive — crafter may adjust wording):
> "The Head Warden. The one who gave the order. My fire is ready — and so is my fury."

---

## Consequences

**Positive**:
- Narrative coherence restored at the climactic encounter — judges understand the
  story's human-antagonist theme.
- Change is confined to ~20 lines in `Renderer.swift`. No domain model changes.
- Regular guard name ("DUNGEON GUARD"), art, and thoughts are unchanged.

**Negative**:
- None identified. This is a targeted content replacement with no architectural impact.

---

## Alternatives Considered

### Alternative: Rename to "WARDEN BOSS" or "CHIEF WARDEN"

Rejected. DEC-DISCUSS-05 specifies "HEAD WARDEN" as a hard requirement traceable to
the game's human-antagonist narrative. Alternative names were not evaluated — the
decision was made in the DISCUSS wave with the developer.

### Alternative: Use a generic human silhouette (no armour)

Rejected. DEC-DISCUSS-06 specifies the art "should read as large and armoured
(formidable jailer aesthetic)". A plain silhouette fails the formidable constraint.
The adopted art's `|=====|` torso and `_____` base convey armour and bulk.
