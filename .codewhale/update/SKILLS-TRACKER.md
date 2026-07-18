# Skills tracker (keep in sync with `~/.codewhale/skills/`)

**Last updated:** 2026-07-18 (added gordon-docker-expert integration)  
**Auto-use:** Yes — see `AUTO-ROUTING.md` + skill `skill-auto-router`

## Status legend

- **NOW** — load and auto-route today  
- **FUTURE** — documented; implement when pain/priority  
- **META** — how CodeWhale behaves  

---

## META

| Skill | Status | Purpose |
|-------|--------|---------|
| skill-auto-router | NOW | Seamless apply without user naming skills |
| **replace-keep-ref** | **NOW** | Better new path; delete old live refs; small recovery note only |
| **agent-efficiency** | **NOW** | Grok-speed: tools first, batch, product scripts, no thrash |
| **permission-lanes** | **NOW** | Opt-in read / edit / ship lanes (Codex-class, free) |
| **long-horizon-harness** | **NOW** | Kimi-class: dynamic tools, preserve thinking, compact, swarm, goal bounds |
| **agent-os** | **NOW** | Mythos/Fable/Codex multi-session OS: FEATURES, init/worker, hard-tail swarm, fallback |
| **frontier-acquire** | **NOW** | Deep dive before Update acquire; free+proven; stars untrusted; default WATCH |
| **edit-file-discipline** | **NOW** | Read→edit→re-read; stop thrash (live TUI #1) |
| **thinking-discipline** | **NOW** | Timebox plan; checklist; finish or handoff |
| **frontier-product-ui** | **NOW** | Premium local web UIs (Control Center pattern) |
| **skill-synthesis** | **NOW** | Web skill gate: recreate/reject, never bulk junk |
| **session-handoff** | **NOW** | Compact HANDOFF packets across sessions |
| **grill-plan** | **NOW** | Interview before multi-file coding |
| **surgical-change** | **NOW** | Small goal-driven diffs |
| **control-center-ops** | **NOW** | Run/fix CodeWhale Control Center |
| **grok-parity-build** | **NOW** | Encode Grok durable work; Update ParityFix re-applies live config every run |
| analyze-fix | NOW | Repro→fix→prove→ship |
| retrieval-intent | NOW | No junk citations |
| codewhale-plan-mode | NOW | Plan before multi-file |
| priority-focus | NOW | A/B/C/D finish lines |
| secrets-never-ship | NOW | Never commit secrets |
| windows-shell-pitfalls | NOW | $PID, locks, paths, bare python |
| codewhale-alive-split | NOW | Two programs |
| codewhale-update-ops | NOW | Update panel agents |
| competitive-edge | NOW | Free grabs / model strategy |
| thinking-copy | NOW | Mouse select/scroll thinking pane |
| live-checklist | NOW | TUI todo always current |
| yolo-excellence | NOW | Frontier execute |
| tool-mastery | NOW | Tool decision matrix |
| finish-job | NOW | Stop loops; handoff Grok |

## Docker / Containers — NOW (NEW SECTION)

| Skill | Status | Purpose |
|-------|--------|---------|
| **gordon-docker-expert** | **NOW** | Containerization, Dockerfile optimization, docker-compose, debugging (portable to any project) |

**Auto-routes on:** containerize, dockerfile, docker build, docker-compose, container, healthcheck, image optimization, DHI migration

**How:** User says `gordon: task` → CodeWhale invokes Gordon → results integrated

## ALIVE — NOW

| Skill | Status | Purpose |
|-------|--------|---------|
| alive-backend-fix | NOW | Health 500, Chroma skew |
| alive-chroma-ingest | NOW | Windows-only ingest |
| alive-ship | NOW | SAFE task-ship |
| alive-launch-ops | NOW | Pro launcher / ports |
| alive-gpu-embed | NOW | Torch/CUDA embeddings |
| alive-kiwix-zim | NOW | ZIM/encyclopedia |
| alive-manuals-recovery | NOW | Find manuals on disks |
| alive-pdf-pipeline | NOW | PDF normalize |
| alive-error-telemetry | NOW | Build-phase errors |
| alive-vision-local | NOW | Vision/n_ctx/mmproj |
| alive-smoke-deep | NOW | Fast then deep UX |
| local-vs-cloud-copy | NOW | Copy/limits messaging |
| hf-models-merge | NOW | HF/LoRA/GGUF |
| github-ci-noise | NOW | CI email noise |
| alive-portable-usb | NOW | Product USB architecture |
| recovery-usb-win11 | NOW | Recovery stick |

## Useful extras (added without you naming them)

| Skill | Status | Purpose |
|-------|--------|---------|
| alive-first-run | NOW | First boot / empty KB / Setup wizard path |
| alive-ollama-routing | NOW | 3B default, escalate 7B/14B, warm |
| codewhale-workspace | NOW | CODEWHALE_WORKSPACE, browse, ship target |
| dual-drive-backup | NOW | Hunt files across E:/D:/USB without nuking |
| prove-before-done | NOW | Definition of done checklist |
| no-invent-backlog | NOW | NEXT only user-requested |

## FUTURE (optional later — not blocking)

| Item | When |
|------|------|
| Engine-level block: edit_file without prior read_file | If skill still ignored often |
| Live agent labels in chat thinking header | UX pain returns |
| Sticky "% complete" footer in TUI | Product change |
| CompassTool-native (macOS menu bar full native) | Pain returns / product priority |
| Gmail OAuth flow (auto-read GitHub error mails) | Pain returns |
| Fleet multi-PC agents | Pain returns |
| Full plan-mode UI **in ALIVE product** | Product roadmap |
| alive-gpu-cuda-wheel install automation | If torch CPU keeps biting |
| Retail USB factory flash CI | When Mini SKU ships |
| BitLocker key capture automation | When encryption on |
| GitHub Actions + Docker Hub push automation | When CI/CD pain returns |
| Kubernetes support (k8s manifests, deployment) | When multi-node needed |

See `FUTURE-BACKLOG.md` + `THINKING-PROCESS.md`.
