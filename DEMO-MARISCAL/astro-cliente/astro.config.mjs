import { defineConfig } from 'astro/config';

// ==================================================
// Configuracion de Astro para la demo BIOPET
// ==================================================
// El cliente se ejecuta en http://localhost:4321 y consume
// la API REST de Spring Boot en http://localhost:8080.
export default defineConfig({
  server: {
    port: 4321,
    host: true,
  },
});
