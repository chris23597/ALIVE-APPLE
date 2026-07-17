---
name: grill-plan
description: >
  Interview the user about goals, constraints, and success criteria BEFORE coding
  multi-file or ambiguous work. Use when requirements are vague, "build X", large
  refactors, or product UI changes. Recreated from high-value "Grill Me" plan skills.
user-invocable: true
---

# Grill-plan (clarity before code)

## When

- Ambiguous product request  
- Multi-file or multi-hour work  
- "make it better" without metrics  
- New UI / architecture path  

## Protocol (max 8 questions, batch them)

Ask only what blocks correct design:

1. **Outcome** — what must be true when done?  
2. **Out of scope** — what must not change?  
3. **Proof** — how do we verify (test, screenshot, API)?  
4. **Constraints** — stack, offline, no sudo, Windows/WSL?  
5. **Audience** — only you / multi-user / sellable?  
6. **Risk** — data loss, secrets, breaking prod?  

Then write a **PLAN** checklist (5–12 steps) and wait for go **unless** user already said "just do it".

## Anti-patterns

- 20 interrogating questions  
- Planning forever with zero tools after approval  
- Inventing backlog items user did not want  

## After approval

`thinking-discipline` + `edit-file-discipline` + prove + ship.

## Done bar

- Shared success criteria written  
- Checklist exists  
- User greenlit **or** explicit YOLO from user  
