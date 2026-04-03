# Evolution: rules-coverage
**Date**: 2026-04-03
**Feature ID**: rules-coverage
**Status**: COMPLETE

---

## Feature Summary

Wired the upgrade prompt to the staircase transition in `RulesEngine.applyMove` to close
the DCJam R10 rule gap. The `UpgradePool`, `Upgrade`, `UpgradeEffect`, `UpgradePrompt`
screen mode, and `applyUpgrade` function all existed and were tested, but
`RulesEngine.applyMove` never transitioned to `.upgradePrompt`. This single wiring step
connected the fully-built upgrade system to the live game loop.

---

## Business Context

DCJam 2026 requires "at least one way to affect character stats" (R10). The intended
mechanism — milestone upgrades offered on staircase descent — was fully implemented
(`UpgradePool` with 8 upgrades, upgrade screen rendering, `applyUpgrade` application)
but was never triggered during normal play. A player could complete a full 5-floor run
without ever seeing an upgrade choice. This made the submission technically non-compliant
with R10 and left the boss encounter on Floor 5 likely unwinnable at default stats, since
upgrades are the intended pacing tool for escalating combat difficulty.

The rules-coverage DISCUSS wave produced a full gap analysis (`requirements.md`) mapping
all 11 DCJam rules to implementation status. Gap 1 (R10) was rated CRITICAL with ~2 hour
effort estimate. Gaps 2 and 3 (R11 theme confirmation, minimap visual inconsistency) were
rated non-blocking.

---

## Steps Completed

| Session | Phase | Status | Timestamp (UTC) |
|---------|-------|--------|-----------------|
| 01-01 | PREPARE | PASS | 2026-04-03T13:57:57Z |
| 01-01 | RED_ACCEPTANCE | PASS | 2026-04-03T13:58:02Z |
| 01-01 | RED_UNIT | PASS | 2026-04-03T13:58:02Z |
| 01-01 | GREEN | PASS | 2026-04-03T13:58:02Z |
| 01-01 | COMMIT | PASS | 2026-04-03T13:58:18Z |
| 01-01 | PREPARE (refactor) | PASS | 2026-04-03T14:00:17Z |
| 01-01 | RED_ACCEPTANCE | SKIPPED (refactor task) | 2026-04-03T14:00:25Z |
| 01-01 | RED_UNIT | SKIPPED (refactor task) | 2026-04-03T14:00:25Z |
| 01-01 | GREEN | PASS | 2026-04-03T14:00:28Z |
| 01-01 | COMMIT | PASS | 2026-04-03T14:00:40Z |

Single roadmap phase: "Wire upgrade prompt to staircase transition." One step: 01-01
"Trigger upgradePrompt screen mode on every non-final floor descent."

---

## Key Decisions

**Option A selected (upgrade on every non-final floor descent, floors 1-4).**

Two viable options were identified in `requirements.md`:
- Option A: offer upgrade on every floor transition (floors 1→2, 2→3, 3→4, 4→5). Four
  upgrades per 5-floor run. Simple and predictable.
- Option B: offer upgrade on even-numbered floors only (2 and 4). Two upgrades per run;
  less frequent; closer to a "milestone" framing.

Option A was chosen because the boss at Floor 5 deals 25 damage per 2-second hit. With
four upgrade opportunities, players can meaningfully compensate for escalating difficulty.
Option B would leave the boss encounter more punishing and harder to balance.

**`upgradeChoiceCount = 3` added to `GameConfig`.**

The number of choices presented at each upgrade prompt was hardcoded as a magic literal
in the original upgrade tests. It was promoted to `GameConfig.upgradeChoiceCount` (default
3) to make it configurable without code changes — consistent with how other tuning
constants (`dashCooldownSeconds`, `braceWindowDuration`, etc.) are managed.

---

## Commits

| Hash | Type | Description |
|------|------|-------------|
| `0eb9399` | feat | trigger upgradePrompt on staircase descent (floors 1-4); add `upgradeChoiceCount` to GameConfig; unit tests for floor 4→5 boundary and final floor guard; fix RendererHPBarColorTests |
| `acf84bd` | refactor | L1-L4 cleanup: rename abbreviation `c` → `config` in `GameConfig.withFloorCount`; rename `d` → `moveDelta` in `RulesEngine.applyMove`; all 213 tests pass |
| `cebcfc9` | fix | remap 1/2/3 keys to upgrade selection on upgrade prompt screen |
| `9937796` | fix | grant dash charges immediately when charge cap upgrade is taken |
| `12e3ba6` | fix | grant HP immediately when max HP upgrade is taken |

---

## Files Changed

**Production** (2 files):
- `Sources/GameDomain/GameConfig.swift` — added `upgradeChoiceCount: Int = 3`
- `Sources/GameDomain/RulesEngine.swift` — wired `applyMove` staircase branch to call
  `UpgradePool.drawChoices` and return `.upgradePrompt(choices:)` on non-final floors

**Tests** (2 files):
- `Tests/DCJam2026Tests/ProgressionTests.swift` — made acceptance test concrete (assert
  3 distinct choices); added unit tests for floor 4→5 boundary and final-floor guard
- `Tests/DCJam2026Tests/RendererHPBarColorTests.swift` — updated test setup to use
  `GameConfig.default` mutation pattern instead of memberwise initializer (broken by new
  `upgradeChoiceCount` field)

---

## Lessons Learned

1. **Feature scaffolding without trigger wiring is a delivery gap.** The upgrade system
   was fully implemented — domain types, rendering, application logic, tests — but the
   single call site in `RulesEngine.applyMove` was missing. A rules/requirements audit
   at the end of a delivery wave (as this DISCUSS wave performed) is a high-value,
   low-effort check.

2. **Magic numbers in tests are a smell.** The `upgradeChoiceCount = 3` literal appeared
   in tests before appearing in `GameConfig`. Promoting it to config during this feature
   closed a small but real drift between test assumptions and configurable behaviour.

3. **DISCUSS wave gap analysis is worth the time.** The requirements.md produced here
   took approximately 30 minutes and found a submission-blocking gap that would not have
   been caught by standard test coverage (all existing tests passed).

---

## Migrated Artifacts

| Source | Destination |
|--------|-------------|
| `docs/feature/rules-coverage/discuss/requirements.md` | `docs/ux/rules-coverage/requirements.md` |

The requirements.md has lasting value as an R10 gap analysis and DCJam 2026 rule
coverage reference. Design and distill directories were not created for this feature
(rules-coverage was a targeted one-step wiring task, not a full design wave feature).
