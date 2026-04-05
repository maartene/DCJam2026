# Ember's Escape — DCJam 2026

A first-person dungeon exploration and combat game for DCJam 2026. You are Ember, a young dragon reclaiming a stolen egg and their freedom from a 5-floor dungeon.

Runs in any ANSI-capable terminal (min 80x25 characters) on macOS and Linux.

## Controls

- `W` / `A` / `S` / `D`: Move
- `1`: Dash forward (ignoring enemies)
- `2`: Brace (temporary shield that blocks attacks, charges SPECIAL on succesful block)
- `3`: Use SPECIAL ability - "Burn baby burn" (requires charge)
- `Esc`: Quit the game

## Gameplay hints
- the `Brace` action provides 0.5 seconds of invulnerability. Watch the enemy's attack timer and brace in time.

## Running the game
1. Requires a 80x25 ANSI-capable terminal
2. You can find prebuilt binaries on [itch.io](https://maartene.itch.io/dcjam2026) 
3. Play a [web version](https://www.embersescape.party). Note this one performs worse (Raspberry Pi connected through a Powerline ethernet adapter)

## Building from source

### Requirements

- Swift 6.3+
- macOS or Linux (x86_64 / aarch64)

### Building

```bash
# Debug build
swift build

# Release binary
swift build -c release
```

The release binary is placed at `.build/release/DCJam2026`.

### Running

```bash
# Run directly via SwiftPM
swift run

# Or run the release binary
.build/release/DCJam2026
```

### Testing

```bash
swift test
```

## Licensed assets:
The guard and boss sprites are from [Joan Stark's Ascii Art gallery](https://asciiart.website/mirrors/jgs/www.geocities.com/SoHo/7373/indexjava.html)