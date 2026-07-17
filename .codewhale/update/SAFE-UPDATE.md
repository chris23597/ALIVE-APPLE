# Safe Update — never kill or damage product projects

**Law:** CodeWhale **Update must not break, delete, or rewrite product code** for:

- **ALIVE** (`C:\ALIVE`) — the offline prep product  
- **CodeWhale** (`C:\Users\chris\CodeWhale`) — the agent/Update product  

You do not need to remember how. **Update enforces this automatically.**

**Shared module:** `scripts/codewhale-safe-path.ps1`  
**Manifest:** `update/SAFE-UPDATE-MANIFEST.json`  
**Guard:** `scripts/codewhale-safe-update-guard.ps1`  
**Cleaners:** WorkCleaner + CleanObsolete (both use SafePath)

---

## What Update may touch

| Zone | Allowed? | What |
|------|----------|------|
| Temp logs (`%TEMP%\codewhale-*`) | Yes | WorkCleaner |
| `~/.codewhale` / `~/.grok` **skills** (agent homes) | Yes | SkillsSync + CleanObsolete (foreign only) |
| `~/.grok/codewhale-update` mirror | Yes | Docs mirror |
| Project **`.codewhale/`** only | Yes | Agent harness (not app source) |
| Entire `C:\ALIVE\**` | **NO** for cleaners | Product frozen |
| CodeWhale `scripts/`, `update/`, `update-ui/` | **NO** for cleaners | Package source protected |
| `.env`, docker-compose* | **NO** | Secrets / deploy |

---

## Update pipeline order (correct)

```
1 SafeGuard SNAPSHOT     — canaries first
2 WorkCleaner            — temp only (SafePath)
3 BinaryUpdater
4 SkillsSync             — package becomes truth in agent homes
5 Project harness seed
6 CleanObsolete          — SelfTest then -Clean -Force foreign skills only
7 Intel / Scout / Parity / …
N SafeGuard VERIFY       — fail if canaries moved
```

CleanObsolete runs **after** SkillsSync so “best” = current package, not a half-synced home.

---

## Is-SafePath / Test-CodeWhaleSafeToDelete

`$true` = cleaner **may** delete. `$false` = **PROTECTED**.

Blocks (non-exhaustive — full list from SAFE-UPDATE-MANIFEST):

```
C:\ALIVE\**                          (all product)
C:\Users\chris\CodeWhale\scripts
C:\Users\chris\CodeWhale\update
C:\Users\chris\CodeWhale\update-ui
.env  .env.local  docker-compose.yml  docker-compose.prod.yml
```

Prove anytime:

```powershell
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-clean-obsolete.ps1 -SelfTest
```

---

## Best only (CleanObsolete) — correct definition

**Keep** a skill folder if **any** of:

1. Present under **`update/skills/`** (`package_skills` in MANAGED-MANIFEST)  
2. Listed in MANAGED-MANIFEST / PARITY always-on  
3. FRONTIER-REGISTRY **`kind` = skill|pattern** and **`state` = ADOPT**  
4. Hard cores (analyze-fix, agent-os, skill-synthesis, …)  
5. Name starts with `alive-` or `codewhale-`  
6. Seeded under ALIVE `.codewhale/skills`  

**Wrong definition (never use):**  
“Keep only FRONTIER-REGISTRY ADOPT model ids.” That deletes the real package.

**Remove only:** foreign skill folders in agent homes that match **none** of the keep rules.

```powershell
# Scan
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-clean-obsolete.ps1
# Update path (no prompt) — only after SelfTest
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-clean-obsolete.ps1 -SelfTest
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-clean-obsolete.ps1 -Clean -Force
```

---

## WorkCleaner rules

May delete only temp CodeWhale logs (not active run logs), stale `last-chat.env.cmd`, empty workspace agent junk.  
Uses same SafePath module — refuses ALIVE + product trees.

---

## Project seed rules (ALIVE + CodeWhale)

- Writes **only** under `<repo>\.codewhale\`  
- Never touches Chroma DB, manuals, `.env`, venv, node_modules, backend/frontend  

---

## Manual SafeGuard

```powershell
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-safe-update-guard.ps1 -Mode Snapshot
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-safe-update-guard.ps1 -Mode Verify
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-safe-update-guard.ps1 -Mode Status
```
