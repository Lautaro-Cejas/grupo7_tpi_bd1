-- ===============================================================
-- Script: 04_indices.sql
-- Propósito: Crear (solo si no existen) los índices usados en 05_explain.sql
-- Compatibilidad: MySQL 5.7 / 8.0 (sin CREATE INDEX IF NOT EXISTS)
-- Estrategia: INFORMATION_SCHEMA.STATISTICS + PREPARE/EXECUTE
-- ===============================================================

USE gestion_empleados_legajos;

-- Utilidades inline
SET @sql = NULL;

-- ===============================================================
-- ========== Índices para CONSULTA 6: IGUALDAD ==================
-- tipo_documento_legajo(idx_tipo_doc: tipo_doc)
SET @tbl = 'tipo_documento_legajo';
SET @idx = 'idx_tipo_doc';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'SELECT 0',
    CONCAT('CREATE INDEX ', @idx, ' ON ', @tbl, ' (tipo_doc)')
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- documento_legajo(idx_estado_tipo: estado, id_tipo)
SET @tbl = 'documento_legajo';
SET @idx = 'idx_estado_tipo';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'SELECT 0',
    CONCAT('CREATE INDEX ', @idx, ' ON ', @tbl, ' (estado, id_tipo)')
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ===============================================================
-- ============ Índices para CONSULTA 5: RANGO ===================
-- legajo(idx_legajo_fecha: fecha_alta)
SET @tbl = 'legajo';
SET @idx = 'idx_legajo_fecha';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'SELECT 0',
    CONCAT('CREATE INDEX ', @idx, ' ON ', @tbl, ' (fecha_alta)')
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- ===============================================================
-- ============ Índices para CONSULTA 1: JOIN ====================
-- Nota: La FK empleado.id_cargo → cargo.id_cargo requiere índice por (id_cargo).
--       Mantenemos el índice simple (FK) y el compuesto para optimización del filtro.
-- empleado(idx_empleado_idcargo: id_cargo)
SET @tbl = 'empleado';
SET @idx = 'idx_empleado_idcargo';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'SELECT 0',
    'CREATE INDEX idx_empleado_idcargo ON empleado (id_cargo)'
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- empleado(idx_empleado_idcargo_salario: id_cargo, salario)
SET @tbl = 'empleado';
SET @idx = 'idx_empleado_idcargo_salario';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1
      FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'SELECT 0',
    'CREATE INDEX idx_empleado_idcargo_salario ON empleado (id_cargo, salario)'
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;
