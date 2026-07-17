---
name: long-horizon-harness
description: >
  Long-horizon agent harness patterns (from Kimi K3 / Kimi Code research).
  Use when multi-hour jobs, large tool catalogs, swarm/subagents, 1M-context
  models, preserve-thinking, context compaction, over-proactive agents, Goal
  mode, or "agent loses the plot" over many turns.
user-invocable: true
---

# Long-horizon harness (Kimi-class patterns, CodeWhale-owned)

**Source signal:** Moonshot Kimi K3 + Kimi Code CLI best practices (2026-07).  
**Acquire path:** pattern recreate only — do **not** vendor Kimi binaries or require Kimi as default.

## When

| Signal | Apply |
|--------|--------|
| Job spans many tool turns / hours | Full checklist below |
| Large MCP / tool inventory | Dynamic tool load |
| Reasoning model multi-turn | Preserve full assistant history |
| Huge context window available | Compact, don’t dump |
| Parallel independent work | Disciplined swarm (≤ max_subagents) |
| Agent deletes/deploys without ask | Explicit proactive bounds |
| User says Goal / long-running | Persist goal + progress |

## 1. Dynamic tool loading (token + accuracy)

Don’t send every tool definition every turn when the catalog is large.

1. Keep a **core set** always available (read/edit/shell/git/ship for coding).  
2. For the rest, use **search-then-load** (CodeWhale: `search_tool` → `use_tool`; product MCP meta).  
3. Prefer **domain keywords** in the search query (github, browser, linear, db).  
4. After load, call the tool; drop unused defs on later turns if prefix cache thrashing.

**Done bar:** each request carries only tools needed for the next step(s), not the full universe.

## 2. Preserve thinking / full assistant turns

Some frontier models (Kimi K3 class) train with **preserved reasoning history**.

| Do | Don’t |
|----|--------|
| Pass complete assistant messages (content + reasoning/tool-call fields the API returns) | Strip `reasoning_content` / thinking blocks mid-session |
| Keep one model for the whole long session when possible | Switch model mid-thread when the new one needs thinking history |
| Stream reasoning separately, store it for next request | Drop reasoning after display |

If the harness cannot preserve thinking, **prefer a model that tolerates stripped history** for that session.

## 3. Context compaction (not “use all 1M”)

Large windows help; blind full dumps hurt.

1. **Map first** — file tree, grep hits, HANDOFF, then targeted reads.  
2. **Compact ~300k-class** when long browse/agent loops accumulate: summarize completed subgoals, keep open diffs + failing tests + next step.  
3. Prefer **selective re-fetch** over replaying entire tool traces.  
4. Vendor benches often show compaction **matching or beating** raw max context.

## 4. Disciplined swarm (parallel subagents)

Kimi-style swarm: orchestrator decomposes → parallel specialists → synthesize.

| Rule | CodeWhale default |
|------|-------------------|
| Only **independent** workstreams | Same file → serial |
| Cap concurrency | `max_subagents` (parity default 8; often 2–3 is enough) |
| Each child gets **narrow prompt + done bar** | No “figure out the whole product” |
| Parent **merges** results and resolves conflicts | Don’t ship partial swarms |
| No infinite spawn | After 1 synthesis pass, finish or handoff |

## 5. Goal mode (long jobs)

For multi-hour / multi-session work:

1. Write a **one-line goal** + checklist (or `session-handoff` packet).  
2. Every major turn: update checklist status (thinking-discipline).  
3. On resume: load HANDOFF first — not full chat dump.  
4. Stop condition: proof commands green or explicit BLOCKED next step.

## 6. Proactive bounds (anti “surprise deploy”)

Long-horizon training makes models **over-helpful**. Put hard lines in system / `AGENTS.md` / project rules:

```
Never without explicit user ask:
- delete branches, force-push, drop DB, rm -rf broad paths
- production deploy / paid API spend
- send external messages (email, Slack, public posts)
- change shared permissions / CI secrets
```

Prefer **confirm then act** for those classes even in YOLO coding lanes.

## 7. Shell vs agent mode (UX pattern)

Steal the *idea*, not the binary:

- Coding agent loop for plans, edits, multi-step tools.  
- Raw shell for short, user-directed commands.  
- Don’t mix: don’t bury `git push` inside silent multi-tool soup — use ship scripts.

## 8. MCP as extension surface

| Pattern | Our path |
|---------|----------|
| `mcp add/list/remove` style manageability | `~/.codewhale/mcp.json` + product docs |
| Ad-hoc project MCP | Project `.codewhale` / workspace mcp when present |
| Validate before long run | MCP ritual in `tool-mastery` |

## 9. Model lane honesty (Kimi K3 signal)

| Fact | Product rule |
|------|----------------|
| K3 is strong long-horizon / coding / multimodal (independent AA ~top tier) | **Optional** user-key only until free/open path + local smoke |
| API paid (~Sonnet-class $3/$15 list); weights promised later | Never force as free CodeWhale default |
| Verbose max-reasoning burns output tokens | Prefer cheaper coding models for high-volume loops unless job needs K3-class |
| Harness matters as much as weights | This skill + prove-before-done beat model-chasing |

Re-score via `frontier-acquire` when open weights land or user proves better outcomes on *their* work.

## Pair with

| Skill | Role |
|-------|------|
| `thinking-discipline` | Plan → checklist → finish |
| `agent-efficiency` | Tools first, batch, no thrash |
| `tool-mastery` | Which tool when |
| `session-handoff` | Cross-session goal resume |
| `agent-os` | Multi-day FEATURES/PLAN; init vs worker; model fallback |
| `permission-lanes` | Read/edit/ship bounds |
| `frontier-acquire` | Gate model default changes |
| `prove-before-done` | Proof before “done” |

## Done bar

- [ ] Tool set minimized per turn when catalog is large  
- [ ] Long job has goal + checklist (or HANDOFF)  
- [ ] Parallel work capped and independent  
- [ ] Risky actions bounded  
- [ ] Context mapped/compacted — not whole-repo dump  
- [ ] Proof attached for completion  

## Never

- Vendor-install Kimi CLI into Update package as a hard dependency  
- Switch free-product default to paid K3 on launch-day hype  
- Spawn 50 subagents “because swarm”  
- Strip reasoning mid-session on models that require it  
- Claim done without verify  
---
