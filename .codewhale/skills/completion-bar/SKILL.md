---
name: completion-bar
description: MANDATORY before claiming done. Frontier completion criteria by task type — proof required.
---

# Completion Bar — frontier "done"

**Done = verified proof, not intention.**

## By task type

| Type | Required proof |
|------|----------------|
| **Backend code** | `pytest -q` pass (scoped or full) + re-read changed files |
| **Frontend code** | Above + TypeScript builds OR Chrome MCP snapshot on `:5173` + console clean |
| **Full-stack feature** | pytest + UI verify + API health 200 |
| **Delete/refactor** | `grep` confirms no orphan imports + pytest pass |
| **Harness/config** | File written + `codewhale doctor` OK + upgrade script if skills changed |
| **Start/run** | `alive-health-probe.sh` → backend 200 + frontend 200 |
| **Push/deploy** | `codewhale-task-ship.ps1` success + `git log -1` matches origin |

## Proof format (reply template)

```
DONE — <one line summary>
- Tests: 177 passed (pytest -q)
- Files: N changed (list key paths)
- Git: <sha> pushed / not requested
- UI: console clean / n/a
```

## NOT done (never claim)

- Tests not run
- "Should work" / "likely fixed"
- Partial checklist (3 of 13 steps)
- User asked to run commands you could run
- Known failing test ignored
- Pushed without running tests

## Multi-step jobs

Use checklist. **100% complete** or report exactly what's left:

```
BLOCKED at step 7/13: <reason>
Files done: <list>
Files remaining: <list>
Next: <exact command or handoff>
```

## Self-improvement

If you claimed done and were wrong:
1. Fix the code
2. Append row to `JUDGE.md` Permanent fixes
3. Patch the relevant skill so it never repeats