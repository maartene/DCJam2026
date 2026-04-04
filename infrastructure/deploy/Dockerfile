# Dockerfile — Ember's Escape multi-stage ARM64 build
# Build context: project root (DCJam2026/)
# Usage: docker build --platform linux/arm64 -t embers-escape -f infrastructure/deploy/Dockerfile .

# ── Stage 1: Build Swift binary ───────────────────────────────────────────────
FROM swift:6.3-jammy AS builder

COPY . /build
WORKDIR /build
RUN swift build -c release

# ── Stage 2: Runtime image ────────────────────────────────────────────────────
FROM arm64v8/node:20-alpine

# Build tools required for node-pty native compilation via node-gyp
RUN apk add --no-cache python3 make g++

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
