# CodeWhale Update folder — track skills & future work

**Purpose:** Single place to keep track of playbooks for **this project (ALIVE/CodeWhale)** and the **next**.  
CodeWhale loads these automatically via skills + startup rules — **you do not need to invoke skill names**.

| File | What it is |
|------|------------|
| **`BEST-ALWAYS.md`** | **North star:** model-agnostic; proven outcomes only; no brand loyalty |
| **`SAFE-UPDATE.md`** | **Protect ALIVE + CodeWhale product** — Update cannot kill app code |
| `SAFE-UPDATE-MANIFEST.json` | Canary files + deny lists for SafeGuard |
| **`REPLACE-KEEP-REF.md`** | **Permanent function:** new wins; delete old; small recovery ref |
| **`EFFICIENCY.md`** | **Grok-speed:** tools first, batch, product scripts, no thrash |
| **`WIN-CONDITIONS.md`** | Honest: not #1 everywhere — #1 for *your* free proof-gated harness |
| `skills/replace-keep-ref/` | Always-on skill (ParityFix) for that function |
| `references/` | Thin recovery notes after cleanup (not dual product) |
| `AUTO-ROUTING.md` | Symptom → skill (auto-apply; seamless) |
| `SKILLS-TRACKER.md` | Full skill inventory + status |
| `THINKING-PROCESS.md` | Live diagnosis of thinking thrash + permanent fixes |
| `COMPETITIVE-SKILLS-INTEL.md` | Web skills: recreate vs reject; CodeWhale vs Grok gap |
| `FRONTIER-ACQUIRE.md` | Deep-dive gate before anything enters Update (free + proven) |
| `FRONTIER-REGISTRY.json` | WATCH / PROVISIONAL / ADOPT / REJECT ledger |
| `PARITY.md` | Grok-parity permanent Update law |
| `PARITY-MANIFEST.json` | Live agent defaults + skill list (ParityFix applies every run) |
| `skills/frontier-acquire/` | Skill: scout before download; stars untrusted alone |
| `FUTURE-BACKLOG.md` | Later work (optional / when pain returns) |
| `RULES.md` | Standing rules (30-min skill rule, etc.) |
| `COMPETITIVE-UPDATE.md` | Symlink/copy note → `../COMPETITIVE-UPDATE.md` |
| `CHANGELOG.md` | What we taught when |
| `MANAGED-MANIFEST.json` | What Update mode may force-write (safe list) |
| `skills/` | Packaged **new** skills for SkillsSync |

## Deploy (safe)

```powershell
# Dry-run first
powershell -NoProfile -File C:\Users\chris\CodeWhale\scripts\codewhale-skills-sync.ps1 -DryRun

# Real sync → CodeWhale homes + Grok mirror + new Grok skills only
powershell -NoProfile -File C:\Users\chris\CodeWhale\scripts\codewhale-skills-sync.ps1

# Prove protected Grok files unchanged
powershell -NoProfile -File C:\Users\chris\CodeWhale\scripts\codewhale-skills-sync-test.ps1
```

Or: **Launch-CodeWhale-Update.bat** → leave **SkillsSync** checked → Run.

**Grok up-to-speed folder:** `C:\Users\chris\.grok\codewhale-update\`  
Protected (never touched): analyze-fix, retrieval-intent, docx/pptx/xlsx, config.toml, auth.

**Also live under:** `~/.codewhale/skills/`, `C:\ALIVE\.codewhale\skills\`, curriculum `~/.codewhale/SKILLS-CURRICULUM.md`.

## Rule (permanent)

> If a fix burns **> 30 minutes once** → extract/update a skill **the same day**.

## Seamless use

CodeWhale must **auto-select** skills from context (see `AUTO-ROUTING.md` + skill `skill-auto-router`).  
User never needs: “Use alive-backend-fix…”.
