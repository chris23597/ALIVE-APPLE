# CodeWhale on this project

Seeded: 2026-07-17 02:12
Portable harness v4.0 (Agent OS multi-day + long-horizon; works on any git project).

Workspace: C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE
Ship:
  powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-task-ship.ps1 -Repo "C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE" -LastDone "summary" -Next "none"

Chat:
  set CODEWHALE_WORKSPACE=C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE
  Launch-CodeWhale.bat

ALIVE-only skills (alive-*) apply only when this repo is ALIVE.