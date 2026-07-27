-- ============================================================================
-- ARCHIVO GENERADO PARA DEMO-SGB — NO EDITAR A MANO.
-- Fuente (repo sgb-saas): db/schema.sql + db/procs/*.sql + db/seed.sql.
-- ============================================================================

-- ============================================================================
-- SGB-SaaS — db/schema.sql
-- Snapshot consolidado del modelo de datos (24 tablas) para reproducibilidad
-- desde cero vía docker-entrypoint-initdb.d/. Ver docs/adr/adr-006-estrategia-schema-reproducible.md
-- para la justificación de por qué este archivo coexiste con
-- database/migrations/ (Flyway sigue siendo el mecanismo real de
-- versionado incremental; este archivo NO reemplaza a Flyway).
--
-- Este archivo resulta de fusionar:
--   - database/migrations/V1__schema_inicial.sql (Entrega 1B, 5 tablas)
--   - el schema de 24 tablas del módulo de Administración de BD
-- Discrepancias entre ambas fuentes revisadas y decididas por el equipo
-- (sin migración de datos: entorno de desarrollo, sin usuarios reales;
-- `activo BOOLEAN` eliminado de `usuarios`/`libros` en favor de `estado_id`).
-- Ver los comentarios "NOTA DE FUSIÓN" bajo `usuarios` y `libros` más abajo.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- MÓDULO 1: SEGURIDAD (8 tablas)
-- ============================================================================
CREATE TABLE estados_usuario (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE roles (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(30)  NOT NULL UNIQUE,
    descripcion VARCHAR(200)
);

CREATE TABLE permisos (
    id     SERIAL PRIMARY KEY,
    codigo VARCHAR(60) NOT NULL UNIQUE
);

CREATE TABLE rol_permisos (
    rol_id     INTEGER NOT NULL REFERENCES roles(id)    ON DELETE CASCADE,
    permiso_id INTEGER NOT NULL REFERENCES permisos(id) ON DELETE CASCADE,
    PRIMARY KEY (rol_id, permiso_id)
);

-- NOTA DE FUSIÓN (usuarios): database/migrations/V1__schema_inicial.sql
-- (Entrega 1B) define esta tabla de forma distinta:
--   - tenía columna `rol VARCHAR(20)` embebida con CHECK
--     (ROLE_LECTOR/ROLE_BIBLIOTECARIO/ROLE_GERENTE) en vez de las tablas
--     normalizadas roles/usuario_roles de abajo.
--   - tenía columna `activo BOOLEAN` en vez de `estado_id` (FK a
--     estados_usuario, que además distingue 4 estados en vez de 2).
--   - la columna de fecha se llamaba `creado_en`, aquí es `fecha_registro`.
--   - no existían `apellido`, `identificacion_usuario`, `correo_verificado`.
-- Decisión del equipo: sin migración de datos (V1 solo tenía datos de
-- prueba en desarrollo, sin usuarios reales); se recrea la BD desde este
-- archivo + db/seed.sql. `correo` no lleva UNIQUE inline: la unicidad se
-- exige únicamente vía `idx_usuarios_correo` (evita índice duplicado).
CREATE TABLE usuarios (
    id                     BIGSERIAL PRIMARY KEY,
    nombre                 VARCHAR(100) NOT NULL,
    apellido               VARCHAR(100) NOT NULL,
    correo                 VARCHAR(150) NOT NULL,
    password_hash          VARCHAR(255) NOT NULL,
    identificacion_usuario VARCHAR(20),
    estado_id              INTEGER NOT NULL REFERENCES estados_usuario(id) ON DELETE RESTRICT,
    correo_verificado      BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_registro         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    actualizado_en         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_usuarios_correo ON usuarios (correo);

CREATE TABLE usuario_roles (
    usuario_id BIGINT  NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    rol_id     INTEGER NOT NULL REFERENCES roles(id)    ON DELETE RESTRICT,
    asignado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (usuario_id, rol_id)
);

CREATE TABLE tokens_invalidos (
    id          BIGSERIAL PRIMARY KEY,
    jti         VARCHAR(100) NOT NULL UNIQUE,
    usuario_id  BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    expira_en   TIMESTAMPTZ NOT NULL,
    invalidado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE verificaciones_correo (
    id          BIGSERIAL PRIMARY KEY,
    usuario_id  BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    token       UUID NOT NULL DEFAULT uuid_generate_v4(),
    expira_en   TIMESTAMPTZ NOT NULL,
    usado       BOOLEAN NOT NULL DEFAULT FALSE,
    creado_en   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- MÓDULO 2: CATÁLOGO E INVENTARIO (8 tablas)
-- ============================================================================

-- NOTA DE FUSIÓN (editoriales): V1 no tenía la columna `pais_origen`
-- (nullable, aditiva — sin conflicto).
CREATE TABLE editoriales (
    id           SERIAL PRIMARY KEY,
    nombre       VARCHAR(150) NOT NULL UNIQUE,
    pais_origen  VARCHAR(80)
);

CREATE TABLE idiomas (
    id         SERIAL PRIMARY KEY,
    nombre     VARCHAR(50) NOT NULL UNIQUE,
    codigo_iso VARCHAR(5)  NOT NULL UNIQUE
);

CREATE TABLE estados_libro (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
    -- Valores esperados (ver db/seed.sql): 'ACTIVO', 'DADO_DE_BAJA',
    -- 'EN_REPARACION', 'PERDIDO'
);

CREATE TABLE categorias (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE autores (
    id     BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL
);

-- NOTA DE FUSIÓN (libros): respecto a V1:
--   - V1 tenía además una columna `activo BOOLEAN DEFAULT TRUE`, redundante
--     con `estado_id` (que ya distinguía ACTIVO/DADO_DE_BAJA/...). Decisión
--     del equipo: confirmado, se elimina (no se reintroduce).
--   - la columna de fecha se llamaba `creado_en`, aquí es `fecha_registro`.
--   - se agrega `ubicacion_fisica` (nueva, nullable, sin conflicto).
--   - el CHECK `stock_disponible <= stock_total` estaba inline en V1
--     (`chk_stock_disponible`); aquí es una constraint de tabla al final
--     (`chk_stock`) con el mismo efecto.
--   - `isbn` no lleva UNIQUE inline: la unicidad se exige únicamente vía
--     `idx_libros_isbn` (evita índice duplicado).
CREATE TABLE libros (
    id                BIGSERIAL PRIMARY KEY,
    isbn              VARCHAR(13)   NOT NULL,
    titulo            VARCHAR(255)  NOT NULL,
    resumen           TEXT,
    portada_url       VARCHAR(1000),
    anio_publicacion  SMALLINT      NOT NULL CHECK (anio_publicacion BETWEEN 1000 AND 2100),
    editorial_id      INTEGER       NOT NULL REFERENCES editoriales(id)   ON DELETE RESTRICT,
    idioma_id         INTEGER       NOT NULL REFERENCES idiomas(id)       ON DELETE RESTRICT,
    estado_id         INTEGER       NOT NULL REFERENCES estados_libro(id) ON DELETE RESTRICT,
    stock_total       SMALLINT      NOT NULL DEFAULT 1 CHECK (stock_total >= 0),
    stock_disponible  SMALLINT      NOT NULL DEFAULT 1 CHECK (stock_disponible >= 0),
    ubicacion_fisica  VARCHAR(50),
    fecha_registro    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    actualizado_en    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_stock CHECK (stock_disponible <= stock_total)
);

CREATE UNIQUE INDEX idx_libros_isbn ON libros (isbn);

CREATE TABLE libro_categorias (
    libro_id     BIGINT  NOT NULL REFERENCES libros(id)     ON DELETE CASCADE,
    categoria_id INTEGER NOT NULL REFERENCES categorias(id) ON DELETE RESTRICT,
    PRIMARY KEY (libro_id, categoria_id)
);

CREATE TABLE libro_autores (
    libro_id  BIGINT NOT NULL REFERENCES libros(id)  ON DELETE CASCADE,
    autor_id  BIGINT NOT NULL REFERENCES autores(id) ON DELETE RESTRICT,
    PRIMARY KEY (libro_id, autor_id)
);

-- ============================================================================
-- MÓDULO 3: TRANSACCIONES (5 tablas)
-- ============================================================================
CREATE TABLE configuracion_sistema (
    clave  VARCHAR(50) PRIMARY KEY,
    valor  VARCHAR(200) NOT NULL
);

CREATE TABLE estados_prestamo (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE estados_multa (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE estados_reservacion (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE reservaciones (
    id                     BIGSERIAL PRIMARY KEY,
    usuario_id             BIGINT  NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    libro_id               BIGINT  NOT NULL REFERENCES libros(id)   ON DELETE RESTRICT,
    estado_reservacion_id  INTEGER NOT NULL REFERENCES estados_reservacion(id),
    fecha_reserva          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_limite_retiro    TIMESTAMPTZ NOT NULL
);

CREATE TABLE prestamos (
    id                          BIGSERIAL PRIMARY KEY,
    usuario_id                  BIGINT  NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    libro_id                    BIGINT  NOT NULL REFERENCES libros(id)   ON DELETE RESTRICT,
    bibliotecario_id            BIGINT  NOT NULL REFERENCES usuarios(id) ON DELETE RESTRICT,
    reservacion_id              BIGINT  REFERENCES reservaciones(id) ON DELETE SET NULL,
    fecha_prestamo              TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_devolucion_estimada   TIMESTAMPTZ NOT NULL,
    fecha_devolucion_real       TIMESTAMPTZ,
    renovaciones_realizadas     SMALLINT NOT NULL DEFAULT 0 CHECK (renovaciones_realizadas >= 0),
    estado_prestamo_id          INTEGER NOT NULL REFERENCES estados_prestamo(id)
);

-- DECISIÓN DE NEGOCIO (resuelta): un préstamo SÍ puede generar más de una
-- multa (ej. daño al libro + atraso, registrados por separado). Por eso
-- prestamo_id NO lleva UNIQUE -- ver database/migrations/V3__multas_multiples_por_prestamo.sql
-- para el DROP CONSTRAINT sobre bases ya existentes con el UNIQUE previo.
CREATE TABLE multas (
    id               BIGSERIAL PRIMARY KEY,
    prestamo_id      BIGINT NOT NULL REFERENCES prestamos(id) ON DELETE RESTRICT,
    monto            NUMERIC(8,2) NOT NULL CHECK (monto > 0),
    estado_multa_id  INTEGER NOT NULL REFERENCES estados_multa(id),
    fecha_generada   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    fecha_pagada     TIMESTAMPTZ,
    observaciones    VARCHAR(255)
);

-- ============================================================================
-- MÓDULO 4: EXPERIENCIA DEL LECTOR (2 tablas)
-- ============================================================================
-- NOTA: favoritos y sugerencias_adquisicion exigen usuario_id NOT NULL en
-- ambas tablas — a propósito, no es un descuido. Ambas funcionalidades
-- requieren usuario autenticado; el portal anónimo (visitante sin login,
-- solo landing + catálogo público) NO tiene persistencia de favoritos ni
-- puede enviar sugerencias de adquisición. Es una decisión de producto ya
-- tomada implícitamente por el diseño del schema; se documenta aquí para
-- que quede explícita.
CREATE TABLE favoritos (
    usuario_id  BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    libro_id    BIGINT NOT NULL REFERENCES libros(id)   ON DELETE CASCADE,
    agregado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (usuario_id, libro_id)
);

CREATE TABLE sugerencias_adquisicion (
    id           BIGSERIAL PRIMARY KEY,
    usuario_id   BIGINT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
    titulo       VARCHAR(255) NOT NULL,
    autor        VARCHAR(150),
    isbn         VARCHAR(13),
    justificacion TEXT,
    estado       VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE'
                 CHECK (estado IN ('PENDIENTE','APROBADA','RECHAZADA')),
    revisado_por BIGINT REFERENCES usuarios(id) ON DELETE SET NULL,
    creado_en    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- MÓDULO 5: AUDITORÍA (1 tabla)
-- ============================================================================
CREATE TABLE bitacora_auditoria (
    id              BIGSERIAL PRIMARY KEY,
    usuario_id      BIGINT REFERENCES usuarios(id) ON DELETE SET NULL,
    tipo_operacion  VARCHAR(20) NOT NULL
                    CHECK (tipo_operacion IN
                           ('INSERT','UPDATE','DELETE','LOGIN_OK','LOGIN_FAIL','LOGOUT')),
    tabla_afectada  VARCHAR(50) NOT NULL,
    registro_id     BIGINT,
    detalles        TEXT NOT NULL,
    ip_origen       VARCHAR(45),
    fecha_hora      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================================
-- TRIGGERS DE actualizado_en
-- ============================================================================
CREATE OR REPLACE FUNCTION set_actualizado_en()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usuarios_actualizado_en
    BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

CREATE TRIGGER trg_libros_actualizado_en
    BEFORE UPDATE ON libros
    FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

-- ============================================================================
-- FIN DEL SCHEMA — 24 TABLAS
-- ============================================================================


-- ---------------------------------------------------------------------
-- fn_listar_prestamos_activos_por_usuario.sql
-- ---------------------------------------------------------------------
-- ============================================================================
-- fn_listar_prestamos_activos_por_usuario
-- Tipo: función SQL pura (LANGUAGE sql, STABLE), retorna TABLE (varias filas).
--
-- Propósito: proyección heterogénea (préstamo + libro + estado) de los
-- préstamos "activos" de un usuario. Se define aquí porque requiere JOIN
-- entre prestamos/libros/estados_prestamo — no es CRUD elemental.
--
-- Definición de "activo": cualquier préstamo cuyo estado NO sea 'DEVUELTO'
-- (incluye ACTIVO, RENOVADO y VENCIDO), para que un lector vea también los
-- libros que tiene atrasados. Si se requiere restringir estrictamente a
-- estado_prestamo = 'ACTIVO', ajustar el filtro WHERE de abajo.
--
-- Parámetros (nombrados):
--   p_usuario_id BIGINT — usuario cuyos préstamos se listan
--
-- Retorno TABLE:
--   prestamo_id                 BIGINT
--   libro_titulo                VARCHAR(255)
--   libro_isbn                  VARCHAR(13)
--   fecha_prestamo               TIMESTAMPTZ
--   fecha_devolucion_estimada    TIMESTAMPTZ
--   dias_restantes                INTEGER  -- negativo si está atrasado
--   estado_nombre                VARCHAR(30)
--
-- Tablas afectadas: solo lectura (prestamos, libros, estados_prestamo).
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_listar_prestamos_activos_por_usuario(
    p_usuario_id BIGINT
)
RETURNS TABLE (
    prestamo_id                BIGINT,
    libro_titulo               VARCHAR(255),
    libro_isbn                 VARCHAR(13),
    fecha_prestamo              TIMESTAMPTZ,
    fecha_devolucion_estimada   TIMESTAMPTZ,
    dias_restantes               INTEGER,
    estado_nombre                VARCHAR(30)
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        p.id,
        l.titulo,
        l.isbn,
        p.fecha_prestamo,
        p.fecha_devolucion_estimada,
        (p.fecha_devolucion_estimada::date - NOW()::date)::INTEGER,
        ep.nombre
    FROM prestamos p
    JOIN libros l ON l.id = p.libro_id
    JOIN estados_prestamo ep ON ep.id = p.estado_prestamo_id
    WHERE p.usuario_id = p_usuario_id
      AND ep.nombre <> 'DEVUELTO'
    ORDER BY p.fecha_devolucion_estimada ASC;
$$;

-- ---------------------------------------------------------------------
-- fn_reporte_libros_mas_prestados.sql
-- ---------------------------------------------------------------------
-- ============================================================================
-- fn_reporte_libros_mas_prestados
-- Tipo: función SQL pura (LANGUAGE sql, STABLE), retorna TABLE (varias filas).
--
-- Propósito: reporte de los libros con más préstamos, opcionalmente acotado
-- a un rango de fechas. Requiere JOIN + agregación (GROUP BY/COUNT) — no es
-- CRUD elemental.
--
-- Parámetros (nombrados):
--   p_limite INTEGER    DEFAULT 10   — máximo de filas a retornar
--   p_desde  TIMESTAMPTZ DEFAULT NULL — filtra prestamos.fecha_prestamo >= p_desde (NULL = sin límite inferior)
--   p_hasta  TIMESTAMPTZ DEFAULT NULL — filtra prestamos.fecha_prestamo <= p_hasta (NULL = sin límite superior)
--
-- Retorno TABLE:
--   libro_id         BIGINT
--   titulo           VARCHAR(255)
--   isbn             VARCHAR(13)
--   total_prestamos  BIGINT
--
-- Tablas afectadas: solo lectura (prestamos, libros).
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_reporte_libros_mas_prestados(
    p_limite INTEGER DEFAULT 10,
    p_desde TIMESTAMPTZ DEFAULT NULL,
    p_hasta TIMESTAMPTZ DEFAULT NULL
)
RETURNS TABLE (
    libro_id         BIGINT,
    titulo           VARCHAR(255),
    isbn             VARCHAR(13),
    total_prestamos  BIGINT
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        l.id,
        l.titulo,
        l.isbn,
        COUNT(*) AS total_prestamos
    FROM prestamos p
    JOIN libros l ON l.id = p.libro_id
    WHERE (p_desde IS NULL OR p.fecha_prestamo >= p_desde)
      AND (p_hasta IS NULL OR p.fecha_prestamo <= p_hasta)
    GROUP BY l.id, l.titulo, l.isbn
    ORDER BY total_prestamos DESC
    LIMIT p_limite;
$$;

-- ---------------------------------------------------------------------
-- sp_anular_multa.sql
-- ---------------------------------------------------------------------
-- ============================================================================
-- sp_anular_multa
-- Tipo: función (LANGUAGE plpgsql), múltiples parámetros de salida (OUT).
--
-- Propósito: anular una multa pendiente (p.ej. por decisión administrativa),
-- dejando constancia en la bitácora de auditoría. Requiere rol GERENTE o
-- ADMIN — verificado aquí como segunda barrera además del @PreAuthorize
-- que aplicará el backend.
--
-- Parámetros (nombrados):
--   p_multa_id     BIGINT       — multa a anular
--   p_motivo       VARCHAR(255) — justificación, se guarda en multas.observaciones
--                                 y en bitacora_auditoria.detalles. Se usa
--                                 siempre como VALOR insertado (bind), nunca
--                                 concatenado dentro de una cláusula WHERE u
--                                 otra sentencia SQL — no constituye SQL
--                                 dinámico ni concatenación de entrada de
--                                 usuario en una query ejecutable.
--   p_rol_ejecutor VARCHAR(30)  — rol del usuario que ejecuta la operación
--
-- Retorno (OUT):
--   o_multa_id             BIGINT  — mismo id recibido, para confirmación
--   o_usuario_desbloqueado BOOLEAN — true si el usuario volvió a ACTIVO
--
-- Errores:
--   LB422 — p_rol_ejecutor no es GERENTE ni ADMIN
--   LB404 — la multa no existe
--   LB409 — la multa no está en estado PENDIENTE
--
-- Tablas afectadas: multas (lectura+UPDATE), prestamos (lectura),
-- estados_multa (lectura), usuarios (UPDATE estado condicional),
-- estados_usuario (lectura), bitacora_auditoria (INSERT).
--
-- Nota: bitacora_auditoria.usuario_id se deja en NULL porque esta función
-- no recibe el id del usuario ejecutor (solo su rol, p_rol_ejecutor) —
-- si se requiere trazar exactamente QUIÉN anuló la multa, agregar un
-- parámetro p_ejecutor_id BIGINT en una futura revisión de este archivo.
-- ============================================================================
CREATE OR REPLACE FUNCTION sp_anular_multa(
    p_multa_id BIGINT,
    p_motivo VARCHAR(255),
    p_rol_ejecutor VARCHAR(30),
    OUT o_multa_id BIGINT,
    OUT o_usuario_desbloqueado BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_multa_id           INTEGER;
    v_estado_pendiente_id       INTEGER;
    v_estado_anulada_id         INTEGER;
    v_estado_activo_usuario_id  INTEGER;
    v_usuario_id                BIGINT;
    v_otras_pendientes          INTEGER;
BEGIN
    IF p_rol_ejecutor <> 'GERENTE' AND p_rol_ejecutor <> 'ADMIN' THEN
        RAISE EXCEPTION 'Solo GERENTE o ADMIN puede anular multas' USING ERRCODE = 'LB422';
    END IF;

    SELECT m.estado_multa_id, p.usuario_id
      INTO v_estado_multa_id, v_usuario_id
      FROM multas m
      JOIN prestamos p ON p.id = m.prestamo_id
     WHERE m.id = p_multa_id
     FOR UPDATE OF m;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La multa % no existe', p_multa_id USING ERRCODE = 'LB404';
    END IF;

    SELECT id INTO v_estado_pendiente_id FROM estados_multa WHERE nombre = 'PENDIENTE';

    IF v_estado_multa_id <> v_estado_pendiente_id THEN
        RAISE EXCEPTION 'La multa % no esta pendiente, no se puede anular', p_multa_id USING ERRCODE = 'LB409';
    END IF;

    SELECT id INTO v_estado_anulada_id FROM estados_multa WHERE nombre = 'ANULADA';

    UPDATE multas
       SET estado_multa_id = v_estado_anulada_id,
           observaciones = p_motivo
     WHERE id = p_multa_id;

    o_multa_id := p_multa_id;

    SELECT count(*) INTO v_otras_pendientes
      FROM multas m2
      JOIN prestamos p2 ON p2.id = m2.prestamo_id
     WHERE p2.usuario_id = v_usuario_id
       AND m2.estado_multa_id = v_estado_pendiente_id
       AND m2.id <> p_multa_id;

    IF v_otras_pendientes = 0 THEN
        SELECT id INTO v_estado_activo_usuario_id FROM estados_usuario WHERE nombre = 'ACTIVO';
        UPDATE usuarios SET estado_id = v_estado_activo_usuario_id WHERE id = v_usuario_id;
        o_usuario_desbloqueado := TRUE;
    ELSE
        o_usuario_desbloqueado := FALSE;
    END IF;

    INSERT INTO bitacora_auditoria (usuario_id, tipo_operacion, tabla_afectada, registro_id, detalles)
    VALUES (NULL, 'UPDATE', 'multas', p_multa_id, 'Multa anulada: ' || p_motivo);
END;
$$;

-- ---------------------------------------------------------------------
-- sp_crear_prestamo.sql
-- ---------------------------------------------------------------------
-- ============================================================================
-- sp_crear_prestamo
-- Tipo: función (LANGUAGE plpgsql), no procedure nativo — ver nota de diseño
-- en docs/basedatos/CATALOGO-SP.md sobre por qué se usa FUNCTION en todos
-- los casos de este módulo.
--
-- Propósito: registrar un nuevo préstamo de forma atómica, validando que el
-- usuario no esté bloqueado por multas y que el libro tenga stock disponible.
--
-- Parámetros (nombrados):
--   p_usuario_id       BIGINT  — usuario que retira el libro
--   p_libro_id         BIGINT  — libro a prestar
--   p_bibliotecario_id BIGINT  — usuario (rol BIBLIOTECARIO/GERENTE/ADMIN)
--                                que registra la operación
--   p_dias_prestamo    INTEGER — plazo del préstamo en días
--
-- Retorno: BIGINT — id del préstamo creado.
--
-- Errores (SQLSTATE personalizado, ver convención en CATALOGO-SP.md):
--   LB404 — usuario o libro no existen
--   LB422 — usuario bloqueado por multa, o libro sin stock disponible
--
-- Tablas afectadas: usuarios (lectura), libros (lectura+UPDATE stock),
-- estados_usuario (lectura), estados_prestamo (lectura), prestamos (INSERT).
--
-- Toda la lógica corre en una única transacción implícita de la función:
-- si cualquier RAISE EXCEPTION dispara, PostgreSQL revierte automáticamente
-- todos los cambios hechos dentro de esta invocación.
-- ============================================================================
CREATE OR REPLACE FUNCTION sp_crear_prestamo(
    p_usuario_id BIGINT,
    p_libro_id BIGINT,
    p_bibliotecario_id BIGINT,
    p_dias_prestamo INTEGER
)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_usuario_id     INTEGER;
    v_estado_bloqueado_id   INTEGER;
    v_stock_disponible      SMALLINT;
    v_estado_activo_prestamo_id INTEGER;
    v_prestamo_id           BIGINT;
BEGIN
    SELECT id INTO v_estado_bloqueado_id
      FROM estados_usuario
     WHERE nombre = 'BLOQUEADO_POR_MULTA';

    SELECT estado_id INTO v_estado_usuario_id
      FROM usuarios
     WHERE id = p_usuario_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El usuario % no existe', p_usuario_id USING ERRCODE = 'LB404';
    END IF;

    IF v_estado_usuario_id = v_estado_bloqueado_id THEN
        RAISE EXCEPTION 'El usuario % esta bloqueado por multas pendientes y no puede solicitar prestamos', p_usuario_id
            USING ERRCODE = 'LB422';
    END IF;

    SELECT stock_disponible INTO v_stock_disponible
      FROM libros
     WHERE id = p_libro_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El libro % no existe', p_libro_id USING ERRCODE = 'LB404';
    END IF;

    IF v_stock_disponible <= 0 THEN
        RAISE EXCEPTION 'El libro % no tiene stock disponible', p_libro_id USING ERRCODE = 'LB422';
    END IF;

    SELECT id INTO v_estado_activo_prestamo_id
      FROM estados_prestamo
     WHERE nombre = 'ACTIVO';

    UPDATE libros
       SET stock_disponible = stock_disponible - 1
     WHERE id = p_libro_id;

    INSERT INTO prestamos (
        usuario_id, libro_id, bibliotecario_id,
        fecha_prestamo, fecha_devolucion_estimada, estado_prestamo_id
    ) VALUES (
        p_usuario_id, p_libro_id, p_bibliotecario_id,
        NOW(), NOW() + make_interval(days => p_dias_prestamo), v_estado_activo_prestamo_id
    )
    RETURNING id INTO v_prestamo_id;

    RETURN v_prestamo_id;
END;
$$;

-- ---------------------------------------------------------------------
-- sp_expirar_reservaciones_vencidas.sql
-- ---------------------------------------------------------------------
-- ============================================================================
-- sp_expirar_reservaciones_vencidas
-- Tipo: función (LANGUAGE plpgsql), UPDATE masivo.
--
-- Propósito: pasar a estado EXPIRADA todas las reservaciones que siguen
-- PENDIENTE o LISTA_PARA_RETIRO cuya fecha_limite_retiro ya pasó. Pensada
-- para invocarse periódicamente (job/scheduler del backend).
--
-- Parámetros (nombrados):
--   p_ahora TIMESTAMPTZ DEFAULT NOW() — permite fijar la fecha de referencia
--                                       en pruebas; en producción se usa el
--                                       valor por defecto (NOW()).
--
-- Retorno: INTEGER — cantidad de reservaciones actualizadas.
--
-- Tablas afectadas: reservaciones (lectura+UPDATE), estados_reservacion
-- (lectura).
-- ============================================================================
CREATE OR REPLACE FUNCTION sp_expirar_reservaciones_vencidas(
    p_ahora TIMESTAMPTZ DEFAULT NOW()
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_pendiente_id   INTEGER;
    v_estado_lista_id       INTEGER;
    v_estado_expirada_id    INTEGER;
    v_filas_afectadas       INTEGER;
BEGIN
    SELECT id INTO v_estado_pendiente_id FROM estados_reservacion WHERE nombre = 'PENDIENTE';
    SELECT id INTO v_estado_lista_id     FROM estados_reservacion WHERE nombre = 'LISTA_PARA_RETIRO';
    SELECT id INTO v_estado_expirada_id  FROM estados_reservacion WHERE nombre = 'EXPIRADA';

    UPDATE reservaciones
       SET estado_reservacion_id = v_estado_expirada_id
     WHERE estado_reservacion_id IN (v_estado_pendiente_id, v_estado_lista_id)
       AND fecha_limite_retiro < p_ahora;

    GET DIAGNOSTICS v_filas_afectadas = ROW_COUNT;

    RETURN v_filas_afectadas;
END;
$$;

-- ---------------------------------------------------------------------
-- sp_pagar_multa.sql
-- ---------------------------------------------------------------------
-- ============================================================================
-- sp_pagar_multa
-- Tipo: función (LANGUAGE plpgsql), múltiples parámetros de salida (OUT).
--
-- Propósito: registrar el pago de una multa pendiente y, si el usuario no
-- tiene otras multas pendientes, reactivar su cuenta (estado ACTIVO).
--
-- Parámetros (nombrados):
--   p_multa_id BIGINT — multa a pagar
--
-- Retorno (OUT):
--   o_multa_id             BIGINT  — mismo id recibido, para confirmación
--   o_usuario_desbloqueado BOOLEAN — true si el usuario volvió a ACTIVO
--
-- Errores:
--   LB404 — la multa no existe
--   LB409 — la multa no está en estado PENDIENTE (ya pagada o anulada)
--
-- Tablas afectadas: multas (lectura+UPDATE), prestamos (lectura, para
-- ubicar al usuario dueño de la multa), estados_multa (lectura),
-- usuarios (UPDATE estado condicional), estados_usuario (lectura).
-- ============================================================================
CREATE OR REPLACE FUNCTION sp_pagar_multa(
    p_multa_id BIGINT,
    OUT o_multa_id BIGINT,
    OUT o_usuario_desbloqueado BOOLEAN
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_estado_multa_id           INTEGER;
    v_estado_pendiente_id       INTEGER;
    v_estado_pagada_id          INTEGER;
    v_estado_activo_usuario_id  INTEGER;
    v_usuario_id                BIGINT;
    v_otras_pendientes          INTEGER;
    v_ahora                     TIMESTAMPTZ := NOW();
BEGIN
    SELECT m.estado_multa_id, p.usuario_id
      INTO v_estado_multa_id, v_usuario_id
      FROM multas m
      JOIN prestamos p ON p.id = m.prestamo_id
     WHERE m.id = p_multa_id
     FOR UPDATE OF m;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'La multa % no existe', p_multa_id USING ERRCODE = 'LB404';
    END IF;

    SELECT id INTO v_estado_pendiente_id FROM estados_multa WHERE nombre = 'PENDIENTE';

    IF v_estado_multa_id <> v_estado_pendiente_id THEN
        RAISE EXCEPTION 'La multa % no esta pendiente de pago', p_multa_id USING ERRCODE = 'LB409';
    END IF;

    SELECT id INTO v_estado_pagada_id FROM estados_multa WHERE nombre = 'PAGADA';

    UPDATE multas
       SET estado_multa_id = v_estado_pagada_id,
           fecha_pagada = v_ahora
     WHERE id = p_multa_id;

    o_multa_id := p_multa_id;

    SELECT count(*) INTO v_otras_pendientes
      FROM multas m2
      JOIN prestamos p2 ON p2.id = m2.prestamo_id
     WHERE p2.usuario_id = v_usuario_id
       AND m2.estado_multa_id = v_estado_pendiente_id
       AND m2.id <> p_multa_id;

    IF v_otras_pendientes = 0 THEN
        SELECT id INTO v_estado_activo_usuario_id FROM estados_usuario WHERE nombre = 'ACTIVO';
        UPDATE usuarios SET estado_id = v_estado_activo_usuario_id WHERE id = v_usuario_id;
        o_usuario_desbloqueado := TRUE;
    ELSE
        o_usuario_desbloqueado := FALSE;
    END IF;
END;
$$;

-- ---------------------------------------------------------------------
-- sp_registrar_devolucion.sql
-- ---------------------------------------------------------------------
-- ============================================================================
-- sp_registrar_devolucion
-- Tipo: función (LANGUAGE plpgsql), múltiples parámetros de salida (OUT).
--
-- Propósito: registrar la devolución de un préstamo. Si la devolución es
-- tardía, genera una multa automáticamente y bloquea al usuario.
--
-- Parámetros (nombrados):
--   p_prestamo_id BIGINT — préstamo a devolver
--
-- Retorno (OUT, fila única — ver nota de integración en CATALOGO-SP.md sobre
-- @NamedStoredProcedureQuery con múltiples parámetros OUT):
--   o_prestamo_id  BIGINT   — mismo id recibido, para confirmación
--   o_hubo_multa   BOOLEAN  — si se generó una multa por atraso
--   o_monto_multa  NUMERIC(8,2) — monto de la multa generada, NULL si no hubo
--
-- Errores:
--   LB404 — el préstamo no existe
--   LB409 — el préstamo ya estaba devuelto (evita doble devolución)
--   LB422 — falta configurar 'monto_multa_diaria' en configuracion_sistema
--
-- Tablas afectadas: prestamos (lectura+UPDATE), libros (UPDATE stock),
-- estados_prestamo (lectura), configuracion_sistema (lectura),
-- estados_multa (lectura), multas (INSERT si hay atraso),
-- estados_usuario (lectura), usuarios (UPDATE estado si hay atraso).
-- ============================================================================
CREATE OR REPLACE FUNCTION sp_registrar_devolucion(
    p_prestamo_id BIGINT,
    OUT o_prestamo_id BIGINT,
    OUT o_hubo_multa BOOLEAN,
    OUT o_monto_multa NUMERIC(8,2)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_libro_id                    BIGINT;
    v_usuario_id                  BIGINT;
    v_estado_prestamo_id          INTEGER;
    v_estado_devuelto_id          INTEGER;
    v_fecha_devolucion_estimada   TIMESTAMPTZ;
    v_dias_atraso                 INTEGER;
    v_valor_multa_diaria          NUMERIC(8,2);
    v_estado_pendiente_multa_id   INTEGER;
    v_estado_bloqueado_id         INTEGER;
    v_ahora                       TIMESTAMPTZ := NOW();
BEGIN
    SELECT libro_id, usuario_id, estado_prestamo_id, fecha_devolucion_estimada
      INTO v_libro_id, v_usuario_id, v_estado_prestamo_id, v_fecha_devolucion_estimada
      FROM prestamos
     WHERE id = p_prestamo_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'El prestamo % no existe', p_prestamo_id USING ERRCODE = 'LB404';
    END IF;

    SELECT id INTO v_estado_devuelto_id FROM estados_prestamo WHERE nombre = 'DEVUELTO';

    IF v_estado_prestamo_id = v_estado_devuelto_id THEN
        RAISE EXCEPTION 'El prestamo % ya fue devuelto', p_prestamo_id USING ERRCODE = 'LB409';
    END IF;

    UPDATE prestamos
       SET fecha_devolucion_real = v_ahora,
           estado_prestamo_id = v_estado_devuelto_id
     WHERE id = p_prestamo_id;

    UPDATE libros
       SET stock_disponible = stock_disponible + 1
     WHERE id = v_libro_id;

    o_prestamo_id := p_prestamo_id;
    o_hubo_multa := FALSE;
    o_monto_multa := NULL;

    IF v_ahora > v_fecha_devolucion_estimada THEN
        -- Cualquier atraso, aunque sea de horas, cuenta como mínimo 1 día.
        v_dias_atraso := CEIL(EXTRACT(EPOCH FROM (v_ahora - v_fecha_devolucion_estimada)) / 86400.0)::INTEGER;

        SELECT valor::NUMERIC INTO v_valor_multa_diaria
          FROM configuracion_sistema
         WHERE clave = 'monto_multa_diaria';

        IF v_valor_multa_diaria IS NULL THEN
            RAISE EXCEPTION 'Falta configurar monto_multa_diaria en configuracion_sistema'
                USING ERRCODE = 'LB422';
        END IF;

        o_monto_multa := v_dias_atraso * v_valor_multa_diaria;
        o_hubo_multa := TRUE;

        SELECT id INTO v_estado_pendiente_multa_id FROM estados_multa WHERE nombre = 'PENDIENTE';

        INSERT INTO multas (prestamo_id, monto, estado_multa_id, fecha_generada)
        VALUES (p_prestamo_id, o_monto_multa, v_estado_pendiente_multa_id, v_ahora);

        SELECT id INTO v_estado_bloqueado_id FROM estados_usuario WHERE nombre = 'BLOQUEADO_POR_MULTA';

        UPDATE usuarios SET estado_id = v_estado_bloqueado_id WHERE id = v_usuario_id;
    END IF;
END;
$$;

-- ============================================================================
-- SGB-SaaS — db/seed.sql
-- Datos iniciales para levantar un entorno de desarrollo desde cero junto
-- con db/schema.sql (montados ambos en docker-entrypoint-initdb.d/).
-- NO usar en producción tal cual: contiene una contraseña de desarrollo
-- documentada en texto plano en este mismo archivo (ver más abajo) y en
-- README.md → "Credenciales de desarrollo".
--
-- Catálogos de estados_prestamo, estados_multa y estados_reservacion
-- confirmados por el equipo (deben coincidir exactamente con los nombres
-- referenciados por los stored procedures de A.2 — sp_registrar_devolucion,
-- sp_pagar_multa, sp_anular_multa, etc. — cualquier cambio aquí debe
-- reflejarse también allá).
-- ============================================================================

-- ===== estados_usuario =====
INSERT INTO estados_usuario (nombre) VALUES
    ('ACTIVO'),
    ('BLOQUEADO_POR_MULTA'),
    ('INACTIVO'),
    ('PENDIENTE_VERIFICACION');

-- ===== roles =====
INSERT INTO roles (nombre, descripcion) VALUES
    ('LECTOR',        'Usuario final: consulta catálogo, reserva y solicita préstamos'),
    ('BIBLIOTECARIO',  'Gestiona préstamos, devoluciones, reservas y multas'),
    ('GERENTE',        'Gestiona catálogo, inventario y reportes'),
    ('ADMIN',          'Administración total del sistema, usuarios y roles');

-- ===== estados_libro =====
INSERT INTO estados_libro (nombre) VALUES
    ('ACTIVO'),
    ('DADO_DE_BAJA'),
    ('EN_REPARACION'),
    ('PERDIDO');

-- ===== estados_prestamo =====
INSERT INTO estados_prestamo (nombre) VALUES
    ('ACTIVO'),
    ('RENOVADO'),
    ('DEVUELTO'),
    ('VENCIDO');

-- ===== estados_multa =====
INSERT INTO estados_multa (nombre) VALUES
    ('PENDIENTE'),
    ('PAGADA'),
    ('ANULADA');

-- ===== estados_reservacion =====
INSERT INTO estados_reservacion (nombre) VALUES
    ('PENDIENTE'),
    ('LISTA_PARA_RETIRO'),
    ('RETIRADA'),
    ('EXPIRADA'),
    ('CANCELADA');

-- ===== configuracion_sistema =====
-- 'monto_multa_diaria' es requerido por db/procs/sp_registrar_devolucion.sql
-- (calcula multas.monto = dias_atraso * este valor). Placeholder razonable
-- para desarrollo — ajustar al valor real que defina la biblioteca.
INSERT INTO configuracion_sistema (clave, valor) VALUES
    ('monto_multa_diaria', '0.50');

-- ===== editoriales =====
INSERT INTO editoriales (nombre, pais_origen) VALUES
    ('Prentice Hall',    'Estados Unidos'),
    ('Addison-Wesley',   'Estados Unidos'),
    ('Debolsillo',       'España'),
    ('Debate',           'España'),
    ('Plaza & Janés',    'España');

-- ===== idiomas =====
INSERT INTO idiomas (nombre, codigo_iso) VALUES
    ('Español', 'es'),
    ('Inglés',  'en');

-- ===== categorias =====
INSERT INTO categorias (nombre) VALUES
    ('Ficción'),
    ('Tecnología'),
    ('Historia');

-- ===== autores =====
INSERT INTO autores (nombre) VALUES
    ('Robert C. Martin'),
    ('Martin Fowler'),
    ('Gabriel García Márquez'),
    ('Isabel Allende'),
    ('Yuval Noah Harari');

-- ============================================================================
-- USUARIO ADMINISTRADOR DE DESARROLLO
-- Contraseña en texto plano: Admin123!
-- Hash BCrypt (costo 12, generado con org.springframework.security.crypto
-- .bcrypt.BCryptPasswordEncoder(12), el mismo encoder usado por
-- SecurityConfig.passwordEncoder()):
--   $2a$12$FIh2GQfhmm1nmqybVIIquuoL0xsLlbcL1oBQ74b6P0QXOwJQ34B8y
-- Ver también README.md → "Credenciales de desarrollo". NO usar esta
-- contraseña ni este hash en un entorno real.
-- ============================================================================
INSERT INTO usuarios (nombre, apellido, correo, password_hash, estado_id, correo_verificado)
VALUES (
    'Admin',
    'SGB',
    'admin@sgb-saas.local',
    '$2a$12$FIh2GQfhmm1nmqybVIIquuoL0xsLlbcL1oBQ74b6P0QXOwJQ34B8y',
    (SELECT id FROM estados_usuario WHERE nombre = 'ACTIVO'),
    TRUE
);

INSERT INTO usuario_roles (usuario_id, rol_id)
VALUES (
    (SELECT id FROM usuarios WHERE correo = 'admin@sgb-saas.local'),
    (SELECT id FROM roles WHERE nombre = 'ADMIN')
);

-- ============================================================================
-- LIBROS DE EJEMPLO
-- ============================================================================
INSERT INTO libros (isbn, titulo, resumen, anio_publicacion, editorial_id, idioma_id, estado_id, stock_total, stock_disponible)
VALUES
    ('9780132350884', 'Clean Code',
     'Guía de prácticas para escribir código legible y mantenible.',
     2008,
     (SELECT id FROM editoriales WHERE nombre = 'Prentice Hall'),
     (SELECT id FROM idiomas WHERE codigo_iso = 'en'),
     (SELECT id FROM estados_libro WHERE nombre = 'ACTIVO'),
     3, 3),
    ('9780134757599', 'Refactoring: Improving the Design of Existing Code',
     'Catálogo de técnicas para mejorar la estructura interna del código sin alterar su comportamiento.',
     2018,
     (SELECT id FROM editoriales WHERE nombre = 'Addison-Wesley'),
     (SELECT id FROM idiomas WHERE codigo_iso = 'en'),
     (SELECT id FROM estados_libro WHERE nombre = 'ACTIVO'),
     2, 2),
    ('9780307474728', 'Cien años de soledad',
     'Novela emblemática del realismo mágico latinoamericano.',
     1967,
     (SELECT id FROM editoriales WHERE nombre = 'Debolsillo'),
     (SELECT id FROM idiomas WHERE codigo_iso = 'es'),
     (SELECT id FROM estados_libro WHERE nombre = 'ACTIVO'),
     4, 4),
    ('9788499926223', 'Sapiens: De animales a dioses',
     'Recorrido por la historia de la humanidad desde la Edad de Piedra hasta la actualidad.',
     2014,
     (SELECT id FROM editoriales WHERE nombre = 'Debate'),
     (SELECT id FROM idiomas WHERE codigo_iso = 'es'),
     (SELECT id FROM estados_libro WHERE nombre = 'ACTIVO'),
     2, 2),
    ('9788401352836', 'La casa de los espíritus',
     'Saga familiar que combina historia política y elementos fantásticos.',
     1982,
     (SELECT id FROM editoriales WHERE nombre = 'Plaza & Janés'),
     (SELECT id FROM idiomas WHERE codigo_iso = 'es'),
     (SELECT id FROM estados_libro WHERE nombre = 'ACTIVO'),
     3, 3);

INSERT INTO libro_autores (libro_id, autor_id) VALUES
    ((SELECT id FROM libros WHERE isbn = '9780132350884'), (SELECT id FROM autores WHERE nombre = 'Robert C. Martin')),
    ((SELECT id FROM libros WHERE isbn = '9780134757599'), (SELECT id FROM autores WHERE nombre = 'Martin Fowler')),
    ((SELECT id FROM libros WHERE isbn = '9780307474728'), (SELECT id FROM autores WHERE nombre = 'Gabriel García Márquez')),
    ((SELECT id FROM libros WHERE isbn = '9788499926223'), (SELECT id FROM autores WHERE nombre = 'Yuval Noah Harari')),
    ((SELECT id FROM libros WHERE isbn = '9788401352836'), (SELECT id FROM autores WHERE nombre = 'Isabel Allende'));

INSERT INTO libro_categorias (libro_id, categoria_id) VALUES
    ((SELECT id FROM libros WHERE isbn = '9780132350884'), (SELECT id FROM categorias WHERE nombre = 'Tecnología')),
    ((SELECT id FROM libros WHERE isbn = '9780134757599'), (SELECT id FROM categorias WHERE nombre = 'Tecnología')),
    ((SELECT id FROM libros WHERE isbn = '9780307474728'), (SELECT id FROM categorias WHERE nombre = 'Ficción')),
    ((SELECT id FROM libros WHERE isbn = '9788499926223'), (SELECT id FROM categorias WHERE nombre = 'Historia')),
    ((SELECT id FROM libros WHERE isbn = '9788401352836'), (SELECT id FROM categorias WHERE nombre = 'Ficción'));
