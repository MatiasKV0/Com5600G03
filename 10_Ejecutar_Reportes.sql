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
EXEC expensa.Reporte_RecaudacionSemanal
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-05-05',
    @ConsorcioId = 1;
GO

--REPORTE 2
EXEC expensa.Reporte_RecaudacionMesDepartamentos
    @Anio = 2025,
    @ConsorcioId = 2,
    @MesInicio = 1,
    @MesFin = 6;
GO

--REPORTE 3
EXEC expensa.Reporte_RecaudacionPorTipoPeriodo
    @Anio = 2025,
    @ConsorcioId = 3,
    @TipoPago = 'ORDINARIO';   --COLOCAR 'ORDINARIO' O 'EXTRAORDINARIO'
GO

-- REPORTE 4
EXEC expensa.Reporte_TopMesesGastosIngresos
    @Anio = 2025,
    @ConsorcioId = 1,
    @TopN = 5;
GO

-- REPORTE 5
EXEC expensa.Reporte_Top3Morosos
    @ConsorcioId = 1,
    @TopN = 3,
    @Rol = 'PROPIETARIO'
GO

-- REPORTE 6
EXEC expensa.Reporte_FechasPagosUF
    @ConsorcioId = 1,
    @UFCodigo = 1,
    @TipoPago = 'ORDINARIO'
GO

-- ACTUALIZAR API DOLAR
EXEC administracion.ActualizarCotizacionDolarOficial
GO

-- REPORTE 7
EXEC expensa.Reporte7_DeudaPeriodo_ARS_USD
    @ConsorcioId = 3,
    @Anio = 2025,
    @Mes = 4;
GO
