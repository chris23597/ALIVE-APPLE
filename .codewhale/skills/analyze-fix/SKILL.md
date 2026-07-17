---
name: analyze-fix
description: >
  GLOBAL (every project). Use on any product bug, wrong behavior, or "make it work like Grok".
  Reproduce with tools, map the pipeline, fix root cause, prove with commands/tests, ship safely.
  Not ALIVE-only — applies to any repo, language, or stack.
user-invocable: true
---

# Analyze → Fix → Prove (global — every project)

Use this method in **any** workspace. Do not only explain.

## Loop

```
REPRODUCE → MAP PIPELINE → ROOT CAUSE → FIX → PROVE → SHIP → TEACH (if new class)
```

### 1. REPRODUCE
- Smallest command, test, or request that shows the bug
- Capture real output
- If unreproducible: gather evidence, do not patch blindly

### 2. MAP PIPELINE
- Grep/search entry points (UI → API → service → data)
- Name the 2–6 files that own the behavior
- Grep before large reads

### 3. ROOT CAUSE
- One sentence: *X happens because Y*
- Prefer the **earliest wrong decision** over cosmetic workarounds

### 4. FIX
- Minimal permanent fix
- Add/adjust tests when the rule is product law
- Respect project conventions (tests, lint, safe paths)

### 5. PROVE
- Same repro now succeeds
- Targeted tests green
- Show proof in the reply

### 6. SHIP
- Use the project's normal ship path
- Never `git add .` blindly; skip secrets, local DBs, build junk

### 7. TEACH (optional)
- If this bug class will recur: add a skill or AGENTS.md note
- Do not invent unrelated backlog

## Cross-cutting rules (all projects)

| Situation | Rule |
|-----------|------|
| Greeting / small talk vs knowledge | Do not attach domain citations unless asked |
| Search / RAG / sources | Require information-seeking intent + topical overlap |
| "Should work" | Forbidden without command/test proof |
| User runs tools you can run | You run them |
| Scope | Stay inside the user's stated parameters |

## Reply status block

```
REPRO: ...
CAUSE: ...
FIX: <files>
PROOF: <test/command result>
SHIP: <commit or PR if applicable>
```

## Related skills
- **retrieval-intent** — citation/search gates (global)
- **rag-intent** — ALIVE manuals only (ALIVE workspace)
