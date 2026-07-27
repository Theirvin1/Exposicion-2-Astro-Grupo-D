-- V1__schema_inicial.sql
-- Migracion inicial de SGROAS
-- Entrega 1B: Autenticacion JWT + CRUD de conductores

CREATE OR REPLACE FUNCTION actualizar_fecha_modificacion()
RETURNS TRIGGER AS $$
BEGIN
    NEW.actualizado_en = NOW();
RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TABLE usuarios (
                          id BIGSERIAL PRIMARY KEY,
                          nombre VARCHAR(100) NOT NULL,
                          email VARCHAR(255) NOT NULL,
                          password_hash VARCHAR(255) NOT NULL,
                          rol VARCHAR(30) NOT NULL DEFAULT 'ROLE_COORDINADOR',
                          activo BOOLEAN NOT NULL DEFAULT TRUE,
                          creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                          actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_usuarios_email
    ON usuarios(email);

ALTER TABLE usuarios
    ADD CONSTRAINT chk_usuarios_rol
        CHECK (
            rol IN (
                    'ROLE_ADMIN',
                    'ROLE_COORDINADOR',
                    'ROLE_SEGURIDAD'
                )
            );

CREATE TRIGGER trg_usuarios_actualizado_en
    BEFORE UPDATE ON usuarios
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_modificacion();


CREATE TABLE conductores (
                             id BIGSERIAL PRIMARY KEY,
                             nombres VARCHAR(100) NOT NULL,
                             apellidos VARCHAR(100) NOT NULL,
                             cedula VARCHAR(10) NOT NULL,
                             numero_licencia VARCHAR(30) NOT NULL,
                             tipo_licencia VARCHAR(10) NOT NULL,
                             fecha_vencimiento_licencia DATE NOT NULL,
                             telefono VARCHAR(20),
                             email VARCHAR(255),
                             estado VARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
                             activo BOOLEAN NOT NULL DEFAULT TRUE,
                             creado_en TIMESTAMPTZ NOT NULL DEFAULT NOW(),
                             actualizado_en TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX idx_conductores_cedula
    ON conductores(cedula);

CREATE UNIQUE INDEX idx_conductores_numero_licencia
    ON conductores(numero_licencia);

ALTER TABLE conductores
    ADD CONSTRAINT chk_conductores_estado
        CHECK (
            estado IN (
                       'ACTIVO',
                       'INACTIVO',
                       'SUSPENDIDO'
                )
            );

ALTER TABLE conductores
    ADD CONSTRAINT chk_conductores_cedula_longitud
        CHECK (char_length(cedula) = 10);

ALTER TABLE conductores
    ADD CONSTRAINT chk_conductores_fecha_licencia
        CHECK (fecha_vencimiento_licencia >= DATE '2020-01-01');

CREATE TRIGGER trg_conductores_actualizado_en
    BEFORE UPDATE ON conductores
    FOR EACH ROW
    EXECUTE FUNCTION actualizar_fecha_modificacion();