---
name: surgical-change
description: >
  Prefer small goal-driven diffs. Think before coding, simplicity first, no drive-by
  refactors. Use on bugfixes and focused features. Recreated from Karpathy-style
  LLM coding guidelines (community skill patterns 2026).
user-invocable: true
---

# Surgical change

## Four rules

1. **Think before coding** — restate goal + smallest fix surface  
2. **Simplicity first** — fewest files; no frameworks for a 20-line job  
3. **Surgical** — do not "clean up" unrelated code  
4. **Goal-driven** — stop when proof passes; no bonus features  

## Steps

1. grep scope — list touch files  
2. Minimal patch (or write_file only if rewrite required)  
3. Run the narrowest test/build  
4. Re-read diff mentally — any extra? delete it  
5. Ship only if user wants  

## Never

- Rewrite whole app for a one-line bug  
- Upgrade dependencies "while here"  
- Invent NEXT backlog  

## Done bar

- Diff matches stated goal  
- Proof command output  
- No unrelated files in ship  
