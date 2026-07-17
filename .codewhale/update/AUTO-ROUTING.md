# Auto-routing (seamless — no user invoke required)

CodeWhale **must** apply matching skills automatically when symptoms appear.  
Do **not** wait for the user to say “use skill X”.

## Always on (every turn)

| Condition | Apply |
|-----------|--------|
| Any message | `retrieval-intent` (greetings → no junk docs) |
| Any work turn | **`agent-efficiency`** (tools first, batch, scripts over rediscovery) |
| Any coding task | `analyze-fix` method when bugs |
| Multi-step / multi-file | `thinking-discipline` + `live-checklist` |
| Any `edit_file` / `apply_patch` | `edit-file-discipline` (read first) |
| Multi-file (>2) or “fix all” | `codewhale-plan-mode` |
| Unclear project | `codewhale-alive-split` + workspace check |
| About to push/commit | `alive-ship` or CodeWhale ship + `secrets-never-ship` |
| PowerShell automation | `windows-shell-pitfalls` |
| Faster / like Grok / stop stalling | `agent-efficiency` + `yolo-excellence` + `tool-mastery` |
| Better than Cursor/Claude/Codex? / am I #1? | `WIN-CONDITIONS.md` + `COMPETITIVE-SCORECARD.md` (honest) |
| read-only / edit only / no push / ship lane | `permission-lanes` |

## Symptom → skill (ALIVE)

| User / log signal | Auto-apply |
|-------------------|------------|
| health 500, Internal server error, Chroma, `_type`, InvalidCollection | `alive-backend-fix` |
| rag_chunks 0, manuals not cited, “ingest”, “digest” | `alive-chroma-ingest` |
| rename manuals, missing PDFs, backup drive, “40 manuals” | `alive-manuals-recovery` + `alive-pdf-pipeline` |
| ZIM, kiwix, encyclopedia corrupt | `alive-kiwix-zim` |
| photo, vision, mmproj, context 4096, deep analysis hang | `alive-vision-local` + `alive-smoke-deep` |
| GPU, embedding device, torch CPU | `alive-gpu-embed` |
| Launch ALIVE, ports, won’t start | `alive-launch-ops` |
| Ship / GitHub / push ALIVE | `alive-ship` + `github-ci-noise` if CI emails |
| Local unlimited tokens claim | `local-vs-cloud-copy` |
| HF download, LoRA, GGUF merge | `hf-models-merge` |
| USB product, phone offline sell | `alive-portable-usb` |
| WIN11 recovery stick | `recovery-usb-win11` |
| Update CodeWhale panel | `codewhale-update-ops` + `control-center-ops` |
| Update stuck / blank / hang / wrong port / can’t see progress | `control-center-ops` → run `codewhale-update-diag.ps1` first |
| “What should we finish” | `priority-focus` |
| API keys, .env | `secrets-never-ship` |

## CodeWhale product (agent itself)

| Signal | Auto-apply |
|--------|------------|
| Update / binary / skills refresh | `codewhale-update-ops` |
| Competitive / Qwen / ChatGPT / Cursor | `competitive-edge` + `COMPETITIVE-UPDATE.md` |
| Any shell on Windows | `windows-shell-pitfalls` |
| `has not been read in this session` / `Search string not found` | `edit-file-discipline` |
| `python: command not found` / bare python in WSL | `windows-shell-pitfalls` + `alive-backend-fix` |
| Thinking loops / stalled checklist / “still reading” forever | `thinking-discipline` + `finish-job` after 2 retries |
| Tools denied / approval gate | `approval-unblock` then fresh YOLO session |

## Optional later (do **not** start unless user asks or pain returns)

| Topic | Note |
|-------|------|
| CompassTool-native | macOS menu bar full native — deferred |
| Gmail OAuth flow | Read GitHub emails automated — deferred |
| Fleet multi-PC | Multi-machine agent fleet — deferred |
| Full plan-mode UI in ALIVE product | Product feature, not agent-only — deferred |

Track in `FUTURE-BACKLOG.md`.

## Any project (portable)

| Signal | Auto-apply |
|--------|------------|
| New / unknown repo | codewhale-project-init + workspace skills |
| Multi-file any stack | codewhale-plan-mode + thinking-discipline |
| About to push any repo | ship scripts with `-Repo` + secrets-never-ship |
| ALIVE-only symptoms | alive-* skills (only when workspace is ALIVE) |


## Frontier parity (v4.0 — best always, model-agnostic)

| Signal | Auto-apply |
|--------|------------|
| Chat feels weak / not like Grok / flash model | Run Update **or** `codewhale-parity-fix.ps1`; open **new** chat |
| New skill should always load | Add to `update/skills` + `always_on_skills` only if every session needs it |
| Best model / switch provider / not tied to brand | `BEST-ALWAYS.md` + `frontier-acquire` — proven outcomes only |
| Should we stay on DeepSeek/Qwen forever? | **No** — temporary lane winners; demote when proof loses |

## Frontier parity (skills)

| Signal | Auto-apply |
|--------|------------|
| UI looks primitive / Control Center / update panel | `frontier-product-ui` + `control-center-ops` |
| can CodeWhale do what Grok did / teach permanently | `grok-parity-build` |
| Install random web skills / awesome lists | `skill-synthesis` + `frontier-acquire` (analyze; recreate or reject; no bulk) |
| Best free model / frontier / stars / GitHub hype | `frontier-acquire` + `FRONTIER-REGISTRY.json` (deep dive; default WATCH) |
| Download into Update / acquire new capability | `frontier-acquire` — ADOPT only after compare + proof |
| Handoff / new session / context full | `session-handoff` |
| Vague build X / multi-hour ambiguity | `grill-plan` before code |
| Small bug fix / focused change | `surgical-change` |
| Replace / cleanup old / dual stack / delete dead code but keep a note | `replace-keep-ref` (new wins; delete old live path; small recovery ref) |
| can CodeWhale do what Grok did | `grok-parity-build` + read `update/CODEWHALE-OWNS-THIS.md` |
| Multi-hour job / swarm / large MCP catalog / loses plot / Goal mode / Kimi-class harness | `long-horizon-harness` + `thinking-discipline` + `session-handoff` |
| Kimi K3 / Moonshot / should we switch default model | `frontier-acquire` + registry (model **WATCH**; harness already ADOPT) |
| Multi-day / continue tomorrow / context died / FEATURES list / initializer / Mythos/Fable harness | `agent-os` + `session-handoff` + `prove-before-done` |
| Top of the line / beat Claude / Mythos / Fable | `agent-os` + `long-horizon-harness` + `WIN-CONDITIONS.md` (harness > brand) |
| Model refused / rate limit / empty response | `agent-os` fallback chain (do not thrash same model) |
