# Prioritization: Turning Mechanic

## Release Priority

| Priority | Release | Target Outcome | Rationale |
|----------|---------|----------------|-----------|
| 1 | Walking Skeleton | End-to-end turn flow works; jam rule satisfied | Validates core assumption; unblocks all other stories |
| 2 | Release 1 | Player can use all keyboard inputs and read facing clearly on minimap | Completes UX; all inputs wired; Facing label readable |
| 3 | Release 2 | No regression on movement; facing persists across floors | Polish + edge cases; safe to defer to end |

---

## Backlog Suggestions

> Note: Story IDs are assigned here for planning and will be confirmed in the user-stories.md file.

| Story | Release | Priority | Outcome Link | Dependencies |
|-------|---------|----------|-------------|--------------|
| US-TM-01: CardinalDirection domain type | WS | P1 | KPI-1 jam compliance | None |
| US-TM-02: RulesEngine turn command | WS | P1 | KPI-1 jam compliance | US-TM-01 |
| US-TM-03: Facing-relative movement delta | WS | P1 | KPI-1 jam compliance | US-TM-01, US-TM-02 |
| US-TM-04: Minimap caret indicator | WS | P1 | KPI-2 orientation | US-TM-01 |
| US-TM-05: Input bindings A/D + Arrow Left/Right | R1 | P2 | KPI-2 orientation | US-TM-02 |
| US-TM-06: Facing persistence + combat turn acceptance | R2 | P3 | KPI-3 no regression | US-TM-01..05 |

---

## Prioritization Scores

Formula: Value (1-5) × Urgency (1-5) / Effort (1-5)

| Story | Value | Urgency | Effort | Score | Notes |
|-------|-------|---------|--------|-------|-------|
| US-TM-01 | 5 | 5 | 1 | 25.0 | Unblocks everything; pure enum, minimal work |
| US-TM-02 | 5 | 5 | 2 | 12.5 | Core turn logic; one pure function |
| US-TM-03 | 5 | 5 | 2 | 12.5 | Core movement change; delta resolution |
| US-TM-04 | 5 | 5 | 1 | 25.0 | Minimal Renderer change; high UX value |
| US-TM-05 | 4 | 4 | 1 | 16.0 | InputHandler is simple; unblocks UX |
| US-TM-06 | 3 | 3 | 2 | 4.5 | Edge case polish; safe to do last |

---

## MoSCoW

| Story | Classification | Rationale |
|-------|---------------|-----------|
| US-TM-01 | Must Have | Without CardinalDirection there is no turning at all |
| US-TM-02 | Must Have | Without turn command there is no jam compliance |
| US-TM-03 | Must Have | Without facing-relative movement the mechanic is incomplete |
| US-TM-04 | Must Have | Minimap is primary UX concern (WD-01); required for orientation |
| US-TM-05 | Must Have | A/D + Arrow keys are the player-facing interface; no turning without bindings |
| US-TM-06 | Should Have | Persistence and combat edge case; game works without it but may have regression risk |
