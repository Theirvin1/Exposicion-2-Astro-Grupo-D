# ==================================================
# DEMO-SGB - verificar-demo.ps1
# ==================================================
# Comprueba que todos los componentes de la demo esten funcionando:
# puertos, Actuator, registro, login, token, listado de libros,
# PostgreSQL y Redis. Muestra un resumen final con lo que esta
# correcto y lo que falla.
#
# NOTA: se registra un usuario temporal (rol LECTOR por defecto) en vez
# de usar el admin sembrado, porque el admin de seed.sql tiene rol ADMIN
# y /api/v1/libros (GET) solo acepta LECTOR/BIBLIOTECARIO/GERENTE. Para
# probar POST/PUT/DELETE (que si requieren BIBLIOTECARIO o GERENTE) hazlo
# manualmente desde el cliente Astro despues de ajustar un rol en la BD
# (ver CODIGOS-EXPOSICION.txt).
#
# Uso:
#   cd DEMO-SGB
#   .\scripts\verificar-demo.ps1

$ErrorActionPreference = "SilentlyContinue"
$resultados = @()

function Test-Puerto($puerto, $nombre) {
    $conexion = Test-NetConnection -ComputerName "localhost" -Port $puerto -WarningAction SilentlyContinue
    return $conexion.TcpTestSucceeded
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "VERIFICACION DE LA DEMO SGB-SAAS + ASTRO" -ForegroundColor Cyan
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

# 3) Registro de un usuario temporal (rol LECTOR por defecto)
Write-Host "[3/8] Registro de usuario temporal..." -ForegroundColor Yellow
$correoTemp = "verificacion.$(Get-Random)@sgb-saas.local"
$passwordTemp = "Verificar123!"
$okRegistro = $false
try {
    $cuerpoRegistro = @{
        nombre = "Verificacion"; apellido = "Demo"
        correo = $correoTemp; password = $passwordTemp
    } | ConvertTo-Json
    Invoke-RestMethod -Uri "http://localhost:8080/api/auth/registro" `
        -Method Post -Body $cuerpoRegistro -ContentType "application/json" -TimeoutSec 5 | Out-Null
    $okRegistro = $true
} catch {}
$resultados += [pscustomobject]@{ Prueba = "Registro de usuario temporal"; Resultado = $okRegistro }

# 4) Login con el usuario temporal
Write-Host "[4/8] Login con el usuario temporal..." -ForegroundColor Yellow
$token = $null
$okLogin = $false
if ($okRegistro) {
    try {
        $cuerpoLogin = @{ correo = $correoTemp; password = $passwordTemp } | ConvertTo-Json
        $respuestaLogin = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" `
            -Method Post -Body $cuerpoLogin -ContentType "application/json" `
            -SessionVariable sesionWeb -TimeoutSec 5
        $token = $respuestaLogin.accessToken
        $okLogin = ($null -ne $token -and $token -ne "")
    } catch {}
}
$resultados += [pscustomobject]@{ Prueba = "Login usuario temporal"; Resultado = $okLogin }

# 5) Obtencion del accessToken
Write-Host "[5/8] accessToken recibido..." -ForegroundColor Yellow
$resultados += [pscustomobject]@{ Prueba = "accessToken recibido"; Resultado = $okLogin }

# 6) GET /api/v1/libros (rol LECTOR ya es suficiente para esto)
Write-Host "[6/8] GET /api/v1/libros..." -ForegroundColor Yellow
$okGetLibros = $false
if ($okLogin) {
    try {
        $cabeceras = @{ Authorization = "Bearer $token" }
        $respuestaLibros = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/libros?page=0&size=10" `
            -Headers $cabeceras -TimeoutSec 5
        $okGetLibros = $true
    } catch {}
}
$resultados += [pscustomobject]@{ Prueba = "GET /api/v1/libros responde"; Resultado = $okGetLibros }

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
    Write-Host "Recuerda: POST/PUT/DELETE de libros requieren rol BIBLIOTECARIO o" -ForegroundColor Yellow
    Write-Host "GERENTE (ver CODIGOS-EXPOSICION.txt para ajustar el rol del admin)." -ForegroundColor Yellow
} else {
    Write-Host "$fallos prueba(s) fallaron. Revisa docker compose logs antes de exponer." -ForegroundColor Red
}
