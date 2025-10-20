-- ===============================================================
-- Script: 01_Esquema.sql
-- Propósito: Establecer la base de la base de datos
-- ===============================================================

-- ======================================
-- BASE DE DATOS
-- ======================================
CREATE DATABASE IF NOT EXISTS gestion_empleados_legajos;
USE gestion_empleados_legajos;

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
  eliminado BOOLEAN NOT NULL DEFAULT 0,
  nombre VARCHAR(80) NOT NULL,
  apellido VARCHAR(80) NOT NULL,
  dni VARCHAR(15) NOT NULL UNIQUE,
  email VARCHAR(120),
  fecha_ingreso DATE NOT NULL,
  id_area BIGINT NOT NULL,
  id_cargo BIGINT NOT NULL,
  id_legajo BIGINT UNIQUE,
  salario DECIMAL(10,2) NOT NULL,
  estado ENUM('ACTIVO','LICENCIA','SUSPENDIDO','INACTIVO') NOT NULL,
  FOREIGN KEY (id_area) REFERENCES area(id_area) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (id_cargo) REFERENCES cargo(id_cargo) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (id_legajo) REFERENCES legajo(id_legajo) ON UPDATE CASCADE ON DELETE CASCADE
);