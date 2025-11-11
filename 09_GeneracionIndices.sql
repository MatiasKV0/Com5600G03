/*
------------------------------------------------------------
Trabajo Práctico Integrador - ENTREGA 5
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

-- GENERACIÓN DE INDICES NO CLUSTER PARA LA OPTIMIZACION DE LOS REPORTES

USE Com5600G03;
GO

--------------------------------------------------------------------------------
--INDICE PARA REPORTE 1
--------------------------------------------------------------------------------


IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IDX_Reporte1' 
)
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Reporte1
    ON banco.pago (fecha, uf_id, tipo)
    INCLUDE (importe);
END;
GO

-----------------------------------------------------------------------------------
--INDICE PARA REPORTE 2
-----------------------------------------------------------------------------------
IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IDX_Reporte2' 
 
)
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Reporte2
    ON unidad_funcional.unidad_funcional (consorcio_id, uf_id)
    INCLUDE (depto);
END;
GO


-----------------------------------------------------------------------------------
--INDICE PARA REPORTE 3
-----------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IDX_Reporte3' 
)
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Reporte3
    ON expensa.periodo (consorcio_id, anio, mes)
    INCLUDE (periodo_id);
END;
GO

-----------------------------------------------------------------------------------
--INDICE PARA REPORTE 4
-----------------------------------------------------------------------------------

IF NOT EXISTS (
    SELECT 1 
    FROM sys.indexes 
    WHERE name = 'IDX_Reporte4'
)
BEGIN
    CREATE NONCLUSTERED INDEX IDX_Reporte4
    ON expensa.gasto (periodo_id)
    INCLUDE (importe);
END;
GO

