---
name: skill-auto-router
description: >
  ALWAYS ON. Auto-select and apply skills from symptoms without user saying skill names.
  Read CodeWhale/update/AUTO-ROUTING.md. Seamless operation.
user-invocable: true
---

# Skill auto-router (ALWAYS APPLY)

## Mandate

You **already have** all project skills loaded.  
**Never** require the user to say “use skill X”.

On every user message about work:

1. Match symptoms using the table in  
   `C:\Users\chris\CodeWhale\update\AUTO-ROUTING.md`  
   (also `~/.codewhale/update/AUTO-ROUTING.md` if synced).
2. **Silently** apply the matching skill playbook(s).
3. Optionally one short status line: e.g. `Playbook: Windows Chroma ingest`.
4. If multiple match, order: **safety** (secrets) → **repro** → **fix** → **prove** → **ship**.

## Always-on filters

- Greetings / non-questions → **retrieval-intent** (no KB spam).
- About to commit/push → **secrets-never-ship** + ship skill.
- ALIVE + python/chroma → force **Windows venv** doctrine from **alive-backend-fix**.
- Multi-file → **codewhale-plan-mode** first.
- Any edit/patch → **edit-file-discipline** (read this session first).
- Multi-step work → **thinking-discipline** + **live-checklist**.
- `Search string not found` / `has not been read` → recovery in **edit-file-discipline**.
- Replace/cleanup old code / dual stack → **replace-keep-ref** (new wins; delete old; small reference).
- Faster / efficient / like Grok → **agent-efficiency** (tools first; scripts; batch).
- Multi-day / continue tomorrow / FEATURES.md / context died → **agent-os** + **session-handoff**.
- Multi-hour / swarm / large MCP catalog / loses plot → **long-horizon-harness**.
- Mythos / Fable / Kimi / top of the line / best stack → **agent-os** + **long-horizon-harness** + `BEST-STACK-NOW.md` (harness over brand).
- Model refuse / rate limit / empty thrash → **agent-os** fallback chain.
- Look at CodeWhale / help it along / stuck Update → **codewhale-session-assist**.
- GitHub Actions / CI failed / IPA / check main build → **github-actions-finish** (not F4 unless user asks).

## Forbidden

- “Tell me which skill to use”  
- Ignoring a matching playbook because user didn’t name it  
- Inventing backlog from FUTURE-BACKLOG without user ask  

## Tracker paths

| Path | Role |
|------|------|
| `C:\Users\chris\CodeWhale\update\` | Source of truth tracker |
| `SKILLS-TRACKER.md` | Inventory |
| `FUTURE-BACKLOG.md` | Optional later |
| `RULES.md` | 30-min rule, standing policy |

## Optional later (do not start unless asked or pain returns)

CompassTool-native · Gmail OAuth · fleet multi-PC · full plan-mode UI in ALIVE product.
