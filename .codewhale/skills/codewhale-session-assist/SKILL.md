---
name: codewhale-session-assist
description: >
  Look at live CodeWhale (Update UI + engine + stamps), decide if it is healthy,
  mid-run, or needs help; push it to completion error-free. Use when user says
  look at CodeWhale, what is it doing, help it along, finish update, is it stuck,
  error free, into completion, or "watch the update".
user-invocable: true
---

# CodeWhale session assist (live health → completion)

## Goal

When the user asks about **their running CodeWhale**, do not guess from memory:

1. **Read live truth** (state / log / stamps / HTTP)  
2. **Classify** HEALTHY | IN_PROGRESS | NEEDS_HELP  
3. **Help along** only if needed (heal, re-run fail step, start UI)  
4. **Prove** fail=0 + FUNCTIONAL / READY  
5. **Teach** permanent fix into skills/CHANGELOG if a new failure class appeared  

## One-shot script (always first)

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\chris\CodeWhale\scripts\codewhale-session-health.ps1
# If issues:
powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\chris\CodeWhale\scripts\codewhale-session-health.ps1 -Heal
```

Report: `%TEMP%\codewhale-session-health.md`

Deep Update diag (UI ports / HTTP):

```powershell
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-update-diag.ps1
```

## Truth table (do not invent)

| Source | Meaning |
|--------|---------|
| `%TEMP%\codewhale-update-state.json` `done=true fail=0` | **Update completed successfully** |
| Log line `RESULT done=N fail=0` | Same |
| Timeline step `FAIL` | That agent needs fix + re-run |
| Timeline `RUNNING` + old timestamp | Likely hung → kill update-run PID only, re-run engine |
| `UPDATE-FUNCTIONAL-STATUS.txt` `Result=FUNCTIONAL` | Post-download gate green |
| `SEAMLESS-STATUS.txt` `Result=READY` | Logon/UI/boot path green |
| `update-ui\url.txt` | **Only** browser URL to open |
| HTTP FAIL on that URL | Restart `Launch-CodeWhale-Update.bat` |

## Help-along playbook

| Situation | Action |
|-----------|--------|
| HEALTHY fail=0 FUNCTIONAL | Tell user complete; open **NEW** chat; do not re-run whole Update unless asked |
| IN_PROGRESS | Wait; poll state every ~30s; do not kill unless hung >10 min |
| UI down, engine done | Start server / seamless-boot `-StartUpdateUi` or `-Heal` |
| One step FAIL (e.g. compete) | Fix root cause script, re-run that script, then full `codewhale-update-run.ps1` to prove 16/16 |
| BootProve FAIL | SkillsSync + ParityFix + BootProve (session-health `-Heal` does this) |
| SafeGuard FAIL | **Stop** — product canary changed; investigate SAFE-UPDATE before force |
| Stale READY stamp (>36h) | `codewhale-ready.ps1` or session-health `-Heal` |
| Workspace = CodeWhale product root | Point `workspace-path.txt` at ALIVE_APPLE / ALIVE / workspace |

## ALIVE APPLE / git finish tips (learned 2026-07-17)

| Symptom | Fix |
|---------|-----|
| Push rejected: workflow `.github/workflows/*` | PAT needs **`workflow`** + `repo` (user must edit on github.com/settings/tokens) |
| `git` error `cannot hash .agents/skills` / `Function not implemented` | WSL junction to `~/.codewhale/skills` — **never commit**. `rmdir` junction, `git rm --cached`, add `.agents/` to `.gitignore` |
| Endless “fix last Sendable error” commits | Stop thrash: one clear compile log, one fix commit, push; do not re-open without new Xcode/CI error |
| Update HEALTHY but product dirty | Finish **git** job separately: status → commit remaining → push → scrub token from `origin` URL |
| User wants **GitHub Actions / CI / IPA** | Hand off to skill **`github-actions-finish`** + `scripts/codewhale-actions-prove.ps1` — do **not** invent F4/Mac product work |

### Route table (pick the real job)

| User intent | Skill / script |
|-------------|----------------|
| Look at CodeWhale / Update stuck | This skill + `codewhale-session-health.ps1` |
| Actions red / check main build / IPA | **`github-actions-finish`** + `codewhale-actions-prove.ps1` |
| Push blocked on workflow scope | User edits PAT; then push; scrub remote URL |

## Never

- Claim “looks fine” without state + HTTP or session-health proof  
- Kill System PID 4 to free ports  
- Delete live `codewhale-update-state.json` mid-run  
- Invent backlog outside finishing the live job  
- Conflate ALIVE product updates with CodeWhale Update  
- Commit WSL reparse points / agent home symlinks into product repos

## Pair with

- **`github-actions-finish`** — CI diagnose → fix → push → poll green (ALIVE-APPLE IPA lane)  
- `control-center-ops` — deep Update UI/engine surgery  
- `codewhale-update-ops` — agent table (FunctionalReady final gate)  
- `prove-before-done` — show commands + exit codes  
- `finish-job` — if blocked after 2 heals, write HANDOFF + stop thrashing  

## Reply shape (user-facing)

```
DOING: <what CodeWhale is doing now>
VERDICT: HEALTHY | IN_PROGRESS | NEEDS_HELP
PROOF: state fail= / FUNCTIONAL / UI URL
HELPED: <what you fixed, or none>
NEXT: open NEW chat | wait | re-run Update
```
