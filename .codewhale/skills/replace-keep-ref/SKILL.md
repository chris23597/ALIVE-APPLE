---
name: replace-keep-ref
description: >
  When improving code, keep the new path and delete old references/call sites.
  Keep only a small recovery reference in case old pieces are needed later.
  Use for cleanup, refactor, replace feature, remove dual stack, delete dead code,
  "don't leave both", "archive old", or upgrade path A to B.
user-invocable: true
---

# Replace → delete old → keep small reference

**Permanent function** (now + future): law `update/REPLACE-KEEP-REF.md`, always-on via ParityFix, Update agent **ReplaceKeepRef** every Run update.

## Product law

When you change something **for the better**:

1. **Keep the new** as the only live path.  
2. **Delete the old** (call sites, dual flags, dead branches, obsolete files).  
3. **Keep a small reference** — enough to fix/recover if something from the old is needed.  
4. **Do not** leave two full systems running “just in case.”

## Why

| Leave full old + new | Small reference only |
|----------------------|----------------------|
| Confusion, bugs, double maintenance | One clear path |
| Agent and human pick the wrong one | Recoverable if proven needed |
| Context bloat | Thin archive |

## Steps (mandatory)

### 1. Scope

- Grep/glob every use of the **old** name/path/API.  
- List files that will die vs stay.

### 2. Land the new

- New implementation complete and **proven** (test/command/UI).  
- No “new half-wired, old still required for happy path.”

### 3. Remove the old (cleanup)

Delete or stop using:

- Old functions/components/routes that nothing calls  
- Feature flags that only exist to pick old vs new  
- Duplicate configs, dead imports, obsolete docs that teach the old path as current  

**Do not** rename old to `_old` and leave it imported.

### 4. Small reference (required)

Create **one** thin recovery note (pick the best place):

| Prefer | Path example |
|--------|----------------|
| Project harness | `.codewhale/references/<topic>.md` |
| CodeWhale package (if product-wide) | `update/references/<topic>.md` |
| Already have JUDGE/CHANGELOG | Short section + link, not a second codebase |

**Reference must include:**

```markdown
# Reference: <old thing> (removed YYYY-MM-DD)

## Why removed
<one sentence — what is better now>

## Live path now
<path or symbol of the new system>

## If you need a piece of the old
- What: <specific useful bit>
- Where it lived: <old path>
- How to recover: git history / snippet below (keep SHORT)

## Snippet (optional, max ~40 lines)
... only the critical fragment, not the whole module ...

## Do not
- Re-enable dual stack without user ask + proof new is worse
```

**Size rule:** reference is a **fix aid**, not a second product. Prefer “git log path” over pasting 500 lines.

### 5. Teach permanently

- Line in `CHANGELOG` or project HANDOFF: what replaced what.  
- If this class of cleanup will recur for CodeWhale itself → this skill already covers it.  
- Update AUTO-ROUTING only if a new permanent symptom appears.

## Done bar

- [ ] New path is the only runtime path (grep shows no live old usage)  
- [ ] Old dead code removed (not commented-out piles)  
- [ ] Small reference file or CHANGELOG/JUDGE section exists  
- [ ] Proof: test/command still passes  
- [ ] User-facing docs don’t still teach the old path as current  

## Never

- Keep old + new both active “for safety” without user order  
- Delete with **zero** recovery breadcrumb when the old was non-trivial  
- Dump entire old tree into `archive/` forever without summarizing  
- Break ALIVE/CodeWhale product trees outside `.codewhale` during “cleanup” (see `SAFE-UPDATE`)  

## Pair with

| Skill | Role |
|-------|------|
| `surgical-change` | Small focused diffs |
| `prove-before-done` | Prove new before deleting old |
| `no-invent-backlog` | Don’t open rewrite of unrelated systems |
| `safe-ship` | Don’t stage secrets/junk while cleaning |
| `edit-file-discipline` | Read before delete/edit |

## Example (Update product)

| Change | New | Old removed | Small ref |
|--------|-----|-------------|-----------|
| Safe Update | SafeGuard snapshot/verify | — | `SAFE-UPDATE.md` |
| Grok parity | PARITY-MANIFEST driven config | Stale “local Qwen is default” startup | CHANGELOG + BEST-ALWAYS |
| Lean skills | always_on ~16 | Bulk 40 skills every turn | PARITY-MANIFEST note |

When you replace a dual launcher or dual config later: delete the dead launcher, leave one `.codewhale/references/old-launcher.md` with the useful env lines only.
