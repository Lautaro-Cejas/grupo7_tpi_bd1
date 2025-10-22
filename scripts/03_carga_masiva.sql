-- ===============================================================
-- Script: 03_carga_masiva.sql
-- Propósito: Generar carga masiva
-- ===============================================================

USE gestion_empleados_legajos;

-- ======================================
-- LEGAJOS (50k)
-- ======================================
INSERT INTO legajo (nro_legajo, categoria, estado, fecha_alta)
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n+1 FROM seq WHERE n < 50000
)
SELECT
  CONCAT('LEG-', YEAR(DATE_ADD('2018-01-01', INTERVAL (n % 3650) DAY)), '-', LPAD(n,6,'0')),
  CASE WHEN n % 3 = 1 THEN 'Junior' WHEN n % 3 = 2 THEN 'Semi-Senior' ELSE 'Senior' END,
  CASE WHEN n % 10 = 0 THEN 'INACTIVO' ELSE 'ACTIVO' END,
  DATE_ADD('2018-01-01', INTERVAL (n % 3650) DAY)
FROM seq
ON DUPLICATE KEY UPDATE nro_legajo = nro_legajo;
-- ======================================
-- EMPLEADOS (50k)
-- ======================================
INSERT INTO empleado (nombre, apellido, dni, cuil, email, fecha_ingreso, id_legajo, id_area, id_cargo, salario, estado)
WITH RECURSIVE seq50k AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n+1 FROM seq50k WHERE n < 50000
)
SELECT
  n.nombre,
  a.apellido,
  (20000000 + s.n),
  CONCAT('20-', LPAD((20000000 + s.n),8,'0'), '-', (s.n % 10)),
  CONCAT(LOWER(n.nombre),'.',LOWER(a.apellido),'.', s.n, '@empresa.com'),
  DATE_ADD('2000-01-01', INTERVAL FLOOR(RAND()*9132) DAY),
  ((s.n % (SELECT IFNULL(MAX(id_legajo),10000) FROM legajo)) + 1),
  ((s.n % (SELECT COUNT(*) FROM area)) + 1),
  ((s.n % (SELECT COUNT(*) FROM cargo)) + 1),
  ROUND(60000 + FLOOR(RAND()*240000),2),
  CASE WHEN (s.n % 100) < 80 THEN 'ACTIVO' WHEN (s.n % 100) < 90 THEN 'LICENCIA' WHEN (s.n % 100) < 95 THEN 'SUSPENDIDO' ELSE 'INACTIVO' END
FROM seq50k s
JOIN nombres_seed n ON ((s.n - 1) % (SELECT COUNT(*) FROM nombres_seed) + 1) = n.id_nombre
JOIN apellidos_seed a ON ((s.n - 1) % (SELECT COUNT(*) FROM apellidos_seed) + 1) = a.id_apellido
ON DUPLICATE KEY UPDATE dni = dni;
-- ======================================
-- DOCUMENTOS (150k)
-- ======================================
INSERT INTO documento_legajo (nro_documento, id_empleado, id_tipo, fecha_emision, estado)
WITH RECURSIVE seq150k AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n+1 FROM seq150k WHERE n < 150000
)
SELECT
  CONCAT('DOC-', LPAD(n,6,'0')),
  ((n % (SELECT COUNT(*) FROM empleado)) + 1),
  CASE
    WHEN (n % 100) < 30 THEN (SELECT id_tipo FROM tipo_documento_legajo WHERE tipo_doc='CONTRATO' LIMIT 1)
    WHEN (n % 100) < 55 THEN (SELECT id_tipo FROM tipo_documento_legajo WHERE tipo_doc='CERTIFICADO' LIMIT 1)
    WHEN (n % 100) < 70 THEN (SELECT id_tipo FROM tipo_documento_legajo WHERE tipo_doc='CAPACITACION' LIMIT 1)
    ELSE (SELECT id_tipo FROM tipo_documento_legajo WHERE tipo_doc='OTROS' LIMIT 1)
  END,
  DATE_ADD('2000-01-01', INTERVAL FLOOR(RAND()*9132) DAY),
  CASE
    WHEN (n % 100) < 85 THEN 'VIGENTE'
    WHEN (n % 100) < 95 THEN 'VENCIDO'
    ELSE 'ANULADO'
  END
FROM seq150k
ON DUPLICATE KEY UPDATE nro_documento = nro_documento;

-- =========================
-- CONSULTAS DE VERIFICACION (cuadro de verificaciones)
-- =========================

-- Conteos generales
SELECT COUNT(*) AS total_empleados FROM empleado;
SELECT COUNT(*) AS total_legajos FROM legajo;

-- FK huérfanas (deben ser 0)
-- empleado -> legajo
SELECT COUNT(*) AS huerfanos_legajo_empleado
FROM empleado e
LEFT JOIN legajo l ON e.id_legajo = l.id_legajo
WHERE l.id_legajo IS NULL;

-- legajo -> empleado
SELECT COUNT(*) AS huerfanos_empleado_legajo
FROM legajo l
LEFT JOIN empleado e ON l.id_legajo = e.id_legajo
WHERE e.id_legajo IS NULL;

-- empleado -> area
SELECT COUNT(*) AS huerfanos_area_empleado
FROM empleado e
LEFT JOIN area a ON e.id_area = a.id_area
WHERE a.id_area IS NULL;

-- Distribuciones y porcentajes
-- Estados empleados (esperado: ~80% ACTIVO, 10% LICENCIA, 5% SUSPENDIDO, 5% INACTIVO)
SELECT estado, COUNT(*) AS cantidad, ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM empleado),2) AS porcentaje
FROM empleado GROUP BY estado;

-- Tipos de documento (aprox: 30/25/15/30)
SELECT t.tipo_doc, COUNT(*) AS cantidad, ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM documento_legajo),2) AS porcentaje
FROM tipo_documento_legajo t
JOIN documento_legajo d ON t.id_tipo = d.id_tipo
GROUP BY t.tipo_doc;

-- Estados documentos (85% VIGENTE, 10% VENCIDO, 5% ANULADO)
SELECT estado, COUNT(*) AS cantidad, ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM documento_legajo),2) AS porcentaje
FROM documento_legajo GROUP BY estado;

-- Rango DNIs (deben estar dentro de 20.000.000 - 20.050.000 en este script)
SELECT MIN(dni) AS min_dni, MAX(dni) AS max_dni FROM empleado;

-- Rangos de fechas de ingreso y conteo por año
SELECT MIN(fecha_ingreso) AS min_fecha_ingreso, MAX(fecha_ingreso) AS max_fecha_ingreso FROM empleado;
SELECT YEAR(fecha_ingreso) AS anio, COUNT(*) AS cantidad FROM empleado GROUP BY YEAR(fecha_ingreso) ORDER BY anio;

-- Salarios: min/max/avg por cargo
SELECT c.nombre_cargo, COUNT(*) AS cantidad,
       ROUND(MIN(e.salario),2) AS min_salario, ROUND(MAX(e.salario),2) AS max_salario, ROUND(AVG(e.salario),2) AS avg_salario
FROM empleado e
JOIN cargo c ON e.id_cargo = c.id_cargo
GROUP BY c.nombre_cargo;

-- Emails consistentes (deben devolver 0 filas si todos siguen el patrón creado)
SELECT *
FROM empleado
WHERE email NOT LIKE CONCAT(LOWER(nombre),'.',LOWER(apellido),'%','@empresa.com')
LIMIT 10;

-- Documentos por empleado (promedio ~3)
SELECT ROUND(AVG(cantidad),2) AS avg_docs_por_empleado FROM (
  SELECT id_empleado, COUNT(*) AS cantidad FROM documento_legajo GROUP BY id_empleado
) t;

-- Empleados por área (para ver distribución)
SELECT id_area, COUNT(*) AS cantidad_empleados FROM empleado GROUP BY id_area ORDER BY cantidad_empleados DESC LIMIT 20;