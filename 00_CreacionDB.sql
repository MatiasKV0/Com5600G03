/*
------------------------------------------------------------
Trabajo Práctico Integrador
Comisión: 5600
Grupo: 03
Materia: Bases de Datos Aplicada
Integrantes: 
Apellido y Nombre             - Github          - DNI
Villan Matias Nicolas         - MatiasKV0       - 46117338
Lucas Tadeo Messina           - TotoMessina     - 44552900
Oliveti Lautaro Nahuel        - lautioliveti    - 43863497
Mamani Estrada Lucas Gabriel  - lucasGME        - 43624305
Sotelo Matias Ivan            - MatiSotelo2004  - 45870010
------------------------------------------------------------
*/

----CREACIÓN DE LA BASE DE DATOS

USE master;
GO

IF DB_ID('Com5600G03') IS NOT NULL
    DROP DATABASE Com5600G03;
GO

CREATE DATABASE Com5600G03;
GO

USE Com5600G03;
GO

----CREACIÓN DE LOS SCHEMAS

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'administracion')
BEGIN
	EXEC ('CREATE SCHEMA administracion')
END;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'unidad_funcional')
BEGIN
	EXEC ('CREATE SCHEMA unidad_funcional')
END;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'persona')
BEGIN
	EXEC ('CREATE SCHEMA persona')
END;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'expensa')
BEGIN
	EXEC ('CREATE SCHEMA expensa')
END;
GO

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'financiero')
BEGIN
	EXEC ('CREATE SCHEMA financiero')
END;
GO

------------------------------------------------------------
-- TABLAS BASE
------------------------------------------------------------

DROP TABLE IF EXISTS administracion.administracion;
CREATE TABLE administracion.administracion (
    administracion_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(200),
    cuit VARCHAR(20),
    domicilio VARCHAR(250),
    email VARCHAR(200),
    telefono VARCHAR(50),
    created_at DATETIME DEFAULT GETDATE()
);
GO


DROP TABLE IF EXISTS administracion.consorcio;
CREATE TABLE administracion.consorcio (
    consorcio_id INT IDENTITY(1,1) PRIMARY KEY,
    administracion_id INT,
    nombre VARCHAR(200),
    cuit VARCHAR(20),
    domicilio VARCHAR(250),
    superficie_total_m2 NUMERIC(12,2),
    fecha_alta DATE,
    FOREIGN KEY (administracion_id) REFERENCES administracion.administracion(administracion_id)
);
GO


DROP TABLE IF EXISTS administracion.cuenta_bancaria;
CREATE TABLE administracion.cuenta_bancaria (
    cuenta_id INT IDENTITY(1,1) PRIMARY KEY,
    banco VARCHAR(120),
    alias VARCHAR(120),
    cbu_cvu VARCHAR(40)
);
GO


DROP TABLE IF EXISTS administracion.consorcio_cuenta_bancaria;
CREATE TABLE administracion.consorcio_cuenta_bancaria (
    consorcio_cuenta_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT,
    cuenta_id INT,
    es_principal BIT,
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    FOREIGN KEY (cuenta_id) REFERENCES administracion.cuenta_bancaria(cuenta_id)
);
GO


------------------------------------------------------------
-- UNIDADES FUNCIONALES
------------------------------------------------------------

DROP TABLE IF EXISTS unidad_funcional.unidad_funcional;
CREATE TABLE unidad_funcional.unidad_funcional (
    uf_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT,
    codigo VARCHAR(50),
    piso VARCHAR(20),
    depto VARCHAR(20),
    superficie_m2 NUMERIC(12,2),
    porcentaje NUMERIC(7,4),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id)
);
GO


DROP TABLE IF EXISTS unidad_funcional.uf_cuenta;
CREATE TABLE unidad_funcional.uf_cuenta (
    uf_cuenta_id INT IDENTITY(1,1) PRIMARY KEY,
    uf_id INT,
    cuenta_id INT,
    fecha_desde DATE,
    fecha_hasta DATE,
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    FOREIGN KEY (cuenta_id) REFERENCES administracion.cuenta_bancaria(cuenta_id)
);
GO


DROP TABLE IF EXISTS unidad_funcional.cochera;
CREATE TABLE unidad_funcional.cochera (
    cochera_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT,
    uf_id INT,
    codigo VARCHAR(50),
    superficie_m2 NUMERIC(12,2),
    porcentaje NUMERIC(7,4),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id)
);
GO


DROP TABLE IF EXISTS unidad_funcional.baulera;
CREATE TABLE unidad_funcional.baulera (
    baulera_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT,
    uf_id INT,
    codigo VARCHAR(50),
    superficie_m2 NUMERIC(12,2),
    porcentaje NUMERIC(7,4),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id)
);
GO


------------------------------------------------------------
-- PERSONAS Y CONTACTOS
------------------------------------------------------------

DROP TABLE IF EXISTS persona.persona;
CREATE TABLE persona.persona (
    persona_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre_completo VARCHAR(200),
    tipo_doc VARCHAR(20),
    nro_doc VARCHAR(40),
    direccion VARCHAR(250)
);
GO


DROP TABLE IF EXISTS persona.persona_contacto;
CREATE TABLE persona.persona_contacto (
    contacto_id INT IDENTITY(1,1) PRIMARY KEY,
    persona_id INT,
    tipo VARCHAR(20),
    valor VARCHAR(200),
    es_preferido BIT,
    FOREIGN KEY (persona_id) REFERENCES persona.persona(persona_id)
);
GO


DROP TABLE IF EXISTS persona.uf_persona_vinculo;
CREATE TABLE persona.uf_persona_vinculo (
    uf_persona_id INT IDENTITY(1,1) PRIMARY KEY,
    uf_id INT,
    persona_id INT,
    rol VARCHAR(20),
    fecha_desde DATE,
    fecha_hasta DATE,
    medio_envio_preferido VARCHAR(20),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    FOREIGN KEY (persona_id) REFERENCES persona.persona(persona_id)
);
GO


------------------------------------------------------------
-- PERIODOS Y GASTOS
------------------------------------------------------------

DROP TABLE IF EXISTS expensa.periodo;
CREATE TABLE expensa.periodo (
    periodo_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT,
    anio SMALLINT,
    mes SMALLINT,
    vencimiento_1 DATE,
    vencimiento_2 DATE,
    interes_entre_vtos_pct NUMERIC(6,3),
    interes_post_2do_pct NUMERIC(6,3),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id)
);
GO




DROP TABLE IF EXISTS expensa.tipo_gasto;
CREATE TABLE expensa.tipo_gasto (
    tipo_id INT IDENTITY(1,1) PRIMARY KEY,
    nombre VARCHAR(50)
);
GO


DROP TABLE IF EXISTS expensa.sub_tipo_gasto;
CREATE TABLE expensa.sub_tipo_gasto (
    sub_id INT IDENTITY(1,1) PRIMARY KEY,
    tipo_id INT,
    nombre VARCHAR(50),
    FOREIGN KEY (tipo_id) REFERENCES expensa.tipo_gasto(tipo_id)
);
GO

DROP TABLE IF EXISTS expensa.proveedor;
CREATE TABLE expensa.proveedor (
    proveedor_id INT IDENTITY(1,1) PRIMARY KEY,
	consorcio_id INT,
	sub_id INT,
    nombre NVARCHAR(200),
    detalle NVARCHAR(200),
    cuit VARCHAR(20),
	FOREIGN KEY (sub_id) REFERENCES expensa.sub_tipo_gasto(sub_id),
	FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio
);
GO

DROP TABLE IF EXISTS expensa.gasto;
CREATE TABLE expensa.gasto (
    gasto_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT,
    periodo_id INT,
    tipo_id INT,
    sub_id INT,
    proveedor_id INT,
    nro_factura VARCHAR(60),
    detalle TEXT,
    importe NUMERIC(14,2),
    cuota_num SMALLINT,
    cuota_total SMALLINT,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    FOREIGN KEY (periodo_id) REFERENCES expensa.periodo(periodo_id),
    FOREIGN KEY (tipo_id) REFERENCES expensa.tipo_gasto(tipo_id),
    FOREIGN KEY (sub_id) REFERENCES expensa.sub_tipo_gasto(sub_id),
    FOREIGN KEY (proveedor_id) REFERENCES expensa.proveedor(proveedor_id)
);
GO


DROP TABLE IF EXISTS expensa.gasto_item;
CREATE TABLE expensa.gasto_item (
    item_id INT IDENTITY(1,1) PRIMARY KEY,
    gasto_id INT,
    concepto VARCHAR(200),
    cantidad NUMERIC(10,2),
    importe NUMERIC(14,2),
    FOREIGN KEY (gasto_id) REFERENCES expensa.gasto(gasto_id)
);
GO

DROP TABLE IF EXISTS expensa.expensa_uf;
CREATE TABLE expensa.expensa_uf (
    expensa_uf_id INT IDENTITY(1,1) PRIMARY KEY,
    periodo_id INT,
    uf_id INT,
    porcentaje NUMERIC(7,4),
    saldo_anterior_abonado NUMERIC(14,2),
    pagos_recibidos NUMERIC(14,2),
    deuda_anterior NUMERIC(14,2),
    interes_mora NUMERIC(14,2),
    expensas_ordinarias NUMERIC(14,2),
    expensas_extraordinarias NUMERIC(14,2),
    total_a_pagar NUMERIC(14,2),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    FOREIGN KEY (periodo_id) REFERENCES expensa.periodo(periodo_id),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id)
);
GO


DROP TABLE IF EXISTS expensa.expensa_uf_detalle;
CREATE TABLE expensa.expensa_uf_detalle (
    detalle_id INT IDENTITY(1,1) PRIMARY KEY,
    expensa_uf_id INT,
    gasto_id INT,
    concepto VARCHAR(200),
    importe NUMERIC(14,2),
    FOREIGN KEY (expensa_uf_id) REFERENCES expensa.expensa_uf(expensa_uf_id),
    FOREIGN KEY (gasto_id) REFERENCES expensa.gasto(gasto_id)
);
GO


DROP TABLE IF EXISTS expensa.expensa_uf_interes;
CREATE TABLE expensa.expensa_uf_interes (
    id INT IDENTITY(1,1) PRIMARY KEY,
    expensa_uf_id INT,
    tipo VARCHAR(20),
    porcentaje NUMERIC(6,3),
    importe NUMERIC(14,2),
    FOREIGN KEY (expensa_uf_id) REFERENCES expensa.expensa_uf(expensa_uf_id)
);
GO


DROP TABLE IF EXISTS expensa.envio_documento;
CREATE TABLE expensa.envio_documento (
    envio_id INT IDENTITY(1,1) PRIMARY KEY,
    periodo_id INT,
    uf_id INT,
    persona_id INT,
    medio VARCHAR(20),
    destino VARCHAR(250),
    fecha_envio DATETIME,
    estado VARCHAR(30),
    FOREIGN KEY (periodo_id) REFERENCES expensa.periodo(periodo_id),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    FOREIGN KEY (persona_id) REFERENCES persona.persona(persona_id)
);
GO


------------------------------------------------------------
-- ESTADOS Y PAGOS
------------------------------------------------------------

DROP TABLE IF EXISTS financiero.estado_financiero;
CREATE TABLE financiero.estado_financiero (
    estado_id INT IDENTITY(1,1) PRIMARY KEY,
    periodo_id INT,
    saldo_anterior NUMERIC(14,2),
    ingresos_en_termino NUMERIC(14,2),
    ingresos_adeudados NUMERIC(14,2),
    ingresos_adelantados NUMERIC(14,2),
    egresos_del_mes NUMERIC(14,2),
    saldo_cierre NUMERIC(14,2),
    FOREIGN KEY (periodo_id) REFERENCES expensa.periodo(periodo_id)
);
GO

DROP TABLE IF EXISTS financiero.banco_movimiento;
CREATE TABLE financiero.banco_movimiento (
    movimiento_id INT IDENTITY(1,1) PRIMARY KEY,
    consorcio_id INT,
    cuenta_id INT,
    cbu_origen VARCHAR(40),
    fecha DATE,
    importe NUMERIC(14,2),
    estado_conciliacion VARCHAR(20),
    FOREIGN KEY (consorcio_id) REFERENCES administracion.consorcio(consorcio_id),
    FOREIGN KEY (cuenta_id) REFERENCES administracion.cuenta_bancaria(cuenta_id)
);
GO


DROP TABLE IF EXISTS financiero.pago;
CREATE TABLE financiero.pago (
    pago_id INT IDENTITY(1,1) PRIMARY KEY,
    uf_id INT,
    fecha DATE,
    importe NUMERIC(14,2),
    tipo VARCHAR(20),
    movimiento_id INT,
    motivo_no_asociado VARCHAR(200),
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME,
    created_by VARCHAR(50),
    updated_by VARCHAR(50),
    FOREIGN KEY (uf_id) REFERENCES unidad_funcional.unidad_funcional(uf_id),
    FOREIGN KEY (movimiento_id) REFERENCES financiero.banco_movimiento(movimiento_id)
);
GO

PRINT 'Base de datos Com5600G03 creada correctamente.';
GO

