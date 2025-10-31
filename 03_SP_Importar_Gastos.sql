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


USE Com5600G03
GO

DROP PROCEDURE administracion.ImportarGastos;
GO
-- IMPORTAR GASTOS DESDE JSON.
CREATE OR ALTER PROCEDURE administracion.ImportarGastos
	@RutaArchivo NVARCHAR(400)
AS
BEGIN
	SET NOCOUNT ON;

    -- 1. Se declara una tabla temporal para cargar el JSON
    IF OBJECT_ID('tempdb..#gastos_archivo') IS NOT NULL DROP TABLE #gastos_archivo;
	CREATE TABLE #gastos_archivo(
        ConsorcioNombre VARCHAR(200),
        MesNombre VARCHAR(50),
        Bancarios VARCHAR(50),
        Limpieza VARCHAR(50),
        Administracion VARCHAR(50),
        Seguros VARCHAR(50),
        GastosGenerales VARCHAR(50),
        Agua VARCHAR(50),
        Luz VARCHAR(50)
    );

    -- 2. Se inserta el JSON en la tabla temporal usando OPENJSON
    DECLARE @bulk_json NVARCHAR(MAX) = N'
    INSERT INTO #gastos_archivo (
        ConsorcioNombre, MesNombre, Bancarios, Limpieza, Administracion,
        Seguros, GastosGenerales, Agua, Luz
    )
    SELECT
        ConsorcioNombre,
        Mes,
        BANCARIOS,
        LIMPIEZA,
        ADMINISTRACION,
        SEGUROS,
        GastosGenerales,
        Agua,
        Luz
    FROM OPENROWSET(BULK ''' + @RutaArchivo + ''', SINGLE_CLOB) as j
    CROSS APPLY OPENJSON(BulkColumn)
    WITH (
        ConsorcioNombre VARCHAR(200) ''$.\"Nombre del consorcio\"'',
        Mes VARCHAR(50) ''$.Mes'',
        BANCARIOS VARCHAR(50) ''$.BANCARIOS'',
        LIMPIEZA VARCHAR(50) ''$.LIMPIEZA'',
        ADMINISTRACION VARCHAR(50) ''$.ADMINISTRACION'',
        SEGUROS VARCHAR(50) ''$.SEGUROS'',
        GastosGenerales VARCHAR(50) ''$.\"GASTOS GENERALES\"'',
        Agua VARCHAR(50) ''$.\"SERVICIOS PUBLICOS-Agua\"'',
        Luz VARCHAR(50) ''$.\"SERVICIOS PUBLICOS-Luz\"''
    );';

    EXEC(@bulk_json);

    --TABLA CON EL NUMERO DE LOS MESES--
    CREATE TABLE #mesNumero(
        NombreMes VARCHAR(50) PRIMARY KEY,
        NumeroMes INT
    );

    INSERT INTO #mesNumero (NombreMes, NumeroMes)
    VALUES
        ('enero', 1), ('febrero', 2), ('marzo', 3), ('abril', 4),
        ('mayo', 5), ('junio', 6), ('julio', 7), ('agosto', 8),
        ('septiembre', 9), ('octubre', 10), ('noviembre', 11), ('diciembre', 12);
   

    -- 3. Inserta en la tabla GASTO
    
    INSERT INTO expensa.gasto (
        consorcio_id,
        periodo_id,
        tipo_id, 
        sub_id,  
        importe,
        detalle
    )
    SELECT
        c.consorcio_id,
        p.periodo_id,
        sg.tipo_id, 
        sg.sub_id,
        CAST(REPLACE(REPLACE(g.Importe, '.', ''), ',', '.') AS NUMERIC(14, 2)) AS Importe,
        'Gasto ' + g.SubTipoNombre AS detalle
    FROM #gastos_archivo AS t
    INNER JOIN administracion.consorcio AS c ON t.ConsorcioNombre = c.nombre
    INNER JOIN #mesNumero AS m ON m.NombreMes = LOWER(TRIM(t.MesNombre))
    INNER JOIN expensa.periodo AS p ON c.consorcio_id = p.consorcio_id 
                     AND p.anio = YEAR(GETDATE()) 
                     AND p.mes = m.NumeroMes

    CROSS APPLY (
        VALUES
            ('BANCARIOS', t.Bancarios),
            ('LIMPIEZA', t.Limpieza),
            ('ADMINISTRACION', t.Administracion),
            ('SEGUROS', t.Seguros),
            ('GASTOS GENERALES', t.GastosGenerales),
            ('SERVICIOS PUBLICOS-Agua', t.Agua),
            ('SERVICIOS PUBLICOS-Luz', t.Luz)
    ) AS g(SubTipoNombre, Importe)

    INNER JOIN expensa.sub_tipo_gasto AS sg ON g.SubTipoNombre = sg.nombre

    WHERE 
        g.Importe IS NOT NULL AND g.Importe != '0,00'
        AND NOT EXISTS (
            SELECT 1
            FROM expensa.gasto g_exist
            WHERE g_exist.periodo_id = p.periodo_id
              AND g_exist.sub_id = sg.sub_id
        );

    DROP TABLE #gastos_archivo;
    DROP TABLE #mesNumero;

END;
GO


EXEC administracion.ImportarGastos
    @RutaArchivo='C:\Users\Matias\Desktop\consorcios\Servicios.Servicios.json';
GO
