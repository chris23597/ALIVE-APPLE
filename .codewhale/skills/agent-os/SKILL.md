---
name: agent-os
description: >
  Top-line multi-session agent OS (Mythos/Fable-class harness patterns + Codex
  milestones). Use for days-long work, continue after context death, initializer
  vs worker, feature list + test gates, hard-tail multi-agent, model refusal
  fallback, Plan/Implement artifacts, or "make CodeWhale top of the line".
user-invocable: true
---

# Agent OS — top-line harness (model-agnostic)

**Source signals (patterns only, not weights):**
- Anthropic long-running harness (initializer + coding agent; feature list; git + tests as state)
- Claude Fable/Mythos multi-agent research (non-blocking hard-tail parallelism)
- Codex long-horizon (Plan.md / Implement.md style milestones)
- Pair with `long-horizon-harness` (Kimi) + `session-handoff`

**Law:** Harness quality often beats model brand. Default model stays free-capable until proof flips `PARITY-MANIFEST`.

## When

| Signal | Mode |
|--------|------|
| Work will exceed one context / one day | Full Agent OS |
| User says continue / resume / multi-day | Worker resume |
| Brand-new epic / greenfield | Initializer first |
| Hard multi-module job (pass rate would be low single-agent) | Hard-tail swarm |
| Model refuses / rate-limits / empty | Fallback chain |
| "Top of the line" / beat Claude Code craft | Apply this + prove-before-done |

## 1. Two roles (never mix blindly)

### Initializer (once per epic)

1. Map repo (tree, tests, ship policy) — no bulk dump.  
2. Write **feature list** with checkboxes (ordered by dependency).  
3. Write **success proof** per feature (exact command).  
4. Seed `.codewhale/` state files (below).  
5. First green smoke if possible.  
6. Hand off to Worker with HANDOFF packet.

### Worker (every later session)

1. Read HANDOFF + feature list + last git HEAD.  
2. Pick **one** unchecked feature (or the explicit NEXT).  
3. Implement incrementally.  
4. Run that feature's proof.  
5. Commit or ship only when proof passes and policy allows.  
6. Update feature list + HANDOFF; stop or continue.

## 2. On-disk state (beats chat memory)

Keep under project `.codewhale/` (portable):

| File | Purpose |
|------|---------|
| `HANDOFF.md` | Short packet (`session-handoff`) |
| `FEATURES.md` | Checkbox feature list + proof commands |
| `PLAN.md` | Current milestone plan (what / why / order) |
| `IMPLEMENT.md` | Active slice: files, steps, done bar |
| `STATE.md` | Freeform blockers, env notes |

**Seeded automatically** by `codewhale-project-init.ps1` / SkillsSync from `update/project-template/` (v4.0).  
If missing: run project-init or copy templates — do not invent a second layout.

**Cross-session truth order:** git status → FEATURES.md → HANDOFF → chat.

### FEATURES.md template

```markdown
# FEATURES
Goal: <one line>

- [ ] F1: <slice> — proof: `<cmd>`
- [ ] F2: ...
- [x] F0: scaffold — proof: `pytest -q` (done 2026-07-17)
```

### PLAN.md / IMPLEMENT.md (Codex-class)

- **PLAN.md** — milestones only (no code). Update when direction changes.  
- **IMPLEMENT.md** — current slice only; wipe/refresh each feature.

## 3. Session exit gate (anti fake-done)

Before claiming done or ending a work session:

1. Proof command for the slice ran and passed (or BLOCKED with exact error).  
2. FEATURES.md checkbox updated.  
3. HANDOFF.md refreshed.  
4. No secret files staged.  
5. If user asked ship: `task-ship` / identify SAFE path.

**Never** exit on "should work."

## 4. Hard-tail multi-agent only

From Fable/Mythos multi-agent research: parallelism wins on **hard** work; hurts easy work.

| Situation | Action |
|-----------|--------|
| Easy / single file | One agent |
| Independent modules + hard | Parallel subagents (own scopes) |
| Same file / shared state | Serial |
| After spawn | Parent synthesizes + one proof pass |

Cap: parity `max_subagents` (often 2–3). Prefer quality of decomposition over count.

## 5. Model fallback (refusal / failure)

Paid frontier models (Fable, Mythos-restricted, GPT Sol) can refuse, rate-limit, or empty-out.

```
primary (frontier profile)
  -> on refuse / 429 / empty / thrash x2
    -> alternate provider if user has key
    -> fast profile for narrow retry
    -> local profile offline
    -> handoff packet + stop with BLOCKED
```

- Do **not** require Claude Mythos (restricted Glasswing).  
- Do **not** flip free default to Fable without outcome proof.  
- Log what failed in HANDOFF without dumping secrets.

## 6. What Mythos/Fable are (so we do not chase ghosts)

| Model | Access | For CodeWhale |
|-------|--------|---------------|
| **Claude Mythos 5** | Restricted (Project Glasswing / trusted cyber) | **REJECT** as product path — same class as Fable, safeguards lifted; not yours to install |
| **Claude Fable 5** | Public paid Mythos-class | **WATCH** optional user key; steal harness ideas only |
| **Harness patterns** | Free to recreate | **ADOPT** (this skill) |

Peak IQ without harness still fails multi-day work. Your edge: Update + Safe + Scout + Agent OS + free-capable default.

## 7. Top-of-the-line stack (for this user)

| Layer | CodeWhale holder |
|-------|------------------|
| Free-capable default model | Current `PARITY-MANIFEST` frontier (DeepSeek until proof) |
| Long-horizon single session | `long-horizon-harness` |
| Multi-day / multi-context | **this skill** + `session-handoff` |
| Speed / thrash control | `agent-efficiency` + `edit-file-discipline` |
| Proof | `prove-before-done` + `completion-bar` |
| Ship | safe-ship / task-ship |
| Acquire new winners | `frontier-acquire` + auto logon scout |
| Optional peak paid model | User key only; never brand marriage |

## Pair with

| Skill | Role |
|-------|------|
| `session-handoff` | Compact resume packet |
| `long-horizon-harness` | In-session swarm / tools / compaction |
| `thinking-discipline` | Checklist finish |
| `grill-plan` | Interview before huge builds |
| `permission-lanes` | Read/edit/ship |
| `frontier-acquire` | Model default changes |
| `prove-before-done` | Exit gate |

## Done bar

- [ ] FEATURES.md exists for multi-day work  
- [ ] Worker read HANDOFF before coding  
- [ ] Each session left proof + updated checkboxes  
- [ ] Swarm only on hard independent work  
- [ ] Fallback path known if primary model fails  
- [ ] No claim of Mythos access we do not have  

## Never

- Depend on Mythos 5 or any restricted model  
- Make Fable/Claude required for free CodeWhale  
- Restart multi-day work from empty chat memory  
- Parallelize easy tasks "for show"  
- Mark features done without proof commands  
---
