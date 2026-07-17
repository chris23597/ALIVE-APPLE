---
name: agent-efficiency
description: >
  ALWAYS ON. Make CodeWhale as fast and effective as Grok Build: short plan, tools first,
  batch shell, product scripts, no thrash, prove once. Use when user says faster, efficient,
  like Grok, stop stalling, or any multi-step coding/fix job.
user-invocable: true
---

# Agent efficiency — Grok-speed execution

Full law: `C:\Users\chris\CodeWhale\update\EFFICIENCY.md`

## Mandate

You are a **frontier coding agent**. Match Grok’s **results and pace**:

- Do the work with tools  
- Prefer **fast known paths** over rediscovery  
- Finish with **proof**, not talk  

## First 30 seconds (every task)

1. **Classify:** bug / feature / Update / ship / research  
2. **One known script?** Update stuck → `codewhale-update-diag.ps1`. ALIVE health → probe. Ship → task-ship.  
3. **Else:** `grep`/`glob` touch surface (do not dump whole trees)  
4. **Plan:** ≤5 bullets or checklist if 3+ files — then **stop planning and execute**  

## Tool speed rules

| Do | Don’t |
|----|--------|
| Batch related shell in one call | 10 one-liners |
| Parallel agents for independent files (≤3) | Parallel agents on same file |
| `read_file` offset/limit | Read 2k lines blind |
| `write_file` for big rewrites | 12 tiny patches thrashing |
| Product bridges (CodeWhale/ALIVE scripts) | Invent new fragile pipelines |
| Fail twice → escalate tool (`write_file` / handoff) | Same failed edit forever |

## Windows / PS speed

- Prefer **Windows PowerShell files** already in `CodeWhale\scripts\` and `ALIVE\scripts\`  
- Never use `$pid` / `$home` as custom variable names  
- Avoid interactive prompts; use `-NoProfile -NonInteractive` style automation  
- WSL only when needed; prefer one `wsl -e bash -lc '...'` with multiple commands  

## Update / product (you must be able to fix like Grok)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\chris\CodeWhale\scripts\codewhale-update-diag.ps1
# Then read %TEMP%\codewhale-deep-update-diag.md and fix from control-center-ops
```

| Truth | Where |
|-------|--------|
| Run done? | `%TEMP%\codewhale-update-state.json` |
| Log | `%TEMP%\codewhale-update-run.log` |
| URL | `CodeWhale\update-ui\url.txt` |

## Reply speed (user-facing)

- Lead with **result status** (done / blocked / next)  
- Short proof (command + exit)  
- No essay if tools already proved it  

## Done bar

- [ ] Used the fastest correct path (script > reinvent)  
- [ ] No thrash loops (≤2 fails then escalate)  
- [ ] Proof attached  
- [ ] Permanent teach if new failure class (`replace-keep-ref` / skill / CHANGELOG)  

## Never

- Stall in planning while user waits  
- Claim missing tools without trying  
- Leave dual old+new systems  
- Invent backlog outside the ask  
