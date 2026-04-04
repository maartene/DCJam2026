# ADR-012: Raspberry Pi + Cloudflare Tunnel as Deployment Platform

**Date**: 2026-04-04  
**Status**: Accepted  
**Author**: Morgan (Solution Architect — DESIGN wave)  
**Deciders**: Maarten Engels (developer)

---

## Context

The bridge server needs to be publicly accessible during the DCJam 2026 judging window. The developer has a Raspberry Pi (aarch64 / ARM64 Linux) available. The question is how to expose it to judges on the internet.

---

## Decision

**Deploy on the developer's Raspberry Pi. Use Cloudflare Tunnel (`cloudflared`) for public HTTPS/WSS access.**

The Swift binary is compiled natively on the RPi. Docker packages the Node.js bridge server and the Swift binary together. Cloudflare Tunnel creates an outbound-only encrypted connection from the RPi to Cloudflare's edge — no router configuration or port forwarding required.

---

## Rationale

### Raspberry Pi over cloud VPS
- Developer already has the hardware — zero infrastructure cost
- No cloud account, no billing risk during jam
- Raspberry Pi 4 (4 GB RAM) is capable: handles 10+ concurrent sessions comfortably
- No "where do I deploy Swift?" problem — developer controls the environment

### Cloudflare Tunnel over router port forwarding
- Port forwarding requires editing router NAT rules — depends on ISP and router model; not always possible (CGNAT)
- Cloudflare Tunnel creates an **outbound** TCP/QUIC connection from the RPi to Cloudflare's edge. No inbound firewall rules needed
- Provides HTTPS/WSS termination automatically — judges get a clean `https://` URL with a valid TLS certificate
- Free tier supports unlimited bandwidth, no session limits
- `cloudflared` is a single binary; trivial to run as a systemd service

### Cloudflare Tunnel over ngrok
- ngrok free tier limits concurrent connections (1 tunnel, limited bandwidth)
- Cloudflare Tunnel free tier has no such limits
- Cloudflare Tunnel supports custom domains (optional but available)
- Both provide HTTPS — Cloudflare Tunnel preferred for reliability during a judging window that may span days

---

## Swift Binary Compilation on ARM64

Two options were considered:

**Option A — Cross-compile on macOS** (`--swift-sdk aarch64-swift-linux-musl`): Produces a statically-linked binary. Requires installing the musl Swift SDK. Best for CI.

**Option B — Native compile on RPi** (`swift build -c release`): Requires Swift 6.3 on RPi. Build time ~2–3 minutes. Simpler setup for a jam with no CI pipeline.

**Selected: Option B for jam** — developer installs Swift once on the RPi and builds natively. No cross-compilation SDK needed. The Raspberry Pi 4 can build the Swift package in acceptable time.

---

## Alternatives Considered

### Cloud VPS (fly.io, Railway, DigitalOcean)
**Pros**: Always-on, no hardware concern, easy HTTPS  
**Cons**: Swift on ARM (fly.io uses Firecracker VMs, some tiers are x86); requires account/billing; cross-compilation or slow CI build  
**Rejected**: RPi is simpler given existing hardware

### AWS/GCP/Azure
**Rejected**: Overkill for a jam. Billing risk. Setup time.

### ngrok
**Rejected**: Free tier limitations (1 tunnel, rate limits). Cloudflare Tunnel is more reliable for a multi-day judging window.

### Expose RPi directly (port forwarding)
**Rejected**: Requires ISP support for static IP or DDNS; requires router NAT rule; TLS not automatic. More fragile than Cloudflare Tunnel.

---

## Consequences

### Positive
- Zero cost for hosting
- HTTPS/WSS out of the box — browser WebSocket requirement satisfied
- No router configuration needed
- Swift version and ARM architecture fully under developer control
- Simple systemd service keeps tunnel alive during judging window

### Negative
- If the RPi powers off, the game is unavailable — developer must keep it on during judging window
- Cloudflare Tunnel requires an outbound internet connection from the RPi
- Quick-start tunnel (`--url` flag) gives a temporary URL valid for ~24h; persistent tunnel requires a free Cloudflare account

### Neutral
- Docker on ARM64 requires `arm64v8/` base images — this is standard and well-supported
- `node-pty` native addon compiles correctly in Alpine Linux with standard build tools
