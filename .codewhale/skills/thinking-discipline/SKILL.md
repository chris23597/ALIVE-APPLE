---
name: thinking-discipline
description: >
  MANDATORY for multi-step work. Shape CodeWhale thinking so it finishes:
  short plan → checklist → act → verify → ship. No long ruminate loops without tools.
user-invocable: false
---

# Thinking discipline (finish what you start)

## User need

The user **reads your thinking panel** (scroll/select/copy — see `thinking-copy`).  
Thinking must help **progress**, not stall. If you plan for many turns without landing edits or proof, you are failing the frontier loop.

## Thinking budget (per user message)

| Phase | Timebox | Output |
|-------|---------|--------|
| **SCOPE** | ≤1 tool round | grep/glob + HANDOFF; name the files |
| **PLAN** | ≤1 short block in thinking | 3–8 checklist items max |
| **EXECUTE** | most of the turn | tools that change state |
| **VERIFY** | 1 batched shell | pytest / health / re-read |
| **SHIP** | end of task | identify + task-ship |

**Rule:** After the plan is clear, the next action is a **tool**, not another monologue.

## Visible progress (user-facing)

1. **`checklist_write` immediately** on multi-step jobs (see `live-checklist`)  
2. Update checklist **after every completed step** — not only at the end  
3. Reply **STATUS bar** top + bottom (`copy-paste-flow`)  
4. Durable facts go to **HANDOFF** via task-ship — never only inside collapsed thinking  

## Anti-patterns (from live sessions)

| Bad thinking | Fix |
|--------------|-----|
| Re-explaining the same architecture 5× | One plan block → execute |
| “Let me read more…” forever | Cap exploration: 3 greps + 3 reads → first edit |
| edit_file fails → pure re-reasoning | Follow `edit-file-discipline` recovery |
| `python: command not found` | Windows venv only (`windows-shell-pitfalls` / `alive-backend-fix`) |
| Partial job (50% checklist) then chat ends | Finish remaining items **or** write BLOCKED + HANDOFF + exact next paths |
| Inventing NEXT backlog mid-thought | `no-invent-backlog` — NEXT only user-owned |

## When stuck (max 2 retries of same approach)

1. Different tool or strategy once  
2. If still stuck → `finish-job`: STATE.md + HANDOFF packet + stop looping  
3. Tell user what is done / remaining with file paths — do not claim “impossible”

## Thinking panel UX

- Prefer **short section headers** the user can select: `PLAN`, `DOING`, `BLOCKED`  
- Put irreversible decisions (ship SHA, test counts) in the **reply body** and HANDOFF  
- Never require mouse-capture mode (launcher uses `--no-mouse-capture`)

## Frontier loop (never skip)

```
SCOPE → PLAN → EXECUTE → VERIFY → IDENTIFY → SHIP → LEARN
```

LEARN = wrong judgment → JUDGE.md + skill patch **same day** (30-min rule).
