---
name: codewhale-update-ops
description: >
  CodeWhale Update panel agents: WorkCleaner, BinaryUpdater, SkillsSync, CompetitiveIntel,
  FrontierScout. Clear old work fast; no sudo; free frontier gate before acquire.
user-invocable: true
---

# CodeWhale update operations

## Launch

`C:\Users\chris\CodeWhale\Launch-CodeWhale-Update.bat`

## Agents (must stay visible in log)

| Agent | Does |
|-------|------|
| SafeGuard | Snapshot + verify ALIVE/CodeWhale product canaries — **fail Update if product code changes** |
| ReplaceKeepRef | **Permanent.** Ensure replace-keep-ref law+skill always present (new wins; delete old; small ref) |
| CompetitiveEnsure | **Permanent.** WIN-CONDITIONS + scorecard + efficiency stack + Startup seamless/frontier |
| FunctionalReady | **Final gate every run.** Startup bat, re-seed ALIVE/ALIVE_APPLE/workspace, APPLE product files, BootProve, posture, seamless UI, CompetitiveEnsure again — fail Update if not FUNCTIONAL |
| WorkCleaner | `scripts/codewhale-clear-old-work.ps1` — temp logs only; **refuses product deletes** |
| BinaryUpdater | `scripts/codewhale-self-update.sh` → `~/.local` npm, no sudo |
| SkillsSync | `codewhale-skills-sync.ps1` — managed docs + new skills + Grok mirror (never corrupt cores) |
| CompetitiveIntel | stream `COMPETITIVE-UPDATE.md` free grabs |
| FrontierScout | `codewhale-frontier-scout.ps1` — deep dive registry; **no download**; stars untrusted alone |
| ParityFix | **Always.** Apply `update/PARITY-MANIFEST.json` → live WSL config (Pro + high + skills). Now and every future Update |
| BootProve | Instructions load path exists + order (SEQUENCE/BOOT first) |
| ModelWarmer | health every run; optional deep warm |
| StatusReporter | version check |

**Law after download:** `RESULT fail=0` and `UPDATE-FUNCTIONAL-STATUS Result=FUNCTIONAL` or Update is not done.

## Parity (permanent Update law)

| Path | Role |
|------|------|
| `update/PARITY.md` | Human policy |
| `update/PARITY-MANIFEST.json` | Defaults + skill list (future changes go here) |
| `scripts/codewhale-parity-fix.ps1` | Apply + verify |

**Future:** new always-on skill → add to package + `PARITY-MANIFEST` `core_skills` (or keep `include_manifest_new_skills: true`) → next **Run update** wires live config.

## Safe Update (never damage ALIVE or CodeWhale product)

| Path | Role |
|------|------|
| `update/SAFE-UPDATE.md` | Policy |
| `update/SAFE-UPDATE-MANIFEST.json` | Canaries + deny lists |
| `scripts/codewhale-safe-update-guard.ps1` | Snapshot / Verify / AssertWrite |

Product code under `C:\ALIVE\backend|frontend|data|...` is **never** an Update write target. Only `.codewhale/` harness.

## Replace-keep-ref (permanent function)

| Path | Role |
|------|------|
| `update/REPLACE-KEEP-REF.md` | Law |
| `update/skills/replace-keep-ref/` | Always-on skill via ParityFix |
| `scripts/codewhale-replace-keep-ref-ensure.ps1` | Every Update verifies function still exists |
| `update/references/` + project `.codewhale/references/` | Small recovery notes |

If ensure fails, Update fails — function cannot silently vanish.

## Competitive intel file

`C:\Users\chris\CodeWhale\COMPETITIVE-UPDATE.md`  
Refresh when user asks about Qwen / ChatGPT / Cursor / Claude Code.

## Frontier acquire (before anything new enters Update)

| Path | Role |
|------|------|
| `update/FRONTIER-ACQUIRE.md` | Policy law |
| `update/FRONTIER-REGISTRY.json` | WATCH / PROVISIONAL / ADOPT / REJECT |
| `update/skills/frontier-acquire/SKILL.md` | Agent skill |
| `scripts/codewhale-frontier-scout.ps1` | Scout agent |

**Default = wait-and-see (WATCH).** Only **proven better** free options become ADOPT and then the update.

## Grok up-to-speed (safe mirror)

| Path | Role |
|------|------|
| `C:\Users\chris\CodeWhale\update\` | Source of truth |
| `C:\Users\chris\.grok\codewhale-update\` | Grok read mirror (overwrite OK) |
| `C:\Users\chris\.grok\skills\edit-file-discipline\` | New skill only |
| `C:\Users\chris\.grok\skills\thinking-discipline\` | New skill only |

**Never** overwrite: Grok `analyze-fix`, `retrieval-intent`, office skills, `config.toml`, `auth.json`.

## Free grabs to keep implementing

- Plan mode before multi-file edits  
- Named agents in status  
- Local Qwen coder MoE when available  
- Permission profiles (read / edit / ship)  

## Never

- Password/sudo install  
- Conflate with ALIVE update  
