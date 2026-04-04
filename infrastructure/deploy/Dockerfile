# Dockerfile — Ember's Escape multi-stage ARM64 build
# Build context: project root (DCJam2026/)
# Usage: docker build --platform linux/arm64 -t embers-escape -f infrastructure/deploy/Dockerfile .

# ── Stage 1: Build Swift binary ───────────────────────────────────────────────
FROM swift:6.3-jammy AS builder

COPY . /build
WORKDIR /build
RUN swift build -c release --static-swift-stdlib

# ── Stage 2: Runtime image ────────────────────────────────────────────────────
# Use jammy (Ubuntu/glibc) — same ABI as swift:6.3-jammy builder stage.
# Alpine (musl) cannot run glibc-linked Swift binaries.
FROM node:20-bookworm

# Build tools required for node-pty native compilation via node-gyp
RUN apt-get update && apt-get install -y --no-install-recommends g++ && rm -rf /var/lib/apt/lists/*

# Copy compiled Swift binary
COPY --from=builder /build/.build/release/DCJam2026 /usr/local/bin/DCJam2026

# Copy Node.js bridge application
COPY infrastructure/web/server.js /app/web/server.js
COPY infrastructure/web/index.html /app/web/index.html
COPY infrastructure/web/package.json /app/web/package.json
COPY infrastructure/web/package-lock.json /app/web/package-lock.json

WORKDIR /app/web

# Install production dependencies (node-pty compiles natively here)
RUN npm ci --omit=dev

EXPOSE 3000

CMD ["node", "server.js"]
