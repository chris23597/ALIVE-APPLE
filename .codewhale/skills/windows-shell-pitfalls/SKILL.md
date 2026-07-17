---
name: windows-shell-pitfalls
description: >
  Windows PowerShell + WSL gotchas that break ALIVE/CodeWhale automation. $pid, locks, stderr noise, paths.
user-invocable: true
---

# Windows shell pitfalls

## PowerShell

| Bad | Good |
|-----|------|
| `$pid = $proc.Id` | `$procId = $proc.Id` (`$PID` is read-only) |
| Assume `D:` always USB | Resolve by label / BusType USB + size |
| Kill nothing then rename chroma | Free `:8000` first, then rename |
| Treat uvicorn INFO on stderr as crash | Check process still listening; red INFO is often noise |

## Locks

```powershell
Get-NetTCPConnection -LocalPort 8000 -State Listen -EA SilentlyContinue |
  ForEach-Object { Stop-Process -Id $_.OwningProcess -Force -EA SilentlyContinue }
```

## Paths

- Prefer `C:\ALIVE\...` from Windows PowerShell.
- WSL: `/mnt/c/ALIVE/...` only for **read** or non-Chroma tools.
- Desktop logs: `%USERPROFILE%\Desktop\ALIVE-startup.log`, `%TEMP%\alive-backend-launch.log`

## USB eject

Safely eject after writes. Dirty FAT32 → `chkdsk X: /f` (we did this for WIN11-REC).
