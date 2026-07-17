---
name: task-ship
description: MANDATORY after EVERY CodeWhale task on a git workspace. Sync MD, SAFE GitHub push, Docker if available. Not ALIVE's ship.
user-invocable: true
---

# Task-ship (CodeWhale only)

**CodeWhale and ALIVE are separate.** This skill ships the **workspace CodeWhale is editing**, not the ALIVE product pipeline.

```powershell
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-task-ship.ps1 -Repo $env:CODEWHALE_WORKSPACE -LastDone "what you finished" -Next "none"
```

For the **ALIVE product**, use ALIVE's own script (do not call CodeWhale ship for ALIVE maintenance unless the user set workspace to ALIVE intentionally):

```powershell
powershell -File C:\ALIVE\scripts\codewhale-task-ship.ps1 -LastDone "what you finished"
```

Never: WSL git push, `git add .`, skip identify.
