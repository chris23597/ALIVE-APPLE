---
name: codewhale-plan-mode
description: >
  Before multi-file edits: short plan, then execute. Free grab from Qwen Code / Claude Code.
  Reduces thrash and half-finished agents.
user-invocable: true
---

# Plan mode (before big edits)

## When

- >2 files will change  
- Architecture / RAG / ship / portable  
- User said “fix all” or “make it work”

## Pattern

```
1. PLAN (5–10 bullets, files, risks, prove steps)
2. USER ok or YOLO already on
3. EXECUTE smallest vertical slice
4. PROVE (command/test)
5. Next slice or ship
```

## Anti-pattern

- Start 6 agents, rewrite 20 files, no prove  
- Mark todos complete without curl/pytest evidence  
