# Best always — product law (model-agnostic)

**You are not tied to any model, vendor, or brand.**  
No shareholder loyalty. No “we use X because we always did.”  
**Only proven outcomes** keep something as the default.

This file is the north star for **CodeWhale Update** — now and into the future.

---

## The law (one paragraph)

Stay **ahead of the curve** using whatever is **actually best for your results** at this time: free-capable when possible, any model/provider when proven better for coding agent work. Stars, hype, press, and brand love **do not** decide. **Measured proof** does. When something wins on proof, **that becomes the update** (registry ADOPT + `PARITY-MANIFEST` defaults). When it loses later, **demote it** without sentiment.

---

## What “best” means (outcomes, not brands)

| Outcome (must improve or hold) | How we know |
|--------------------------------|-------------|
| Fixes real bugs in your repos | Repro → fix → tests/commands green |
| Ships safely | identify SAFE; no secret leaks |
| Finishes multi-file jobs | fewer thrash loops; plan → execute → verify |
| Uses tools correctly | read-before-edit; no fake “done” |
| Stays affordable / free-capable | no forced paid lock-in as product core |
| Latency acceptable for the job | frontier vs fast profile when needed |

If a new model/tool wins these **on your machine / your work**, promote it.  
If the current default loses, demote it. **No hard feelings.**

---

## What never decides alone

- GitHub stars / HF downloads  
- Reddit or review scores (manipulable)  
- Vendor marketing / “#1 model” headlines  
- “Everyone switched to Y this week”  
- Emotional attachment to DeepSeek, Qwen, OpenAI, Anthropic, local-only, etc.

Those may be **signals**. They are never **proof**.

---

## Lifecycle (same as frontier acquire)

```
SIGNAL → deep dive → score → WATCH / PROVISIONAL → ADOPT | REJECT | DEMOTE
                              ↑ wait-and-see default
```

| State | Meaning for defaults |
|-------|----------------------|
| **WATCH** | Interesting; do not switch default yet |
| **PROVISIONAL** | Trial allowed; soak more proof |
| **ADOPT** | Current best-proven for a lane (cloud / local / pattern) → may set `PARITY-MANIFEST` |
| **DEMOTE** | Was ADOPT; lost on outcomes → remove from default; re-scout peers |
| **REJECT** | Wrong fit, unsafe, or paid-only as forced core |

**Default verdict = WATCH.** Switching the **frontier profile** default requires ADOPT-level proof.

---

## Lanes (not brands)

CodeWhale thinks in **lanes**, not marriages:

| Lane | Role | Current holder is temporary |
|------|------|-----------------------------|
| **frontier** | Best all-around coding agent default | Whatever `profiles.frontier` says after last proven ADOPT |
| **fast** | Cheap/quick turns | Optional; never “the identity” |
| **local** | Offline / zero API | Optional; promote only after smoke on this PC |
| **patterns** | Plan mode, subagents, ship, UI | Recreate winners; never clone junk |

Today’s name in a lane is a **label**. Tomorrow’s winner may be different.

---

## How Update enforces this

Every **Run update**:

1. **CompetitiveIntel** — map the field (not install).  
2. **FrontierScout** — score registry; no download on hype.  
3. **ParityFix** — apply **current** proven defaults from `PARITY-MANIFEST.json` to live config.  
4. SkillsSync — only managed package content.

When proof says switch:

1. Update `FRONTIER-REGISTRY.json` (ADOPT new / DEMOTE old).  
2. Point `profiles.frontier` (and/or defaults) in `PARITY-MANIFEST.json` at the winner.  
3. Line in `CHANGELOG.md` with **outcome evidence** (what got better).  
4. Next Update run ships the new default. **That is staying in front of the curve.**

---

## Free preference (not free dogma)

- Prefer free / open / user-key paths so the product is not locked.  
- If a paid model is **clearly proven better** for a job **and you choose to use your key**, it may sit as an **optional** profile — never as the only path, never as brand loyalty.  
- Product core stays runnable without one vendor’s subscription.

---

## Agent behavior (every CodeWhale session)

1. Optimize for **your outcomes**, not defending the current model name.  
2. If user asks “is X better?” → deep dive + compare + proof, not fanboy answer.  
3. If thrash / fails increase after a switch → DEMOTE and report.  
4. Never say “we can’t switch; we are a DeepSeek/Qwen shop.” **There is no shop.**

---

## Files that own this law

| File | Role |
|------|------|
| **This file** | North star (human) |
| `FRONTIER-ACQUIRE.md` | Gate before anything enters Update |
| `FRONTIER-REGISTRY.json` | Candidates + states |
| `PARITY-MANIFEST.json` | Live defaults (current winners only) |
| `COMPETITIVE-SCORECARD.md` | Rival harness patterns |
| `COMPETITIVE-UPDATE.md` | Field map |
| `CHANGELOG.md` | Record of proven switches |

---

## Done bar (are we still “best always”?)

- [ ] No doc claims eternal loyalty to one model brand  
- [ ] Defaults in PARITY match registry ADOPT for frontier lane  
- [ ] Scout still default-WATCH for unproven shiny things  
- [ ] Last CHANGELOG model/default change cites **outcomes**, not stars  
- [ ] User can open Update and see agents re-apply current proven stack  

---

*Stay ahead of the curve. Prove it. Update it. Drop what loses.*
