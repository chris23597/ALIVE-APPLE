---
name: grok-parity-build
description: >
  Answer "can CodeWhale do what Grok did" and encode Grok/Cursor durable work into
  CodeWhale skills+scripts. Use when user asks to teach CodeWhale, match Grok,
  or make CodeWhale independent of Grok Build.
user-invocable: true
---

# Can CodeWhale do what Grok did?

## Short answer

**Yes — for anything already encoded under `C:\Users\chris\CodeWhale\`.**  
**No — for work that only exists in a chat transcript.**  

Your job: if Grok built something durable, **teach CodeWhale the same day** via skills + scripts + update package.

## Update always re-applies posture

CodeWhale Update **ParityFix** (every Run update + end of SkillsSync):

1. Reads `update/PARITY-MANIFEST.json`  
2. Rewrites live **WSL** `~/.codewhale/config.toml` (Pro, high reasoning, skill instructions)  
3. Verifies TOML + forbids flash/local-Qwen default lie  

When you teach a new always-on skill: put it in `update/skills/`, list in `MANAGED-MANIFEST`, and in `PARITY-MANIFEST` `core_skills` (or rely on `include_manifest_new_skills`).

## Capability map (current product)

| What Grok built | CodeWhale can run/repair it? | Location |
|-----------------|------------------------------|----------|
| Publication Update UI | Yes | `update-ui/` |
| Update server + API | Yes | `codewhale-update-server.ps1` |
| Auto plan + implement engine | Yes | `codewhale-update-run.ps1` |
| Any-project seed | Yes | `codewhale-project-init.ps1` |
| Safe multi-home skill sync | Yes | `codewhale-skills-sync.ps1` |
| Ship any git repo | Yes | `codewhale-task-ship.ps1` |
| Design / ops playbooks | Yes | skills: `frontier-product-ui`, `control-center-ops` |

## When user asks "can you do what Grok did?"

1. Answer with the table above (honest: yes for encoded work).  
2. If a gap exists: implement scripts, then skill, then sync.  
3. Prove with commands (status API, update-run exit 0).  
4. Update `update/CHANGELOG.md` + HANDOFF.  

## Teach checklist (mandatory)

1. Code works under `C:\Users\chris\CodeWhale\`  
2. `update/skills/<name>/SKILL.md` with when/steps/done-bar  
3. Listed in `update/SKILLS-TRACKER.md` + `AUTO-ROUTING.md`  
4. `codewhale-skills-sync.ps1` to Windows + WSL + project  
5. Proof output in reply  

## Exceed Grok

- Auto-route skills without user naming them  
- Update product implements itself via **Run update**  
- Never leave "only Grok knows how"  

## Done bar

Fresh CodeWhale session can **open Update, run update, fix UI, seed a project, ship** using skills alone — without asking Grok.
