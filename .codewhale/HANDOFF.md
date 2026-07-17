# ALIVE APPLE - HANDOFF

```
PROJECT HANDOFF
Date:      2026-07-17
HEAD:      (see git log)
Branch:    main
Tests:     GitHub Actions iOS build (watch Actions tab); full device needs Xcode/Mac
Harness:   CodeWhale portable v4.0 (agent-os)
Workspace: C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE

LAST_DONE: Swift 6 concurrency/CI compile thrash finished locally — withTimeout @Sendable, VisionService loadItem, ModelManager/ChatMessage Sendable; removed broken .agents/skills WSL junction from repo; main on GitHub with workflow scope
IN_FLIGHT: none
NEXT:      F4 real Fast-tier GGUF (Mac/Xcode + llama.cpp Metal) OR confirm GH Actions build green on latest main
BLOCKED:   Full on-device Metal/llama build cannot complete on Windows-only host
FEATURE:   F4 next (product); compile-fix lane closed on Windows
DO_NOT_REDO: Do not re-open endless Sendable/Observable thrash without a new Xcode error log; do not re-add .agents WSL junctions to git

IF_STUCK:  codewhale-task-ship.ps1 -Repo this path; or handoff Grok with this file
```

## Product truth

- **ALIVE APPLE** = iPhone 16 on-device agent (SwiftUI).
- **Windows ALIVE** = separate product; reference only.
- InferenceEngine still uses a **structured demo stream** when llama.cpp is not linked; comments mark the real eval loop for Mac builds.
- Push requires PAT scopes: **repo** + **workflow** (because `.github/workflows/build.yml`).

## Open a NEW CodeWhale chat after Update so global SEQUENCE/BOOT load.
