---
name: permission-lanes
description: >
  Codex-style permission lanes without paid lock-in. Use when user says read-only,
  read lane, edit only, no push, ship lane, safer mode, or restrict tools.
  Default product remains full YOLO unless user names a lane.
user-invocable: true
---

# Permission lanes (competitive parity)

Close the gap with Codex **profiles** using simple named lanes.  
**Default:** full agent (YOLO) — you asked for power. Lanes are opt-in.

## Lanes

| Lane | User phrases | Allowed | Forbidden |
|------|--------------|---------|-----------|
| **read** | read-only, diagnose only, no edits | read, grep, glob, shell probes that don’t mutate, health | write/edit/patch, ship, delete product files |
| **edit** | implement, fix, but don’t push | everything in read + edit/write/tests | git push, force, production deploy |
| **ship** | ship it, push, full | edit + identify + task-ship | secrets, git add ., SKIP paths |

## Behavior

1. If user names a lane → **state it once** (`Lane: edit`) and obey for the rest of the task.  
2. If a forbidden action is required → stop, say what lane blocks it, ask to switch.  
3. **Safe Update / SafeGuard** still apply (never trash ALIVE product trees).  
4. Leaving lane: user says “full YOLO” / “ship lane” / “unrestricted”.  

## Done bar

- [ ] Lane named in status  
- [ ] No forbidden side effects  
- [ ] If blocked, clear upgrade path stated  
