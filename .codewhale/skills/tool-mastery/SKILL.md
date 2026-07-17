---
name: tool-mastery
description: MANDATORY. Decision matrix for every tool — when to use which, anti-patterns, Windows bridges. Frontier tool use.
---

# Tool Mastery — decision matrix

## Golden rule

**Lowest token cost that fully solves the step.** Prove with output, not claims.

## Built-in tools

| Tool | Use when | Never use when |
|------|----------|----------------|
| `grep_files` | Find symbols, imports, references | You already know exact path |
| `glob` | Find files by name pattern | Content search |
| `read_file` | Need file content; always offset/limit on large files | Whole repo sweep |
| `write_file` | New file OR >30% rewrite | 2-line tweak |
| `apply_patch` | ≤10 line surgical fix | Rewriting entire component |
| `edit_file` | Same as patch — **only after `read_file` this session** | Full rewrites; never without prior read |
| `exec_shell` | Run tests, rm, git bridge scripts, heredoc writes | Simple read |
| `agent` | 2–3 independent files in parallel | Single-file fix |
| `task_create` | Blocked shell or >60s background | Trivial probes |
| `git_status/log/diff` | Quick repo state | Push (use bridge) |
| `remember` | Durable fact for future sessions | Ephemeral debug |
| `web_search` | External docs/APIs | Localhost health |

## MCP tools

| Server | Prefix | Use |
|--------|--------|-----|
| memory | `mcp_memory_*` | Persist facts to knowledge graph |
| chrome-devtools | `mcp_chrome-devtools_*` | UI debug, console, network, snapshot |
| chrome-devtools-remote | same | When CDP :9222 already open |
| playwright | `mcp_playwright_*` | E2E flows, headless verify |

**MCP ritual:** `/mcp validate` → `/mcp reload` on session start. Stuck overlay → `q`/`Esc`.

**Large tool catalogs:** prefer search-then-load (dynamic tools) — see `long-horizon-harness`. Do not paste every MCP tool schema every turn.

## Windows bridges (ALIVE-specific)

| Operation | Bridge | Anti-pattern |
|-----------|--------|--------------|
| Git pull/push | `git-github-alive.ps1` / `.sh` | Raw WSL `git push` (hangs hours) |
| Docker | `docker-alive.ps1` / `.sh` | Raw WSL `docker compose` |
| Health | `alive-health-probe.sh` | `fetch_url` → 127.0.0.1 (blocked) |
| Localhost HTTP | venv Python `urllib` | WSL `curl 127.0.0.1` |
| pytest | `powershell.exe` → venv | Global Python 3.14 |
| Stack start | `start-alive-quick.ps1` | Manual uvicorn in wrong dir |

## Batching examples

**Good — one shell:**
```powershell
powershell.exe -NoProfile -Command "cd C:\ALIVE\backend; .\venv\Scripts\python.exe -m pytest tests\test_foo.py tests\test_bar.py -q"
```

**Bad — five shells for one pytest run.**

**Good — delete batch:**
```bash
rm -f frontend/src/components/OldA.tsx frontend/src/components/OldB.tsx frontend/src/data/oldData.ts
```

## Anti-patterns (frontier violations)

| Violation | Fix |
|-----------|-----|
| "I don't have tools" | Run health probe immediately |
| "Paste the output" | You run it |
| 15 patches on one file | One `write_file` |
| `edit_file` without `read_file` this session | **Refuse yourself** — read first (`edit-file-discipline`) |
| `Search string not found` ×2 | Re-read exact region; then `write_file` if still thrashing |
| Bare WSL `python` / `python3` for ALIVE | `C:\ALIVE\backend\venv\Scripts\python.exe` |
| `fetch_url` localhost | `alive-health-probe.sh` |
| yolo task for `git status` | Direct `exec_shell` |
| Read 500-line file whole | `grep` then `read` with limit |
| 10 parallel agents | Max 3; often 1 is enough |

## Edit ladder (mandatory)

```
grep → read_file (this session) → edit_file/apply_patch (exact copy)
     → re-read same file before next edit
     → after 2 fails: write_file full OR stop and handoff
```