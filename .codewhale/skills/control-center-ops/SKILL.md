---
name: control-center-ops
description: >
  Run, fix, and deeply diagnose CodeWhale Update (Control Center UI + engine).
  Use for Update stuck, blank, hang, wrong port, timeline not moving, API timeout,
  Launch-CodeWhale-Update, SkillsSync UI, agents, Run update. Do not only explain —
  run diag + fix + prove like Grok would.
user-invocable: true
---

# CodeWhale Update — operations (permanent)

## What this product is

**CodeWhale Update** = local web app that **scans, plans, and implements** updates  
(binary, skills, seed, intel, scout, parity, replace-keep-ref, SafeGuard).

## Launch

```bat
C:\Users\chris\CodeWhale\Launch-CodeWhale-Update.bat
```

Keep the PowerShell server window open. Open **only** the URL in `update-ui\url.txt`  
(usually `http://127.0.0.1:8787/` — port may be 8788+ if busy).

| Piece | Path |
|-------|------|
| UI | `update-ui/` |
| Server | `scripts/codewhale-update-server.ps1` |
| Engine | `scripts/codewhale-update-run.ps1` |
| Deep diag | `scripts/codewhale-update-diag.ps1` |
| State | `%TEMP%\codewhale-update-state.json` |
| Log | `%TEMP%\codewhale-update-run.log` |

---

## When user says stuck / blank / can’t see / not working

**Do this yourself (CodeWhale must match Grok depth):**

### 1. Deep diagnostic (always first)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\chris\CodeWhale\scripts\codewhale-update-diag.ps1
```

Read report: `%TEMP%\codewhale-deep-update-diag.md`

### 2. Map truth vs UI

| Source of truth | Meaning |
|-----------------|---------|
| `state.json` `done=true fail=0` | **Engine succeeded** even if browser looks frozen |
| Log `RESULT done=N fail=0` | Same |
| HTTP FAIL all ports | Server dead → restart launcher |
| url.txt port ≠ browser | User on wrong port |
| `/api/log` fail but `/api/update/state` ok | Log lag only; show timeline from state |
| `/api/status` >3s | Hang risk; caches / skip nested work |

### 3. Fix playbook

| Symptom | Fix |
|---------|-----|
| No server | `Launch-CodeWhale-Update.bat` |
| Wrong port | Open exact `url.txt` URL; hard refresh Ctrl+F5 |
| State done but UI Idle | Hard refresh; poll uses state — check Activity table |
| SkillsSync FAIL parse | Fix `codewhale-skills-sync.ps1` parse; re-run engine |
| SafeGuard FAIL | Product canary changed — investigate before force; see SAFE-UPDATE |
| Engine hang | Kill stuck `codewhale-update-run` powershell; re-run engine headless |
| UI hang on complete | Ensure app.js does not await slow status after done (fetch timeouts) |
| Shows **N remaining** after success | Bug was treating next-plan `neededCount` as remaining — fix `applyRunCounts` / scan last-run branch; remaining must be 0 when `done=true` |

### 4. Headless prove (no browser required)

```powershell
# Plan
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-update-run.ps1 -PlanOnly

# Full update
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-update-run.ps1

# APIs (use port from url.txt)
Invoke-RestMethod http://127.0.0.1:8787/api/update/state
Invoke-RestMethod http://127.0.0.1:8787/api/status
```

### 5. Done bar (must show proof)

- [ ] diag report written  
- [ ] state `done` + `fail` explained to user  
- [ ] HTTP `/` and `/api/update/state` OK or restart proven  
- [ ] If engine failed, step name + log line + fix applied  
- [ ] Teach permanent fix in skill/CHANGELOG if new class  

**Never** say “looks fine” without state + HTTP proof.

---

## User flow (happy path)

1. Open Update → scan (`GET /api/status`)  
2. **Run update** → `POST /api/update/start`  
3. UI polls `GET /api/update/state` ~400ms  
4. Engine writes state after each step  
5. Complete: status Complete, bar 100%, SafeGuard green  

## API

| Method | Path | Role |
|--------|------|------|
| GET | `/` `app.js` `styles.css` | UI |
| GET | `/api/status` | plan scan (cached; must stay fast) |
| GET | `/api/update/state` | live run truth |
| GET | `/api/log` | tail of engine log (shared read, never hang) |
| POST | `/api/update/start` | start engine |
| POST | `/api/workspace` `/api/browse` | workspace |
| POST | `/api/launch` | chat |

## Critical engineering rules

1. Never redirect engine stdout without draining — deadlock  
2. Never delete live `codewhale-update-state.json` or SafeGuard snapshot mid-run  
3. PlanOnly never writes into live state while busy — use plan file  
4. Never use `$pid` / `$home` as custom vars in PS  
5. Bind 127.0.0.1 only  
6. Log API: `FileShare.ReadWrite` + size cap  
7. UI fetch: AbortController timeouts  
8. Permanent functions every run: SafeGuard, ParityFix, ReplaceKeepRef  

## Permanent Update agents

WorkCleaner → SafeGuard snap → Binary → SkillsSync → Seed → Intel → Scout → ParityFix → ReplaceKeepRef → SafeGuard verify → Warm?

## Pair with

- **`codewhale-session-assist`** — user says “look at CodeWhale / help it along / finish” → run `codewhale-session-health.ps1` first  
- `codewhale-update-ops` — agent table (includes FunctionalReady)  
- `SAFE-UPDATE` — product canaries  
- `replace-keep-ref` — cleanup when fixing dual systems  
- `prove-before-done` — always show commands  

## Never

- Tell user to “just refresh” without reading state/log  
- Claim stuck when `done=true fail=0` (explain complete + refresh URL)  
- Kill System PID 4 when freeing ports  
- Invent backlog outside Update fix  
