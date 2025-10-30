﻿/*
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

CREATE OR ALTER PROCEDURE administracion.ImportarUF
  @RutaArchivo NVARCHAR(400)
AS
BEGIN
  SET NOCOUNT ON;

  -- 1) Cargar archivo 
  IF OBJECT_ID('tempdb..#uf_archivo') IS NOT NULL DROP TABLE #uf_archivo;
  CREATE TABLE #uf_archivo (
    NombreConsorcio NVARCHAR(200),
    NroUF           NVARCHAR(20),
    Piso            NVARCHAR(20),
    Depto           NVARCHAR(20),
    Coeficiente     NVARCHAR(50),
    M2UF            NVARCHAR(50),
    Bauleras        NVARCHAR(10),
    Cochera         NVARCHAR(10),
    M2Baulera       NVARCHAR(50),
    M2Cochera       NVARCHAR(50)
  );

  DECLARE @sql_bulk NVARCHAR(MAX) = N'
    BULK INSERT #uf_archivo
    FROM N''' + REPLACE(@RutaArchivo,'''','''''') + N'''
    WITH (
      FIELDTERMINATOR = ''\t'',
      ROWTERMINATOR   = ''0x0a'',
      CODEPAGE        = ''65001'',
      FIRSTROW        = 2,
      TABLOCK
    );';
  EXEC(@sql_bulk);

  -- 2) Normalizar + buscar consorcio_id + armar código → #uf_limpio
  IF OBJECT_ID('tempdb..#uf_limpio') IS NOT NULL DROP TABLE #uf_limpio;
  ;WITH datos_limpios AS (
    SELECT
      LTRIM(RTRIM(NombreConsorcio)) AS consorcio_nombre,
      LTRIM(RTRIM(NroUF))           AS nro_uf,
      LTRIM(RTRIM(Piso))            AS piso,
      LTRIM(RTRIM(Depto))           AS depto,
      TRY_CONVERT(NUMERIC(12,2), REPLACE(REPLACE(M2UF,     '.', ''), ',', '.')) AS m2_uf,
      TRY_CONVERT(NUMERIC(7,4),  REPLACE(REPLACE(Coeficiente,'.',''), ',', '.')) AS coef_uf
    FROM #uf_archivo
  )
  SELECT 
    c.consorcio_id,
    d.consorcio_nombre,
    d.nro_uf,
    d.piso,
    d.depto,
    d.m2_uf,
    d.coef_uf,
    codigo_uf = CONCAT('UF', d.nro_uf)
  INTO #uf_limpio
  FROM datos_limpios d
  JOIN administracion.consorcio c
    ON c.nombre = d.consorcio_nombre;

  -- 3) Insertar UF (evita duplicados por consorcio+piso+depto)
  INSERT INTO unidad_funcional.unidad_funcional
    (consorcio_id, codigo, piso, depto, superficie_m2, porcentaje)
  SELECT
    x.consorcio_id,
    x.codigo_uf,
    x.piso,
    x.depto,
    ISNULL(x.m2_uf, 0),
    ISNULL(x.coef_uf, 0)
  FROM #uf_limpio x
  WHERE NOT EXISTS (
    SELECT 1
    FROM unidad_funcional.unidad_funcional u
    WHERE u.consorcio_id = x.consorcio_id
      AND u.piso  = x.piso
      AND u.depto = x.depto
  );

  DROP TABLE IF EXISTS #uf_limpio;
  DROP TABLE IF EXISTS #uf_archivo;

  PRINT 'UF importadas OK';
END;
GO


EXEC administracion.ImportarUF
@RutaArchivo='C:\Users\lauti\OneDrive\Desktop\Altos de SaintJust\UF por consorcio.txt';
go

-----------------------------------------------------------------------------------------------
-------------------IMPORTAR BAULERAS DESDE MISMO CSV--------------------------------------

CREATE OR ALTER PROCEDURE administracion.ImportarBauleras
  @RutaArchivo NVARCHAR(400)
AS
BEGIN
  SET NOCOUNT ON;

  -- 1) Cargar archivo (TAB, UTF-8, con encabezados)
  IF OBJECT_ID('tempdb..#ba_archivo') IS NOT NULL DROP TABLE #ba_archivo;
  CREATE TABLE #ba_archivo (
    NombreConsorcio NVARCHAR(200),
    NroUF           NVARCHAR(20),
    Piso            NVARCHAR(20),
    Depto           NVARCHAR(20),
    Coeficiente     NVARCHAR(50),
    M2UF            NVARCHAR(50),
    Bauleras        NVARCHAR(10),
    Cochera         NVARCHAR(10),
    M2Baulera       NVARCHAR(50),
    M2Cochera       NVARCHAR(50)
  );

  DECLARE @sql_bulk NVARCHAR(MAX) = N'
    BULK INSERT #ba_archivo
    FROM N''' + REPLACE(@RutaArchivo,'''','''''') + N'''
    WITH (
      FIELDTERMINATOR = ''\t'',
      ROWTERMINATOR   = ''0x0a'',
      CODEPAGE        = ''65001'',
      FIRSTROW        = 2,
      TABLOCK
    );';
  EXEC(@sql_bulk);

  -- 2) Normalizar + consorcio_id (sin generar código aquí)
  IF OBJECT_ID('tempdb..#ba_limpio') IS NOT NULL DROP TABLE #ba_limpio;
  ;WITH datos_limpios AS (
    SELECT
      LTRIM(RTRIM(NombreConsorcio)) AS consorcio_nombre,
      LTRIM(RTRIM(NroUF))           AS nro_uf,
      LTRIM(RTRIM(Piso))            AS piso,
      LTRIM(RTRIM(Depto))           AS depto,
      UPPER(LTRIM(RTRIM(Bauleras))) AS flag_baulera,
      TRY_CONVERT(NUMERIC(12,2), REPLACE(REPLACE(M2UF,      '.', ''), ',', '.')) AS m2_uf,
      TRY_CONVERT(NUMERIC(12,2), REPLACE(REPLACE(M2Baulera, '.', ''), ',', '.')) AS m2_baulera
    FROM #ba_archivo
  )
  SELECT 
    c.consorcio_id,
    d.nro_uf,
    d.piso,
    d.depto,
    d.flag_baulera,
    d.m2_uf,
    d.m2_baulera
  INTO #ba_limpio
  FROM datos_limpios d
  JOIN administracion.consorcio c
    ON c.nombre = d.consorcio_nombre;

  -- 3) Insertar Bauleras (código simple B-<uf_id>)
  INSERT INTO unidad_funcional.baulera
    (consorcio_id, uf_id, codigo, superficie_m2, porcentaje)
  SELECT
    x.consorcio_id,
    u.uf_id,
    CONCAT('B-', u.uf_id) AS codigo,
    ISNULL(x.m2_baulera, 0),
    CASE WHEN x.m2_baulera IS NOT NULL AND x.m2_uf IS NOT NULL AND x.m2_uf > 0
         THEN (x.m2_baulera / x.m2_uf) * u.porcentaje ELSE 0 END
  FROM #ba_limpio x
  JOIN unidad_funcional.unidad_funcional u
    ON u.consorcio_id = x.consorcio_id
   AND u.piso  = x.piso
   AND u.depto = x.depto
  WHERE x.flag_baulera = 'SI'
    AND NOT EXISTS (
      SELECT 1 FROM unidad_funcional.baulera b
      WHERE b.uf_id = u.uf_id AND b.codigo = CONCAT('B-', u.uf_id)
    );

  DROP TABLE IF EXISTS #ba_limpio;
  DROP TABLE IF EXISTS #ba_archivo;

  PRINT 'Bauleras importadas OK';
END;
GO



EXEC administracion.ImportarBauleras
@RutaArchivo='C:\Users\lauti\OneDrive\Desktop\Altos de SaintJust\UF por consorcio.txt';
go


-----------------------------------------------------------------------------------------------
-------------------IMPORTAR COCHERAS DESDE MISMO CSV--------------------------------------

CREATE OR ALTER PROCEDURE administracion.ImportarCocheras
  @RutaArchivo NVARCHAR(400)
AS
BEGIN
  SET NOCOUNT ON;

  -- 1) Cargar archivo 
  IF OBJECT_ID('tempdb..#co_archivo') IS NOT NULL DROP TABLE #co_archivo;
  CREATE TABLE #co_archivo (
    NombreConsorcio NVARCHAR(200),
    NroUF           NVARCHAR(20),
    Piso            NVARCHAR(20),
    Depto           NVARCHAR(20),
    Coeficiente     NVARCHAR(50),
    M2UF            NVARCHAR(50),
    Bauleras        NVARCHAR(10),
    Cochera         NVARCHAR(10),
    M2Baulera       NVARCHAR(50),
    M2Cochera       NVARCHAR(50)
  );

  DECLARE @sql_bulk NVARCHAR(MAX) = N'
    BULK INSERT #co_archivo
    FROM N''' + REPLACE(@RutaArchivo,'''','''''') + N'''
    WITH (
      FIELDTERMINATOR = ''\t'',
      ROWTERMINATOR   = ''0x0a'',
      CODEPAGE        = ''65001'',
      FIRSTROW        = 2,
      TABLOCK
    );';
  EXEC(@sql_bulk);

  -- 2) Normalizar + consorcio_id (sin generar código aquí)
  IF OBJECT_ID('tempdb..#co_limpio') IS NOT NULL DROP TABLE #co_limpio;
  ;WITH datos_limpios AS (
    SELECT
      LTRIM(RTRIM(NombreConsorcio)) AS consorcio_nombre,
      LTRIM(RTRIM(NroUF))           AS nro_uf,
      LTRIM(RTRIM(Piso))            AS piso,
      LTRIM(RTRIM(Depto))           AS depto,
      UPPER(LTRIM(RTRIM(Cochera)))  AS flag_cochera,
      TRY_CONVERT(NUMERIC(12,2), REPLACE(REPLACE(M2UF,      '.', ''), ',', '.')) AS m2_uf,
      TRY_CONVERT(NUMERIC(12,2), REPLACE(REPLACE(M2Cochera, '.', ''), ',', '.')) AS m2_cochera
    FROM #co_archivo
  )
  SELECT 
    c.consorcio_id,
    d.nro_uf,
    d.piso,
    d.depto,
    d.flag_cochera,
    d.m2_uf,
    d.m2_cochera
  INTO #co_limpio
  FROM datos_limpios d
  JOIN administracion.consorcio c
    ON c.nombre = d.consorcio_nombre;

  -- 3) Insertar Cocheras (código simple C-<uf_id>)
  INSERT INTO unidad_funcional.cochera
    (consorcio_id, uf_id, codigo, superficie_m2, porcentaje)
  SELECT
    x.consorcio_id,
    u.uf_id,
    CONCAT('C-', u.uf_id) AS codigo,
    ISNULL(x.m2_cochera, 0),
    CASE WHEN x.m2_cochera IS NOT NULL AND x.m2_uf IS NOT NULL AND x.m2_uf > 0
         THEN (x.m2_cochera / x.m2_uf) * u.porcentaje ELSE 0 END
  FROM #co_limpio x
  JOIN unidad_funcional.unidad_funcional u
    ON u.consorcio_id = x.consorcio_id
   AND u.piso  = x.piso
   AND u.depto = x.depto
  WHERE x.flag_cochera = 'SI'
    AND NOT EXISTS (
      SELECT 1 FROM unidad_funcional.cochera c
      WHERE c.uf_id = u.uf_id AND c.codigo = CONCAT('C-', u.uf_id)
    );

  DROP TABLE IF EXISTS #co_limpio;
  DROP TABLE IF EXISTS #co_archivo;

  PRINT 'Cocheras importadas OK';
END;
GO


EXEC administracion.ImportarCocheras
@RutaArchivo='C:\Users\lauti\OneDrive\Desktop\Altos de SaintJust\UF por consorcio.txt';
go


delete from unidad_funcional.baulera
delete from unidad_funcional.cochera
delete from unidad_funcional.unidad_funcional