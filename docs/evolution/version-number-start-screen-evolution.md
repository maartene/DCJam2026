# Evolution: version-number-start-screen

**Date**: 2026-04-04
**Feature**: Add version number to start screen (lower-left corner)
**Status**: DELIVERED

---

## Summary

Added a `v1.0.0` version label to the lower-left corner (row 25, col 1) of the start screen. The version is sourced from a new `AppVersion` constant — not a magic inline string — and renders only on the start screen, not on dungeon or other screens.

## Steps Executed

| Step | Name | TDD Phases | Result |
|------|------|-----------|--------|
| 01-01 | Render version string in lower-left corner | PREPARE → RED_ACCEPTANCE → RED_UNIT → GREEN → COMMIT | PASS |

## Artifacts

- `Sources/App/AppVersion.swift` — new file; `enum AppVersion { static let current = "v1.0.0" }`
- `Sources/App/Renderer.swift` — `renderStartScreen()` writes version at row 25 col 1
- `Tests/DCJam2026Tests/StartScreenVersionTests.swift` — 4 tests (AC1–AC4), all green

## Test Results

All 286 tests pass (including 4 new version tests).

## Commit

`6c3970f feat(version-number-start-screen): show version v1.0.0 in lower-left of start screen`
