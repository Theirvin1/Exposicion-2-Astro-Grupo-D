##  ORM / driver de BD y configuracion

> **"El ORM es Hibernate via `spring-boot-starter-data-jpa` y el driver JDBC es
> `org.postgresql.Driver`."**

Dependencias en `pom.xml`: `spring-boot-starter-data-jpa` (linea 35) y
`postgresql` runtime (linea 63).

> **"La conexion se configura en `application.yml` con variables de entorno."**

En `application.yml` lineas 4-8 se define el datasource:
```yaml
datasource:
  url: ${DB_URL:jdbc:postgresql://localhost:5432/sgb_db}
  username: ${DB_USER:sgb_user}
  password: ${DB_PASSWORD:changeme}
  driver-class-name: org.postgresql.Driver
```

Docker Compose sobreescribe esas variables en `docker-compose.yml` lineas 52-57
para que el backend se conecte a `postgres:5432` (el nombre del servicio Docker)
en vez de localhost.

> **"Hibernate mapea las entidades a tablas con `@Entity`, `@Table`, `@ManyToOne`,
> `@ManyToMany`. Por ejemplo, `Libro.java` mapea a la tabla `libros` y `Usuario.java`
> usa una tabla puente `usuario_roles` para los roles. Los IDs usan
> `GenerationType.IDENTITY` (SERIAL de PostgreSQL). El `ddl-auto` esta en
> `validate`: Hibernate solo valida, nunca modifica el schema."**


> **"Los repositorios extienden `JpaRepository` y Spring Data genera las consultas
> por nombre de metodo, como `findByEstado_Nombre` en `LibroRepository`. Para
> stored procedures se usa `@Procedure` y `@Query(nativeQuery=true)`."**

---

