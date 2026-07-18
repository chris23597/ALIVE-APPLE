# ALIVE APPLE - HANDOFF (session save)

```
PROJECT HANDOFF
Date:      2026-07-17
HEAD:      046d9ef (main, CI green)
Branch:    main
Tests:     GitHub Actions GREEN run 29603151139; IPA artifact ALIVE_APPLE_iPhone16
Harness:   CodeWhale portable v4
Workspace: C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE

LAST_DONE: BM25 RAG (no CoreML/Mac); CI green; IPA downloaded; Sideloadly installed; iPhone seen on USB — user paused before Apple ID sign-in
IN_FLIGHT: none (paused by user)
NEXT:      Resume Sideloadly install of ALIVE_APPLE.ipa to iPhone (user enters Apple ID in Sideloadly UI only — never paste password in chat)
BLOCKED:   Needs user Apple ID + Trust This Computer on phone; free sideload ~7 days
FEATURE:   RAG BM25 shipped; F4 llama still Mac-only (do not invent unless asked)
DO_NOT_REDO: CoreML EmbeddingModel conversion; re-add broken llama.cpp SPM pin 0.0.4107; commit WSL .agents junctions

IF_STUCK:  codewhale-session-health.ps1; codewhale-actions-prove.ps1; open Desktop ALIVE_APPLE.ipa + Sideloadly
```

## Paths

| Item | Path |
|------|------|
| Repo | `C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE` |
| IPA | `C:\Users\chris\Desktop\ALIVE_APPLE.ipa` and `%USERPROFILE%\Downloads\ALIVE_APPLE_iPhone16\ALIVE_APPLE.ipa` |
| Sideloadly | `%LOCALAPPDATA%\Sideloadly\sideloadly.exe` |
| Actions green | https://github.com/chris23597/ALIVE-APPLE/actions/runs/29603151139 |
| GitHub | https://github.com/chris23597/ALIVE-APPLE |

## Resume checklist (later)

1. Unlock iPhone, USB, Trust computer
2. Open Sideloadly, drag IPA, select phone
3. Apple ID email+password **only in Sideloadly**
4. Phone: Settings → General → VPN & Device Management → Trust
5. Launch ALIVE APPLE

## Product truth

- RAG = **BM25** (no Mac CoreML)
- IPA = unsigned CI build; Sideloadly re-signs
- Do not store Apple passwords in chat/scripts