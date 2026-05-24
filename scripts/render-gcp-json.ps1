# Muestra service-account.json en una linea para GOOGLE_SERVICE_ACCOUNT_JSON en Render.
$ErrorActionPreference = "Stop"
$path = Join-Path (Split-Path -Parent $PSScriptRoot) "backend\service-account.json"

if (-not (Test-Path $path)) {
    Write-Host "No existe backend\service-account.json" -ForegroundColor Red
    exit 1
}

$json = Get-Content $path -Raw | ConvertFrom-Json | ConvertTo-Json -Compress
Write-Host ""
Write-Host "Copia esto en Render -> GOOGLE_SERVICE_ACCOUNT_JSON:" -ForegroundColor Cyan
Write-Host ""
Write-Host $json
Write-Host ""
