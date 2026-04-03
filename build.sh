#!/usr/bin/env bash
# build.sh — local release packaging for DCJam2026
#
# Produces three zip archives in ./dist/:
#   DCJam2026-macos-universal.zip   (arm64 + x86_64 fat binary)
#   DCJam2026-linux-x86_64.zip      (static stdlib, glibc-dynamic)
#   DCJam2026-linux-aarch64.zip     (static stdlib, Pi 3/4/5 compatible)
#
# Usage:
#   ./build.sh                  build all targets
#   ./build.sh --skip-arm64     skip Linux aarch64 (saves time on Intel Macs)
#
# Requires: Swift toolchain, Docker or Podman

set -euo pipefail

PRODUCT="DCJam2026"
SWIFT_IMAGE="swift:6.3-jammy"
DIST="$(pwd)/dist"
SKIP_ARM64=false

for arg in "$@"; do
  case $arg in
    --skip-arm64) SKIP_ARM64=true ;;
    *) echo "Unknown argument: $arg"; exit 1 ;;
  esac
done

# ── Detect container runtime (prefer Podman) ──────────────────────────────────
if command -v podman &>/dev/null; then
  CONTAINER="podman"
elif command -v docker &>/dev/null; then
  CONTAINER="docker"
else
  echo "error: neither podman nor docker found in PATH"
  exit 1
fi
echo "Container runtime: $CONTAINER"

mkdir -p "$DIST"

# ── [1/3] macOS universal binary ─────────────────────────────────────────────
echo ""
echo "[1/3] Building macOS universal binary (arm64 + x86_64)..."
swift build -c release \
  --arch arm64 \
  --arch x86_64 \
  --product "$PRODUCT"

cp ".build/apple/Products/Release/$PRODUCT" "$DIST/$PRODUCT-macos-universal"
(cd "$DIST" \
  && zip "$PRODUCT-macos-universal.zip" "$PRODUCT-macos-universal" \
  && rm "$PRODUCT-macos-universal")
echo "  -> $DIST/$PRODUCT-macos-universal.zip"

# ── [2/3] Linux x86_64 ───────────────────────────────────────────────────────
echo ""
echo "[2/3] Building Linux x86_64 (via $CONTAINER)..."
"$CONTAINER" run --rm \
  --platform linux/amd64 \
  -v "$(pwd):/src" \
  -w /src \
  "$SWIFT_IMAGE" \
  swift build -c release --product "$PRODUCT" -Xswiftc -static-stdlib

cp ".build/x86_64-unknown-linux-gnu/release/$PRODUCT" "$DIST/$PRODUCT-linux-x86_64"
(cd "$DIST" \
  && zip "$PRODUCT-linux-x86_64.zip" "$PRODUCT-linux-x86_64" \
  && rm "$PRODUCT-linux-x86_64")
echo "  -> $DIST/$PRODUCT-linux-x86_64.zip"

# ── [3/3] Linux aarch64 (Raspberry Pi compatible) ────────────────────────────
echo ""
if [ "$SKIP_ARM64" = true ]; then
  echo "[3/3] Skipping Linux aarch64 (--skip-arm64 passed)"
else
  echo "[3/3] Building Linux aarch64 (via $CONTAINER)..."
  echo "      Uses -static-stdlib (not --swift-sdk) to avoid mimalloc LSE"
  echo "      atomics crash on Raspberry Pi 3/4 (Cortex-A53/A72, ARMv8.0)."
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo "      Running natively on Apple Silicon — fast."
  else
    echo "      Running under QEMU on Intel — this will be slow (~10-20 min)."
  fi

  "$CONTAINER" run --rm \
    --platform linux/arm64 \
    -v "$(pwd):/src" \
    -w /src \
    "$SWIFT_IMAGE" \
    swift build -c release --product "$PRODUCT" -Xswiftc -static-stdlib

  cp ".build/aarch64-unknown-linux-gnu/release/$PRODUCT" "$DIST/$PRODUCT-linux-aarch64"
  (cd "$DIST" \
    && zip "$PRODUCT-linux-aarch64.zip" "$PRODUCT-linux-aarch64" \
    && rm "$PRODUCT-linux-aarch64")
  echo "  -> $DIST/$PRODUCT-linux-aarch64.zip"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "Done. Artifacts in dist/:"
ls -lh "$DIST/"*.zip
