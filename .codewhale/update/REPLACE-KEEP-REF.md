# Replace → keep new → delete old → small reference

**Permanent Update + agent law (now and forever).**  
Not optional polish. Same class as `SAFE-UPDATE.md` and `BEST-ALWAYS.md`.

| Piece | Path |
|-------|------|
| This law | `update/REPLACE-KEEP-REF.md` |
| Skill (always-on) | `update/skills/replace-keep-ref/SKILL.md` |
| Recovery notes | `update/references/` and project `.codewhale/references/` |
| RULES | `RULES.md` item **0c** |
| Live load | `PARITY-MANIFEST.json` → `always_on_skills` includes `replace-keep-ref` |
| Update check | agent **ReplaceKeepRef** in every Run update |

---

## The function (one paragraph)

Whenever something is changed **for the better**: the **new path is the only live path**, the **old live references are deleted** (call sites, dual flags, dead modules), and a **small recovery reference** is kept so a useful scrap from the old can be found if needed later. Never run two full systems “just in case.”

---

## Always do

1. Prove the new path.  
2. Grep and remove old live uses.  
3. Write thin ref under `references/` (or CHANGELOG section).  
4. Ship / handoff notes say what replaced what.

## Never do

- Leave old + new both active without user order.  
- Delete non-trivial old with **zero** breadcrumb.  
- Dump entire old trees into archive forever.  
- Touch ALIVE/CodeWhale **product** code outside allowlists while “cleaning” (`SAFE-UPDATE`).

---

## Permanent enforcement

| Layer | How |
|-------|-----|
| Every chat | Skill in always-on instructions via ParityFix |
| Auto-route | Symptom table in `AUTO-ROUTING.md` |
| Every Update | ReplaceKeepRef step verifies skill + law present |
| Every project seed | `.codewhale/references/README.md` created |
| Package | MANAGED-MANIFEST + SkillsSync |

If the skill or law file is missing, **Update fails** that step so the function cannot silently disappear.

---

## Reference template (short)

```markdown
# Reference: <old> (removed YYYY-MM-DD)
## Why removed
## Live path now
## If you need a piece of the old
## Snippet (optional, max ~40 lines)
## Do not re-enable dual stack without proof
```

---

*This is standing product function. Do not demote to optional backlog.*
