# Upstream Issues: Turning Mechanic — DISTILL Wave

## Issue 1: Floor Grid Size Mismatch (RESOLVED)

**Detected**: During DELIVER wave initialization
**Source**: DESIGN ADR-004 was updated from 11×7 to 15×7 after DISTILL ran

**Original DISTILL assumption** (from DESIGN wave-decisions.md at time of DISTILL):
> DSGN-02: 11×7 L-shaped corridor, main corridor x=4

**Updated DESIGN decision** (ADR-004 revision):
> 15×7 L-shaped corridor, main corridor x=7
> Rationale: 15×7 gives visual aspect ratio 15:14 ≈ square at 2:1 terminal font. 11×7 left 8 empty rows in the minimap panel.

**Resolution**: DISTILL test files and scenarios updated before DELIVER:
- `TwoDFloorTests.swift` — comments and test names updated to 15×7, x=7, entry=(7,0)
- `test-scenarios.md` — grid topology reference updated
- `wave-decisions.md` — DSGN-02 entry updated

**Impact on tests**: Zero — all test bodies were `{}` (disabled, empty). Only comments and test names were changed. The crafter implementing TwoDFloorTests will use (7,0) for entry, x=7 for the main corridor, and the 15×7 grid dimensions.
