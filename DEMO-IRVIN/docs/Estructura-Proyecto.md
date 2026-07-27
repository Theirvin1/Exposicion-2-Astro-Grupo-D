# SGB-SAAS

---

##  Estructura del proyecto



**Frontend — `astro-cliente/` (generado con `npm create astro@latest`)**

```
astro-cliente/
├── astro.config.mjs          # config: puerto 4321, host: true
├── package.json               # astro@^5.18.2, @astrojs/check, typescript
├── package-lock.json
├── tsconfig.json              # extends: astro/tsconfigs/strict
├── public/
│   └── favicon.svg
└── src/
    └── pages/
        └── index.astro        # SPA unica: HTML + CSS + <script> con fetch()
```

**Backend — `backend-springboot/` (generado con Spring Initializr)**

```
backend-springboot/
├── pom.xml                        # Spring Boot 4.0.6, Java 21
├── Dockerfile                     # build multi-etapa: eclipse-temurin:21
├── mvnw / mvnw.cmd               # Maven wrapper
├── .mvn/wrapper/
├── database/
│   └── migrations/
│       ├── V1__schema_inicial.sql
│       ├── V2__rbac_normalizado.sql
│       └── V3__multas_multiples_por_prestamo.sql
└── src/
    ├── main/
    │   ├── java/com/uteq/backend/
    │   │   ├── BackendApplication.java
    │   │   ├── config/
    │   │   │   ├── SecurityConfig.java      # CORS, JWT filter, sesiones stateless
    │   │   │   └── RedisConfig.java         # cache Redis para libros
    │   │   ├── controller/
    │   │   │   ├── AuthController.java      # /api/auth/* (registro, login, logout, refresh)
    │   │   │   ├── LibroController.java     # /api/v1/libros (CRUD)
    │   │   │   └── TestController.java      # /api/test/protegido
    │   │   ├── dto/
    │   │   │   ├── LibroRequestDTO.java
    │   │   │   ├── LibroResponseDTO.java
    │   │   │   ├── LoginRequestDTO.java
    │   │   │   ├── RegistroRequestDTO.java
    │   │   │   ├── TokenResponseDTO.java
    │   │   │   └── UsuarioResponseDTO.java
    │   │   ├── entity/
    │   │   │   ├── Editorial.java
    │   │   │   ├── EstadoLibro.java
    │   │   │   ├── EstadoUsuario.java
    │   │   │   ├── Idioma.java
    │   │   │   ├── Libro.java
    │   │   │   ├── Multa.java
    │   │   │   ├── Prestamo.java
    │   │   │   ├── Reservacion.java
    │   │   │   ├── Rol.java
    │   │   │   └── Usuario.java
    │   │   ├── exception/
    │   │   │   └── GlobalExceptionHandler.java
    │   │   ├── repository/
    │   │   │   ├── EditorialRepository.java
    │   │   │   ├── EstadoLibroRepository.java
    │   │   │   ├── EstadoUsuarioRepository.java
    │   │   │   ├── IdiomaRepository.java
    │   │   │   ├── LibroRepository.java
    │   │   │   ├── MultaProcedureRepository.java
    │   │   │   ├── MultaRepository.java
    │   │   │   ├── PrestamoProcedureRepository.java
    │   │   │   ├── PrestamoRepository.java
    │   │   │   ├── ReservacionProcedureRepository.java
    │   │   │   ├── ReservacionRepository.java
    │   │   │   ├── RolRepository.java
    │   │   │   ├── UsuarioRepository.java
    │   │   │   └── projection/
    │   │   │       ├── LibroMasPrestadoProjection.java
    │   │   │       └── PrestamoActivoProjection.java
    │   │   ├── security/
    │   │   │   ├── JwtAuthFilter.java
    │   │   │   ├── JwtService.java
    │   │   │   └── UserDetailsServiceImpl.java
    │   │   └── service/
    │   │       ├── AuthService.java
    │   │       ├── CorreoYaRegistradoException.java
    │   │       └── LibroService.java
    │   └── resources/
    │       └── application.yml
    └── test/java/com/uteq/backend/
        ├── BackendApplicationTests.java
        └── service/
            ├── AuthServiceTest.java
            └── LibroServiceTest.java
```
