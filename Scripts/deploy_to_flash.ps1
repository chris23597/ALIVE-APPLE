# Deploy all ALIVE APPLE files to flash drive
$src = "C:\Users\chris\CodeWhale\demo-other-project\ALIVE_APPLE"
$flash = "D:\ALIVE_MODELS"
$launcher = "$src\flash-drive"

Write-Host "=== Deploying ALIVE APPLE to Flash Drive ==="

# Launcher files
Copy-Item "$launcher\autorun.inf" -Destination $flash -Force
Copy-Item "$launcher\START-HERE.bat" -Destination $flash -Force
Copy-Item "$launcher\dashboard.html" -Destination $flash -Force

# Scripts (flash-drive)
New-Item -ItemType Directory -Force -Path "$flash\scripts" | Out-Null
Copy-Item "$launcher\scripts\*" -Destination "$flash\scripts\" -Force

# Root docs
Copy-Item "$src\README.md" -Destination $flash -Force
Copy-Item "$src\BUILD_GUIDE.md" -Destination $flash -Force
Copy-Item "$src\MODEL_INVENTORY.md" -Destination $flash -Force
Copy-Item "$src\USB_SETUP.md" -Destination $flash -Force

# ========================================
# XCODE PROJECT (for building on Mac)
# ========================================
$xcBase = "$flash\ALIVE_APPLE_Xcode"

# Config files
Copy-Item "$src\project.yml" -Destination "$xcBase\" -Force
Copy-Item "$src\build.sh" -Destination "$xcBase\" -Force

# Info.plist
New-Item -ItemType Directory -Force -Path "$xcBase\Xcode" | Out-Null
Copy-Item "$src\Xcode\Info.plist" -Destination "$xcBase\Xcode\" -Force

# Swift source
$swiftBase = "$xcBase\ALIVE_APPLE"
$dirs = @("Models", "Services", "Views", "ViewModels", "Utils")
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path "$swiftBase\$d" | Out-Null
    Copy-Item "$src\ALIVE_APPLE\$d\*.swift" -Destination "$swiftBase\$d\" -Force
}
Copy-Item "$src\ALIVE_APPLE\*.swift" -Destination "$swiftBase\" -Force

# Asset catalog with app icon
New-Item -ItemType Directory -Force -Path "$xcBase\Xcode\Assets.xcassets\AppIcon.appiconset" | Out-Null
New-Item -ItemType Directory -Force -Path "$xcBase\Xcode\Assets.xcassets\LaunchBackground.colorset" | Out-Null
Copy-Item "$src\Xcode\Assets.xcassets\Contents.json" -Destination "$xcBase\Xcode\Assets.xcassets\" -Force
Copy-Item "$src\Xcode\Assets.xcassets\AppIcon.appiconset\*" -Destination "$xcBase\Xcode\Assets.xcassets\AppIcon.appiconset\" -Force -ErrorAction SilentlyContinue
Copy-Item "$src\Xcode\Assets.xcassets\LaunchBackground.colorset\*" -Destination "$xcBase\Xcode\Assets.xcassets\LaunchBackground.colorset\" -Force -ErrorAction SilentlyContinue

# Source: docs + scripts
New-Item -ItemType Directory -Force -Path "$xcBase\Docs" | Out-Null
New-Item -ItemType Directory -Force -Path "$xcBase\Scripts" | Out-Null
Copy-Item "$src\Docs\*.md" -Destination "$xcBase\Docs\" -Force -ErrorAction SilentlyContinue
Copy-Item "$src\Scripts\*.sh" -Destination "$xcBase\Scripts\" -Force -ErrorAction SilentlyContinue
Copy-Item "$src\Scripts\*.py" -Destination "$xcBase\Scripts\" -Force -ErrorAction SilentlyContinue
Copy-Item "$src\ARCHITECTURE.md" -Destination "$xcBase\" -Force
Copy-Item "$src\PRD.md" -Destination "$xcBase\" -Force

# ========================================
# Source reference (same as before)
# ========================================
$srcBase = "$flash\source\ALIVE_APPLE"
New-Item -ItemType Directory -Force -Path "$srcBase\Models" | Out-Null
New-Item -ItemType Directory -Force -Path "$srcBase\Services" | Out-Null
New-Item -ItemType Directory -Force -Path "$srcBase\Views" | Out-Null
New-Item -ItemType Directory -Force -Path "$srcBase\ViewModels" | Out-Null
New-Item -ItemType Directory -Force -Path "$srcBase\Utils" | Out-Null
Copy-Item "$src\ALIVE_APPLE\*.swift" -Destination "$srcBase\" -Force
Copy-Item "$src\ALIVE_APPLE\Models\*.swift" -Destination "$srcBase\Models\" -Force
Copy-Item "$src\ALIVE_APPLE\Services\*.swift" -Destination "$srcBase\Services\" -Force
Copy-Item "$src\ALIVE_APPLE\Views\*.swift" -Destination "$srcBase\Views\" -Force
Copy-Item "$src\ALIVE_APPLE\ViewModels\*.swift" -Destination "$srcBase\ViewModels\" -Force
Copy-Item "$src\ALIVE_APPLE\Utils\*.swift" -Destination "$srcBase\Utils\" -Force
New-Item -ItemType Directory -Force -Path "$flash\source\Scripts" | Out-Null
New-Item -ItemType Directory -Force -Path "$flash\source\Docs" | Out-Null
Copy-Item "$src\Scripts\download_models.sh" -Destination "$flash\source\Scripts\" -Force
Copy-Item "$src\Scripts\convert_to_coreml.py" -Destination "$flash\source\Scripts\" -Force
Copy-Item "$src\Docs\*.md" -Destination "$flash\source\Docs\" -Force -ErrorAction SilentlyContinue
Copy-Item "$src\ARCHITECTURE.md" -Destination "$flash\source\" -Force
Copy-Item "$src\PRD.md" -Destination "$flash\source\" -Force

Write-Host ""
Write-Host "=== Flash Drive Contents ==="
Get-ChildItem $flash -Recurse -Depth 3 | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
    $rel = $_.FullName.Replace($flash, "").TrimStart("\")
    $kb = [math]::Round($_.Length / 1KB, 1)
    Write-Host "  $kb KB  $rel"
}

Write-Host ""
Write-Host "=== Deploy Complete ==="
Write-Host "=== ALIVE_APPLE_Xcode/  <- open this on a Mac, run: bash build.sh ==="
