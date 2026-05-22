# Instala Memurai Developer (Redis en Windows) — ejecutar COMO ADMINISTRADOR.
# Clic derecho en PowerShell → "Ejecutar como administrador", luego:
#   cd C:\Proyectos\melodai_app
#   .\scripts\install-memurai.ps1

$ErrorActionPreference = "Stop"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Este script debe ejecutarse como Administrador." -ForegroundColor Red
    Write-Host "Abre PowerShell con clic derecho → Ejecutar como administrador" -ForegroundColor Yellow
    exit 1
}

Write-Host "=== Instalación Memurai Developer ===" -ForegroundColor Cyan

# Puerto 6379 ocupado
$portInUse = Get-NetTCPConnection -LocalPort 6379 -State Listen -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Host "[!!] El puerto 6379 ya está en uso (¿Redis/Memurai ya corre?):" -ForegroundColor Yellow
    $portInUse | Format-Table LocalAddress, OwningProcess
    $proc = Get-Process -Id $portInUse[0].OwningProcess -ErrorAction SilentlyContinue
    if ($proc) { Write-Host "     Proceso: $($proc.ProcessName)" }
}

$installed = winget list --id Memurai.MemuraiDeveloper --source winget 2>$null
if ($LASTEXITCODE -eq 0 -and $installed -match "Memurai") {
    Write-Host "[OK] Memurai ya está instalado (winget)" -ForegroundColor Green
} else {
    Write-Host "Instalando con winget..." -ForegroundColor Cyan
    winget install Memurai.MemuraiDeveloper --source winget --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Host "winget falló. Descarga manual: https://www.memurai.com/get-memurai" -ForegroundColor Red
        exit $LASTEXITCODE
    }
}

# Servicio Windows
$svc = Get-Service -Name "Memurai" -ErrorAction SilentlyContinue
if ($svc) {
    if ($svc.Status -ne "Running") {
        Start-Service Memurai
    }
    Write-Host "[OK] Servicio Memurai: $($svc.Status)" -ForegroundColor Green
} else {
    Write-Host "[--] Servicio 'Memurai' no encontrado; revisa instalación en Program Files\Memurai" -ForegroundColor Yellow
}

# Prueba PING Redis
Start-Sleep -Seconds 2
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect("127.0.0.1", 6379)
    $tcp.Close()
    Write-Host "[OK] Puerto 6379 responde" -ForegroundColor Green
} catch {
    Write-Host "[!!] No se pudo conectar a 127.0.0.1:6379" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Siguiente:" -ForegroundColor Cyan
Write-Host "  1. backend/.env y worker/.env → REDIS_URL=redis://127.0.0.1:6379"
Write-Host "  2. Reinicia: cd backend; npm run dev"
Write-Host "  3. Worker: cd worker; .venv\Scripts\activate; python main.py"
Write-Host "  4. Comprueba: Invoke-RestMethod http://127.0.0.1:3000/health"
