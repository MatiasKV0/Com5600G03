/*
------------------------------------------------------------
Trabajo Práctico Integrador - ENTREGA 6
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


--EJECUCION DE LOS REPORTES CREADOS

USE Com5600G03
GO

--REPORTE 1 
EXEC expensa.reporte_recaudacion_semanal
    @FechaInicio = '2025-04-04',
    @FechaFin = '2025-05-05',
    @ConsorcioId = 1;
GO

--REPORTE 2
EXEC expensa.reporte_recaudacion_mes_departamento
    @Anio = 2025,
    @ConsorcioId = 2,
    @MesInicio = 1,
    @MesFin = 6;
GO

--REPORTE 3
EXEC expensa.reporte_recudacion_tipo_periodo
    @Anio = 2025,
    @ConsorcioId = 3,
    @TipoPago = 'ORDINARIO';   --COLOCAR 'ORDINARIO' O 'EXTRAORDINARIO'
GO

-- REPORTE 4
EXEC expensa.reporte_top_gastos_ingresos
    @Anio = 2025,
    @ConsorcioId = 1,
    @TopN = 3;
GO

-- REPORTE 5
EXEC expensa.reporte_top_morosos
    @ConsorcioId = 5,
    @TopN = 5,
    @Rol = 'PROPIETARIO'
GO

-- REPORTE 6
EXEC expensa.reporte_fechas_pagos_uf
    @ConsorcioId = 1,
    @UFCodigo = 1,
    @TipoPago = 'ORDINARIO'
GO

-- REPORTE 7
EXEC expensa.reporte_deuda_periodo_usd
    @ConsorcioId = 2,
    @Anio = 2025,
    @Mes = 4;
GO
