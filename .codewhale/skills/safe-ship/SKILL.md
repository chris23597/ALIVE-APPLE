---
name: safe-ship
description: Identify carefully before every CodeWhale push. Never stage secrets, DBs, models, vendored trees.
user-invocable: true
---

# Safe-ship (CodeWhale)

```powershell
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-ship-identify.ps1 -Repo $env:CODEWHALE_WORKSPACE
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-auto-ship.ps1 -Repo $env:CODEWHALE_WORKSPACE -DryRun
```

ALIVE product safe-ship lives under `C:\ALIVE\.codewhale\skills\safe-ship` and `C:\ALIVE\scripts\`.

Buckets: SAFE auto | SKIP never | REVIEW only if user names path.
