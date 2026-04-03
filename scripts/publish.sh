#!/usr/bin/env bash
# publish.sh — push release artifacts to itch.io via butler
#
# Pushes the zip files in ./dist/ to:
#   https://maartene.itch.io/dcjam2026
#
# Usage:
#   ./publish.sh              push all zips found in dist/
#   ./publish.sh 0.1.2        push with explicit version label
#
# Requires: butler (https://itch.io/docs/butler/installing.html)
# Auth:     run `butler login` once before using this script

set -euo pipefail

ITCHIO_TARGET="maartene/dcjam2026"
DIST="$(pwd)/dist"

# ── Sanity checks ─────────────────────────────────────────────────────────────
if ! command -v butler &>/dev/null; then
  echo "error: butler not found in PATH"
  echo "  Install: https://itch.io/docs/butler/installing.html"
  exit 1
fi

if [ ! -d "$DIST" ] || [ -z "$(ls "$DIST"/*.zip 2>/dev/null)" ]; then
  echo "error: no zip files found in dist/ — run ./build.sh first"
  exit 1
fi

# ── Version label ─────────────────────────────────────────────────────────────
if [ $# -ge 1 ]; then
  VERSION="$1"
else
  # Try to derive from the latest git tag
  VERSION="$(git describe --tags --abbrev=0 2>/dev/null || echo "")"
fi

VERSION_FLAG=""
if [ -n "$VERSION" ]; then
  VERSION_FLAG="--userversion $VERSION"
  echo "Version: $VERSION"
else
  echo "Version: (none — pass a version as argument or create a git tag)"
fi

# ── Push ──────────────────────────────────────────────────────────────────────
echo ""

push() {
  local file="$1"
  local channel="$2"
  if [ -f "$file" ]; then
    echo "Pushing $(basename "$file") -> $ITCHIO_TARGET:$channel"
    # shellcheck disable=SC2086
    butler push "$file" "$ITCHIO_TARGET:$channel" $VERSION_FLAG
  else
    echo "Skipping $channel ($(basename "$file") not found)"
  fi
}

push "$DIST/DCJam2026-macos-universal.zip"  "mac"
push "$DIST/DCJam2026-linux-x86_64.zip"     "linux-amd64"
push "$DIST/DCJam2026-linux-aarch64.zip"    "linux-arm64"

echo ""
echo "Done. Check your page at https://maartene.itch.io/dcjam2026"
