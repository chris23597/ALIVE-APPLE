---
name: prove-before-done
description: >
  Definition of done: command/test proof. No green todos without evidence.
user-invocable: true
---

# Prove before done

## Checklist

- [ ] Reproduced original failure (or showed absent)  
- [ ] Fix applied in correct project path  
- [ ] Prove command (curl / pytest / git log / health JSON)  
- [ ] Ship if ALIVE/code change needs backup  
- [ ] No secret staged  

## Multi-day / Agent OS exit (when FEATURES.md exists)

Also required before end of session:

- [ ] Active feature proof command ran  
- [ ] `.codewhale/FEATURES.md` checkbox updated  
- [ ] `.codewhale/HANDOFF.md` refreshed  

See skill **`agent-os`**. Project templates seed these files via `codewhale-project-init.ps1`.

## Forbidden

- "Should work now" without output  
- Marking ingest complete from WSL-only counts  
- Checking FEATURES boxes without running the listed proof  

