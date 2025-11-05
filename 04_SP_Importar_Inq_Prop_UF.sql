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

USE Com5600G03;
GO

CREATE OR ALTER PROCEDURE unidad_funcional.ImportarUnidadesFuncionales
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    ------------------------------------------------------------
    -- Crear tabla temporal
    ------------------------------------------------------------
    IF OBJECT_ID('tempdb..#UnidadesFuncionales') IS NOT NULL
        DROP TABLE #UnidadesFuncionales;

    CREATE TABLE #UnidadesFuncionales (
        cbu_cvu VARCHAR(40),
        nombre_consorcio VARCHAR(200),
        nro_unidad VARCHAR(50),
        piso VARCHAR(20),
        departamento VARCHAR(20)
    );

    ------------------------------------------------------------
    -- Cargar CSV en tabla temporal
    ------------------------------------------------------------
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = '
        BULK INSERT #UnidadesFuncionales
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIELDTERMINATOR = ''|'',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            CODEPAGE = ''65001''
        );
    ';
    EXEC (@SQL);

    ------------------------------------------------------------
    -- Crear administración base si no existe
    ------------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM administracion.administracion WHERE nombre = 'Administración General')
    BEGIN
        INSERT INTO administracion.administracion (nombre, cuit, domicilio, email, telefono)
        VALUES ('Administración General', '30-00000000-0', 'Av. Principal 100', 'admin@email.com', '1122334455');
        PRINT 'Administración General creada.';
    END

    DECLARE @admin_id INT = (SELECT TOP 1 administracion_id FROM administracion.administracion WHERE nombre = 'Administración General');
    -- Asociar a todos los consorcios que no tengan administracion_id
	UPDATE administracion.consorcio
	SET administracion_id = @admin_id
	WHERE administracion_id IS NULL;

    ------------------------------------------------------------
    -- Insertar consorcios que aún no existan
    ------------------------------------------------------------
    INSERT INTO administracion.consorcio (administracion_id, nombre, cuit, domicilio, superficie_total_m2, fecha_alta)
    SELECT DISTINCT
        @admin_id,
        u.nombre_consorcio,
        '30-00000000-0',
        u.nombre_consorcio + ' 100',
        0,
        GETDATE()
    FROM #UnidadesFuncionales u
    WHERE NOT EXISTS (
        SELECT 1 FROM administracion.consorcio c WHERE c.nombre = u.nombre_consorcio
    );

    ------------------------------------------------------------
    -- Insertar cuentas bancarias (si no existen)
    ------------------------------------------------------------
    INSERT INTO administracion.cuenta_bancaria (banco, alias, cbu_cvu)
    SELECT 
        'Desconocido',
        NULL,
        u.cbu_cvu
    FROM #UnidadesFuncionales u
    WHERE u.cbu_cvu IS NOT NULL
      AND NOT EXISTS (
          SELECT 1 FROM administracion.cuenta_bancaria c WHERE c.cbu_cvu = u.cbu_cvu
      );

    ------------------------------------------------------------
    -- Insertar unidades funcionales
    ------------------------------------------------------------
    INSERT INTO unidad_funcional.unidad_funcional (consorcio_id, codigo, piso, depto, superficie_m2, porcentaje)
    SELECT 
        c.consorcio_id,
        u.nro_unidad,
        u.piso,
        u.departamento,
        0,      -- superficie pendiente de definir
        0       -- porcentaje pendiente de definir
    FROM #UnidadesFuncionales u
    JOIN administracion.consorcio c ON c.nombre = u.nombre_consorcio
    WHERE NOT EXISTS (
        SELECT 1 FROM unidad_funcional.unidad_funcional f
        WHERE f.codigo = u.nro_unidad AND f.consorcio_id = c.consorcio_id
    );

    ------------------------------------------------------------
    -- Vincular cada unidad con su cuenta bancaria
    ------------------------------------------------------------
    INSERT INTO unidad_funcional.uf_cuenta (uf_id, cuenta_id, fecha_desde)
    SELECT 
        uf.uf_id,
        cb.cuenta_id,
        GETDATE()
    FROM #UnidadesFuncionales u
    JOIN administracion.consorcio c ON c.nombre = u.nombre_consorcio
    JOIN unidad_funcional.unidad_funcional uf ON uf.codigo = u.nro_unidad AND uf.consorcio_id = c.consorcio_id
    JOIN administracion.cuenta_bancaria cb ON cb.cbu_cvu = u.cbu_cvu
    WHERE NOT EXISTS (
        SELECT 1 
        FROM unidad_funcional.uf_cuenta x
        WHERE x.uf_id = uf.uf_id AND x.cuenta_id = cb.cuenta_id
    );

    ------------------------------------------------------------
    -- Mostrar resumen final
    ------------------------------------------------------------
    SELECT 'Consorcios' AS entidad, COUNT(*) AS registros FROM administracion.consorcio
    UNION ALL
    SELECT 'Cuentas bancarias', COUNT(*) FROM administracion.cuenta_bancaria
    UNION ALL
    SELECT 'Unidades funcionales', COUNT(*) FROM unidad_funcional.unidad_funcional
    UNION ALL
    SELECT 'UF-Cuentas', COUNT(*) FROM unidad_funcional.uf_cuenta;
END;
GO


EXEC unidad_funcional.ImportarUnidadesFuncionales 
     @RutaArchivo='C:\Users\matia\OneDrive\Escritorio\Consorcios\Inquilino-propietarios-UF.csv';
GO

select * from unidad_funcional.unidad_funcional
