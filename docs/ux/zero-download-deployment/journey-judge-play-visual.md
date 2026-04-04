# Journey Map — Judge Plays Ember's Escape Without Installing

**Feature**: zero-download-deployment
**Persona**: DCJam 2026 judge
**Scenario**: Judge receives a jam submission URL and plays the game in their browser

---

## Journey Overview

```
[Receive URL] → [Open Browser] → [Terminal Loads] → [Play Game] → [Submit Rating]
      ↑               ↑                 ↑                ↑               ↑
   No friction    One click         Instant         Identical         No residue
```

---

## Detailed Journey

### Step 1 — Receive submission link
**Judge action**: Sees submission on DCJam 2026 page, clicks the "Play in browser" link  
**System**: Browser opens `https://embersescape.example.com` (or equivalent hosting URL)  
**Emotion**: Neutral → slight curiosity  
**Expected output**: Page loads within 3 seconds  
**Failure mode**: Link is dead, page 404s  
**Success signal**: xterm.js terminal renders in browser viewport

---

### Step 2 — Terminal initialises
**Judge action**: Waits for connection  
**System**: WebSocket connects to server; Swift game process spawns (or resumes from pool); start screen renders  
**Emotion**: Curious → engaged  
**Expected output**: Start screen with title art, key bindings, and "Press any key" prompt visible within 2 seconds of page load  
**Failure mode**: WebSocket connection refused; server overloaded; terminal renders blank  
**Success signal**: Full 80×25 start screen visible, game controls listed

---

### Step 3 — Play the game
**Judge action**: Types WASD / number keys as shown on start screen  
**System**: Browser captures keydown events → sends over WebSocket → Swift game processes → renders ANSI frame → WebSocket sends back → xterm.js renders  
**Emotion**: Engaged  
**Expected output**: < 100 ms input-to-frame latency (imperceptible for turn-paced play)  
**Failure mode**: Key input not registering; rendering corruption; game crashes  
**Success signal**: Smooth dungeon navigation; combat, overlays, minimap all visible

---

### Step 4 — Session ends
**Judge action**: Wins, dies, or closes the tab  
**System**: WebSocket closes; server-side game process ends cleanly; no persistent state left  
**Emotion**: Satisfied (win/death) or neutral (tab close)  
**Expected output**: No error on server; server ready for next connection  
**Failure mode**: Zombie processes accumulate; server OOMs after N sessions  
**Success signal**: Can re-open URL and start a fresh game immediately

---

## Emotional Arc

```
Skeptical     Curious       Engaged       Satisfied
(will this    (oh, it's     (actual       (that worked
 even work?)   loading)      game!)        perfectly)
    ●─────────────●────────────●──────────────●
  Step 1       Step 2       Step 3         Step 4
```

Target: Judge reaches **Engaged** by Step 3 with zero friction moments.

---

## Shared Artifacts

| Artifact | Owner | Notes |
|---|---|---|
| Hosting URL | Developer | Must be live during judging window |
| WebSocket server | Server (Docker container) | Spawns one Swift process per connection |
| xterm.js page | Browser | Thin HTML/JS page; no build required for judge |
| Swift executable | Docker image | Unchanged from local build |

---

## What the Judge Does NOT Experience

- No download prompt
- No "install Swift" instruction
- No terminal configuration
- No port 23 firewall issues (WebSocket runs on port 80/443 over HTTP)
- No WASM loading screen (pure browser approach would add this)
