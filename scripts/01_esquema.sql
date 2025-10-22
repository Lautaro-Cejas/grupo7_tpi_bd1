-- ===============================================================
-- Script: 01_esquema.sql
-- Propósito: Establecer la base de la base de datos
-- ===============================================================

-- ======================================
-- BASE DE DATOS
-- ======================================
DROP DATABASE IF EXISTS gestion_empleados_legajos; -- Si ya existe, elimina la base de datos
CREATE DATABASE IF NOT EXISTS gestion_empleados_legajos; -- Crea la base de datos
USE gestion_empleados_legajos; -- La empezamos a usar

-- ======================================
-- TABLAS BASE
-- ======================================
CREATE TABLE IF NOT EXISTS area (
  id_area BIGINT PRIMARY KEY AUTO_INCREMENT,
  nombre_area VARCHAR(50) NOT NULL UNIQUE,
  descripcion VARCHAR(255),
  eliminado BOOLEAN NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS legajo (
  id_legajo BIGINT PRIMARY KEY AUTO_INCREMENT,
  nro_legajo VARCHAR(20) NOT NULL UNIQUE,
  categoria VARCHAR(30),
  estado ENUM('ACTIVO','INACTIVO') NOT NULL DEFAULT 'ACTIVO',
  fecha_alta DATE,
  observaciones VARCHAR(255),
  eliminado BOOLEAN DEFAULT 0
);

CREATE TABLE IF NOT EXISTS cargo (
 id_cargo BIGINT PRIMARY KEY AUTO_INCREMENT,
  nombre_cargo VARCHAR(50) NOT NULL UNIQUE,
  salario_min DECIMAL(10,2) NOT NULL,
  salario_max DECIMAL(10,2) NOT NULL,
  eliminado BOOLEAN NOT NULL DEFAULT 0,
  CONSTRAINT chk_salario_rango CHECK (salario_min <= salario_max)
);

CREATE TABLE IF NOT EXISTS empleado (
  id_empleado BIGINT PRIMARY KEY AUTO_INCREMENT,
  nombre VARCHAR(80) NOT NULL,
  apellido VARCHAR(80) NOT NULL,
  dni INT NOT NULL UNIQUE,
  cuil VARCHAR(15) NOT NULL UNIQUE,
  email VARCHAR(200) NOT NULL UNIQUE,
  fecha_ingreso DATE,
  id_legajo BIGINT,
  id_area BIGINT,
  id_cargo BIGINT,
  salario DECIMAL(10,2),
  estado ENUM('ACTIVO','LICENCIA','SUSPENDIDO','INACTIVO') DEFAULT 'ACTIVO',
  eliminado BOOLEAN DEFAULT 0,
  FOREIGN KEY (id_legajo) REFERENCES legajo(id_legajo) ON DELETE SET NULL,
  FOREIGN KEY (id_area) REFERENCES area(id_area) ON DELETE SET NULL,
  FOREIGN KEY (id_cargo) REFERENCES cargo(id_cargo) ON DELETE SET NULL
) ENGINE=InnoDB;