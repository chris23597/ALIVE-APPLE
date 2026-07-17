# Verify GGUF headers on flash drive models
$models = @("Phi-4-mini-instruct-Q4_K_M.gguf", "Qwen2.5-7B-Instruct-Q4_K_M.gguf", "SmolVLM2-2.2B-Instruct-Q4_K_M.gguf", "Qwen2.5-VL-7B-Instruct-Q4_K_M.gguf")
$dest = "D:\ALIVE_MODELS\models"

foreach ($f in $models) {
    $path = Join-Path $dest $f
    $size = (Get-Item $path).Length
    $gb = [math]::Round($size/1GB, 2)
    
    $fs = [System.IO.File]::OpenRead($path)
    $header = New-Object byte[] 4
    $fs.Read($header, 0, 4) | Out-Null
    $fs.Close()
    $magic = [System.Text.Encoding]::ASCII.GetString($header)
    
    $status = if ($magic -eq "GGUF") { "OK" } else { "FAIL" }
    Write-Host "[$status] $gb GB  $f"
}

Write-Host ""
Write-Host "Total: $(Get-ChildItem $dest | Measure-Object -Property Length -Sum | ForEach-Object { [math]::Round($_.Sum/1GB, 1) }) GB"
