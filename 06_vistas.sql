-- ===============================================================
-- Script: 06_vistas.sql
-- Objetivo: Creación de vistas útiles para consultas y análisis
-- ===============================================================

USE gestion_empleados_legajos;

-- Vista: v_promedio_salario_por_cargo
-- Qué hace:
--   Crea una vista que muestra el salario promedio (redondeado a 2 decimales)
--   y la cantidad de empleados asociados a cada cargo.
-- Útil para:
--   Análisis salarial general y soporte a consultas que comparan
--   el salario individual con el promedio del cargo.
CREATE OR REPLACE VIEW v_promedio_salario_por_cargo AS
SELECT 
    c.id_cargo,
    c.nombre_cargo,
    ROUND(AVG(e.salario), 2) AS avg_salario_cargo,
    COUNT(*) AS cant
FROM empleado e
JOIN cargo c ON e.id_cargo = c.id_cargo
GROUP BY c.id_cargo;
