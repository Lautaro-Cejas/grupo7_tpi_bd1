-- ===============================================================
-- Script: 09_concurrencia_guiada.sql
-- Propósito: Etapa 5 - Guion de pruebas para simular
--           Deadlocks y comparar Niveles de Aislamiento.
-- ===============================================================

-- !! IMPORTANTE !!
-- Este script debe ejecutarse manualmente en DOS (2) terminales
-- o pestañas de cliente SQL separadas (SESIÓN 1 y SESIÓN 2).

USE gestion_empleados_legajos;

-- ==========================================================
-- 1. SIMULACIÓN DE DEADLOCK (Interbloqueo)
-- ==========================================================

-- ➡️ EN SESIÓN 1:
START TRANSACTION;
-- Paso 1.1: Bloquear al empleado 10
UPDATE empleado SET salario = salario + 100 WHERE id_empleado = 10;
-- Paso 1.2: !! AHORA VE A LA SESIÓN 2 !!


-- ➡️ EN SESIÓN 2:
START TRANSACTION;
-- Paso 2.1: Bloquear al empleado 20
UPDATE empleado SET salario = salario + 100 WHERE id_empleado = 20;
-- Paso 2.2: !! AHORA VUELVE A LA SESIÓN 1 !!


-- ➡️ EN SESIÓN 1:
-- Paso 1.3: Intentar bloquear al empleado 20 (queda colgada)
UPDATE empleado SET salario = salario + 100 WHERE id_empleado = 20;


-- ➡️ EN SESIÓN 2:
-- Paso 2.3: Intentar bloquear al empleado 10 (crea el deadlock)
UPDATE empleado SET salario = salario + 100 WHERE id_empleado = 10;
-- !! RESULTADO: ERROR 1213 (40001): Deadlock found...
ROLLBACK; -- (Ejecutar en ambas)


-- ==========================================================
-- 2. COMPARACIÓN DE NIVELES DE AISLAMIENTO
-- ==========================================================

-- Preparación: Anota el salario original del empleado 30
SELECT id_empleado, salario FROM empleado WHERE id_empleado = 30;


-- ### PRUEBA A: REPEATABLE READ (Default de InnoDB) ###

-- ➡️ EN SESIÓN 1:
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
-- Paso 1.1: Leer el salario original
SELECT salario FROM empleado WHERE id_empleado = 30;
-- Paso 1.2: !! VE A LA SESIÓN 2 !!


-- ➡️ EN SESIÓN 2:
-- Paso 2.1: Actualizar el salario (COMMIT es automático)
UPDATE empleado SET salario = 999999.00 WHERE id_empleado = 30;
-- Paso 2.2: !! VUELVE A LA SESIÓN 1 !!


-- ➡️ EN SESIÓN 1:
-- Paso 1.3: Volver a leer el salario
SELECT salario FROM empleado WHERE id_empleado = 30;
-- ** RESULTADO: Seguirás viendo el salario ORIGINAL.
COMMIT;


-- ### PRUEBA B: READ COMMITTED ###

-- Preparación: Restaura el salario original del empleado 30
-- (Usa el valor que anotaste al inicio)
UPDATE empleado SET salario = 150000.00 WHERE id_empleado = 30; -- (Ajusta este valor)


-- ➡️ EN SESIÓN 1:
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
-- Paso 1.1: Leer el salario original
SELECT salario FROM empleado WHERE id_empleado = 30;
-- Paso 1.2: !! VE A LA SESIÓN 2 !!


-- ➡️ EN SESIÓN 2:
-- Paso 2.1: Actualizar el salario (COMMIT es automático)
UPDATE empleado SET salario = 999999.00 WHERE id_empleado = 30;
-- Paso 2.2: !! VUELVE A LA SESIÓN 1 !!


-- ➡️ EN SESIÓN 1:
-- Paso 1.3: Volver a leer el salario
SELECT salario FROM empleado WHERE id_empleado = 30;
-- ** RESULTADO: Verás el salario NUEVO (999999.00).
COMMIT;