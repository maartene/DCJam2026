# Wave Decisions — handcrafted-maps

**Feature**: handcrafted-maps
**Wave**: DISCUSS
**Date**: 2026-04-04
**Agent**: Luna (nw-product-owner)

---

## Decision 1: Is this user-facing?

**Yes.** Two users are affected:

- **Developer (Maartene)**: Authors five distinct floor layouts in Swift source code and sees them rendered in-game.
- **Player**: Navigates floors that feel intentionally designed rather than algorithmically identical.

Both journeys produce observable outcomes. Full DISCUSS wave applies.

## Decision 2: Walking skeleton needed?

**Yes, with a specific definition.** The walking skeleton is the safe migration step: the existing L-shaped corridor expressed as a `FloorDefinition` character grid, wired through `FloorRegistry`, producing a `FloorMap` cell-for-cell identical to today's output. All existing tests pass. No visible change to the player.

This step is the hard gate before any new floor topologies are authored. It proves the new data pipeline is correct before content is added on top of it.

Story map records this as the walking skeleton in story-map.md.

## Decision 3: Lightweight or full?

**Lightweight.** This is a jam entry. Scope is tightly bounded:

- 5 floors, all handcrafted
- No external data format (no JSON, no file I/O — pure Swift literal arrays)
- No procedural generation retained in production path
- Floor label relocation is a single rendering change

Full JTBD analysis skipped — motivation is clear (procedural maps are boring; all floors look identical).

## Decision 4: JTBD needed?

**No.** The job is obvious: "When I enter a new floor, I want it to feel distinct, so I can stay engaged with the dungeon." No competing jobs, no unclear motivations. Opportunity scoring not required.

---

## Scope Assessment

5 user stories, 2 bounded contexts (GameDomain, Renderer), estimated 2–3 days.

**Scope Assessment: PASS — 5 stories, 2 contexts, estimated 2–3 days**
