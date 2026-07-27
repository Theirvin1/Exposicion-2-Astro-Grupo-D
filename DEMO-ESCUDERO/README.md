# Demo Escudero — SGROAS (Astro + Spring Boot)

## Descripción
Demostración del framework **Astro** como frontend consumiendo una API REST construida con **Spring Boot**, con conexión a base de datos **PostgreSQL** y autenticación **JWT**.

## Requisitos
- Java JDK 17+ (OpenJDK 25 recomendado)
- Node.js 18+ y npm
- PostgreSQL 12+

## Instalación y Ejecución

### 1. Base de datos
```sql
-- En pgAdmin o psql, crear la base de datos:
CREATE DATABASE sgroas_db;
-- Las tablas se crean automáticamente con Hibernate (ddl-auto=update)
```

### 2. Backend (Spring Boot)
```bash
cd api-backend

# Compilar
mvn clean compile

# Ejecutar (arranca en http://localhost:8080)
mvn spring-boot:run
```

### 3. Frontend (Astro)
```bash
cd astro-cliente

# Instalar dependencias
npm install

# Desarrollo (arranca en http://localhost:4321)
npm run dev
```

### 4. Probar la demo
1. Abrir http://localhost:4321
2. Registrar un usuario
3. Hacer login
4. Ver lista de conductores (GET)
5. Crear un conductor nuevo (POST)

## API Endpoints
| Método | Endpoint | Auth | Descripción |
|--------|----------|------|-------------|
| POST | `/api/auth/register` | No | Registrar usuario |
| POST | `/api/auth/login` | No | Iniciar sesión |
| GET | `/api/conductores` | JWT | Listar conductores |
| POST | `/api/conductores` | JWT | Crear conductor |
| GET | `/api/conductores/{id}` | JWT | Obtener conductor |
| PUT | `/api/conductores/{id}` | JWT | Actualizar conductor |

## Tecnologías
- **Frontend:** Astro (Framework web moderno)
- **Backend:** Spring Boot 3.5 (Java)
- **Base de datos:** PostgreSQL
- **ORM:** Hibernate/JPA
- **Autenticación:** JWT (JSON Web Tokens)
- **Seguridad:** Spring Security

## Integrante
María del Rosario Escudero Plaza
