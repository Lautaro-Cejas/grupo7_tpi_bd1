-- ===============================================================
-- Script: 05_consultas.sql
-- Objetivo: Consultas complejas + utilidad práctica (comentarios)
-- ===============================================================

USE gestion_empleados_legajos;

-- Consulta 1 (JOIN simple):
-- Obtiene salarios por cargo con verificación de rango (fuera de salario_min / salario_max).
-- Útil para auditoría y detección de desvíos salariales por cargo.
SELECT e.id_empleado, e.salario, c.nombre_cargo, c.salario_min, c.salario_max
FROM empleado e 
JOIN cargo c ON e.id_cargo = c.id_cargo
WHERE (e.salario < c.salario_min OR e.salario > c.salario_max);

-- Consulta 2 (JOIN + filtro):
-- Obtiene empleados que poseen al menos un documento con estado VIGENTE.
-- Útil para control de cumplimiento documental actualizado.
SELECT e.id_empleado, e.dni, e.nombre, e.apellido, l.nro_legajo
FROM empleado e
JOIN legajo l ON e.id_legajo = l.id_legajo
JOIN documento_legajo d ON d.id_legajo = l.id_legajo
WHERE d.estado = 'VIGENTE'
GROUP BY e.id_empleado
ORDER BY e.id_empleado ASC;

-- Consulta 3 (GROUP BY + HAVING):
-- Obtiene, por área, la cantidad de empleados en LICENCIA y el porcentaje que representan.
-- Útil para monitorear ausentismo relativo por área y priorizar intervenciones.
SELECT a.nombre_area,
       SUM(e.estado='LICENCIA') AS cant_licencia,
       COUNT(*) AS total_area,
       ROUND(100*SUM(e.estado='LICENCIA')/COUNT(*),2) AS pct_licencia
FROM empleado e
JOIN area a ON e.id_area = a.id_area
GROUP BY a.nombre_area
HAVING pct_licencia >= 10  
ORDER BY pct_licencia DESC;

-- Consulta 4 (Subconsulta + JOIN):
-- Obtiene empleados cuyo salario supera el promedio de su cargo.
-- Útil para análisis salarial interno y detección de outliers positivos por cargo.
SELECT 
  e.id_empleado, e.apellido, e.nombre, c.nombre_cargo, e.salario
FROM empleado e
JOIN (
  SELECT id_cargo, AVG(salario) AS avg_sal
  FROM empleado
  GROUP BY id_cargo
) m ON m.id_cargo = e.id_cargo
JOIN cargo c ON c.id_cargo = e.id_cargo
WHERE e.salario > m.avg_sal;

-- Consulta 5 (Rango por fecha):
-- Obtiene altas de legajo agregadas por mes dentro del año 2020.
-- Útil para analizar tendencia temporal de incorporaciones (serie mensual).
SELECT DATE_FORMAT(fecha_alta,'%Y-%m') AS anio_mes, COUNT(*) AS altas
FROM legajo
WHERE fecha_alta BETWEEN '2020-01-01' AND '2020-12-31'
GROUP BY DATE_FORMAT(fecha_alta,'%Y-%m')
ORDER BY anio_mes;

-- Consulta 6 (JOIN + IN):
-- Obtiene el conteo de documentos por tipo (CONTRATO, CERTIFICADO) y estado (VIGENTE, VENCIDO).
-- Útil como tablero rápido de control documental por categorías definidas.
SELECT t.tipo_doc,d.estado, count(*) AS cantidad
FROM tipo_documento_legajo t
JOIN documento_legajo d ON t.id_tipo = d.id_tipo
WHERE t.tipo_doc IN ('CONTRATO','CERTIFICADO')
  AND d.estado IN ('VIGENTE','VENCIDO')
GROUP BY t.tipo_doc, d.estado
ORDER BY cantidad DESC;

