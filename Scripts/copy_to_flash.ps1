# ALIVE APPLE - Copy models to flash drive + verify
# Run after downloads complete in C:\Users\chris\alive_apple_downloads

$ErrorActionPreference = "Continue"
$source = "C:\Users\chris\alive_apple_downloads"
$dest = "D:\ALIVE_MODELS\models"

Write-Host "========================================="
Write-Host "  ALIVE APPLE - Model Copy and Verify"
Write-Host "========================================="
Write-Host "Source: $source"
Write-Host "Dest:   $dest"
Write-Host ""

$models = @(
    @{File="Phi-4-mini-instruct-Q4_K_M.gguf";      ExpectedGB=2.4; Label="Phi-4 Mini 3.8B (Fast Text)"},
    @{File="Qwen2.5-7B-Instruct-Q4_K_M.gguf";      ExpectedGB=4.4; Label="Qwen2.5 7B (Moderate Text)"},
    @{File="SmolVLM2-2.2B-Instruct-Q4_K_M.gguf";   ExpectedGB=1.1; Label="SmolVLM2 2.2B (Fast Vision)"},
    @{File="Qwen2.5-VL-7B-Instruct-Q4_K_M.gguf";   ExpectedGB=4.7; Label="Qwen2.5-VL 7B (Moderate Vision)"}
)

$totalCopied = 0
$totalFailed = 0
$totalSize = 0

foreach ($m in $models) {
    $srcPath = Join-Path $source $m.File
    $dstPath = Join-Path $dest $m.File
    $label = $m.Label

    Write-Host "---"
    Write-Host "[$(($models.IndexOf($m))+1)/$($models.Count)] $label"
    Write-Host "  File: $($m.File)"

    if (-not (Test-Path $srcPath)) {
        Write-Host "  SKIP: Source file not found" -ForegroundColor Yellow
        $totalFailed++
        continue
    }

    $srcSize = (Get-Item $srcPath).Length
    $srcGB = [math]::Round($srcSize / 1GB, 2)
    Write-Host "  Size: $srcGB GB"

    # Validate GGUF magic bytes (use FileStream for large files)
    Write-Host "  Validating GGUF header..."
    try {
        $fs = [System.IO.File]::OpenRead($srcPath)
        $header = New-Object byte[] 4
        $fs.Read($header, 0, 4) | Out-Null
        $fs.Close()
        $magic = [System.Text.Encoding]::ASCII.GetString($header)
        if ($magic -ne "GGUF") {
            Write-Host "  FAIL: Invalid GGUF header (got: $magic)" -ForegroundColor Red
            $totalFailed++
            continue
        }
        Write-Host "  GGUF header: OK" -ForegroundColor Green
    } catch {
        Write-Host "  FAIL: Cannot read file header: $_" -ForegroundColor Red
        $totalFailed++
        continue
    }

    # Size check - within 10% of expected
    $expectedMin = [int64]($m.ExpectedGB * 0.9 * 1GB)
    if ($srcSize -lt $expectedMin) {
        $msg = "  FAIL: File too small ($srcGB GB, expected about $($m.ExpectedGB) GB)"
        Write-Host $msg -ForegroundColor Red
        $totalFailed++
        continue
    }
    $msg = "  Size check: OK (expected about $($m.ExpectedGB) GB)"
    Write-Host $msg -ForegroundColor Green

    # SHA-256
    Write-Host "  Computing SHA-256..."
    $sha = (Get-FileHash -Path $srcPath -Algorithm SHA256).Hash
    $shortSha = $sha.Substring(0,16) + "..." + $sha.Substring($sha.Length-8)
    Write-Host "  SHA-256: $shortSha"

    # Copy to flash drive
    Write-Host "  Copying to D: drive..."
    try {
        Copy-Item $srcPath -Destination $dstPath -Force
        $totalCopied++
        $totalSize += $srcSize

        # Verify copy
        $dstSize = (Get-Item $dstPath).Length
        if ($dstSize -eq $srcSize) {
            Write-Host "  COPY OK: $srcGB GB" -ForegroundColor Green
        } else {
            Write-Host "  COPY MISMATCH: src=$srcSize dst=$dstSize" -ForegroundColor Red
            $totalFailed++
        }
    } catch {
        Write-Host "  COPY FAILED: $_" -ForegroundColor Red
        $totalFailed++
    }
}

Write-Host ""
Write-Host "========================================="
Write-Host "SUMMARY"
Write-Host "========================================="
Write-Host "  Copied: $totalCopied / $($models.Count)"
Write-Host "  Failed: $totalFailed"
$totalGB = [math]::Round($totalSize/1GB, 1)
Write-Host "  Total size: $totalGB GB"
Write-Host ""

# List final contents of D:\ALIVE_MODELS\models
Write-Host "D:\ALIVE_MODELS\models contents:"
Get-ChildItem $dest | ForEach-Object {
    $gb = [math]::Round($_.Length/1GB, 2)
    Write-Host "  $gb GB  $($_.Name)"
}

# Free space
$free = [math]::Round((Get-Volume -DriveLetter D).SizeRemaining/1GB, 1)
Write-Host ""
Write-Host "Flash drive free space: $free GB"

if ($totalFailed -eq 0) {
    Write-Host ""
    Write-Host "========================================="
    Write-Host "  ALL MODELS COPIED SUCCESSFULLY!"
    Write-Host "========================================="
    Write-Host ""
    Write-Host "  NEXT STEPS:"
    Write-Host "  1. Safely eject the flash drive"
    Write-Host "  2. Plug into iPhone 16 USB-C"
    Write-Host "  3. Open ALIVE APPLE > Models > Import from USB"
}
