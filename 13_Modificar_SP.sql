/*
------------------------------------------------------------
Trabajo Práctico Integrador - ENTREGA 7
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

----------------------------------------------------------------
-- 1. administracion.ImportarConsorcios
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE administracion.ImportarConsorcios
    @RutaArchivo NVARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;

    CREATE TABLE #Consorcios (
        consorcioId VARCHAR(100), nombreConsorcio VARCHAR(200),
        domicilio VARCHAR(200), cantUF INT, m2total NUMERIC(12,2)
    );
    DECLARE @SQL NVARCHAR(MAX) = '
        BULK INSERT #Consorcios FROM ''' + @RutaArchivo + '''
        WITH (FIELDTERMINATOR = '';'', ROWTERMINATOR = ''\n'', CODEPAGE =''65001'', FIRSTROW = 2);
    ';
    EXEC (@SQL);
    
    -- Administración General
    IF NOT EXISTS (SELECT 1 FROM administracion.administracion WHERE nombre = 'Administración General')
    BEGIN
        INSERT INTO administracion.administracion (nombre, cuit, domicilio, email, telefono)
        VALUES (
            'Administración General',
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), '30-00000000-0'),
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), 'Av. Principal 100'),
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), 'admin@email.com'),
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), '1122334455')
        );
        PRINT 'Administracion general creada.';
    END
    DECLARE @admin_id INT = (SELECT TOP 1 administracion_id FROM administracion.administracion WHERE nombre = 'Administración General');

    -- Insertar consorcios
    DECLARE @Nuevos TABLE (consorcio_id INT PRIMARY KEY, nombre VARCHAR(200));
    INSERT INTO administracion.consorcio (administracion_id, nombre, domicilio, superficie_total_m2, fecha_alta)
    OUTPUT inserted.consorcio_id, inserted.nombre INTO @Nuevos(consorcio_id, nombre)
    SELECT
        @admin_id,
        LTRIM(RTRIM(c.nombreConsorcio)),
        CASE WHEN c.domicilio IS NOT NULL 
             THEN ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), LTRIM(RTRIM(c.domicilio)))
             ELSE NULL 
        END,
        c.m2total,
        GETDATE()
    FROM #Consorcios c
    WHERE NOT EXISTS (SELECT 1 FROM administracion.consorcio a WHERE a.nombre = c.nombreConsorcio);
    PRINT 'Consorcio insertado.';
    
    IF NOT EXISTS (SELECT 1 FROM @Nuevos)
    BEGIN
        DROP TABLE #Consorcios;
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
        RETURN;
    END;

    -- Generar CBU
    DECLARE @CBUs TABLE (consorcio_id INT PRIMARY KEY, cbu VARCHAR(22));
    INSERT INTO @CBUs (consorcio_id, cbu)
    SELECT n.consorcio_id,
            (SELECT '' + CHAR(48 + (CONVERT(INT, SUBSTRING(r.bytes, d.i, 1)) % 10))
             FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10), (11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22)) AS d(i)
             FOR XML PATH(''), TYPE).value('.', 'varchar(22)') AS cbu
    FROM @Nuevos n
    CROSS APPLY (SELECT CRYPT_GEN_RANDOM(22) AS bytes) AS r;

    -- Crear cuentas
    DECLARE @InsCtas TABLE (cuenta_id INT PRIMARY KEY, cbu VARCHAR(22));
    INSERT INTO administracion.cuenta_bancaria (banco, cbu_cvu)
    OUTPUT inserted.cuenta_id, inserted.cbu_cvu INTO @InsCtas(cuenta_id, cbu)
    SELECT 'Desconocido',
           ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), c.cbu)
    FROM @CBUs c
    WHERE NOT EXISTS (
        SELECT 1 FROM administracion.cuenta_bancaria cb 
        WHERE CONVERT(VARCHAR(40), DECRYPTBYKEY(cb.cbu_cvu)) = c.cbu
    );

    -- Vincular cuentas
    INSERT INTO administracion.consorcio_cuenta_bancaria (consorcio_id, cuenta_id, es_principal)
    SELECT cbu.consorcio_id, ins.cuenta_id, 1
    FROM @CBUs cbu
    JOIN @InsCtas ins
        ON CONVERT(VARCHAR(40), DECRYPTBYKEY(ins.cbu)) = cbu.cbu
    WHERE NOT EXISTS (
        SELECT 1 FROM administracion.consorcio_cuenta_bancaria l
        WHERE l.consorcio_id = cbu.consorcio_id AND l.es_principal = 1
    );
    PRINT 'Cuentas bancarias listas.';
    DROP TABLE #Consorcios;
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO
PRINT 'SP administracion.ImportarConsorcios modificado.';
GO

----------------------------------------------------------------
-- 2. unidad_funcional.ImportarUnidadesFuncionales
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE unidad_funcional.ImportarUnidadesFuncionales
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    BEGIN TRY
        IF OBJECT_ID('tempdb..#UnidadesFuncionales') IS NOT NULL DROP TABLE #UnidadesFuncionales;
        CREATE TABLE #UnidadesFuncionales (
            cbu_cvu VARCHAR(40), nombre_consorcio VARCHAR(200), nro_unidad VARCHAR(50),
            piso VARCHAR(20), departamento VARCHAR(20)
        );
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'BULK INSERT #UnidadesFuncionales FROM ''' + @RutaArchivo + ''' WITH (
                FIELDTERMINATOR = ''|'', ROWTERMINATOR = ''\n'', FIRSTROW = 2, CODEPAGE = ''65001'');';
        EXEC (@SQL);

        IF NOT EXISTS (SELECT 1 FROM administracion.administracion WHERE nombre = 'Administración General')
        BEGIN
            INSERT INTO administracion.administracion (nombre, cuit, domicilio, email, telefono)
            VALUES (
                'Administración General',
                ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), '30-00000000-0'),
                ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), 'Av. Principal 100'),
                ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), 'admin@email.com'),
                ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), '1122334455')
            );
        END
        DECLARE @admin_id INT = (SELECT TOP 1 administracion_id FROM administracion.administracion WHERE nombre = 'Administración General');

        -- Insertar consorcios
        INSERT INTO administracion.consorcio (administracion_id, nombre, cuit, domicilio, superficie_total_m2, fecha_alta)
        SELECT DISTINCT
            @admin_id, u.nombre_consorcio,
            ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), '30-00000000-0'),
            CASE WHEN u.nombre_consorcio IS NOT NULL 
                 THEN ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), u.nombre_consorcio + ' 100')
                 ELSE NULL
            END,
            0, GETDATE()
        FROM #UnidadesFuncionales u
        WHERE NOT EXISTS (SELECT 1 FROM administracion.consorcio c WHERE c.nombre = u.nombre_consorcio);

        -- Insertar cuentas bancarias
        INSERT INTO administracion.cuenta_bancaria (banco, alias, cbu_cvu)
        SELECT 'Desconocido',
            NULL AS alias, 
            CASE WHEN u.cbu_cvu IS NOT NULL 
                 THEN ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), u.cbu_cvu)
                 ELSE NULL
            END AS cbu_cvu
        FROM #UnidadesFuncionales u
        WHERE u.cbu_cvu IS NOT NULL
          AND LEN(LTRIM(RTRIM(u.cbu_cvu))) > 0
          AND NOT EXISTS (
              SELECT 1 FROM administracion.cuenta_bancaria c 
              WHERE CONVERT(VARCHAR(40), DECRYPTBYKEY(c.cbu_cvu)) = u.cbu_cvu
          );

        -- Insertar UF
        INSERT INTO unidad_funcional.unidad_funcional (consorcio_id, codigo, piso, depto, superficie_m2, porcentaje)
        SELECT c.consorcio_id, u.nro_unidad, u.piso, u.departamento, 0, 0
        FROM #UnidadesFuncionales u
        INNER JOIN administracion.consorcio c ON c.nombre = u.nombre_consorcio
        WHERE NOT EXISTS (
            SELECT 1 FROM unidad_funcional.unidad_funcional f
            WHERE f.codigo = u.nro_unidad AND f.consorcio_id = c.consorcio_id
        );

        -- Vincular UF con cuentas
        INSERT INTO unidad_funcional.uf_cuenta (uf_id, cuenta_id, fecha_desde)
        SELECT uf.uf_id, cb.cuenta_id, GETDATE()
        FROM #UnidadesFuncionales u
        INNER JOIN administracion.consorcio c ON c.nombre = u.nombre_consorcio
        INNER JOIN unidad_funcional.unidad_funcional uf ON uf.codigo = u.nro_unidad AND uf.consorcio_id = c.consorcio_id
        INNER JOIN administracion.cuenta_bancaria cb ON CONVERT(VARCHAR(40), DECRYPTBYKEY(cb.cbu_cvu)) = u.cbu_cvu
        WHERE NOT EXISTS (
            SELECT 1 FROM unidad_funcional.uf_cuenta x
            WHERE x.uf_id = uf.uf_id AND x.cuenta_id = cb.cuenta_id AND x.fecha_hasta IS NULL
        );

        PRINT 'Unidades funcionales importadas correctamente';
        DROP TABLE #UnidadesFuncionales;
    END TRY
    BEGIN CATCH
        PRINT 'Error al importar UF: ' + ERROR_MESSAGE();
        IF OBJECT_ID('tempdb..#UnidadesFuncionales') IS NOT NULL DROP TABLE #UnidadesFuncionales;
        IF (EXISTS (SELECT * FROM sys.open_keys WHERE key_name = 'SK_DatosSensibles'))
            CLOSE SYMMETRIC KEY SK_DatosSensibles;
        THROW;
    END CATCH
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO
PRINT 'SP unidad_funcional.ImportarUnidadesFuncionales modificado.';
GO

----------------------------------------------------------------
-- 3. persona.ImportarInquilinosPropietarios
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE persona.ImportarInquilinosPropietarios
    @RutaArchivo NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    BEGIN TRY
        IF OBJECT_ID('tempdb..#InquilinosPropietarios') IS NOT NULL DROP TABLE #InquilinosPropietarios;
        CREATE TABLE #InquilinosPropietarios (
            nombre VARCHAR(100), apellido VARCHAR(100), dni VARCHAR(20),
            email_personal VARCHAR(150), telefono_contacto VARCHAR(50),
            cbu_cvu VARCHAR(40), inquilino BIT
        );
        DECLARE @SQL NVARCHAR(MAX);
        SET @SQL = 'BULK INSERT #InquilinosPropietarios FROM ''' + @RutaArchivo + ''' WITH (
                FIELDTERMINATOR = '';'', ROWTERMINATOR = ''\n'', FIRSTROW = 2, CODEPAGE = ''65001'');';
        EXEC (@SQL);

        -- Insertar personas
        INSERT INTO persona.persona (nombre_completo, tipo_doc, nro_doc)
        SELECT
            CASE WHEN MAX(TRIM(ISNULL(nombre, '') + ' ' + ISNULL(apellido, ''))) IS NOT NULL 
                 THEN ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), MAX(TRIM(ISNULL(nombre, '') + ' ' + ISNULL(apellido, ''))))
                 ELSE NULL
            END,
            'DNI',
            CASE WHEN dni IS NOT NULL 
                 THEN ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), dni)
                 ELSE NULL
            END
        FROM #InquilinosPropietarios i
        WHERE 
            NOT EXISTS (
                SELECT 1 FROM persona.persona p 
                WHERE CONVERT(VARCHAR(40), DECRYPTBYKEY(p.nro_doc)) = i.dni
            )
            AND i.dni IS NOT NULL AND LTRIM(RTRIM(i.dni)) <> '' 
        GROUP BY dni;

        -- Insertar contactos
        INSERT INTO persona.persona_contacto (persona_id, tipo, valor, es_preferido)
        SELECT 
            p.persona_id, 'email',
            CASE WHEN i.email_personal IS NOT NULL 
                 THEN ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), i.email_personal)
                 ELSE NULL
            END,
            1
        FROM #InquilinosPropietarios i
        JOIN persona.persona p ON CONVERT(VARCHAR(40), DECRYPTBYKEY(p.nro_doc)) = i.dni
        WHERE i.email_personal IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM persona.persona_contacto c 
            WHERE c.persona_id = p.persona_id 
              AND CONVERT(VARCHAR(200), DECRYPTBYKEY(c.valor)) = i.email_personal
        );

        INSERT INTO persona.persona_contacto (persona_id, tipo, valor, es_preferido)
        SELECT 
            p.persona_id, 'telefono',
            CASE WHEN i.telefono_contacto IS NOT NULL
                 THEN ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), i.telefono_contacto)
                 ELSE NULL
            END,
            0
        FROM #InquilinosPropietarios i
        JOIN persona.persona p ON CONVERT(VARCHAR(40), DECRYPTBYKEY(p.nro_doc)) = i.dni
        WHERE i.telefono_contacto IS NOT NULL AND NOT EXISTS (
            SELECT 1 FROM persona.persona_contacto c 
            WHERE c.persona_id = p.persona_id 
              AND CONVERT(VARCHAR(200), DECRYPTBYKEY(c.valor)) = i.telefono_contacto
        );
        
        -- Insertar cuentas bancarias
        INSERT INTO administracion.cuenta_bancaria (banco, alias, cbu_cvu)
        SELECT 'Desconocido',
            NULL AS alias,
            CASE WHEN i.cbu_cvu IS NOT NULL
                 THEN ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), i.cbu_cvu)
                 ELSE NULL
            END
        FROM #InquilinosPropietarios i
        WHERE i.cbu_cvu IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM administracion.cuenta_bancaria c 
            WHERE CONVERT(VARCHAR(40), DECRYPTBYKEY(c.cbu_cvu)) = i.cbu_cvu
        );

        -- Insertar vinculos
        INSERT INTO unidad_funcional.uf_persona_vinculo (uf_id, persona_id, rol, fecha_desde)
        SELECT
            ufc.uf_id, p.persona_id,
            CASE WHEN i.inquilino = 1 THEN 'Inquilino' ELSE 'Propietario' END,
            GETDATE()
        FROM #InquilinosPropietarios i
        JOIN persona.persona p ON CONVERT(VARCHAR(40), DECRYPTBYKEY(p.nro_doc)) = i.dni
        JOIN administracion.cuenta_bancaria cb ON CONVERT(VARCHAR(40), DECRYPTBYKEY(cb.cbu_cvu)) = i.cbu_cvu
        JOIN unidad_funcional.uf_cuenta ufc ON cb.cuenta_id = ufc.cuenta_id
        WHERE 
            i.cbu_cvu IS NOT NULL AND ufc.uf_id IS NOT NULL 
            AND NOT EXISTS ( 
                SELECT 1 FROM unidad_funcional.uf_persona_vinculo v 
                WHERE v.persona_id = p.persona_id AND v.uf_id = ufc.uf_id
                  AND v.rol = CASE WHEN i.inquilino = 1 THEN 'Inquilino' ELSE 'Propietario' END
            );
    END TRY
    BEGIN CATCH
        PRINT 'Error al importar Inquilinos/Propietarios: ' + ERROR_MESSAGE();
        IF OBJECT_ID('tempdb..#InquilinosPropietarios') IS NOT NULL DROP TABLE #InquilinosPropietarios;
        IF (EXISTS (SELECT * FROM sys.open_keys WHERE key_name = 'SK_DatosSensibles'))
            CLOSE SYMMETRIC KEY SK_DatosSensibles;
        THROW;
    END CATCH
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO
PRINT 'SP persona.ImportarInquilinosPropietarios modificado.';
GO

----------------------------------------------------------------
-- 4. banco.ImportarYConciliarPagos
----------------------------------------------------------------
CREATE OR ALTER PROCEDURE banco.ImportarYConciliarPagos
    @RutaArchivo NVARCHAR(500),
    @IdCuentaDestino INT
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    DECLARE @consorcio_id INT;
    SELECT @consorcio_id = consorcio_id FROM administracion.consorcio_cuenta_bancaria 
    WHERE cuenta_id = @IdCuentaDestino;
    IF @consorcio_id IS NULL
    BEGIN
        PRINT 'Error: El ID de cuenta destino no se encontró.';
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
        RETURN -1;
    END;

    IF OBJECT_ID('tempdb..#PagosCSV') IS NOT NULL DROP TABLE #PagosCSV;
    CREATE TABLE #PagosCSV (
        id_pago_externo VARCHAR(50), fecha_texto VARCHAR(20),
        cbu_origen VARCHAR(40), valor_texto VARCHAR(50)
    );
    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = 'BULK INSERT #PagosCSV FROM ''' + @RutaArchivo + ''' WITH (
            FIELDTERMINATOR = '','', ROWTERMINATOR = ''\n'', FIRSTROW = 2, CODEPAGE = ''65001'');';
    BEGIN TRY
        EXEC (@SQL);
    END TRY
    BEGIN CATCH
        PRINT 'Error al cargar el CSV: ' + ERROR_MESSAGE();
        DROP TABLE #PagosCSV;
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
        RETURN -1;
    END CATCH;

    IF OBJECT_ID('tempdb..#PagosProcesados') IS NOT NULL DROP TABLE #PagosProcesados;
    SELECT
        ufc.uf_id, LTRIM(RTRIM(csv.cbu_origen)) AS cbu_origen,
        CONVERT(DATE, LTRIM(RTRIM(csv.fecha_texto)), 103) AS fecha_pago,
        TRY_CAST(REPLACE(REPLACE(LTRIM(RTRIM(csv.valor_texto)), '$', ''), '.', '') AS NUMERIC(14, 2)) AS importe_pago,
        csv.id_pago_externo,
        CASE WHEN ufc.uf_id IS NULL THEN 'CBU de origen no vinculado a una UF' ELSE NULL END AS motivo_no_vinculado
    INTO #PagosProcesados
    FROM #PagosCSV csv
    LEFT JOIN administracion.cuenta_bancaria cb ON CONVERT(VARCHAR(40), DECRYPTBYKEY(cb.cbu_cvu)) = csv.cbu_origen
    LEFT JOIN unidad_funcional.uf_cuenta ufc ON cb.cuenta_id = ufc.cuenta_id AND ufc.fecha_hasta IS NULL; 
        
    DECLARE @MovimientosInsertados TABLE (
        movimiento_id INT, cbu_origen VARBINARY(128), fecha DATE, importe NUMERIC(14,2)
    );

    INSERT INTO banco.banco_movimiento (
        consorcio_id, cuenta_id, cbu_origen, fecha, importe, estado_conciliacion
    )
    OUTPUT inserted.movimiento_id, inserted.cbu_origen, inserted.fecha, inserted.importe
    INTO @MovimientosInsertados
    SELECT
        @consorcio_id, @IdCuentaDestino,
        CASE WHEN p.cbu_origen IS NOT NULL 
             THEN ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), p.cbu_origen)
             ELSE NULL
        END,
        p.fecha_pago, p.importe_pago,
        CASE WHEN p.uf_id IS NOT NULL THEN 'ASOCIADO' ELSE 'PENDIENTE' END
    FROM #PagosProcesados p
    WHERE p.importe_pago IS NOT NULL
      AND NOT EXISTS (
            SELECT 1 FROM banco.banco_movimiento bm
            WHERE bm.cuenta_id = @IdCuentaDestino
              AND CONVERT(VARCHAR(40), DECRYPTBYKEY(bm.cbu_origen)) = p.cbu_origen
              AND bm.fecha = p.fecha_pago
              AND bm.importe = p.importe_pago
      );
        
    INSERT INTO banco.pago (
        uf_id, fecha, importe, tipo,
        movimiento_id, motivo_no_asociado, created_by
    )
    SELECT
        p.uf_id, p.fecha_pago, p.importe_pago, 'ORDINARIO',
        mi.movimiento_id, p.motivo_no_vinculado, 'SP_Importar'
    FROM #PagosProcesados p
    JOIN @MovimientosInsertados mi
        ON CONVERT(VARCHAR(40), DECRYPTBYKEY(mi.cbu_origen)) = p.cbu_origen
       AND p.fecha_pago = mi.fecha
       AND p.importe_pago = mi.importe
    WHERE NOT EXISTS (SELECT 1 FROM banco.pago fp WHERE fp.movimiento_id = mi.movimiento_id);
        
    DROP TABLE #PagosCSV;
    DROP TABLE #PagosProcesados;
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO
PRINT 'SP banco.ImportarYConciliarPagos modificado.';
GO

PRINT '--- MODIFICACION FINALIZADA ---';
GO