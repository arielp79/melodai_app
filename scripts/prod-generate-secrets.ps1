# Genera un WORKER_API_KEY seguro para producción (no lo subas a git).
$bytes = New-Object byte[] 32
[System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
$key = [Convert]::ToBase64String($bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')

Write-Host ""
Write-Host "WORKER_API_KEY (copia en Secret Manager / Render / worker prod):" -ForegroundColor Cyan
Write-Host $key
Write-Host ""
Write-Host "Usa el mismo valor en backend (Cloud Run) y worker (RunPod/VM)." -ForegroundColor DarkGray
