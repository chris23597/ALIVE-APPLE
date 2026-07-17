---
name: frontier-acquire
description: >
  Gate any new model, skill pack, CLI, or agent pattern before it enters CodeWhale Update.
  Use when user says frontier, free best models, stars, GitHub skills, download into update,
  compare before install, wait-and-see, cutting edge free, or "should we add X".
  Deep dive first. Stars/reviews untrusted alone. Default WATCH. Only proven better becomes the update.
user-invocable: true
---

# Frontier acquire (deep dive before Update)

## Product law

- **Model-agnostic.** User is not tied to any brand. See `BEST-ALWAYS.md`.  
- Stay **ahead of the curve** with **proven outcomes** only.  
- **If proven better → that is the update** (registry + PARITY-MANIFEST). Demote losers.  
- **Agent scouts and compares before any download** into the Update module.  
- **GitHub stars and reviews can be manipulated** — never promote on popularity alone.  
- **Wait-and-see is often correct.** Default state = **WATCH**.

Full policy: `C:\Users\chris\CodeWhale\update\FRONTIER-ACQUIRE.md`  
North star: `C:\Users\chris\CodeWhale\update\BEST-ALWAYS.md`  
Registry: `C:\Users\chris\CodeWhale\update\FRONTIER-REGISTRY.json`  
Scout: `C:\Users\chris\CodeWhale\scripts\codewhale-frontier-scout.ps1`

## When (auto-apply)

| Signal | Action |
|--------|--------|
| “Add this skill/repo/model” | Scout + scorecard; do not install yet |
| “What’s the best free model now” | Read registry + competitive intel; prefer ADOPT/WATCH notes |
| Bulk awesome lists / star rankings | REJECT path via skill-synthesis |
| Update now | FrontierScout step already enforces gate |
| Something new looks better | Deep dive → PROVISIONAL → soak → ADOPT only with proof |

## States

`SIGNAL → WATCH → PROVISIONAL → ADOPT | REJECT`

| State | Install into `update/`? |
|-------|-------------------------|
| WATCH / PROVISIONAL / SIGNAL | **No** |
| REJECT | **No** |
| ADOPT | **Yes** — recreate skill, doc model tag, or script pattern |

## Deep-dive checklist (required)

1. **License/cost** — free for our product path?  
2. **Job fit** — real CodeWhale job?  
3. **Compare** — name 1–2 alternatives  
4. **Anti-hype** — discount stars/reviews; seek independent or first-hand proof  
5. **Safety** — no curl\|sh, no secret exfil, no bulk dumps  
6. **Reproduce** — one paragraph: what we would actually ship  
7. **Soak** — models/tools: prefer re-scout or local smoke before ADOPT  
8. **Non-duplicate** — check existing skills/scripts  

Scorecard in `FRONTIER-ACQUIRE.md` (≥10/14 + no hard fail for ADOPT).

## Agent procedure

```
1. Load FRONTIER-REGISTRY.json
2. Add SIGNAL row if new candidate (state WATCH)
3. Run codewhale-frontier-scout.ps1 (or fill scorecard manually)
4. Compare peers in writing
5. Verdict: stay WATCH | PROVISIONAL | ADOPT | REJECT
6. If ADOPT skill/pattern → skill-synthesis recreate into update/skills/
7. If ADOPT model → document only (warm tag); do not vendor multi-GB weights
8. CHANGELOG + registry update + SkillsSync
9. Never SkillsSync foreign zips
```

## Hard rejects

- Paid-only as required free path  
- curl \| bash installers  
- 1000-skill dumps  
- Star-only justification  
- Overwrite Grok cores / secrets  

## Pair with

| Skill | Role |
|-------|------|
| `skill-synthesis` | Recreate skill content after ADOPT |
| `codewhale-update-ops` | Update agents including FrontierScout |
| `competitive-edge` | Market map (not install) |
| `prove-before-done` | Local smoke before calling model “best” |
| `no-invent-backlog` | Do not mass-adopt “nice to have” |

## Done bar

- [ ] Candidate scored (not vibes)  
- [ ] Stars explicitly discounted  
- [ ] Verdict written to registry or report  
- [ ] No files downloaded into Update unless ADOPT  
- [ ] If ADOPT: recreate/docs + CHANGELOG + sync  

## Never

- “It has 50k stars so install it”  
- Bulk acquire into update module “to be ready”  
- Skip wait-and-see on release-day hype  
- Claim frontier best without compare + proof  
