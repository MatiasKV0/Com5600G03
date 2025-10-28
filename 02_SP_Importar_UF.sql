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
-- IMPORTAR TABLA DE UNIDAD FUNCIONAL DESDE CSV.

use Com5600G03
go

CREATE OR ALTER PROCEDURE administracion.ImportarUnidadesFuncionales
    @RutaArchivo NVARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;

    PRINT 'Iniciando importación completa desde: ' + @RutaArchivo;

    -- Tabla temporal con TODAS las columnas
    CREATE TABLE #UFTemp (
        col1 VARCHAR(200),  -- Nombre del consorcio
        col2 VARCHAR(10),   -- nroUnidadFuncional
        col3 VARCHAR(20),   -- Piso
        col4 VARCHAR(20),   -- departamento
        col5 VARCHAR(20),   -- coeficiente
        col6 VARCHAR(20),   -- m2_unidad_funcional
        col7 VARCHAR(10),   -- bauleras
        col8 VARCHAR(10),   -- cochera
        col9 VARCHAR(20),   -- m2_baulera
        col10 VARCHAR(20)   -- m2_cochera
    );

    DECLARE @SQL NVARCHAR(MAX) = '
        BULK INSERT #UFTemp
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ''\t'',
            ROWTERMINATOR = ''\n'',
            MAXERRORS = 1000
        );
    ';
    
    BEGIN TRY
        PRINT 'Ejecutando BULK INSERT...';
        EXEC sp_executesql @SQL;
        
        DECLARE @RowCount INT;
        SELECT @RowCount = COUNT(*) FROM #UFTemp;
        PRINT 'Archivo cargado. Filas: ' + CAST(@RowCount AS VARCHAR(10));
        
        -- Mostrar muestra de datos para verificar
        PRINT 'Muestra de datos cargados:';
        SELECT TOP 3 * FROM #UFTemp;
        
        -- 1. Insertar unidades funcionales principales
        PRINT 'Insertando unidades funcionales...';
        INSERT INTO unidad_funcional.unidad_funcional
            (consorcio_id, codigo, piso, depto, superficie_m2, porcentaje)
        SELECT 
            c.consorcio_id,
            'UF' + col2,
            col3,
            col4,
            CASE 
                WHEN ISNUMERIC(REPLACE(col6, ',', '.')) = 1 
                THEN CAST(REPLACE(col6, ',', '.') AS NUMERIC(12,2))
                ELSE 0 
            END,
            CASE 
                WHEN ISNUMERIC(REPLACE(col5, ',', '.')) = 1 
                THEN CAST(REPLACE(col5, ',', '.') AS NUMERIC(7,4))
                ELSE 0 
            END
        FROM #UFTemp uf
        INNER JOIN administracion.consorcio c ON c.nombre = LTRIM(RTRIM(uf.col1));

        PRINT 'Unidades funcionales importadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

        -- 2. Insertar bauleras
        PRINT 'Insertando bauleras...';
        INSERT INTO unidad_funcional.baulera
            (consorcio_id, uf_id, codigo, superficie_m2, porcentaje)
        SELECT 
            c.consorcio_id,
            uf.uf_id,
            'B' + uf_temp.col2,
            CASE 
                WHEN ISNUMERIC(REPLACE(uf_temp.col9, ',', '.')) = 1 
                THEN CAST(REPLACE(uf_temp.col9, ',', '.') AS NUMERIC(12,2))
                ELSE 0 
            END,
            -- PORCENTAJE: se calcula en base a la superficie de la baulera y la superficie total de la UF
            (CASE 
                WHEN ISNUMERIC(REPLACE(uf_temp.col9, ',', '.')) = 1 
                THEN CAST(REPLACE(uf_temp.col9, ',', '.') AS NUMERIC(12,2))
                ELSE 0 
            END / NULLIF(uf.superficie_m2, 0)) * uf.porcentaje
        FROM #UFTemp uf_temp
        INNER JOIN administracion.consorcio c ON c.nombre = LTRIM(RTRIM(uf_temp.col1))
        INNER JOIN unidad_funcional.unidad_funcional uf 
            ON uf.consorcio_id = c.consorcio_id 
            AND uf.piso = uf_temp.col3 
            AND uf.depto = uf_temp.col4
        WHERE uf_temp.col7 = 'SI' 
            AND CASE 
                    WHEN ISNUMERIC(REPLACE(uf_temp.col9, ',', '.')) = 1 
                    THEN CAST(REPLACE(uf_temp.col9, ',', '.') AS NUMERIC(12,2))
                    ELSE 0 
                END > 0;

        PRINT 'Bauleras importadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

        -- 3. Insertar cocheras
        PRINT 'Insertando cocheras...';
        INSERT INTO unidad_funcional.cochera
            (consorcio_id, uf_id, codigo, superficie_m2, porcentaje)
        SELECT 
            c.consorcio_id,
            uf.uf_id,
            'C' + uf_temp.col2,
            CASE 
                WHEN ISNUMERIC(REPLACE(uf_temp.col10, ',', '.')) = 1 
                THEN CAST(REPLACE(uf_temp.col10, ',', '.') AS NUMERIC(12,2))
                ELSE 0 
            END,
            -- PORCENTAJE: se calcula en base a la superficie de la cochera y la superficie total de la UF
            (CASE 
                WHEN ISNUMERIC(REPLACE(uf_temp.col10, ',', '.')) = 1 
                THEN CAST(REPLACE(uf_temp.col10, ',', '.') AS NUMERIC(12,2))
                ELSE 0 
            END / NULLIF(uf.superficie_m2, 0)) * uf.porcentaje
        FROM #UFTemp uf_temp
        INNER JOIN administracion.consorcio c ON c.nombre = LTRIM(RTRIM(uf_temp.col1))
        INNER JOIN unidad_funcional.unidad_funcional uf 
            ON uf.consorcio_id = c.consorcio_id 
            AND uf.piso = uf_temp.col3 
            AND uf.depto = uf_temp.col4
        WHERE uf_temp.col8 = 'SI' 
            AND CASE 
                    WHEN ISNUMERIC(REPLACE(uf_temp.col10, ',', '.')) = 1 
                    THEN CAST(REPLACE(uf_temp.col10, ',', '.') AS NUMERIC(12,2))
                    ELSE 0 
                END > 0;

        PRINT 'Cocheras importadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10));

        -- 4. Verificar datos insertados
      

    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE();
        PRINT 'Número de error: ' + CAST(ERROR_NUMBER() AS VARCHAR(10));
        
        -- Mostrar en qué paso falló
        IF ERROR_MESSAGE() LIKE '%baulera%'
            PRINT 'Error al insertar bauleras';
        ELSE IF ERROR_MESSAGE() LIKE '%cochera%'
            PRINT 'Error al insertar cocheras';
        ELSE
            PRINT 'Error general en el proceso';
    END CATCH

    -- Asegurarse de eliminar la tabla temporal si existe
    IF OBJECT_ID('tempdb..#UFTemp') IS NOT NULL
        DROP TABLE #UFTemp;
END;
GO

EXEC administracion.ImportarUnidadesFuncionales
@RutaArchivo='C:\Users\lauti\OneDrive\Desktop\Altos de SaintJust\UF por consorcio.txt';
go

