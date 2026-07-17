# CodeWhale thinking process — diagnosis & permanent fixes

**Updated:** 2026-07-15/16  
**Source:** Live TUI logs + session `08f98d17` (medical/deep-analysis job) + prior sessions  
**Purpose:** Make thinking finish work; stop thrash; teach harness permanently

---

## What CodeWhale was bad at (evidence)

| Failure | Evidence | Cost |
|---------|----------|------|
| **edit_file without read** | `Refusing edit_file … has not been read in this session` on `api.ts`, `Launch-ALIVE-Pro.ps1` | Wasted turns; stalled frontend |
| **Stale search strings** | `Search string not found` on `orchestrator.py` after own edits | Re-read loops; slow multi-hunk work |
| **WSL bare python** | `python: command not found` in WSL shell | Fake “can’t run RAG checks” |
| **Long plan, late ship** | Checklist at 50% mid-session; many thinking blocks before prove | User sees stall in thinking panel |
| **Historical: approval lock** | Session `8a3df169` auto_deny storm | Fixed by approval-unblock + YOLO launch |
| **Historical: raw WSL git push** | `terminal prompts disabled` / hung push | Fixed by Windows git bridge + safe-ship |

---

## Permanent skills added (NOW)

| Skill | Role |
|-------|------|
| **`edit-file-discipline`** | Read before edit; re-read after edit; max 2 failed patches → write_file |
| **`thinking-discipline`** | Timebox plan; checklist; act with tools; no monologue loops; finish or handoff |

Also tightened: `tool-mastery`, `yolo-excellence`, `windows-shell-pitfalls`, `FRONTIER.md`, `JUDGE.md`, constitution v3.5.

---

## Thinking rules (quick card — copy into new sessions)

```
1. SCOPE: grep + HANDOFF (≤1 round)
2. PLAN: checklist_write 3–8 items
3. DO: tools first after plan (not more essays)
4. EDIT: read_file → edit_file (exact string) → re-read same file
5. FAIL×2 on edit: write_file full OR handoff — no thrash
6. PYTHON: C:\ALIVE\backend\venv\Scripts\python.exe only for ALIVE
7. VERIFY: pytest / health probe
8. SHIP: codewhale-ship-identify + codewhale-task-ship
9. STUCK: STATE + HANDOFF after 2 retries — Grok finishes if locked
```

---

## Future (only if pain returns)

| Item | Trigger |
|------|---------|
| Auto-inject “read before edit” at engine level (product) | If discipline skill still ignored often |
| Live agent labels in chat thinking header | User wants Qwen-Code-style roster |
| Plan-mode hard gate before multi-file | User asks for forced plan UI |
| Session “% complete” sticky footer in TUI | Product change; not skill-only |

See `FUTURE-BACKLOG.md`.

---

## How to use

CodeWhale loads skills via `~/.codewhale/config.toml` + project BOOT.  
User does **not** need to name skills — `skill-auto-router` + startup prompt apply them.

Tracker index: `C:\Users\chris\CodeWhale\update\README.md`
