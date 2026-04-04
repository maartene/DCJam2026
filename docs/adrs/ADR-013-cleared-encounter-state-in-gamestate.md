# ADR-013: Cleared-Encounter State as Set<Position> in GameState

**Status**: Accepted
**Date**: 2026-04-04
**Feature**: gameplay-fixes-polish
**Resolves**: DEC-DISCUSS-03 — "specific data structure is a DESIGN wave decision"

---

## Context

US-GPF-01 requires that when an enemy's HP reaches 0, the encounter cell is marked
as cleared. A cleared cell must:
1. Not trigger combat on re-entry (`RulesEngine.applyMove`).
2. Render as "." on the minimap (`Renderer.minimapChar`).
3. Reset when the player ascends to a new floor.

`FloorMap` is immutable (struct, value type, ADR-002). Mutable run-time state must
live in `GameState`.

Three structural options were considered:

- **Option A**: `Set<Position>` on `GameState` — a set of cleared cell positions for
  the current floor.
- **Option B**: `Optional<Position>` on `GameState` — a single optional position
  representing at most one cleared cell per floor.
- **Option C**: `Bool` flag on `EncounterModel` — mark the encounter as cleared
  within the encounter struct.

---

## Decision

**Option A — `Set<Position>` on `GameState`** is adopted.

A new field `clearedEncounterPositions: Set<Position>` is added to `GameState`.
It is initialised to `Set()` and reset to `Set()` on floor change.
`Position` is already `Hashable` — no changes to `Position` are required.

---

## Consequences

**Positive**:
- Correctly models zero, one, or multiple cleared cells per floor — handles current
  single-guard and single-boss cases as well as any future multi-guard floor without
  redesign.
- `Set` membership check (`contains`) is O(1) — no performance concern.
- Follows the existing `GameState` value-type + `withXxx` pattern (ADR-002).
- Cleared state lifecycle is explicit: insert on kill, reset on floor change.

**Negative**:
- Adds a field to `GameState` that holds a collection. Marginal memory increase
  (at most 2 positions per floor, given current floor design). Negligible.

---

## Alternatives Considered

### Option B: Optional<Position>

Would work for the current single-encounter-per-floor design. Rejected because:
- Artificially constrains future floors to one clearable encounter.
- A `Set` is not meaningfully more complex to implement and is strictly more general.

### Option C: Bool flag on EncounterModel

Rejected because:
- `EncounterModel` is session-scoped to active `.combat` screen mode. Once combat
  resolves, the `EncounterModel` is discarded. It is not retained in `GameState`
  between combat sessions.
- Clearing the encounter would require either persisting `EncounterModel` beyond its
  natural scope or reconstructing it at each cell check — both worse than a simple set.
