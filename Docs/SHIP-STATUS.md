# ALIVE APPLE — ship status (2026-07-19)

**Software wrap: COMPLETE** (CodeWhale `project-green` GREEN · Git+Actions+Docker).

## Green lanes

| Lane | Status | Proof |
|------|--------|--------|
| **GitHub Actions** | GREEN | Latest `main` success; artifact `ALIVE_APPLE_iPhone16` |
| **Git write** | WRITE_READY | `codewhale-git-prove.ps1` — clean tree, repo+workflow scopes |
| **Docker (ref image)** | GREEN | `codewhale-docker-green.ps1 -Build` / `codewhale-alive-apple:local` |
| **ALIVE web stack** (sibling) | GREEN | `http://127.0.0.1:8000/api/health` ok; frontend :5173 200 |
| **One-shot prove** | GREEN | `codewhale-project-green.ps1 -Repo . -PollCi -DockerBuild` |

## Delivered on main

- Unsigned IPA via free macOS Actions runner  
- ServiceContainer → shared InferenceEngine  
- MLX streaming path + Phi-4 Mini model docs  
- `.dockerignore` so Windows docker build skips agent junctions  

## Optional remaining (needs Mac + Apple ID)

- Install IPA on physical iPhone 16 / TestFlight signing  

## Prove commands

```powershell
$Repo = "C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE"
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-actions-prove.ps1 -Repo $Repo
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-git-prove.ps1 -Repo $Repo
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-docker-green.ps1 -Repo $Repo -Build
```

Open a **new** CodeWhale chat on this workspace after Update/Parity.
