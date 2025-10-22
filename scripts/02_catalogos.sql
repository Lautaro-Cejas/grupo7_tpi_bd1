-- ===============================================================
-- Script: 02_catalogos.sql
-- Propósito: Crear tablas de catálogos/semillas y cargarlas
-- ===============================================================

USE gestion_empleados_legajos;

-- ======================================
-- TABLAS SEMILLA
-- ======================================

DROP TABLE IF EXISTS nombres_seed;
CREATE TABLE IF NOT EXISTS nombres_seed (
  id_nombre INT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(80) NOT NULL
);

DROP TABLE IF EXISTS apellidos_seed;
CREATE TABLE IF NOT EXISTS apellidos_seed (
  id_apellido INT PRIMARY KEY AUTO_INCREMENT,
  apellido VARCHAR(80) NOT NULL
);

CREATE TABLE IF NOT EXISTS tipo_documento_legajo (
  id_tipo INT PRIMARY KEY AUTO_INCREMENT,
  tipo_doc VARCHAR(80) NOT NULL UNIQUE
);

DROP TABLE IF EXISTS documento_legajo;
CREATE TABLE IF NOT EXISTS documento_legajo (
  id_documento BIGINT PRIMARY KEY AUTO_INCREMENT,
  nro_documento VARCHAR(40) NOT NULL UNIQUE,
  id_legajo BIGINT NOT NULL,
  id_tipo INT NOT NULL,
  fecha_emision DATE,
  estado ENUM('VIGENTE','VENCIDO','ANULADO') DEFAULT 'VIGENTE',
  observaciones VARCHAR(255),
  FOREIGN KEY (id_legajo) REFERENCES legajo(id_legajo) ON DELETE CASCADE,
  FOREIGN KEY (id_tipo) REFERENCES tipo_documento_legajo(id_tipo) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ======================================
-- SEMILLAS DE DATOS
-- ======================================

-- NOMBRES
TRUNCATE nombres_seed;
INSERT INTO nombres_seed (nombre) VALUES
('Martín'),('Sofía'),('Mateo'),('Valentina'),('Santiago'),('Camila'),('Lucas'),('Isabella'),
('Matías'),('Julieta'),('Agustín'),('Mía'),('Nicolás'),('Diego'),('Lucía'),
('Federico'),('Emma'),('Tomás'),('María'),('Bruno'),('Sara'),('Emiliano'),('Pilar'),
('Joaquín'),('Antonia'),('Ignacio'),('Clara'),('Francisco'),('Victoria'),('Hernán'),('Bianca'),
('Alejandro'),('Catalina'),('Martina'),('Gaspar'),('Zoe'),('Andrés'),('Romina'),('Pablo'),
('Lorena'),('Adrián'),('Luna'),('Rubén'),('Josefina'),('Hugo'),('Manuela'),('Fabián'),
('Agustina'),('Nahuel'),('Mara'),('Esteban'),('Magdalena'),('Gonzalo'),('Aitana'),('Mario'),
('Belén'),('Rodrigo'),('Ariadna'),('Álvaro'),('Fabiana'),('Verónica'),
('Ciro'),('Renata'),('Raúl'),('Carla'),('Baltazar'),('Noelia'),('Ramiro'),('Jimena'),
('Darío'),('Florencia'),('Ezequiel'),('Celeste'),('Óscar'),('Jazmín'),
('Brenda'),('Sergio'),('Elena'),('Cristian'),('Soledad'),('Félix'),('Vanesa'),('César'),
('Milagros'),('Rafael'),('Yesica'),('Jerónimo'),('Raquel'),('Amalia'),
('Mauro'),('Ainhoa'),('Carolina'),('Nora'),('Benjamín'),('Javier'),('Sol'),('Germán'),
('Lola'),('Diana'),('Mariano'),('Yanina'),('Emanuel'),('Graciela'),('Iván'),('Rocío'),
('Luciano'),('MaríaJosé'),('Ulises'),('Priscila'),('Candelaria'),('Joel');

-- APELLIDOS
TRUNCATE apellidos_seed;
INSERT IGNORE INTO apellidos_seed (apellido) VALUES
('González'),('Rodríguez'),('García'),('Martínez'),('López'),('Pérez'),('Sánchez'),('Romero'),
('Torres'),('Ramírez'),('Díaz'),('Herrera'),('Álvarez'),('Flores'),('Vargas'),('Castro'),
('Silva'),('Ruiz'),('Ramos'),('Ortega'),('Molina'),('Ámbito'),('Benítez'),('Giménez'),
('Navarro'),('Cabrera'),('Ferrer'),('Iglesias'),('Sosa'),('Vega'),('Rojas'),('Paredes'),
('Salazar'),('Morales'),('Medina'),('Córdoba'),('Paz'),('Aguirre'),('Mendoza'),('Cruz'),
('Suárez'),('Leiva'),('Lucero'),('Videla'),('Rivera'),('Peralta'),('Bruno'),('Núñez'),
('Herrero'),('Silveira'),('Barrios'),('Ponce'),('Acosta'),('Ferreyra'),('Tapia'),('Pizarro'),
('Gallo'),('Crespo'),('Aguilar'),('Quiroga'),('Serrano'),('Maldonado'),('Cárdenas'),('Bonilla'),
('Rico'),('Mena'),('Yáñez'),('Benavidez'),('Correa'),('Bustos'),('Cano'),
('Roldán'),('León'),('Orellana'),('Zapata'),('Urbano'),('Maturana'),('Bermúdez'),('Cisneros'),
('Lemus'),('Alonso'),('Peña'),('Cortés'),('Montero'),('Quintana'),('Campos'),('Escobar'),
('Guerra'),('Sáenz'),('Arce'),('Oliva'),('Ocampo'),('Figueroa'),('Zárate'),
('Castillo'),('Cáceres'),('Alvarado'),('Cervantes'),('Santos'),('Viera'),('Luna'),('Bravo'),
('Riquelme'),('Chávez'),('Pacheco'),('Almeida'),('Duarte'),('Méndez');

-- CARGOS (no se puede hacer TRUNCATE)
INSERT IGNORE INTO cargo (nombre_cargo, salario_min, salario_max) VALUES
('Operario', 60000.00, 120000.00),
('Administrativo', 80000.00, 160000.00),
('Técnico', 100000.00, 220000.00),
('Supervisor', 150000.00, 300000.00),
('Gerente', 250000.00, 600000.00);

-- TIPOS DE DOCUMENTOS (no se puede hacer TRUNCATE)
INSERT IGNORE INTO tipo_documento_legajo (tipo_doc) VALUES
('CONTRATO'),('CERTIFICADO'),('CAPACITACION'),('OTROS');

-- ÁREAS (no se puede hacer TRUNCATE)
INSERT IGNORE INTO area (nombre_area, descripcion) VALUES
('Recursos Humanos', 'Gestiona todo lo relacionado con personal'),
('Tecnología', 'Departamento de desarrollo y soporte IT'),
('Operaciones', 'Operaciones de planta'),
('Ventas', 'Equipo comercial'),
('Administración', 'Contabilidad y finanzas');