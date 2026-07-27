# DEMO-SGB — Sistema de Gestion de Bibliotecas

Backend Spring Boot + Frontend Astro que consume la API REST via `fetch`.
Docker Compose levanta PostgreSQL, Redis y el backend. El cliente Astro se ejecuta por separado.

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) corriendo
- [Node.js](https://nodejs.org/) >= 18

## Estructura del proyecto

```
DEMO-SGB/
├── docker-compose.yml           # PostgreSQL + Redis + Backend Spring Boot
├── .env.example                 # Variables de entorno (copiar a .env)
├── astro-cliente/               # Frontend Astro (se ejecuta con npm)
│   └── src/pages/index.astro   # SPA que consume la API via fetch
├── backend-springboot/          # API REST (Spring Boot 4 + Java 21)
│   ├── Dockerfile               # Build multi-etapa
│   ├── pom.xml                  # Dependencias (JPA, Redis, JWT, Flyway...)
│   └── src/main/java/com/uteq/backend/
│       ├── config/              # SecurityConfig (CORS, JWT, roles)
│       ├── controller/          # AuthController, LibroController
│       ├── entity/              # Entidades JPA (Libro, Usuario, Rol...)
│       ├── repository/          # JpaRepository + Stored Procedures
│       ├── security/            # Filtro JWT,JwtService, UserDetailsService
│       └── service/             # Logica de negocio + cache Redis
├── db/init/01-consolidado.sql   # Schema + procedimientos + seed de PostgreSQL
└── scripts/                     # Scripts PowerShell para la demo
```

## Ejecucion paso a paso

### Paso 1: Levantar el backend (Docker)

```powershell
cd DEMO-SGB
.\scripts\iniciar-demo.ps1
```

Esto crea PostgreSQL (puerto 5433), Redis (puerto 6380) y el backend (puerto 8080).
Espera a que el backend este saludable antes de continuar.

### Paso 2: Levantar el frontend Astro

En una **segunda terminal**:

```powershell
cd astro-cliente
npm install        # solo la primera vez
npm run dev
```

### Paso 3: Abrir en el navegador

- **Frontend:** http://localhost:4321
- **Swagger UI:** http://localhost:8080/swagger-ui.html
- **Actuator health:** http://localhost:8080/actuator/health

## Verificar que todo funciona

```powershell
.\scripts\verificar-demo.ps1
```

## Credenciales de prueba

| Campo     | Valor                  |
|-----------|------------------------|
| Correo    | admin@sgb-saas.local   |
| Password  | Admin123!              |

> **Nota:** el admin sembrado tiene rol `ADMIN`, pero `/api/v1/libros` solo acepta
> `LECTOR`, `BIBLIOTECARIO` o `GERENTE`. Para probar crear/editar/eliminar libros,
> cambia el rol con un INSERT en la BD (ver `CODIGOS-EXPOSICION.txt`).

## Scripts PowerShell

| Script                  | Que hace                                     |
|-------------------------|----------------------------------------------|
| `iniciar-demo.ps1`      | Levanta Docker + espera backend saludable     |
| `detener-demo.ps1`      | Detiene contenedores (conserva datos)         |
| `reiniciar-demo.ps1`    | Borra datos, reconstruye y relanza todo       |
| `verificar-demo.ps1`    | Health check completo de los 3 servicios      |

## Endpoints de la API

| Metodo | Ruta                    | Auth         | Que hace                        |
|--------|-------------------------|--------------|---------------------------------|
| POST   | /api/auth/registro      | publico      | Registra usuario (rol LECTOR)   |
| POST   | /api/auth/login         | publico      | Login, devuelve JWT             |
| POST   | /api/auth/logout        | Bearer token | Revoca token (Redis blacklist)  |
| POST   | /api/auth/refresh       | cookie       | Renueva accessToken             |
| GET    | /api/v1/libros          | Bearer token | Lista libros (paginado)         |
| POST   | /api/v1/libros          | Bearer token | Crea libro (BIBLIOTECARIO+)     |
| PUT    | /api/v1/libros/{id}     | Bearer token | Actualiza libro                 |
| DELETE | /api/v1/libros/{id}     | Bearer token | Elimina libro (soft-delete)     |
