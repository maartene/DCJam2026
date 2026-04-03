# Ember's Escape — DCJam 2026

A first-person dungeon exploration and combat game for DCJam 2026. You are Ember, a young dragon reclaiming a stolen egg and their freedom from a 5-floor dungeon.

Runs in any ANSI-capable terminal (min 80x25 characters) on macOS and Linux.

## Controls

- `W` / `A` / `S` / `D`: Move
- `1`: Dash forward (ignoring enemies)
- `2`: Brace (temporary shield that blocks attacks, charges SPECIAL on succesful block)
- `3`: Use SPECIAL ability - "Burn baby burn" (requires charge)
- `Esc`: Quit the game

## Requirements

- Swift 6.3+
- macOS or Linux (x86_64 / aarch64)

## Building

```bash
# Debug build
swift build

# Release binary
swift build -c release
```

The release binary is placed at `.build/release/DCJam2026`.

## Running

```bash
# Run directly via SwiftPM
swift run

# Or run the release binary
.build/release/DCJam2026
```

## Testing

```bash
swift test
```

## Download prebuilt binaries
Find them on [itch.io](https://maartene.itch.io/dcjam2026)