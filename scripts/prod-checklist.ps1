# Comprueba variables locales de produccion (backend/.env) sin mostrar secretos.
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $root "backend\.env"

Write-Host "MelodAI - checklist produccion (local)" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $envFile)) {
    Write-Host '[X] No existe backend\.env' -ForegroundColor Red
    exit 1
}

$vars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $vars[$matches[1].Trim()] = $matches[2].Trim()
    }
}

function Test-Var([string]$Name, [scriptblock]$Ok) {
    $val = $vars[$Name]
    if (-not $val) {
        Write-Host ('[ ] ' + $Name + ' - vacio') -ForegroundColor Yellow
        return $false
    }
    if (& $Ok $val) {
        Write-Host ('[OK] ' + $Name) -ForegroundColor Green
        return $true
    }
    Write-Host ('[!] ' + $Name + ' - revisar valor') -ForegroundColor Yellow
    return $false
}

$score = 0
$total = 0

$checks = @(
    @{ N = "MONGODB_URI"; T = { param($v) $v -match "^mongodb\+srv://" } },
    @{ N = "MONGODB_DB"; T = { param($v) $v -eq "melodai" } },
    @{ N = "REDIS_URL"; T = { param($v) $v -match "^rediss?://" } },
    @{ N = "SEPARATION_WORKER_MODE"; T = { param($v) $v -eq "redis" } },
    @{ N = "SEPARATION_REDIS_FALLBACK_STUB"; T = { param($v) $v -eq "false" } },
    @{ N = "AUTH_DISABLED"; T = { param($v) $v -eq "false" } },
    @{ N = "FIREBASE_PROJECT_ID"; T = { param($v) $v -eq "melodaiapp" } },
    @{ N = "GCS_BUCKET_NAME"; T = { param($v) $v.Length -gt 0 } },
    @{ N = "WORKER_API_KEY"; T = { param($v) $v.Length -ge 16 -and $v -ne "dev-worker-key-change-me" } },
    @{ N = "FIREBASE_WEB_API_KEY"; T = { param($v) $v.Length -gt 20 } }
)

foreach ($c in $checks) {
    $total++
    if (Test-Var $c.N $c.T) { $score++ }
}

Write-Host ""
$color = if ($score -eq $total) { "Green" } else { "Yellow" }
Write-Host ($score.ToString() + " / " + $total.ToString() + " comprobaciones OK en backend\.env") -ForegroundColor $color

if ($vars["REDIS_URL"] -match "^redis://127") {
    Write-Host ""
    Write-Host "Nota: REDIS_URL apunta a Redis local. Para prod usa Upstash (rediss://)." -ForegroundColor DarkGray
}

if ($vars["WORKER_API_KEY"] -eq "dev-worker-key-change-me") {
    Write-Host "Genera clave prod: .\scripts\prod-generate-secrets.ps1" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Siguiente: docs/DESPLIEGUE_PROD_PASOS.md paso 2 Upstash" -ForegroundColor Cyan
