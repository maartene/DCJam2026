# Mikado: Remove FloorGenerator

**Goal**: Delete `Sources/GameDomain/FloorGenerator.swift` — all tests pass, FloorRegistry is sole floor source

## Dependency Tree

- [ ] **GOAL**: Delete FloorGenerator.swift
    - [ ] Fix FloorNavigationTests.swift — delete generateRun tests, rewrite remaining with FloorRegistry
        - Analysis:
          - DELETE: "A new run generates between 3 and 5 floors" — procedural generation property, meaningless with registry
          - DELETE: "Exactly one floor in the range 2 through 4 contains an egg room" — uses generateRun
          - DELETE: "Floor 5 contains the boss encounter and the exit square" — uses generateRun
          - DELETE: "Floor 5 contains no egg room" — uses generateRun
          - DELETE: "Each floor has a reachable path..." — uses generateRun, fixed maps always navigable
          - DELETE: "In a 3-floor run, the final floor contains boss encounter and exit" — uses generateRun + withFloorCount(3) not supported by registry
          - DELETE: "In a 3-floor run, the egg room is on Floor 2..." — uses generateRun
          - REWRITE: "Floor 1 contains no egg room" — FloorGenerator.generate → FloorRegistry.floor
          - REWRITE: "Ember is placed at the entry point after descending" — uses FloorGenerator.generate for floor1 and floor2 setup
    - [ ] Fix HandcraftedMapsWalkingSkeletonTests.swift — delete SKELETON-06 and SKELETON-07 parity tests
    - [ ] Fix GuardClearedAfterDefeatTests.swift — replace FloorGenerator.generate with FloorRegistry.floor
        - Affected: Walking Skeleton suite (line 37), Happy Paths H1 (line 75), H3 (line 132), E1 (line 195), E2 (line 222), E3 (line 242), E4 (line 268), E5 (line 283)
    - [ ] Fix TwoDFloorTests.swift — replace FloorGenerator.generate with FloorRegistry.floor
        - Affected: grid stored property (line 35), "Generated floor has correct dimensions" (line 162), "Main corridor cells" (line 168), "Branch corridor cells" (line 180), "Landmark positions match" (line 191)
    - [ ] Fix WalkingSkeletonTests.swift — replace FloorGenerator.generate in stateAtStaircase helper (line 188)
    - [ ] Fix DungeonFrameKeyTests.swift — replace FloorGenerator.generate in grid stored property (line 35)
    - [ ] Fix ProgressionTests.swift — replace FloorGenerator.generate in 3 tests (lines 24, 93, 140)

## Execution Log

| # | Node | Status | Commit |
|---|------|--------|--------|
| 1 | Fix HandcraftedMapsWalkingSkeletonTests.swift | pending | — |
| 2 | Fix GuardClearedAfterDefeatTests.swift | pending | — |
| 3 | Fix TwoDFloorTests.swift | pending | — |
| 4 | Fix WalkingSkeletonTests.swift | pending | — |
| 5 | Fix DungeonFrameKeyTests.swift | pending | — |
| 6 | Fix ProgressionTests.swift | pending | — |
| 7 | Fix FloorNavigationTests.swift | pending | — |
| 8 | Delete FloorGenerator.swift (GOAL) | pending | — |
