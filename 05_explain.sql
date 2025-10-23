-- ===============================================================
-- Script: 05_explain.sql  (versión idempotente y portable)
-- Objetivo: Medición comparativa con/sin índice en 3 consultas 
--           (Igualdad, Rango, JOIN) usando EXPLAIN
-- Notas:
--  - Compatible con MySQL 5.7/8.0 (sin DROP INDEX IF EXISTS).
--  - Usa INFORMATION_SCHEMA.STATISTICS + PREPARE/EXECUTE.
--  - Ejecutar cada SELECT 3 veces y registrar la mediana.
-- ===============================================================

USE gestion_empleados_legajos;

-- Utilidades inline: @tbl, @idx, @sql se reutilizan en cada bloque.
SET @sql = NULL;

-- ===============================================================
-- ===================  CONSULTA 6: IGUALDAD  ====================
-- ===== SIN ÍNDICES =============================================

-- Eliminar idx_tipo_doc si existe (tipo_documento_legajo)
SET @tbl = 'tipo_documento_legajo';
SET @idx = 'idx_tipo_doc';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    CONCAT('DROP INDEX ', @idx, ' ON ', @tbl),
    'SELECT 0'
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Eliminar idx_estado_tipo si existe (documento_legajo)
SET @tbl = 'documento_legajo';
SET @idx = 'idx_estado_tipo';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    CONCAT('DROP INDEX ', @idx, ' ON ', @tbl),
    'SELECT 0'
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- EXPLAIN (SIN ÍNDICES)
EXPLAIN
SELECT t.tipo_doc, d.estado, COUNT(*) AS cantidad
FROM tipo_documento_legajo t
JOIN documento_legajo d /*+ IGNORE_INDEX(d idx_estado_tipo) */
  ON t.id_tipo = d.id_tipo
WHERE t.tipo_doc IN ('CONTRATO','CERTIFICADO')
  AND d.estado  IN ('VIGENTE','VENCIDO')
GROUP BY t.tipo_doc, d.estado;
-- Ejecutar 3 veces el SELECT (sin EXPLAIN) y anotar tiempos/mediana.


-- ===== CON ÍNDICES =============================================

-- Crear idx_tipo_doc si NO existe
SET @tbl = 'tipo_documento_legajo';
SET @idx = 'idx_tipo_doc';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'SELECT 0',
    CONCAT('CREATE INDEX ', @idx, ' ON ', @tbl, ' (tipo_doc)')
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- Crear idx_estado_tipo si NO existe
SET @tbl = 'documento_legajo';
SET @idx = 'idx_estado_tipo';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'SELECT 0',
    CONCAT('CREATE INDEX ', @idx, ' ON ', @tbl, ' (estado, id_tipo)')
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- EXPLAIN (CON ÍNDICES)
EXPLAIN
SELECT t.tipo_doc, d.estado, COUNT(*) AS cantidad
FROM tipo_documento_legajo t
JOIN documento_legajo d FORCE INDEX (idx_estado_tipo)
  ON t.id_tipo = d.id_tipo
WHERE t.tipo_doc IN ('CONTRATO','CERTIFICADO')
  AND d.estado  IN ('VIGENTE','VENCIDO')
GROUP BY t.tipo_doc, d.estado;
-- Ejecutar 3 veces el SELECT (sin EXPLAIN) y anotar tiempos/mediana.


-- ===============================================================
-- =====================  CONSULTA 5: RANGO  =====================
-- ===== SIN ÍNDICES =============================================

-- Eliminar idx_legajo_fecha si existe (legajo)
SET @tbl = 'legajo';
SET @idx = 'idx_legajo_fecha';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    CONCAT('DROP INDEX ', @idx, ' ON ', @tbl),
    'SELECT 0'
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- EXPLAIN (SIN ÍNDICE)
EXPLAIN
SELECT DATE_FORMAT(fecha_alta,'%Y-%m') AS anio_mes, COUNT(*) AS altas
FROM legajo /*+ IGNORE_INDEX(legajo idx_legajo_fecha) */
WHERE fecha_alta BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY DATE_FORMAT(fecha_alta,'%Y-%m')
ORDER BY anio_mes;
-- Ejecutar 3 veces el SELECT y anotar tiempos/mediana.


-- ===== CON ÍNDICE ==============================================

-- Crear idx_legajo_fecha si NO existe
SET @tbl = 'legajo';
SET @idx = 'idx_legajo_fecha';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'SELECT 0',
    CONCAT('CREATE INDEX ', @idx, ' ON ', @tbl, ' (fecha_alta)')
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- EXPLAIN (CON ÍNDICE)
EXPLAIN
SELECT DATE_FORMAT(fecha_alta,'%Y-%m') AS anio_mes, COUNT(*) AS altas
FROM legajo FORCE INDEX (idx_legajo_fecha)
WHERE fecha_alta BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY DATE_FORMAT(fecha_alta,'%Y-%m')
ORDER BY anio_mes;
-- Ejecutar 3 veces el SELECT y anotar tiempos/mediana.


-- ===============================================================
-- ======================  CONSULTA 1: JOIN  =====================
-- ===== SIN ÍNDICES OPTIMIZADORES ===============================
-- IMPORTANTE: La FK empleado.id_cargo → cargo.id_cargo requiere
-- un índice que empiece por (id_cargo). Para no violar la FK:
--   1) Aseguramos índice simple empleado(id_cargo).
--   2) Removemos el índice compuesto (id_cargo, salario) si existe.
-- Así medimos la versión "mínima" (solo FK) vs la "optimizada".

-- (1) Asegurar índice simple para la FK: empleado(id_cargo)
SET @tbl = 'empleado';
SET @idx = 'idx_empleado_idcargo';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'SELECT 0',
    'CREATE INDEX idx_empleado_idcargo ON empleado (id_cargo)'
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- (2) Eliminar el índice compuesto si existe: empleado(id_cargo, salario)
SET @tbl = 'empleado';
SET @idx = 'idx_empleado_idcargo_salario';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'DROP INDEX idx_empleado_idcargo_salario ON empleado',
    'SELECT 0'
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- EXPLAIN (SIN ÍNDICE COMPUESTO; queda el simple por FK)
EXPLAIN
SELECT e.id_empleado, e.salario, c.nombre_cargo, c.salario_min, c.salario_max
FROM empleado e /*+ IGNORE_INDEX(e idx_empleado_idcargo_salario) */
JOIN cargo c ON e.id_cargo = c.id_cargo
WHERE e.salario < c.salario_min OR e.salario > c.salario_max;
-- Ejecutar 3 veces el SELECT y anotar tiempos/mediana.


-- ===== CON ÍNDICES OPTIMIZADORES ===============================
-- Crear el índice compuesto si NO existe: empleado(id_cargo, salario)
SET @tbl = 'empleado';
SET @idx = 'idx_empleado_idcargo_salario';
SET @sql = (
  SELECT IF(
    EXISTS(
      SELECT 1 FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME   = @tbl
        AND INDEX_NAME   = @idx
    ),
    'SELECT 0',
    'CREATE INDEX idx_empleado_idcargo_salario ON empleado (id_cargo, salario)'
  )
);
PREPARE s FROM @sql; EXECUTE s; DEALLOCATE PREPARE s;

-- (Opcional) mantener también el simple por FK; no interfiere.
-- EXPLAIN (FORZANDO USO DEL COMPUESTO)
EXPLAIN
SELECT e.id_empleado, e.salario, c.nombre_cargo, c.salario_min, c.salario_max
FROM empleado e FORCE INDEX (idx_empleado_idcargo_salario)
JOIN cargo c ON e.id_cargo = c.id_cargo
WHERE e.salario < c.salario_min OR e.salario > c.salario_max;
-- Ejecutar 3 veces el SELECT y anotar tiempos/mediana.

-- ======================== FIN DEL SCRIPT =======================
