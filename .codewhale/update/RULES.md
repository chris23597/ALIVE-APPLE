# Standing rules (this project and the next)

0. **Best always (model-agnostic)** — see `BEST-ALWAYS.md`  
   Not tied to any model brand. Stay ahead of the curve with **proven outcomes** only.  
   Stars/hype never decide. Proven better → that becomes the Update default. Losers demote.

0b. **Safe Update** — see `SAFE-UPDATE.md`  
   Update must **never** kill or rewrite ALIVE or CodeWhale **product** trees.  
   Only agent harness (`.codewhale`, agent homes). Canary verify fails the run if product files change.

0c. **Replace → delete old → small reference** — skill `replace-keep-ref`  
   When improving something: **new is live**, **old call sites go away**, keep a **thin** recovery note  
   (`.codewhale/references/` or `update/references/`). No dual stacks “just in case.”

0d. **Grok-speed efficiency** — `EFFICIENCY.md` + skill `agent-efficiency` (always-on)  
   Tools before essays; product scripts first; batch shell; grep before bulk read; prove once.  
   No thrash loops. Match Grok results **faster**.

1. **30-minute skill rule**  
   If a fix burns **> 30 minutes once** → write or update a skill **the same day**. Put a line in `CHANGELOG.md` + `SKILLS-TRACKER.md`.

2. **Auto-route, don’t wait for invoke**  
   Match user symptoms to skills in `AUTO-ROUTING.md`. Apply silently. Mention skill name only in brief status if useful (“following Chroma Windows-ingest playbook”).

3. **CodeWhale ≠ ALIVE**  
   Separate homes, ships, defaults. See skill `codewhale-alive-split`.

4. **ALIVE Chroma = Windows venv only**  
   `C:\ALIVE\backend\venv\Scripts\python.exe` (3.11, chromadb 0.5.x). Never WSL python3 for vector DB write.

5. **Secrets never ship**  
   No `.env`, API keys, tokens to git or retail USB.

6. **SAFE ship only**  
   Identify before stage; no `git add .`; no WSL git push for ALIVE.

7. **Prove before done**  
   curl/pytest/command evidence. Don’t mark complete on hope.

8. **Priorities A–D**  
   Read `priority-focus.json` / desktop card; don’t invent backlog outside user ask.

9. **Optional later stays optional**  
   See `FUTURE-BACKLOG.md` — CompassTool-native, Gmail OAuth, fleet multi-PC, full plan-mode UI — **not blocking** unless pain returns or user prioritizes.

10. **Build phase: errors visible**  
    Prefer logging/recording over silent swallow (`alive-error-telemetry`).

11. **Edit discipline**  
    Never `edit_file` without `read_file` in **this** session. Re-read after each edit on the same path. Max 2 failed searches → `write_file` or handoff (`edit-file-discipline`).

12. **Thinking finishes work**  
    Short plan → checklist → tools. No monologue loops. Finish verify+ship or write BLOCKED + HANDOFF (`thinking-discipline`).
