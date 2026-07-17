# ALIVE APPLE — HANDOFF

```
PROJECT HANDOFF
Date:      2026-07-17
HEAD:      (local scaffold — confirm git if initialized)
Branch:    (n/a or main)
Tests:     not run (Swift needs Xcode/macOS for full build)
Harness:   CodeWhale portable v4.0 (agent-os)
Workspace: C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE

LAST_DONE: Filled agent-os FEATURES/HANDOFF; system prompt; empty-chat + design tokens; Fast path uses system prompt + honest on-device demo until llama.cpp linked on Mac
IN_FLIGHT: none
NEXT:      F4 real Fast-tier GGUF (Mac/Xcode + llama.cpp Metal) — highest product leverage
BLOCKED:   Full on-device Metal/llama build cannot complete on Windows-only host
FEATURE:   F4 next
DO_NOT_REDO: PRD/ARCHITECTURE/scaffold structure already good — don't rewrite whole app

IF_STUCK:  codewhale-task-ship.ps1 -Repo this path; or handoff Grok with this file
```

## Product truth

- **ALIVE APPLE** = iPhone 16 on-device agent (SwiftUI).  
- **Windows ALIVE** = separate product; reference only.  
- InferenceEngine still uses a **structured demo stream** when llama.cpp is not linked; comments mark the real eval loop for Mac builds.

## Open a NEW CodeWhale chat after Update so global SEQUENCE/BOOT load.
