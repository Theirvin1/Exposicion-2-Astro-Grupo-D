import { defineConfig } from 'astro/config';

// ==================================================
// Configuracion de Astro para el cliente de demo de SGB-SAAS
// ==================================================
// El cliente se ejecuta en http://localhost:4321 y consume
// la API REST de Spring Boot en http://localhost:8080.
//
// IMPORTANTE: el backend (SecurityConfig.corsConfigurationSource)
// solo permite por defecto el origen http://localhost:4200 (Angular).
// Para que este cliente funcione hay que anadir "http://localhost:4321"
// a la lista de allowedOrigins en el backend antes de correr la demo.
export default defineConfig({
  server: {
    port: 4321,
    host: true,
  },
});
