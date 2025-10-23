-- ===============================================================
-- Script: 07_seguridad.sql
-- Propósito: Implementar Etapa 4 (Seguridad e Integridad)
-- ===============================================================

USE gestion_empleados_legajos;

-- ======================================
-- 1. CREACIÓN DE USUARIO CON PRIVILEGIOS MÍNIMOS
-- ======================================

CREATE USER IF NOT EXISTS 'usuario_limitado'@'localhost' IDENTIFIED BY 'PasswordSeguro123!';
REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'usuario_limitado'@'localhost';

-- Permisos de lectura a tablas (incluyendo las nuevas seed)
GRANT SELECT ON gestion_empleados_legajos.empleado TO 'usuario_limitado'@'localhost';
GRANT SELECT ON gestion_empleados_legajos.legajo TO 'usuario_limitado'@'localhost';
GRANT SELECT ON gestion_empleados_legajos.area TO 'usuario_limitado'@'localhost';
GRANT SELECT ON gestion_empleados_legajos.cargo TO 'usuario_limitado'@'localhost';
GRANT SELECT ON gestion_empleados_legajos.documento_legajo TO 'usuario_limitado'@'localhost';
GRANT SELECT ON gestion_empleados_legajos.tipo_documento_legajo TO 'usuario_limitado'@'localhost';
GRANT SELECT ON gestion_empleados_legajos.nombres_seed TO 'usuario_limitado'@'localhost';
GRANT SELECT ON gestion_empleados_legajos.apellidos_seed TO 'usuario_limitado'@'localhost';

-- ======================================
-- 2. DISEÑO DE VISTAS (OCULTAR DATOS SENSIBLES)
-- ======================================

CREATE OR REPLACE VIEW v_directorio_publico AS
SELECT
    e.nombre,
    e.apellido,
    e.email,
    a.nombre_area,
    c.nombre_cargo
FROM empleado e
LEFT JOIN area a ON e.id_area = a.id_area
LEFT JOIN cargo c ON e.id_cargo = c.id_cargo
WHERE e.estado = 'ACTIVO' AND e.eliminado = 0;


CREATE OR REPLACE VIEW v_documentos_estado AS
SELECT
    e.id_empleado,
    CONCAT(e.apellido, ', ', e.nombre) AS nombre_completo,
    l.nro_legajo,
    t.tipo_doc,
    d.nro_documento,
    d.estado AS estado_documento,
    d.fecha_emision
FROM documento_legajo d
JOIN legajo l ON d.id_legajo = l.id_legajo
JOIN empleado e ON l.id_legajo = e.id_legajo
JOIN tipo_documento_legajo t ON d.id_tipo = t.id_tipo;

-- Permisos al usuario para que pueda USAR las vistas
GRANT SELECT ON gestion_empleados_legajos.v_directorio_publico TO 'usuario_limitado'@'localhost';
GRANT SELECT ON gestion_empleados_legajos.v_documentos_estado TO 'usuario_limitado'@'localhost';

-- ======================================
-- 3. CONSULTA SEGURA (PROCEDIMIENTO ALMACENADO)
-- ======================================

-- ASEGURAMOS IDEMPOTENCIA
DROP PROCEDURE IF EXISTS sp_buscar_empleado_por_dni;

DELIMITER $$
CREATE PROCEDURE sp_buscar_empleado_por_dni(IN p_dni INT)
BEGIN
    SELECT
        e.id_empleado,
        e.nombre,
        e.apellido,
        e.dni,
        e.email,
        c.nombre_cargo,
        a.nombre_area
    FROM empleado e
    LEFT JOIN cargo c ON e.id_cargo = c.id_cargo
    LEFT JOIN area a ON e.id_area = a.id_area
    WHERE e.dni = p_dni;
END$$
DELIMITER ;

-- Permiso al usuario para EJECUTAR el procedure
GRANT EXECUTE ON PROCEDURE gestion_empleados_legajos.sp_buscar_empleado_por_dni TO 'usuario_limitado'@'localhost';

-- Aplicar todos los permisos
FLUSH PRIVILEGES;

-- ======================================
-- 4. EVIDENCIA DE PRUEBAS (Comentadas)
-- ======================================

/*
-- PRUEBA DE ACCESO RESTRINGIDO (Debe fallar)
-- Conectado como 'usuario_limitado'@'localhost'
DELETE FROM empleado WHERE id_empleado = 1;
-- Resultado: ERROR 1142 (42000): DELETE command denied to user...

-- PRUEBA DE INTEGRIDAD 1: UNIQUE DNI (Debe fallar)
INSERT INTO empleado (nombre, apellido, dni, cuil, email, id_legajo)
VALUES ('Prueba', 'Duplicada', 20000001, '99-99999999-9', 'test@test.com', 999999);
-- Resultado: ERROR 1062 (23000): Duplicate entry '20000001' for key 'empleado.dni'

-- PRUEBA DE INTEGRIDAD 2: CHECK Salario (Debe fallar)
INSERT INTO cargo (nombre_cargo, salario_min, salario_max)
VALUES ('Cargo Roto', 500000.00, 100000.00);
-- Resultado: ERROR 3819 (HY000): Check constraint 'chk_salario_rango' is violated.

-- PRUEBA DE INTEGRIDAD 3: UNIQUE Legajo (Debe fallar)
-- (Suponiendo que el legajo con id 1 ya está asignado al empleado 1)
INSERT INTO empleado (nombre, apellido, dni, cuil, email, id_legajo)
VALUES ('Prueba', 'LegajoDuplicado', 99999999, '99-99999999-8', 'test2@test.com', 1);
-- Resultado: ERROR 1062 (23000): Duplicate entry '1' for key 'empleado.id_legajo'

-- PRUEBA ANTI-INYECCIÓN:
CALL sp_buscar_empleado_por_dni('20000001 OR 1=1');
-- Resultado: Devuelve solo el empleado 20000001. Ataque neutralizado.
*/