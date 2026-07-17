# ALIVE APPLE — First Run Setup
# Downloads all 4 GGUF models to the flash drive
# Run this from the flash drive root: powershell -ExecutionPolicy Bypass -File scripts\first-run.ps1

$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$flashRoot = Split-Path -Parent $scriptDir
$modelsDir = Join-Path $flashRoot "models"
$downloadDir = Join-Path $flashRoot ".downloads"

Write-Host ""
Write-Host "========================================="
Write-Host "  ALIVE APPLE — First Run Setup"
Write-Host "  iPhone 16 On-Device AI"
Write-Host "========================================="
Write-Host ""

# Ensure directories
New-Item -ItemType Directory -Force -Path $modelsDir | Out-Null
New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null

# Check free space
$freeGB = [math]::Round((Get-Volume -DriveLetter (Get-Location).Drive.Name).SizeRemaining / 1GB, 1)
Write-Host "Flash drive free space: $freeGB GB"
if ($freeGB -lt 20) {
    Write-Host "WARNING: Less than 20GB free. Need ~15GB for all models." -ForegroundColor Yellow
}
Write-Host ""

# Model definitions with verified HF repos
$models = @(
    @{
        File = "Phi-4-mini-instruct-Q4_K_M.gguf"
        Repo = "unsloth/Phi-4-mini-instruct-GGUF"
        Label = "Phi-4 Mini 3.8B (Fast Text)"
        Tier = "Fast"
        ExpectedGB = 2.4
    },
    @{
        File = "Qwen2.5-7B-Instruct-Q4_K_M.gguf"
        Repo = "bartowski/Qwen2.5-7B-Instruct-GGUF"
        Label = "Qwen2.5 7B (Moderate Text)"
        Tier = "Moderate"
        ExpectedGB = 4.4
    },
    @{
        File = "SmolVLM2-2.2B-Instruct-Q4_K_M.gguf"
        Repo = "ggml-org/SmolVLM2-2.2B-Instruct-GGUF"
        Label = "SmolVLM2 2.2B (Fast Vision)"
        Tier = "Fast"
        ExpectedGB = 1.1
    },
    @{
        File = "Qwen2.5-VL-7B-Instruct-Q4_K_M.gguf"
        Repo = "unsloth/Qwen2.5-VL-7B-Instruct-GGUF"
        Label = "Qwen2.5-VL 7B (Moderate Vision)"
        Tier = "Moderate"
        ExpectedGB = 4.4
    }
)

# Check which models are already present and valid
$toDownload = @()
$alreadyHave = @()

foreach ($m in $models) {
    $path = Join-Path $modelsDir $m.File
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $gb = [math]::Round($size / 1GB, 2)
        $expectedMin = [int64]($m.ExpectedGB * 0.9 * 1GB)
        
        # Verify GGUF header
        try {
            $fs = [System.IO.File]::OpenRead($path)
            $header = New-Object byte[] 4
            $fs.Read($header, 0, 4) | Out-Null
            $fs.Close()
            $magic = [System.Text.Encoding]::ASCII.GetString($header)
            if ($magic -eq "GGUF" -and $size -ge $expectedMin) {
                Write-Host "[OK] $gb GB  $($m.Label) — already present" -ForegroundColor Green
                $alreadyHave += $m
                continue
            }
        } catch {}
        
        Write-Host "[!!] $gb GB  $($m.Label) — invalid, will re-download" -ForegroundColor Yellow
        Remove-Item $path -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "[--] $($m.Label) — not found" -ForegroundColor Red
    }
    $toDownload += $m
}

Write-Host ""

if ($toDownload.Count -eq 0) {
    Write-Host "All models already present and verified!" -ForegroundColor Green
    Write-Host ""
    & "$scriptDir\check-models.ps1"
    exit 0
}

Write-Host "Need to download: $($toDownload.Count) model(s)"
Write-Host "Already have:      $($alreadyHave.Count) model(s)"
Write-Host ""

# Check for download tool
$hasHF = $false
try {
    $hfCheck = & hf --version 2>&1
    if ($LASTEXITCODE -eq 0 -or $hfCheck -match "huggingface") {
        $hasHF = $true
    }
} catch {}

if (-not $hasHF) {
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host "  huggingface-cli not found on this PC"
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To download the models, install Python and run:"
    Write-Host "  pip install huggingface_hub"
    Write-Host "  hf download REPO_ID FILENAME --local-dir ."
    Write-Host ""
    Write-Host "Or run this on a PC with Python installed."
    Write-Host ""
    Write-Host "Model download URLs (manual):"
    foreach ($m in $toDownload) {
        Write-Host "  https://huggingface.co/$($m.Repo)"
        Write-Host "  -> $($m.File)"
        Write-Host "  -> Save to: $modelsDir\$($m.File)"
        Write-Host ""
    }
    Write-Host "After downloading, run 'scripts\check-models.ps1' to verify."
    Write-Host ""
    pause
    exit 1
}

# Download each missing model
$allSuccess = $true
foreach ($m in $toDownload) {
    Write-Host ""
    Write-Host "--- Downloading: $($m.Label) ---" -ForegroundColor Cyan
    Write-Host "  Repo: $($m.Repo)"
    Write-Host "  File: $($m.File)"
    Write-Host "  Size: ~$($m.ExpectedGB) GB"
    Write-Host ""
    
    try {
        $downloadArgs = @(
            "download", $m.Repo, $m.File,
            "--local-dir", $downloadDir
        )
        
        $result = & hf @downloadArgs 2>&1
        Write-Host $result
        
        if ($LASTEXITCODE -ne 0) {
            throw "hf download failed with exit code $LASTEXITCODE"
        }
        
        # Find the downloaded file
        $dlFile = Get-ChildItem -Path $downloadDir -Filter $m.File -Recurse | Select-Object -First 1
        if (-not $dlFile) {
            # Maybe in a subdirectory
            $dlFiles = Get-ChildItem -Path $downloadDir -Filter "*.gguf" -Recurse | Where-Object { $_.Name -like "*Q4_K_M*" }
            $dlFile = $dlFiles | Select-Object -First 1
        }
        
        if ($dlFile) {
            # Move to models directory
            $dest = Join-Path $modelsDir $m.File
            Move-Item -Path $dlFile.FullName -Destination $dest -Force
            $gb = [math]::Round($dlFile.Length / 1GB, 2)
            Write-Host "[OK] Downloaded and saved: $gb GB" -ForegroundColor Green
        } else {
            Write-Host "[!!] Downloaded but couldn't find file. Check $downloadDir" -ForegroundColor Yellow
            $allSuccess = $false
        }
    } catch {
        Write-Host "[FAIL] $($_.Exception.Message)" -ForegroundColor Red
        $allSuccess = $false
    }
}

# Cleanup
Remove-Item $downloadDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "========================================="
if ($allSuccess) {
    Write-Host "  SETUP COMPLETE!" -ForegroundColor Green
} else {
    Write-Host "  Setup finished with some issues." -ForegroundColor Yellow
    Write-Host "  Run again to retry failed downloads."
}
Write-Host "========================================="
Write-Host ""

# Run status check
& "$scriptDir\check-models.ps1" -StatusOnly

Write-Host ""
Write-Host "Next: Eject flash drive -> plug into iPhone 16 -> ALIVE APPLE -> Import"
Write-Host ""

pause
