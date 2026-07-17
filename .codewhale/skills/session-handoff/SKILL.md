---
name: session-handoff
description: >
  Compress session state into a short HANDOFF packet for a new chat or agent.
  Use when user says handoff, continue later, new session, context full, or
  switch to Grok/CodeWhale. Recreated from popular Handoff skill patterns.
user-invocable: true
---

# Session handoff (portable)

## When

- Context compaction risk  
- User switches agents (CodeWhale ↔ Grok)  
- Multi-day work  
- "where were we?"

## Packet format (max ~20 lines)

Write/update project `.codewhale/HANDOFF.md` top fence:

```
PROJECT HANDOFF
Date:      YYYY-MM-DD
HEAD:      <git log -1 --oneline>
Branch:    <status vs origin>
Workspace: <absolute path>
Tests:     <last proof or not run>
Harness:   CodeWhale portable

LAST_DONE: <one line>
IN_FLIGHT: <one line or none>
NEXT:      <user-owned only or none>
BLOCKED:   <or nothing>
DO_NOT_REDO: <short list>
IF_STUCK:  task-ship then Grok / finish-job
```

## Rules

- **NEXT** only user-requested (`no-invent-backlog`)  
- Prefer facts from git/tests over memory  
- After meaningful work: refresh via `codewhale-task-ship.ps1` or handoff script  
- Never dump entire chat — compress  

## Cross-agent

| To | Read |
|----|------|
| Grok | `.codewhale/HANDOFF.md` + `~/.grok/codewhale-update/` |
| CodeWhale | BOOT + HANDOFF + STATE |

## Done bar

- HANDOFF.md updated  
- User can paste one block into a new session and resume without re-explaining  
