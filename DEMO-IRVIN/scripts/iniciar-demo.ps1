# ==================================================
# DEMO-SGB - iniciar-demo.ps1
# ==================================================
# Levanta PostgreSQL, Redis y el backend Spring Boot con Docker Compose.
# El cliente Astro se inicia aparte (ver el mensaje final de este script).
#
# Uso:
#   cd DEMO-SGB
#   .\scripts\iniciar-demo.ps1

$ErrorActionPreference = "Stop"
$raiz = Split-Path -Parent $PSScriptRoot

function Write-Titulo($texto) {
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host $texto -ForegroundColor Cyan
    Write-Host "==================================================" -ForegroundColor Cyan
}

Write-Titulo "1) Verificando Docker"
try {
    docker version | Out-Null
} catch {
    Write-Host "ERROR: Docker no esta instalado o el Docker Desktop no esta corriendo." -ForegroundColor Red
    Write-Host "Abre Docker Desktop y vuelve a ejecutar este script." -ForegroundColor Red
    exit 1
}
Write-Host "Docker esta disponible." -ForegroundColor Green

Write-Titulo "2) Preparando archivo .env"
$envPath = Join-Path $raiz ".env"
$envEjemploPath = Join-Path $raiz ".env.example"
if (-not (Test-Path $envPath)) {
    Copy-Item $envEjemploPath $envPath
    Write-Host "Se creo .env a partir de .env.example." -ForegroundColor Yellow
} else {
    Write-Host ".env ya existe, no se sobrescribe." -ForegroundColor Green
}

Write-Titulo "3) Levantando PostgreSQL, Redis y el backend"
Push-Location $raiz
try {
    docker compose up -d --build
} catch {
    Write-Host "ERROR: fallo 'docker compose up'. Revisa el mensaje anterior." -ForegroundColor Red
    Pop-Location
    exit 1
}
Pop-Location

Write-Titulo "4) Esperando a que el backend este saludable"
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

if (-not $listo) {
    Write-Host "ERROR: el backend no respondio saludable a tiempo." -ForegroundColor Red
    Write-Host "Revisa los logs con: docker compose logs backend" -ForegroundColor Red
    exit 1
}

Write-Titulo "Backend listo"
Write-Host "Swagger:   http://localhost:8080/swagger-ui.html" -ForegroundColor Green
Write-Host "Actuator:  http://localhost:8080/actuator/health" -ForegroundColor Green
Write-Host "PostgreSQL publicado: localhost:5433" -ForegroundColor Green
Write-Host "Redis publicado:      localhost:6380" -ForegroundColor Green
Write-Host ""
Write-Host "Para iniciar el cliente Astro, en OTRA terminal ejecuta:" -ForegroundColor Cyan
Write-Host "  cd astro-cliente" -ForegroundColor White
Write-Host "  npm install   (solo la primera vez)" -ForegroundColor White
Write-Host "  npm run dev" -ForegroundColor White
Write-Host ""
Write-Host "Astro quedara disponible en: http://localhost:4321" -ForegroundColor Green
