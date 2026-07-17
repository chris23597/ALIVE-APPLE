@echo off
title ALIVE APPLE — First Run Setup
cd /d "%~dp0"

:: Check if models exist, if not offer to download
if not exist "models\Phi-4-mini-instruct-Q4_K_M.gguf" (
    echo.
    echo  ============================================
    echo    ALIVE APPLE — iPhone 16 AI Setup
    echo  ============================================
    echo.
    echo  No models found on this flash drive.
    echo.
    echo  What would you like to do?
    echo.
    echo  [1] Run full setup (recommended first time)
    echo  [2] Open Dashboard only
    echo  [3] Exit
    echo.
    choice /c 123 /n /m "Choose [1-3]: "
    if errorlevel 3 exit /b
    if errorlevel 2 goto dashboard
    if errorlevel 1 goto fullsetup
) else (
    goto dashboard
)

:fullsetup
echo.
echo Starting full first-run setup...
powershell -ExecutionPolicy Bypass -File "scripts\first-run.ps1"
goto dashboard

:dashboard
echo.
echo Opening ALIVE APPLE Dashboard...
:: Run status check to generate status.json
powershell -ExecutionPolicy Bypass -File "scripts\check-models.ps1" -StatusOnly
:: Open the dashboard in browser
start "" "dashboard.html"
exit /b
