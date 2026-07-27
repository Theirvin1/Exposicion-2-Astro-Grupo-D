## Demostración 

### Uso de un Access Token con rol BIBLIOTECARIO


> **"Para esta demostración utilizaré un Access Token JWT correspondiente a un usuario con el rol BIBLIOTECARIO. El token será utilizado para acceder a los endpoints protegidos de la API."**

En Postman:

En la pestaña **Authorization**:

- **Type:** `Bearer Token`
- **Token:** pegar el `accessToken` obtenido previamente.

También puede configurarse manualmente en **Headers**:

| Key | Value |
|------|-------|
| Authorization | Bearer `<accessToken>` |

---

### Endpoint 1: Listar libros


> **"Primero consultaré el catálogo de libros. Este endpoint requiere un JWT válido y un usuario con permisos de lectura."**

En Postman:

- **Method:** `GET`
- **URL:**

```text
http://localhost:8080/api/v1/libros?page=0&size=10
```

Respuesta esperada: `200 OK`

Campos del JSON (según `LibroResponseDTO.java`): `id`, `titulo`, `isbn`, `resumen`, `portadaUrl`, `anioPublicacion`, `editorialId`, `editorial`, `idiomaId`, `idioma`, `estadoId`, `estado`, `stockTotal`, `stockDisponible`, `ubicacionFisica`, `fechaRegistro`.


> **"La petición fue autorizada correctamente y los datos provienen directamente de PostgreSQL mediante Spring Data JPA."**

---

### Endpoint 2: Crear un libro


> **"Ahora registraré un nuevo libro. Esta operación está protegida y únicamente puede ejecutarse con un usuario que posea los permisos correspondientes."**

En Postman:

- **Method:** `POST`
- **URL:**

```text
http://localhost:8080/api/v1/libros
```

Headers:

| Key | Value |
|------|-------|
| Content-Type | application/json |
| Authorization | Bearer `<accessToken>` |

Body (según `LibroRequestDTO.java`):

```json
{
  "titulo": "Cien años de code",
  "isbn": "1234567890123",
  "anioPublicacion": 2025,
  "resumen": "La vida despues del código",
  "portadaUrl": "",
  "editorialId": 1,
  "idiomaId": 1,
  "estadoId": 1,
  "stockTotal": 5,
  "stockDisponible": 5
}
```

Respuesta esperada: `201 Created`

---

### Endpoint 3: Actualizar un libro


> **"Modificaré la información del libro utilizando el mismo Access Token para demostrar el acceso a operaciones de actualización."**

En Postman:

- **Method:** `PUT`
- **URL:**

```text
http://localhost:8080/api/v1/libros/{id}
```

Respuesta esperada: `200 OK`

---

### Endpoint 4: Eliminar un libro


> **"Finalmente eliminaré el libro registrado anteriormente. El backend volverá a validar el JWT y comprobará que el usuario tenga autorización para realizar esta operación."**

En Postman:

- **Method:** `DELETE`
- **URL:**

```text
http://localhost:8080/api/v1/libros/{id}
```

Respuesta esperada: `204 No Content`

---