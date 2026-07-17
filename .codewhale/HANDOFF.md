# ALIVE APPLE - HANDOFF

```
PROJECT HANDOFF
Date:      2026-07-17
HEAD:      b2dc9c1
Branch:    main
Tests:     GitHub Actions GREEN — Build ALIVE APPLE for iPhone 16 (run 29601643084); IPA artifact ALIVE_APPLE_iPhone16
Harness:   CodeWhale portable v4.0 (agent-os)
Workspace: C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE

LAST_DONE: CI green on main — fixed actor-isolated demo token helpers (nonisolated + stream outside @Sendable timeout); Actions build archive + IPA upload success
IN_FLIGHT: none
NEXT:      (user-owned) install IPA from Actions artifact / device QA when ready
BLOCKED:   none for Windows-side CI
FEATURE:   CI build lane closed green
DO_NOT_REDO: Do not re-break InferenceEngine demo helpers isolation without a new Actions error log

IF_STUCK:  re-download Actions logs; codewhale-task-ship.ps1
```

## CI truth

- Workflow: `.github/workflows/build.yml` (macos-latest, unsigned archive → IPA)
- Green run: https://github.com/chris23597/ALIVE-APPLE/actions/runs/29601643084
- Artifact: **ALIVE_APPLE_iPhone16**
