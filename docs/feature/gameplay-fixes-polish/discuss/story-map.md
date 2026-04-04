# Story Map — Gameplay Fixes and Polish

## Scope Assessment: PASS — 3 stories, 2 contexts (GameDomain + Renderer), estimated 3 days

---

## Backbone (User Activities)

```
[Navigate dungeon] --> [Fight encounters] --> [Read minimap] --> [Confront boss]
```

---

## Story Map

```
Backbone:   Navigate dungeon         Fight encounters         Read minimap          Confront boss
            ────────────────         ────────────────         ────────────          ─────────────
Priority 1:                          US-GPF-01                                      (enabled by US-GPF-01)
                                     Guard cleared after
                                     defeat — cell passable,
                                     minimap updated

Priority 2:                                                                         US-GPF-02
                                                                                    Head Warden art +
                                                                                    name + thoughts

Priority 3:                                                   US-GPF-03
                                                              Minimap legend
                                                              in right panel
```

---

## Walking Skeleton

The minimum demonstrable slice is **US-GPF-01** alone: a player who defeats a guard
and then walks through that cell without re-triggering combat. This is a standalone
runnable behaviour requiring no other story to be complete first.

---

## Release Slices

### Slice A — Bug Fix (Must Have, ~1 day)
- **US-GPF-01**: Guard removal after defeat

### Slice B — Narrative Coherence (Should Have, ~1 day)
- **US-GPF-02**: Head Warden boss redesign

### Slice C — Polish (Could Have, ~0.5 day)
- **US-GPF-03**: Minimap legend

---

## Priority Rationale

| Story | MoSCoW | Rationale |
|-------|--------|-----------|
| US-GPF-01 | Must Have | Game-breaking bug — players get soft-locked or unfairly killed |
| US-GPF-02 | Should Have | Narrative incoherence undermines the game's premise for judges |
| US-GPF-03 | Could Have | Legibility improvement; game is playable without it |

---

## Dependencies

- US-GPF-02 and US-GPF-03 are independent of each other and of US-GPF-01.
- US-GPF-01 requires a new field in `GameState` — DESIGN wave must confirm the data
  model before implementation.
- US-GPF-02 is entirely within `Renderer` — no domain model changes required.
- US-GPF-03 is entirely within `Renderer` — no domain model changes required.
