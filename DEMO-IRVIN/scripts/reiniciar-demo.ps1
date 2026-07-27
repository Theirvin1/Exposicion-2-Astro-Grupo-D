# ==================================================
# DEMO-SGB - reiniciar-demo.ps1
# ==================================================
# Reinicia la demo DESDE CERO: borra los datos actuales, reconstruye
# los servicios y vuelve a levantarlos. Util cuando algo falla durante
# la exposicion y se necesita un estado limpio y predecible.
#
# NOTA: al recrear el volumen de PostgreSQL, db/init/01-consolidado.sql
# se vuelve a ejecutar, así que el admin y los catalogos (editoriales,
# idiomas, estados_libro, roles) se recrean automaticamente.
#
# Uso:
#   cd DEMO-SGB
#   .\scripts\reiniciar-demo.ps1

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot

Write-Host "==================================================" -ForegroundColor Yellow
Write-Host "ADVERTENCIA: esto eliminara los datos de PostgreSQL" -ForegroundColor Yellow
Write-Host "de esta demo (usuarios y libros registrados)." -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow
$confirmacion = Read-Host "Escribe SI para continuar"

if ($confirmacion -ne "SI") {
    Write-Host "Operacion cancelada." -ForegroundColor Cyan
    exit 0
}

Push-Location $raiz
try {
    Write-Host "Deteniendo y eliminando contenedores + volumenes..." -ForegroundColor Cyan
    docker compose down -v

    Write-Host "Reconstruyendo servicios..." -ForegroundColor Cyan
    docker compose build

    Write-Host "Levantando servicios..." -ForegroundColor Cyan
    docker compose up -d
} catch {
    Write-Host "ERROR durante el reinicio. Revisa el mensaje anterior." -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Host "Esperando a que el backend este saludable..." -ForegroundColor Cyan
$maximoIntentos = 30
$listo = $false
for ($i = 1; $i -le $maximoIntentos; $i++) {
    try {
        $respuesta = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -TimeoutSec 3
        if ($respuesta.status -eq "UP") {
            $listo = $true
            break
        }
    } catch {
        Start-Sleep -Seconds 3
    }
    Write-Host "Esperando backend... intento $i de $maximoIntentos" -ForegroundColor Yellow
}

if ($listo) {
    Write-Host "Backend saludable. Catalogos y admin de desarrollo recreados" -ForegroundColor Green
    Write-Host "automaticamente via db/init/01-consolidado.sql." -ForegroundColor Green
} else {
    Write-Host "ERROR: el backend no respondio saludable a tiempo." -ForegroundColor Red
    Write-Host "Revisa los logs con: docker compose logs backend" -ForegroundColor Red
    exit 1
}
