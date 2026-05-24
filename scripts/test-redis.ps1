# Prueba REDIS_URL de backend/.env con el Python del worker (redis + truststore).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$py = Join-Path $root "worker\.venv\Scripts\python.exe"

if (-not (Test-Path $py)) {
    Write-Host "No existe worker\.venv. Crea el venv:" -ForegroundColor Red
    Write-Host "  cd worker; python -m venv .venv; .\.venv\Scripts\pip install -r requirements.txt"
    exit 1
}

& $py (Join-Path $root "scripts\test-redis.py")
exit $LASTEXITCODE
