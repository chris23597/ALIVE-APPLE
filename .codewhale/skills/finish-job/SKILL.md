---
name: finish-job
description: MANDATORY when a multi-step job stalls, tools are denied, or Grok handoff is needed. How CodeWhale completes work without loops or fluff.
---

# Finish the job — no loops, no fluff

## CodeWhale movement log (VPN job — learn from this)

| Phase | Session | What happened |
|-------|---------|---------------|
| Plan | `8a3df169` ("update") | Grepped codebase, planned 13 steps, read billing/api files |
| Blocked | `8a3df169` | `write_file`, `exec_shell`, `apply_patch`, `task_create` all **denied** — stale approval gate |
| Fix | Grok | `codewhale-approval-fix.sh` + fresh `codewhale-alive.sh` (YOLO) |
| Done | `2dc966fa` | Full deletes + rewrites, pytest 177 pass, pushed `1f4eab4` |

## Best practice tool use (user preference)

| Change size | Tool |
|-------------|------|
| New file or >30% rewrite | `write_file` with **complete file** — not fragment patches |
| 1–10 line fix | `apply_patch` or `edit_file` |
| Delete files | `exec_shell` `rm` or `git rm` in one batch |
| Multi-file job | `task_create` checklist → execute in dependency order |

**Wrong:** 15 `apply_patch` calls on the same file. **Right:** one `write_file` with the finished component.

## When tools are denied (max 2 attempts)

1. Tell user once: quit TUI, do **not** resume stale session
2. User runs: `bash /mnt/c/ALIVE/scripts/codewhale-approval-fix.sh` then `codewhale-alive.sh`
3. Fresh session → `/mcp reload` → retry **once**

If still denied after restart:

- Stop looping. Use `read_file` / `grep_files` to capture plan + file list.
- Write handoff to `.codewhale/STATE.md` (what's done, what's blocked, exact paths).
- Tell user: **Grok Build will finish from Cursor** — do not claim job is impossible.

## Job completion checklist (every multi-file task)

1. `grep` scope — list all touch points
2. Delete obsolete files first (avoids import errors)
3. Rewrite dependents (imports, routes, api.ts)
4. `pytest -q` — must pass before push
5. `codewhale-auto-ship.sh` or `codewhale-handoff.sh` — **MANDATORY** (auto-pushes safe paths)
6. `docker-alive.sh up -Detached` if user asked for Docker
7. Update `.codewhale/STATE.md` HEAD + one-line summary

## Grok ↔ CodeWhale handoff

- Grok reads `.codewhale/HANDOFF.md` and `.codewhale/STATE.md`
- Grok finishes blocked writes, updates harness, pushes
- CodeWhale reads sync file on next boot — never redo completed work