-- ===============================================================
-- Script: 08_transacciones.sql
-- Propósito: Etapa 5 - Implementación de transacciones con
--           manejo de errores y reintento (retry).
-- ===============================================================

USE gestion_empleados_legajos;

-- ASEGURAMOS IDEMPOTENCIA
DROP PROCEDURE IF EXISTS sp_promover_empleado;

DELIMITER $$
CREATE PROCEDURE sp_promover_empleado(
    IN p_id_empleado BIGINT,
    IN p_nuevo_cargo BIGINT,
    IN p_nuevo_salario DECIMAL(10,2)
)
BEGIN
    -- 1. Definir variables para el bucle de reintento
    DECLARE max_reintentos INT DEFAULT 3;
    DECLARE intento_actual INT DEFAULT 0;
    DECLARE deadlock_encontrado BOOLEAN DEFAULT 0;

    -- 2. Definir el Manejador de Errores (Handler)
    DECLARE CONTINUE HANDLER FOR 1213 SET deadlock_encontrado = 1;

    -- 3. Iniciar bucle de reintentos
    bucle_reintento: LOOP
        SET intento_actual = intento_actual + 1;
        SET deadlock_encontrado = 0; -- Resetear flag

        -- 4. Iniciar la transacción atómica
        START TRANSACTION;

        -- 5. Ejecutar la operación crítica
        UPDATE empleado
        SET id_cargo = p_nuevo_cargo, salario = p_nuevo_salario
        WHERE id_empleado = p_id_empleado;

        -- 6. Verificar si el Handler detectó un deadlock
        IF deadlock_encontrado = 0 THEN
            -- ÉXITO: Confirmar cambios y salir.
            COMMIT;
            SELECT CONCAT('Promoción exitosa en intento ', intento_actual) AS resultado;
            LEAVE bucle_reintento;
        ELSE
            -- FALLO: Revertir cambios.
            ROLLBACK;
            SELECT CONCAT('Deadlock detectado en intento ', intento_actual, '. Reintentando...') AS resultado_log;

            -- 7. Verificar límite de reintentos
            IF intento_actual >= max_reintentos THEN
                -- Abortar permanentemente
                SELECT 'Error: No se pudo resolver el deadlock tras 3 intentos.' AS resultado_final;
                LEAVE bucle_reintento;
            ELSE
                -- Pausa (backoff)
                DO SLEEP(0.5); -- Espera medio segundo
            END IF;
        END IF;
    END LOOP bucle_reintento;

END$$
DELIMITER ;