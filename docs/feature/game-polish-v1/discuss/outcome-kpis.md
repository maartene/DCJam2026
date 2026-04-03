# Outcome KPIs — Game Polish v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)

---

## Measurement Context

This is a game jam submission. Quantitative telemetry is not available.
All KPIs are measured through playtest observation and subjective feedback.
Targets are expressed as "0 complaints of type X" or "observer notes behavior Y".

---

## KPI-P01: Orientation Before Play

| Field | Value |
|-------|-------|
| **Who** | First-time player launching the binary |
| **Does what** | Can identify the quit key (ESC) before making any game move |
| **By how much** | 100% of observed playtest participants (target: 0 confusion events) |
| **Measured by** | Ask player "how do you quit?" before they touch the keyboard |
| **Baseline** | 0% — no start screen exists; Q/ESC undiscoverable without README |
| **Story** | US-P01 Start Screen |

---

## KPI-P02: Zero Accidental Quits via Q

| Field | Value |
|-------|-------|
| **Who** | Player navigating with WASD during any game state |
| **Does what** | Never loses a run due to accidentally pressing Q |
| **By how much** | 0 accidental quit events in any observed playtest session |
| **Measured by** | Playtest observation — note every quit event and its cause |
| **Baseline** | Known issue — multiple confirmed accidental quits in pre-fix playtests |
| **Story** | US-P02 Remove Q as Quit |

---

## KPI-P03: Egg Beat Dwell Time

| Field | Value |
|-------|-------|
| **Who** | Player who has just triggered the egg discovery overlay |
| **Does what** | Reads the egg screen before dismissing it |
| **By how much** | Average dwell time >= 2 seconds before keypress |
| **Measured by** | Stopwatch during playtest observation: time from overlay appear to keypress |
| **Baseline** | Current overlay — anecdotally dismissed quickly; no measurement |
| **Story** | US-P03 Egg Screen |

---

## KPI-P04: Win Screen Dwell Time

| Field | Value |
|-------|-------|
| **Who** | Player who has just won the game |
| **Does what** | Reads the win screen before pressing R |
| **By how much** | Average dwell time >= 3 seconds before restart |
| **Measured by** | Stopwatch during playtest: time from win screen appear to R press |
| **Baseline** | Current "ESCAPED!" screen — anecdotally dismissed immediately |
| **Story** | US-P04 Win Screen |

---

## KPI-P05: State Legibility Under Pressure

| Field | Value |
|-------|-------|
| **Who** | Player navigating the dungeon at any HP or charge state |
| **Does what** | Makes HP/charge decisions without pausing to count bar segments |
| **By how much** | 0 playtest comments of "I didn't know I was that low" or "I didn't know Special was ready" |
| **Measured by** | Playtest observation — count confusion comments about HP or Special state |
| **Baseline** | Current monochrome status bar — state only readable by character count |
| **Stories** | US-P05a HP Color, US-P05b Charge/Cooldown Color, US-P05c Minimap Color |

---

## KPI-P06: Brace Mechanic Legibility

| Field | Value |
|-------|-------|
| **Who** | Player who has just pressed Brace in a combat encounter |
| **Does what** | Immediately understands whether the parry succeeded or failed |
| **By how much** | 0 playtest comments of "I don't know if Brace did anything" |
| **Measured by** | Post-play question: "How did you know when Brace worked?" — answer should reference the overlay |
| **Baseline** | Current state — brace outcome is silent; Special meter change is the only feedback |
| **Story** | US-P06 Brace Feedback |

---

## KPI-P07: Dash as a Named Verb

| Field | Value |
|-------|-------|
| **Who** | Player who has just pressed 1 (Dash) in a combat encounter |
| **Does what** | Recognizes the Dash as a distinct, powerful action rather than a position change |
| **By how much** | 0 playtest comments of "did I dash or just move?" |
| **Measured by** | Playtest observation — note navigation vs. dash confusion; post-play: "what does 1 do?" |
| **Baseline** | Current state — recentDash sets Thoughts text only; not prominent enough |
| **Story** | US-P07 Dash Feedback |

---

## Aggregate Polish Pass Goal

**Before**: Playtest participants accidentally quit, don't know controls, miss feedback on
core mechanics, and can't read state under pressure.

**After**: Playtest participants can orient in under 10 seconds, understand all core mechanics
from feedback alone (no README), and never accidentally quit.

**Signal of success**: A first-time player can complete Floor 1 and correctly describe
Dash, Brace parry success, and Brace miss behavior — without reading any documentation.
