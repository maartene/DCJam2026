# Data Models — linux-port

**Feature**: linux-port
**Date**: 2026-04-03
**Author**: Morgan (Solution Architect — DESIGN wave)

---

## N/A

This feature introduces no new domain types, no new data models, and no changes to existing data models.

The linux-port change is entirely confined to the platform adaptation layer (`Sources/App/PlatformCompat.swift` and conditional imports in three existing files). All domain types in `GameDomain` — `GameState`, `FloorMap`, `EncounterModel`, `TimerModel`, `UpgradePool`, `GameConfig`, `GameCommand`, `Position`, `DungeonFrameKey`, `DungeonDepth`, `NarrativeEvent`, `Upgrade` — are unchanged.
