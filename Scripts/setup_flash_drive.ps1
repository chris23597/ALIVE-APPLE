# ALIVE APPLE — Flash Drive Setup Script
# Creates directory structure and copies reference docs to D:\ALIVE_MODELS

$ErrorActionPreference = "Stop"
$base = "D:\ALIVE_MODELS"

Write-Host "=== Setting up ALIVE APPLE on D:\ ==="

# Create directory structure
New-Item -ItemType Directory -Force -Path $base | Out-Null
New-Item -ItemType Directory -Force -Path "$base\models" | Out-Null
New-Item -ItemType Directory -Force -Path "$base\docs" | Out-Null

Write-Host "Created: $base"
Write-Host "Created: $base\models"
Write-Host "Created: $base\docs"

# Copy reference docs from CodeWhale project (using WSL path via \\wsl$\ or direct C:)
$source = "C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE"

$docs = @(
    "README.md",
    "BUILD_GUIDE.md",
    "USB_SETUP.md",
    "MODEL_INVENTORY.md"
)

foreach ($doc in $docs) {
    $src = Join-Path $source $doc
    if (Test-Path $src) {
        Copy-Item $src -Destination $base -Force
        Write-Host "Copied: $doc"
    } else {
        Write-Host "WARNING: Not found: $src"
    }
}

# List final structure
Write-Host ""
Write-Host "=== D:\ALIVE_MODELS structure ==="
Get-ChildItem -Recurse $base | ForEach-Object {
    $size = if ($_.PSIsContainer) { "[DIR]" } else { "$([math]::Round($_.Length/1KB, 1)) KB" }
    $relPath = $_.FullName.Replace($base, "").TrimStart("\")
    Write-Host "  $size  $relPath"
}

Write-Host ""
Write-Host "Drive free space: $([math]::Round((Get-Volume -DriveLetter D).SizeRemaining/1GB, 1)) GB"
Write-Host "=== Setup complete! Ready for model downloads. ==="
