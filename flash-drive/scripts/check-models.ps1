# ALIVE APPLE - Model Status Checker
param([switch]$StatusOnly)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$flashRoot = Split-Path -Parent $scriptDir
$modelsDir = Join-Path $flashRoot "models"

$models = @(
    @{File="Phi-4-mini-instruct-Q4_K_M.gguf";    Label="Phi-4 Mini 3.8B (Fast Text)";     Tier="Fast"},
    @{File="Qwen2.5-7B-Instruct-Q4_K_M.gguf";    Label="Qwen2.5 7B (Moderate Text)";      Tier="Moderate"},
    @{File="SmolVLM2-2.2B-Instruct-Q4_K_M.gguf"; Label="SmolVLM2 2.2B (Fast Vision)";     Tier="Fast"},
    @{File="Qwen2.5-VL-7B-Instruct-Q4_K_M.gguf"; Label="Qwen2.5-VL 7B (Moderate Vision)"; Tier="Moderate"}
)

$results = @()
$allOk = $true

foreach ($m in $models) {
    $path = Join-Path $modelsDir $m.File
    $ok = $false
    $sizeStr = ""
    
    if (Test-Path $path) {
        $size = (Get-Item $path).Length
        $gb = [math]::Round($size / 1GB, 2)
        $sizeStr = "$gb GB"
        
        try {
            $fs = [System.IO.File]::OpenRead($path)
            $header = New-Object byte[] 4
            $fs.Read($header, 0, 4) | Out-Null
            $fs.Close()
            $magic = [System.Text.Encoding]::ASCII.GetString($header)
            $ok = ($magic -eq "GGUF")
        } catch {
            $ok = $false
        }
    }
    
    if (-not $ok) { $allOk = $false }
    
    $results += @{
        file = $m.File
        label = $m.Label
        tier = $m.Tier
        size = $sizeStr
        ok = $ok
    }
}

Write-Host ""
Write-Host "========================================="
Write-Host "  ALIVE APPLE - Flash Drive Status"
Write-Host "========================================="
Write-Host ""

foreach ($r in $results) {
    $icon = if ($r.ok) { "[OK]" } else { "[--]" }
    $col = if ($r.ok) { "Green" } else { "Red" }
    Write-Host "  $icon  $($r.size)  $($r.label)" -ForegroundColor $col
}

Write-Host ""
if ($allOk) {
    Write-Host "  STATUS: ALL MODELS READY!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  NEXT: Eject flash drive, plug into iPhone 16."
    Write-Host "  Open ALIVE APPLE -> Models -> Import from USB"
} else {
    Write-Host "  STATUS: Models missing" -ForegroundColor Yellow
    Write-Host "  Run first-run.ps1 to download missing models."
}

Write-Host ""

if (-not $StatusOnly) {
    Read-Host "Press Enter to close"
}
