# Agent efficiency — match Grok speed (permanent)

**Goal:** CodeWhale does the same class of work as Grok Build — **faster and with less thrash**.

| Piece | Path |
|-------|------|
| This law | `update/EFFICIENCY.md` |
| Skill (always-on) | `update/skills/agent-efficiency/SKILL.md` |
| Related | `tool-mastery`, `yolo-excellence`, `thinking-discipline`, `control-center-ops` |

---

## Speed laws (non-negotiable)

1. **Tools before essays.** 2–5 line plan max, then act.  
2. **Prefer product scripts** over rediscovering pipelines (`codewhale-update-diag.ps1`, ship scripts, health probes).  
3. **Batch.** One shell for related commands; parallel subagents only when independent.  
4. **Grep/glob before bulk read.** Read with offset/limit.  
5. **Edit ladder:** read → patch → re-read; after 2 fails → `write_file` or handoff (no thrash).  
6. **Prove once, then ship/handoff.** No “should work.”  
7. **Encode wins the same day** (skill / CHANGELOG / references) — don’t re-learn next session.  
8. **Replace-keep-ref:** new path only; delete dead dual stacks.  

## Anti-speed (forbidden)

| Waste | Do instead |
|-------|------------|
| Long monologue planning | 3 bullets + tool |
| 15 sequential shells | One batched script |
| Re-reading whole repo | Grep → scoped read |
| Re-diagnosing Update from scratch | `codewhale-update-diag.ps1` |
| Dual old+new code | `replace-keep-ref` |
| Asking user to run tools you can run | You run them |
| Bare WSL python for ALIVE | Windows venv path |

## Default loop (fast)

```
SCOPE (30s grep) → PLAN (checklist if 3+ files) → EXECUTE (batch) → PROVE → SHIP/LEARN
```

*Loaded every session via ParityFix always_on + startup rule 13.*
