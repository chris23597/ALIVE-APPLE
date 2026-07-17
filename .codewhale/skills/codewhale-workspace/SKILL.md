---
name: codewhale-workspace
description: >
  CodeWhale workspace path, browse folder, ship target, CODEWHALE_WORKSPACE, not ALIVE unless set.
user-invocable: true
---

# CodeWhale workspace

## Sources (priority)

1. User Browse in app / `workspace-path.txt`  
2. `$env:CODEWHALE_WORKSPACE`  
3. Default `C:\Users\chris\CodeWhale\workspace`  

## Rules

- Ship only the **git** workspace user selected.  
- Don’t assume ALIVE.  
- Create dir if missing before chat.  
- App: `scripts/codewhale-app.ps1`
