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


-- IMPORTAR TABLA CONSORCIOS DE CSV. Originalmente estos datos se encuentran en una tabla excel, se pide que exporte la hoja como csv para poder realizar la importacion

USE Com5600G03;
GO


CREATE OR ALTER PROCEDURE administracion.ImportarConsorcios
    @RutaArchivo NVARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    -- Tabla temporal con la estructura EXACTA del CSV
    CREATE TABLE #Consorcios (
        [Consorcio] VARCHAR(100),
        [Nombre del consorcio] VARCHAR(200),
        Domicilio VARCHAR(200),
        [Cant unidades funcionales] INT,
        [m2 totales] NUMERIC(12,2)
    );

    DECLARE @SQL NVARCHAR(MAX) = '
        BULK INSERT #Consorcios
        FROM ''' + @RutaArchivo + '''
        WITH (
            FORMAT = ''CSV'',
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''0x0a'',
            FIRSTROW = 2,
            CODEPAGE = ''65001''
        );
    ';
    
    BEGIN TRY
        EXEC sp_executesql @SQL;

    END TRY
    BEGIN CATCH
        PRINT 'Error al cargar el CSV: ' + ERROR_MESSAGE();
        DROP TABLE #Consorcios;
        RETURN;
    END CATCH;

    -- Insertar en tabla principal (sin administracion_id por ahora)
    INSERT INTO administracion.consorcio
        (nombre, domicilio, superficie_total_m2, fecha_alta)
    SELECT 
        LTRIM(RTRIM([Nombre del consorcio])),
        LTRIM(RTRIM(Domicilio)),
        TRY_CAST([m2 totales] AS NUMERIC(12,2)),
        GETDATE()

    FROM #Consorcios c
    WHERE NOT EXISTS (
        SELECT 1 FROM administracion.consorcio co 
        WHERE co.nombre = LTRIM(RTRIM(c.[Nombre del consorcio]))
    );

    PRINT 'Consorcios importados correctamente. Filas insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

    DROP TABLE #Consorcios;

END;
GO

EXEC administracion.ImportarConsorcios 
    @RutaArchivo = 'C:\Users\lauti\OneDrive\Desktop\Altos de SaintJust\datos varios(Consorcios).csv';
GO