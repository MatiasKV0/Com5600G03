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

----------------------------------------------------------------
-----------------------------------------------------------------
CREATE OR ALTER PROCEDURE administracion.CargarTipoGastos
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. CARGA DE TIPO_GASTO
	
    CREATE TABLE #tipos(nombre NVARCHAR(100));
    INSERT INTO #tipos (nombre)
    VALUES
        ('GASTOS ORDINARIOS'),
        ('GASTOS EXTRAORDINARIOS');

    INSERT INTO expensa.tipo_gasto (nombre)
    SELECT t.nombre
    FROM #tipos t
    WHERE NOT EXISTS (SELECT 1 FROM expensa.tipo_gasto tg WHERE tg.nombre = t.nombre);

    PRINT 'Tipos de gasto cargados.';

    -- 2. CARGA DE SUB_TIPO_GASTO

    CREATE TABLE #subtipos(tipo_nombre NVARCHAR(100), sub_nombre NVARCHAR(150));

    INSERT INTO #subtipos (tipo_nombre, sub_nombre)
    VALUES
        ('GASTOS ORDINARIOS', 'GASTOS DE LIMPIEZA'),
        ('GASTOS ORDINARIOS', 'GASTOS GENERALES'),
        ('GASTOS ORDINARIOS','SERVICIOS PUBLICOS'),
        ('GASTOS ORDINARIOS', 'GASTOS DE ADMINISTRACION'),
        ('GASTOS ORDINARIOS', 'GASTOS BANCARIOS'),
        ('GASTOS ORDINARIOS', 'SEGUROS'),
		('GASTOS EXTRAORDINARIOS', 'CONSTRUCCIONES'),
        ('GASTOS EXTRAORDINARIOS', 'REPARACIONES');

    INSERT INTO expensa.sub_tipo_gasto (tipo_id, nombre)
    SELECT tg.tipo_id, s.sub_nombre
    FROM #subtipos s
    INNER JOIN expensa.tipo_gasto tg ON tg.nombre = s.tipo_nombre
    WHERE NOT EXISTS (
        SELECT 1 FROM expensa.sub_tipo_gasto sg WHERE sg.nombre = s.sub_nombre
    );

    PRINT 'Subtipos de gasto cargados.';

	DROP TABLE #tipos
	DROP TABLE #subtipos
END;
GO

EXEC administracion.CargarTipoGastos;
GO

SELECT * FROM expensa.tipo_gasto
GO
SELECT * FROM expensa.sub_tipo_gasto
GO

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE administracion.CargarProveedores
	@RutaArchivo NVARCHAR(400)
AS
BEGIN 
	SET NOCOUNT ON;

	CREATE TABLE #prove(
		tipo NVARCHAR(100),
		tipoNombre NVARCHAR(100),
		detalle NVARCHAR(100),
		nombreConsorcio VARCHAR(100)
	);

	DECLARE @sql_bulk NVARCHAR(MAX) =
    N'BULK INSERT #prove
    FROM N''' + @RutaArchivo + N'''
    WITH (
       FIELDTERMINATOR = '';'',
       ROWTERMINATOR   = ''\n'',
       CODEPAGE        = ''65001'',
       FIRSTROW        = 2
    );';
	EXEC (@sql_bulk);

	-----------INSERTO LOS DATOS------------
	
	INSERT INTO expensa.proveedor(
		nombre,
		detalle,
		consorcio_id,
		sub_id
		
	)
	SELECT tipoNombre, detalle, con.consorcio_id, sg.sub_id FROM #prove AS P
	JOIN administracion.consorcio AS con ON con.nombre =RTRIM(LTRIM(P.nombreConsorcio))
	JOIN expensa.sub_tipo_gasto AS sg ON P.tipo = sg.nombre
	WHERE NOT EXISTS(
		SELECT 1 FROM expensa.proveedor as e
		JOIN administracion.consorcio AS con ON con.administracion_id = e.consorcio_id
		WHERE  P.nombreConsorcio = con.nombre AND P.detalle = e.detalle
	)

	
END;
GO

EXEC administracion.CargarProveedores
	@RutaArchivo = 'D:\TP_SQL\consorcios\datos varios(Proveedores).csv'
GO

SELECT * from expensa.proveedor

----------------------------------------------------------------------------------
----------------------------------------------------------------------------------

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
        ConsorcioNombre VARCHAR(200) ''$."Nombre del consorcio"'',
		Mes VARCHAR(50) ''$.Mes'',
		BANCARIOS VARCHAR(50) ''$.BANCARIOS'',
		LIMPIEZA VARCHAR(50) ''$.LIMPIEZA'',
		ADMINISTRACION VARCHAR(50) ''$.ADMINISTRACION'',
		SEGUROS VARCHAR(50) ''$.SEGUROS'',
		GastosGenerales VARCHAR(50) ''$."GASTOS GENERALES"'',
		Agua VARCHAR(50) ''$."SERVICIOS PUBLICOS-Agua"'',
		Luz VARCHAR(50) ''$."SERVICIOS PUBLICOS-Luz"''
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
       -- periodo_id,
        tipo_id, 
        sub_id,  
        importe,
        detalle
    )
    SELECT
        c.consorcio_id,
      --  p.periodo_id,
        sg.tipo_id, 
        sg.sub_id,
       CASE
		  WHEN g.ImporteCrudo IS NULL OR LTRIM(RTRIM(g.ImporteCrudo)) = '' THEN NULL
		  WHEN g.ImporteCrudo LIKE '%,%' OR g.ImporteCrudo LIKE '%.%' THEN
			   CAST(
				 CAST(REPLACE(REPLACE(LTRIM(RTRIM(g.ImporteCrudo)), ',', ''), '.', '') AS bigint) / 100.0
				 AS NUMERIC(12,2)
			   )
		  ELSE
			   CAST(LTRIM(RTRIM(g.ImporteCrudo)) AS NUMERIC(12,2))
		END AS Importe,
        tg.nombre + ' - ' + g.SubTipoNombre AS detalle
    FROM #gastos_archivo AS t
    INNER JOIN administracion.consorcio AS c ON t.ConsorcioNombre = c.nombre
   /* INNER JOIN #mesNumero AS m ON m.NombreMes = LOWER(TRIM(t.MesNombre))
    INNER JOIN expensa.periodo AS p ON c.consorcio_id = p.consorcio_id 
                     AND p.anio = YEAR(GETDATE()) 
                     AND p.mes = m.NumeroMes*/

    CROSS APPLY (
        VALUES
            ('BANCARIOS', t.Bancarios),
            ('LIMPIEZA', t.Limpieza),
            ('ADMINISTRACION', t.Administracion),
            ('SEGUROS', t.Seguros),
            ('GASTOS GENERALES', t.GastosGenerales),
            ('Agua', t.Agua),
            ('Luz', t.Luz)
    ) AS g(SubTipoNombre, ImporteCrudo)

    INNER JOIN expensa.sub_tipo_gasto AS sg ON g.SubTipoNombre = sg.nombre
	INNER JOIN expensa.tipo_gasto AS tg ON tg.tipo_id = sg.tipo_id

    WHERE 
        g.ImporteCrudo IS NOT NULL AND g.ImporteCrudo != '0,00'
        AND NOT EXISTS (
            SELECT 1
            FROM expensa.gasto eg
            WHERE eg.sub_id = sg.sub_id
        );

    DROP TABLE #gastos_archivo;
    DROP TABLE #mesNumero;

END;
GO


EXEC administracion.ImportarGastos
    @RutaArchivo='D:\TP_SQL\consorcios\Servicios.Servicios.json';
GO


SELECT * FROM expensa.gasto
--DELETE FROM expensa.gasto


