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

-- IMPORTAR TABLA DE UNIDAD FUNCIONAL DESDE TXT.

USE Com5600G03;
GO

CREATE OR ALTER PROCEDURE administracion.ImportarUF
  @RutaArchivo NVARCHAR(400)
AS
BEGIN
  SET NOCOUNT ON;
  --------------------------creo tabla temporal
  CREATE TABLE #uf_archivo (
    NombreConsorcio VARCHAR(200),
    NroUF           VARCHAR(20),
    Piso            VARCHAR(20),
    Depto			VARCHAR(20),
    Coeficiente     VARCHAR(50),
    M2UF            VARCHAR(50),
    Bauleras        VARCHAR(10),
    Cochera         VARCHAR(10),
    M2Baulera       VARCHAR(50),
    M2Cochera       VARCHAR(50)
  );
  --------------------bulk insert en la tabla temporal
  DECLARE @sql_bulk NVARCHAR(MAX) =
    N'BULK INSERT #uf_archivo
      FROM N''' + @RutaArchivo + N'''
      WITH (
        FIELDTERMINATOR = ''\t'',
        ROWTERMINATOR   = ''\n'',
        CODEPAGE        = ''65001'',
        FIRSTROW        = 2
      );';
  EXEC (@sql_bulk);

  --- INSERTO EN LA TABLA


  INSERT INTO unidad_funcional.unidad_funcional
    (consorcio_id, codigo, piso, depto, superficie_m2, porcentaje)
  SELECT
    c.consorcio_id,
    u.NroUF                               AS codigo,
    u.Piso,
    u.Depto,
    TRY_CONVERT(NUMERIC(12,2), u.M2UF)    AS superficie_m2,
	-----calculo el porcentaje--------
	CAST(
		  CASE
			WHEN SUM(TRY_CONVERT(NUMERIC(18,6), u.M2UF))
				 OVER (PARTITION BY c.consorcio_id) > 0
			THEN 100.0 * TRY_CONVERT(NUMERIC(18,6), u.M2UF)
				 /  SUM(TRY_CONVERT(NUMERIC(18,6), u.M2UF))
					OVER (PARTITION BY c.consorcio_id)
			ELSE 0
		  END
		  AS NUMERIC(7,4)
		) AS porcentaje 
	----------------------
  FROM #uf_archivo u
  JOIN administracion.consorcio c
    ON c.nombre = u.NombreConsorcio
  WHERE NOT EXISTS (
    SELECT 1
    FROM unidad_funcional.unidad_funcional t
    WHERE t.consorcio_id = c.consorcio_id
      AND t.piso         = u.Piso
      AND t.depto        = u.Depto
  );

  DROP TABLE IF EXISTS #uf_archivo;

  PRINT 'UF importadas (solo nuevas) OK';
END;
GO

EXEC administracion.ImportarUF
  @RutaArchivo = 'C:\Users\lauti\OneDrive\Desktop\Altos de SaintJust\UF por consorcio.txt';
GO


select c.uf_id,a.nombre,c.codigo,c.piso,c.depto,c.superficie_m2,c.porcentaje from unidad_funcional.unidad_funcional c join administracion.consorcio a on a.consorcio_id=c.consorcio_id

--delete from unidad_funcional.unidad_funcional


-----------------------------------------------------------------------------------------------
-------------------IMPORTAR BAULERAS DESDE TXT--------------------------------------

CREATE OR ALTER PROCEDURE administracion.ImportarBauleras
  @RutaArchivo NVARCHAR(400)
AS
BEGIN
  SET NOCOUNT ON;


  --------------------------creo tabla temporal
  CREATE TABLE #uf_archivo (
    NombreConsorcio VARCHAR(200),
    NroUF           VARCHAR(20),
    Piso            VARCHAR(20),
    Depto           VARCHAR(20),
    Coeficiente     VARCHAR(50),
    M2UF            VARCHAR(50),
    Bauleras        VARCHAR(10),
    Cochera         VARCHAR(10),
    M2Baulera       VARCHAR(50),
    M2Cochera       VARCHAR(50)
  );
  --------------------bulk insert en la tabla temporal
  DECLARE @sql_bulk NVARCHAR(MAX) =
    N'BULK INSERT #uf_archivo
      FROM N''' + @RutaArchivo + N'''
      WITH (
        FIELDTERMINATOR = ''\t'',
        ROWTERMINATOR   = ''\n'',
        CODEPAGE        = ''65001'',
        FIRSTROW        = 2
      );';
  EXEC (@sql_bulk);

  -------- insertar tabla
  INSERT INTO unidad_funcional.baulera 
  (consorcio_id,uf_id,codigo,superficie_m2,porcentaje)
  select
		c.consorcio_id,
		uf.uf_id,
		---genero un codigo para la baulera---
		CONCAT('B-', LTRIM(RTRIM(u.NroUF))) AS codigo,
		--------------------------------------
		TRY_CONVERT(NUMERIC(12,2), u.M2Baulera) AS superficie_m2,
		-----calculo el porcentaje--------
		CAST(
			  CASE
				WHEN SUM(TRY_CONVERT(NUMERIC(18,6), u.M2Baulera))
					 OVER (PARTITION BY c.consorcio_id) > 0
				THEN 100.0 * TRY_CONVERT(NUMERIC(18,6), u.M2Baulera)
					 /  SUM(TRY_CONVERT(NUMERIC(18,6), u.M2Baulera))
						OVER (PARTITION BY c.consorcio_id)
				ELSE 0
			  END
			  AS NUMERIC(7,4)
			) AS porcentaje 
		------------------------------------
   FROM #uf_archivo u
  JOIN administracion.consorcio c
    ON c.nombre = u.NombreConsorcio
  JOIN unidad_funcional.unidad_funcional uf          
    ON uf.consorcio_id = c.consorcio_id
   AND uf.codigo       =u.NroUF
  WHERE u.Bauleras = 'SI'
    AND NOT EXISTS (
      SELECT 1
      FROM unidad_funcional.baulera b
      WHERE b.codigo = CONCAT('B-', u.NroUF)
   )
	
  DROP TABLE IF EXISTS #uf_archivo;

  PRINT 'Bauleras importadas OK';
END;
GO

-----------------------------EJECUTAR----------------------------------------------------------

EXEC administracion.ImportarBauleras
@RutaArchivo='C:\Users\lauti\OneDrive\Desktop\Altos de SaintJust\UF por consorcio.txt';
GO

select * from unidad_funcional.baulera
--delete from unidad_funcional.baulera
-----------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------
-------------------IMPORTAR COCHERAS DESDE MISMO CSV--------------------------------------

CREATE OR ALTER PROCEDURE administracion.ImportarCocheras
  @RutaArchivo NVARCHAR(400)
AS
BEGIN
  SET NOCOUNT ON;

  --------------------------creo tabla temporal
  CREATE TABLE #uf_archivo (
    NombreConsorcio VARCHAR(200),
    NroUF           VARCHAR(20),
    Piso            VARCHAR(20),
    Depto           VARCHAR(20),
    Coeficiente     VARCHAR(50),
    M2UF            VARCHAR(50),
    Bauleras        VARCHAR(10),
    Cochera         VARCHAR(10),
    M2Baulera       VARCHAR(50),
    M2Cochera       VARCHAR(50)
  );
  --------------------bulk insert en la tabla temporal
  DECLARE @sql_bulk NVARCHAR(MAX) =
    N'BULK INSERT #uf_archivo
      FROM N''' + @RutaArchivo + N'''
      WITH (
        FIELDTERMINATOR = ''\t'',
        ROWTERMINATOR   = ''\n'',
        CODEPAGE        = ''65001'',
        FIRSTROW        = 2
      );';
  EXEC (@sql_bulk);
----------inserto tabla


  INSERT INTO unidad_funcional.cochera
    (consorcio_id, uf_id, codigo, superficie_m2, porcentaje)
   select
		c.consorcio_id,
		uf.uf_id,
		---genero un codigo para la baulera---
		CONCAT('C-', LTRIM(RTRIM(u.NroUF))) AS codigo,
		--------------------------------------
		TRY_CONVERT(NUMERIC(12,2), u.M2Cochera) AS superficie_m2,
		-----calculo el porcentaje--------
		CAST(
			  CASE
				WHEN SUM(TRY_CONVERT(NUMERIC(18,6), u.M2Cochera))
					 OVER (PARTITION BY c.consorcio_id) > 0
				THEN 100.0 * TRY_CONVERT(NUMERIC(18,6), u.M2Cochera)
					 /  SUM(TRY_CONVERT(NUMERIC(18,6), u.M2Cochera))
						OVER (PARTITION BY c.consorcio_id)
				ELSE 0
			  END
			  AS NUMERIC(7,4)
			) AS porcentaje 
		------------------------------------
   FROM #uf_archivo u
  JOIN administracion.consorcio c
    ON c.nombre = u.NombreConsorcio
  JOIN unidad_funcional.unidad_funcional uf          
    ON uf.consorcio_id = c.consorcio_id
   AND uf.codigo       =u.NroUF
  WHERE u.Cochera = 'SI'
    AND NOT EXISTS (
      SELECT 1
      FROM unidad_funcional.cochera co
      WHERE co.codigo = CONCAT('C-', u.NroUF)
   )
	
  DROP TABLE IF EXISTS #uf_archivo;



  PRINT 'Cocheras importadas OK';
END;
GO

-----------------------EJECUTAR-----------------------
EXEC administracion.ImportarCocheras
@RutaArchivo='C:\Users\lauti\OneDrive\Desktop\Altos de SaintJust\UF por consorcio.txt';
GO
---------------------------------------------------------
select * from unidad_funcional.cochera
-- delete from unidad_funcional.cochera
