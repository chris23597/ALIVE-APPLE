---
name: skill-synthesis
description: >
  Evaluate third-party agent skills from the web. Use when user asks to add skills,
  install Claude/Codex/Qwen skills, browse awesome-skills lists, or "make CodeWhale
  better than Grok". Prefer recreate over blind install. Reject junk and secrets risks.
user-invocable: true
---

# Skill synthesis (recreate > clone)

## Mandate

Do **not** bulk-install random GitHub skill packs.  
**Stars and reviews can be manipulated** — never justify install on popularity alone.  
Pair with skill **`frontier-acquire`** (deep dive → WATCH default → ADOPT only when proven).  
Analyze → keep idea / recreate / reject. Ship only high-signal SKILL.md into:

- `C:\Users\chris\CodeWhale\update\skills\`
- project `.codewhale\skills\`
- `~/.codewhale\skills\` via SkillsSync

## Evaluation scorecard (need ≥4/6 to recreate)

| Criterion | Pass if |
|-----------|---------|
| **Trigger clarity** | description says when to load (not marketing fluff) |
| **Actionable steps** | tables, commands, done-bar — not vibes |
| **Portable** | works any project, not one vendor lock-in |
| **Safe** | no exfil, no blind curl\|sh, no secrets in skill |
| **Non-duplicate** | we do not already have equivalent |
| **Proves value** | would have prevented a real past failure |

## Recreate pattern (always)

```
update/skills/<name>/SKILL.md
---
name: <name>
description: >  # trigger phrases for auto-router
  ...
---
# Title
## When
## Steps
## Done bar
## Never
```

Then:

1. Add name to `update/MANAGED-MANIFEST.json` portable list if core  
2. Line in `update/CHANGELOG.md`  
3. Row in `update/SKILLS-TRACKER.md`  
4. Route in `update/AUTO-ROUTING.md`  
5. `codewhale-skills-sync.ps1` or Control Center **Update now**

## Web sources (read-only research)

Worth watching patterns (not blind install):

- agentskills.io open standard (SKILL.md)  
- Qwen Code: plan mode + subagents + approvalMode  
- "Handoff" skills → compact session packets  
- "Grill me" / plan interview → force clarity before code  
- Karpathy-style surgical change rules  
- Superpowers/GStack → role workflows (recreate thin versions only)

**Reject by default:** media generators needing paid APIs, AWS-only toolkits (unless user on AWS), 1000-skill "awesome" dumps, skills that only say "be helpful".

## Security

| Red flag | Action |
|----------|--------|
| curl \| bash install | refuse |
| Asks for API keys in skill body | refuse / secrets-never-ship |
| Overwrites global agent config | refuse |
| Huge vendored trees | skip |

## CodeWhale vs Grok parity

If Grok built a durable system (Control Center, portable seed, ship pipeline):

1. Encode as skill + scripts in CodeWhale home  
2. Do not leave knowledge only in chat  
3. Prove with commands after teaching  

## Done bar

- Scorecard filled for each candidate  
- Recreated skills installed OR explicit REJECT with reason  
- update/ folder current  
- Sync run without corrupting Grok protected cores  
