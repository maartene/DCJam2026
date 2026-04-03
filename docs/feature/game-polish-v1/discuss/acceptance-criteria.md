# Acceptance Criteria — Game Polish v1
**Feature**: game-polish-v1
**Date**: 2026-04-03
**Author**: Luna (Product Owner — DISCUSS wave)

---

Consolidated acceptance criteria derived from UAT scenarios. Each item traces to a story.

---

## US-P01: Start Screen

- [ ] P01-AC-01: Title "Ember's Escape" appears on the first rendered frame after launch
- [ ] P01-AC-02: "DCJam 2026" is displayed beneath the title
- [ ] P01-AC-03: A narrative hook mentioning the egg and the hero is present
- [ ] P01-AC-04: W/S (move), A/D (turn), 1 (Dash), 2 (Brace), 3 (Special), ESC (quit) are all listed
- [ ] P01-AC-05: Q is not mentioned anywhere on the start screen
- [ ] P01-AC-06: "[ Press any key to begin ]" prompt is visible
- [ ] P01-AC-07: Any key press transitions to the dungeon (Floor 1, full HP, 2 Dash charges, empty Special)
- [ ] P01-AC-08: No dungeon view, status bar, minimap, or thoughts panel appears on the start screen

---

## US-P02: Remove Q as Quit Key

- [ ] P02-AC-01: Q pressed during dungeon navigation: no game state change, game continues
- [ ] P02-AC-02: Q pressed during combat: no game state change, combat continues
- [ ] P02-AC-03: Q pressed during any overlay screen: no quit, overlay continues (or "any key" dismiss applies)
- [ ] P02-AC-04: ESC pressed during dungeon: game exits cleanly
- [ ] P02-AC-05: Terminal is restored after ESC quit (cursor visible, raw mode disabled)
- [ ] P02-AC-06: TurnKeyBindingTests (or equivalent) confirms Q produces `.none` GameCommand

---

## US-P03: Egg Pickup Screen

- [ ] P03-AC-01: Overlay contains ASCII egg art (5-line centered .-.  /   \  | o o | etc.)
- [ ] P03-AC-02: Title line contains "My egg" in bright yellow (ANSI 93)
- [ ] P03-AC-03: "Warm. Alive. Still here." renders in bright white
- [ ] P03-AC-04: A flavour line is present in dimmed style
- [ ] P03-AC-05: "[ press any key ]" prompt is visible
- [ ] P03-AC-06: Overlay does not auto-clear — player must press a key to continue
- [ ] P03-AC-07: After dismissal, EGG symbol (*) in status bar is rendered in bright yellow

---

## US-P04: Win Screen

- [ ] P04-AC-01: "The sky." headline renders in bold bright cyan (ANSI 96 + 1)
- [ ] P04-AC-02: "Open. Endless. Yours." text is present
- [ ] P04-AC-03: Starfield art block (asterisks and dots, multiple lines) is present
- [ ] P04-AC-04: "But you are free." or equivalent narrative line is present
- [ ] P04-AC-05: Floors cleared count is displayed
- [ ] P04-AC-06: HP remaining count is displayed
- [ ] P04-AC-07: "[ Press R to play again ]" prompt is visible
- [ ] P04-AC-08: Screen holds until R is pressed (no auto-clear)

---

## US-P05a: HP Bar Color

- [ ] P05a-AC-01: HP >= 40% of maxHP: bar fill renders in green (ANSI 32)
- [ ] P05a-AC-02: HP < 40% and >= 20%: bar fill renders in yellow (ANSI 33)
- [ ] P05a-AC-03: HP < 20%: bar fill renders in red (ANSI 31)
- [ ] P05a-AC-04: HP at exactly 40%: green (threshold is inclusive at 40%)
- [ ] P05a-AC-05: HP at exactly 20%: yellow (threshold is inclusive at 20%)
- [ ] P05a-AC-06: Color change applies in the same frame as the HP change
- [ ] P05a-AC-07: ANSI reset code follows the HP bar — no color bleed to EGG indicator

---

## US-P05b: Charge and Cooldown Color

- [ ] P05b-AC-01: specialIsReady == true: SPEC label and bar render in bold bright cyan (ANSI 96 + 1)
- [ ] P05b-AC-02: specialCharge < 1.0: SPEC bar renders in dim cyan (ANSI 36), not bold
- [ ] P05b-AC-03: Dash cooldown active: cooldown timer text "(cd=Xs)" renders in yellow (ANSI 33)
- [ ] P05b-AC-04: braceOnCooldown == true: "(2)BRACE" label renders in yellow (ANSI 33)
- [ ] P05b-AC-05: ANSI reset follows each colored segment — no bleed between status bar elements

---

## US-P05c: Minimap Color

- [ ] P05c-AC-01: Player character (^, >, v, <): bold bright white (ANSI 97 + 1)
- [ ] P05c-AC-02: Guard (G): bright red (ANSI 91)
- [ ] P05c-AC-03: Boss (B): bold bright red (ANSI 91 + 1)
- [ ] P05c-AC-04: Egg uncollected (*): bright yellow (ANSI 93)
- [ ] P05c-AC-05: Egg collected (e): dim yellow (ANSI 33)
- [ ] P05c-AC-06: Staircase (S): bright cyan (ANSI 96)
- [ ] P05c-AC-07: Exit (X): bold bright cyan (ANSI 96 + 1)
- [ ] P05c-AC-08: Entry (E): dim cyan (ANSI 36)
- [ ] P05c-AC-09: Walls (#): dark gray (ANSI 90)
- [ ] P05c-AC-10: Each cell character is followed by a color reset

---

## US-P06: Brace Feedback Overlays

- [ ] P06-AC-01: Parry success: overlay renders containing developer-confirmed "parry success" word
- [ ] P06-AC-02: Parry success overlay: rendered in bright cyan
- [ ] P06-AC-03: Parry success overlay: auto-clears in approximately 0.75s (no keypress required)
- [ ] P06-AC-04: After parry success overlay clears: SPEC meter reflects +15% bonus (braceSpecialBonus)
- [ ] P06-AC-05: Unbraced hit: overlay renders containing developer-confirmed "hit taken" word
- [ ] P06-AC-06: Unbraced hit overlay: rendered in bright red
- [ ] P06-AC-07: Unbraced hit overlay: auto-clears in approximately 0.75s (no keypress required)
- [ ] P06-AC-08: Fatal hit (hp <= 0 after damage): death screen shows instead of "hit taken" overlay
- [ ] P06-AC-09: After "hit taken" overlay clears: HP bar color reflects new health percentage

---

## US-P07: Dash Feedback Overlay

- [ ] P07-AC-01: Successful dash: overlay renders containing developer-confirmed dash word
- [ ] P07-AC-02: Dash overlay: rendered in bold white
- [ ] P07-AC-03: Dash overlay: includes a dragon-vocabulary sub-line
- [ ] P07-AC-04: Dash overlay: auto-clears in approximately 0.75s (no keypress required)
- [ ] P07-AC-05: After dash overlay clears: Dash charge count is one less than before the dash
- [ ] P07-AC-06: dashCharges == 0 when 1 is pressed: no dash executed, no SWOOSH overlay fires

---

## Developer Confirmation Required Before Implementation

The following items must be decided before US-P06 and US-P07 can be implemented:

| Decision | Options | Record in |
|----------|---------|-----------|
| Brace parry success word | SHIELDED! / GUARDED! / DEFLECTED! / HELD! | wave-decisions.md |
| Brace hit taken word | SCORCHED! / BURNED! / STRUCK! / OUCH! | wave-decisions.md |
| Dash word | SWOOSH! / SURGE! / BURST! / LUNGE! | wave-decisions.md |
| Transient overlay mechanism | GameState field vs. NarrativeEvent cases | DESIGN wave → wave-decisions.md |
