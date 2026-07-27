# ==================================================
# DEMO-MARISCAL - detener-demo.ps1
# ==================================================
# Detiene los contenedores de la demo SIN borrar los datos
# almacenados en PostgreSQL (el volumen se conserva).
#
# Uso:
#   cd DEMO-MARISCAL
#   .\scripts\detener-demo.ps1

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot

Write-Host "Deteniendo contenedores de la demo (los datos se conservan)..." -ForegroundColor Cyan

Push-Location $raiz
try {
    docker compose stop
    Write-Host "Contenedores detenidos." -ForegroundColor Green
} catch {
    Write-Host "ERROR: no se pudo detener docker compose. Revisa el mensaje anterior." -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location
