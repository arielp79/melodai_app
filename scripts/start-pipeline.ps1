# Arranca Redis y comprueba que el pipeline real puede funcionar.
# Uso: .\scripts\start-pipeline.ps1
# Luego en terminales separadas: backend (npm run dev) y worker (python main.py)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "=== MelodAI — Pipeline real ===" -ForegroundColor Cyan

# 1. Redis
Set-Location $Root
$redisRunning = $false
try {
    docker compose ps --format json 2>$null | Out-Null
    docker compose up -d
    Start-Sleep -Seconds 2
    $redisRunning = $true
    Write-Host "[OK] Redis (docker compose up -d)" -ForegroundColor Green
} catch {
    Write-Host "[!!] Docker no disponible." -ForegroundColor Yellow
    Write-Host "     Opciones: Upstash (rediss:// en .env) | winget install Memurai.MemuraiDeveloper --source winget" -ForegroundColor Yellow
}

# 2. ffmpeg (worker)
$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if ($ffmpeg) {
    Write-Host "[OK] ffmpeg en PATH" -ForegroundColor Green
} else {
    Write-Host "[!!] ffmpeg no encontrado — el worker fallará con HTDemucs" -ForegroundColor Yellow
    Write-Host "     Instala: winget install ffmpeg" -ForegroundColor Yellow
}

# 3. Credenciales GCS
$sa = Join-Path $Root "backend\service-account.json"
if (Test-Path $sa) {
    Write-Host "[OK] service-account.json" -ForegroundColor Green
} else {
    Write-Host "[!!] Falta backend\service-account.json" -ForegroundColor Red
}

# 4. Health del orquestador (si ya está corriendo)
try {
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:3000/health" -TimeoutSec 3
    $mode = $health.separation.effectiveMode
    $redisOk = $health.separation.redisOk
    if ($mode -eq "redis" -and $redisOk) {
        Write-Host "[OK] Orquestador: modo redis, Redis OK" -ForegroundColor Green
    } elseif ($mode -eq "stub") {
        Write-Host "[!!] Orquestador en modo STUB — reinicia backend tras levantar Redis" -ForegroundColor Yellow
    } else {
        Write-Host "[--] Orquestador: modo=$mode redisOk=$redisOk" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[--] Orquestador no responde en :3000 (arranca: cd backend; npm run dev)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Siguiente:" -ForegroundColor Cyan
Write-Host "  Terminal 1: cd backend; npm run dev"
Write-Host "  Terminal 2: cd worker; .venv\Scripts\activate; python main.py"
Write-Host "  Terminal 3: flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:3000"
Write-Host ""
Write-Host "Comprueba GET http://127.0.0.1:3000/health → separation.effectiveMode debe ser 'redis'"
