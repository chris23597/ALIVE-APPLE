---
name: frontier-product-ui
description: >
  Build publication-quality local product UIs for CodeWhale Update. Use when UI
  looks cheap, vibe-coded, primitive, or user wants professional update panel.
  Prefer HTML/CSS/JS + local API. Restrained design, not sci-fi dashboards.
user-invocable: true
---

# Publication-quality product UI

## Product principle

**This is an Update tool.** Primary action = Run update.  
Chat, skills browser, logs, force/warm → **Settings menu**, not main stage.

## Architecture (required)

```
C:\Users\chris\CodeWhale\
  update-ui\
    index.html      # structure only
    styles.css      # design system
    app.js          # API client + live state
  scripts\
    codewhale-update-server.ps1   # HttpListener + static + API
    codewhale-update-run.ps1      # plan + implement + state JSON
  Launch-CodeWhale-Update.bat
```

## Design bar (publication-worthy)

### Do

- Neutral dark base (`#0b0f14` / `#12181f`)  
- One accent (gold `#d4a84b`) used sparingly  
- Inter (UI) + IBM Plex Mono (paths, counts, badges)  
- 8px spacing rhythm, 10–12px radius max  
- Clear hierarchy: header → status → primary CTA → stats → agents → table  
- Activity as a **real table** (state / step / detail / time)  
- Full text selection, resizable browser window  

### Do not

- Sci-fi copy ("mission", "command", "flight log", "aurora")  
- Heavy glassmorphism, animated orbs, noise overlays  
- Emoji as icons (use simple SVG)  
- Crowding every control on the main screen  
- WinForms for the primary Update experience  

## Main screen layout

```
[Logo] CodeWhale Update          [status] [menu]
Status: …     Resource: …
[ Run update ]  [ Launch chat ]

Total | Completed | In progress | Remaining | Overall %

Agents (6 cards with IDLE/RUNNING/DONE)

Activity table
```

## Frontend state machine

1. On load → `GET /api/status` → fill plan counts + activity  
2. Run update → `POST /api/update/start` → poll `/api/update/state`  
3. Map timeline rows → agent tiles via step id  
4. On `done:true` → enable buttons, show complete/fail  

## When user says "looks like vibe coding"

1. Strip decorative effects  
2. Tighten type/spacing  
3. Keep function identical  
4. Re-prove with browser load + update run  

## Reference

Current ship: `update-ui/*` (restrained Inter console) + server/run scripts above.
