---
name: yolo-excellence
description: MANDATORY in YOLO mode. Frontier execution doctrine — best tool choice, batching, verification, shipping. Loaded every session.
---

# YOLO Excellence — frontier execution

YOLO means **pre-authorized**, not **careless**. Execute like a staff engineer with full shell access.

## Mindset

| YOLO is | YOLO is NOT |
|---------|-------------|
| Decisive execution | Spray-and-pray patches |
| Batched shell ops | 20 sequential one-liners |
| Full-file rewrites when warranted | 15 fragment patches on one file |
| Verify then ship | "Should work" |
| Self-correct once | Loop forever on same error |

## Execution phases

### 1. Scope (30 seconds, saves hours)

```bash
# Example: "remove feature X"
grep -r "feature_x\|FeatureX" frontend/src backend/app --include="*.{ts,tsx,py}" -l
```

Read `STATE.md` and any domain skill (`vpn-removed`, `alive-project`) before planning.

### 2. Plan (multi-file jobs)

Order: **delete obsolete → edit imports/routes → rewrite components → tests → ship**

For 3+ files: **`checklist_write` immediately** (see `live-checklist` skill). Update after every step.  
For background work: `task_create` with linked checklist items.

### 3. Execute (batch intelligence)

**One `exec_shell` for related ops:**

```bash
# Delete + verify gone
rm -f path/a.tsx path/b.tsx && ls path/ 2>&1
```

**Parallel `agent` only when files are independent** (max 3).

**Full component rewrite → `write_file` with complete file.**  
**≤10 line fix → `apply_patch` / `edit_file` only after `read_file` this session.**  
**Never** 10 patches on the same file.  
**After every successful edit on path P → re-read P before another edit on P** (`edit-file-discipline`).

### 4. Verify (non-negotiable)

```powershell
powershell.exe -NoProfile -Command "cd C:\ALIVE\backend; .\venv\Scripts\python.exe -m pytest tests\ -q --tb=no"
```

Re-read every changed file. UI changes → Chrome MCP snapshot + console check.

### 5. Identify → Ship (SAFE only)

```powershell
powershell.exe -File C:\ALIVE\scripts\codewhale-ship-identify.ps1
powershell.exe -File C:\ALIVE\scripts\codewhale-task-ship.ps1 -LastDone "fix: concise" -Next "none"
# Docker only if user needs containers running — not required for every task
```

Never `git add .`. Never stage SKIP (DBs, secrets, screenshots, models).

## Tool choice in YOLO

| Task | Best tool |
|------|-----------|
| Find references | `grep_files` / `glob` |
| Understand context | `read_file` offset/limit |
| New file or >30% rewrite | `write_file` (complete) |
| Small fix | `apply_patch` |
| Delete files | `exec_shell` `rm` batch |
| Run tests/build | `exec_shell` powershell → venv |
| Independent multi-file | `agent` × ≤3 |
| UI verify | `mcp_chrome-devtools_*` |
| Long job >60s | `exec_shell` background=true |

## `task_create(yolo)` — only when

- Approval gate blocks `exec_shell` (rare after `codewhale-alive.sh`)
- Background job >60s
- **Never** for `ls`, `git status`, single pytest, health probe

Params: `mode="yolo", allow_shell=true, auto_approve=true`

## Self-correction

| Failure | Action |
|---------|--------|
| Test fail | Read traceback → fix root cause → re-run (max 2 fix cycles) |
| Tool denied | `approval-unblock` → quit → relaunch (max 2 attempts) |
| `edit_file` refuse / search not found | Re-read exact region → max 2 retries → `write_file` or handoff |
| `python: command not found` | Use Windows venv path — never bare WSL python for ALIVE |
| Import error after delete | Fix dependents you missed in scope grep |
| Same error 3× | Stop; document in `STATE.md`; handoff to Grok |

## Reply discipline (frontier + copy-paste)

See `copy-paste-flow` skill. Summary:
- **STATUS block first** (progress bar + done/next + HEAD)
- One-line takeaway
- **Same STATUS block last** — user copies without scrolling
- Run `codewhale-handoff.sh` after job steps
- Wrong once → patch harness permanently (`JUDGE.md` + skill)