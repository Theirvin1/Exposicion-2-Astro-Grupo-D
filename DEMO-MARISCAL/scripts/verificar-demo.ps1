# ==================================================
# DEMO-MARISCAL - verificar-demo.ps1
# ==================================================
# Comprueba que todos los componentes de la demo esten funcionando:
# puertos, Actuator, login, token, listado de mascotas, PostgreSQL y Redis.
# Muestra un resumen final con lo que esta correcto y lo que falla.
#
# Uso:
#   cd DEMO-MARISCAL
#   .\scripts\verificar-demo.ps1

$ErrorActionPreference = "SilentlyContinue"
$resultados = @()

function Test-Puerto($puerto, $nombre) {
    $conexion = Test-NetConnection -ComputerName "localhost" -Port $puerto -WarningAction SilentlyContinue
    return $conexion.TcpTestSucceeded
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "VERIFICACION DE LA DEMO BIOPET" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1) Puerto 8080 (backend)
Write-Host "`n[1/8] Puerto 8080 (backend)..." -ForegroundColor Yellow
$ok8080 = Test-Puerto -puerto 8080 -nombre "backend"
$resultados += [pscustomobject]@{ Prueba = "Puerto 8080 (backend)"; Resultado = $ok8080 }

# 2) Actuator health
Write-Host "[2/8] Actuator /actuator/health..." -ForegroundColor Yellow
$okActuator = $false
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -TimeoutSec 5
    $okActuator = ($health.status -eq "UP")
} catch {}
$resultados += [pscustomobject]@{ Prueba = "Actuator health = UP"; Resultado = $okActuator }

# 3) Login con admin@biopet.ec
Write-Host "[3/8] Login con admin@biopet.ec..." -ForegroundColor Yellow
$token = $null
$okLogin = $false
try {
    $cuerpoLogin = @{ email = "admin@biopet.ec"; password = "Admin123*" } | ConvertTo-Json
    $respuestaLogin = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" `
        -Method Post -Body $cuerpoLogin -ContentType "application/json" -TimeoutSec 5
    $token = $respuestaLogin.accessToken
    $okLogin = ($null -ne $token -and $token -ne "")
} catch {}
$resultados += [pscustomobject]@{ Prueba = "Login admin@biopet.ec"; Resultado = $okLogin }

# 4) Obtencion del token JWT
Write-Host "[4/8] Token JWT recibido..." -ForegroundColor Yellow
$resultados += [pscustomobject]@{ Prueba = "Token JWT recibido"; Resultado = $okLogin }

# 5) GET /api/mascotas
Write-Host "[5/8] GET /api/mascotas..." -ForegroundColor Yellow
$okGetMascotas = $false
$tieneAlMenosUnaMascota = $false
if ($okLogin) {
    try {
        $cabeceras = @{ Authorization = "Bearer $token" }
        $respuestaMascotas = Invoke-RestMethod -Uri "http://localhost:8080/api/mascotas" -Headers $cabeceras -TimeoutSec 5
        $okGetMascotas = $true
        $listaMascotas = if ($respuestaMascotas.content) { $respuestaMascotas.content } else { $respuestaMascotas }
        $tieneAlMenosUnaMascota = ($listaMascotas.Count -gt 0)
    } catch {}
}
$resultados += [pscustomobject]@{ Prueba = "GET /api/mascotas responde"; Resultado = $okGetMascotas }

# 6) Existe al menos una mascota
Write-Host "[6/8] Al menos una mascota registrada..." -ForegroundColor Yellow
$resultados += [pscustomobject]@{ Prueba = "Existe al menos 1 mascota"; Resultado = $tieneAlMenosUnaMascota }

# 7) Puerto 5433 (PostgreSQL publicado por Docker)
Write-Host "[7/8] Puerto 5433 (PostgreSQL publicado por Docker)..." -ForegroundColor Yellow
$ok5433 = Test-Puerto -puerto 5433 -nombre "postgres"
$resultados += [pscustomobject]@{ Prueba = "Puerto 5433 (PostgreSQL Docker)"; Resultado = $ok5433 }

# 8) Puerto 6380 (Redis publicado por Docker)
Write-Host "[8/8] Puerto 6380 (Redis publicado por Docker)..." -ForegroundColor Yellow
$ok6380 = Test-Puerto -puerto 6380 -nombre "redis"
$resultados += [pscustomobject]@{ Prueba = "Puerto 6380 (Redis Docker)"; Resultado = $ok6380 }

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "RESUMEN" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

foreach ($r in $resultados) {
    if ($r.Resultado) {
        Write-Host ("  [OK]    " + $r.Prueba) -ForegroundColor Green
    } else {
        Write-Host ("  [FALLO] " + $r.Prueba) -ForegroundColor Red
    }
}

$fallos = ($resultados | Where-Object { -not $_.Resultado }).Count
Write-Host ""
if ($fallos -eq 0) {
    Write-Host "Todo esta funcionando correctamente. Lista para exponer." -ForegroundColor Green
} else {
    Write-Host "$fallos prueba(s) fallaron. Revisa docker compose logs antes de exponer." -ForegroundColor Red
}
