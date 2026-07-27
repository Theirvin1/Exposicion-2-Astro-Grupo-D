# Exposición 2 — Astro y el Consumo de APIs REST

**Universidad Técnica Estatal de Quevedo (UTEQ)**
Facultad de Ciencias de la Computación — Carrera de Ingeniería de Software
5to Semestre Software "A" — Julio 2026 (Semana 13)

## 📌 Tema

**Astro y el Consumo de APIs REST: Integración con servicios web y bases de datos.**

Este repositorio contiene el material de la segunda exposición del curso (Frameworks del Back-End), donde cada integrante del grupo desarrolló su propio **PFC (Proyecto Fin de Curso)** de forma independiente, usando **[Astro](https://astro.build/)** como framework de frontend, consumiendo una API REST propia construida con **Spring Boot**.

## 👥 Integrantes del Grupo D

| Integrante | Carpeta demo | Proyecto |
|---|---|---|
| Cajas Ibarra Irvin Marcelo | [`DEMO-IRVIN`](./DEMO-IRVIN) | Sistema de Gestión de Bibliotecas (SGB) |
| Escudero Plaza María del Rosario | [`DEMO-ESCUDERO`](./DEMO-ESCUDERO) | SGROAS — Gestión de Conductores |
| Mariscal Cabrera Jaime Josué | [`DEMO-MARISCAL`](./DEMO-MARISCAL) | BIOPET — Gestión de Mascotas |

Cada carpeta `DEMO-*` es un PFC independiente y autocontenido: tiene su propio frontend en Astro, su propio backend en Spring Boot, su propia base de datos y sus propias instrucciones de instalación (ver el `README.md` o el archivo de códigos de exposición dentro de cada una).

## 🧱 Stack tecnológico común

Aunque cada proyecto resuelve un problema distinto, los tres comparten la misma arquitectura general:

- **Frontend:** [Astro](https://astro.build/) consumiendo la API vía `fetch`
- **Backend:** Spring Boot (Java) — API REST
- **Base de datos:** PostgreSQL
- **Autenticación:** JWT (JSON Web Tokens) + Spring Security
- **Cache / sesiones (en algunos casos):** Redis
- **Contenedores (en algunos casos):** Docker / Docker Compose

## 📂 Estructura del repositorio

```
Exposicion-2-Astro-Grupo-D/
├── DEMO-IRVIN/          # PFC de Irvin: Sistema de Gestión de Bibliotecas (SGB)
├── DEMO-ESCUDERO/       # PFC de Escudero: SGROAS (gestión de conductores)
├── DEMO-MARISCAL/       # PFC de Mariscal: BIOPET (gestión de mascotas)
└── docs/                # Informe (LaTeX) y diapositivas de la exposición
```

### DEMO-IRVIN — Sistema de Gestión de Bibliotecas (SGB)
Backend en Spring Boot + Frontend en Astro. Usa Docker Compose para levantar PostgreSQL, Redis y el backend; el cliente Astro se ejecuta por separado con `npm run dev`. Incluye scripts en PowerShell para iniciar, detener, reiniciar y verificar la demo.

### DEMO-ESCUDERO — SGROAS
Frontend en Astro que consume una API REST en Spring Boot con base de datos PostgreSQL y autenticación JWT, para la gestión de conductores (registro, login y operaciones CRUD sobre conductores).

### DEMO-MARISCAL — BIOPET
Frontend en Astro + Backend Spring Boot para la gestión de mascotas, con PostgreSQL y Redis (cache y lista negra de tokens JWT), orquestado también con Docker Compose y scripts de PowerShell.

## 📄 Documentación del curso

En `docs/` se encuentra:
- `Diapositivas.pptx`: diapositivas usadas en la exposición.
- `informe/`: informe en LaTeX (`informe.tex`) con la referencia bibliográfica (`REFF.bib`) del tema "Astro y el Consumo de APIs REST".

## 🚀 Cómo probar cada demo

Cada proyecto es independiente, así que hay que entrar a su carpeta correspondiente y seguir sus instrucciones específicas:

```bash
cd DEMO-IRVIN       # o DEMO-ESCUDERO / DEMO-MARISCAL
# seguir el README.md o el archivo de códigos de exposición de esa carpeta
```

En general, el flujo es:
1. Levantar la base de datos (y Redis, si aplica) — manualmente o vía Docker Compose.
2. Levantar el backend Spring Boot (`mvn spring-boot:run` o contenedor Docker).
3. Levantar el frontend Astro (`npm install` + `npm run dev`).
4. Abrir el frontend en el navegador (por lo general `http://localhost:4321`) y probar el flujo de registro/login + operaciones sobre el recurso principal de cada demo.
