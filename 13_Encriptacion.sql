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
-- 1. CREAR JERARQUÍA DE ENCRIPTACIÓN
----------------------------------------------------------------
PRINT '1. Verificando Jerarquía de Encriptación';

-- 1.1. Crear Master Key (si no existe)
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'DatabaseMasterKey')
BEGIN
    PRINT '- Creando Database Master Key...';
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Pa$$w0rdComplej@ParaLaEntrega7!';
    PRINT '- Database Master Key creada.';
END
ELSE
    PRINT '- Database Master Key ya existe.';
GO

-- 1.2. Crear Certificado (si no existe)
IF NOT EXISTS (SELECT * FROM sys.certificates WHERE name = 'CertParaDatosSensibles')
BEGIN
    PRINT '- Creando Certificado "CertParaDatosSensibles"...';
    CREATE CERTIFICATE CertParaDatosSensibles
    WITH SUBJECT = 'Certificado para encriptación de datos PII';
    PRINT '- Certificado "CertParaDatosSensibles" creado.';
END
ELSE
    PRINT '- Certificado "CertParaDatosSensibles" ya existe.';
GO

-- 1.3. Crear Llave Simétrica (si no existe)
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = 'SK_DatosSensibles')
BEGIN
    PRINT '- Creando Llave Simétrica "SK_DatosSensibles"...';
    CREATE SYMMETRIC KEY SK_DatosSensibles
    WITH ALGORITHM = AES_256
    ENCRYPTION BY CERTIFICATE CertParaDatosSensibles;
    PRINT '- Llave Simétrica "SK_DatosSensibles" (AES_256) creada.';
END
ELSE
    PRINT '- Llave Simétrica "SK_DatosSensibles" ya existe.';
GO

----------------------------------------------------------------
-- 2. MIGRACIÓN DE DATOS: persona.persona
----------------------------------------------------------------
PRINT '2. Encriptando tabla persona.persona (nombre_completo, nro_doc, direccion)';

-- 2.1. Dropear constraint UQ
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('persona.persona') AND name = 'UQ_persona_doc')
    BEGIN
        ALTER TABLE persona.persona DROP CONSTRAINT UQ_persona_doc;
        PRINT '- Constraint UQ_persona_doc eliminada.';
    END
END TRY
BEGIN CATCH
    PRINT 'ERROR Dropeando UQ_persona_doc: ' + ERROR_MESSAGE();
END CATCH
GO

-- 2.2. Añadir columnas temporales (si no existen)
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona') AND name = 'nombre_completo_cifrado')
        ALTER TABLE persona.persona ADD nombre_completo_cifrado VARBINARY(512);
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona') AND name = 'nro_doc_cifrado')
        ALTER TABLE persona.persona ADD nro_doc_cifrado VARBINARY(128);
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona') AND name = 'direccion_cifrada')
        ALTER TABLE persona.persona ADD direccion_cifrada VARBINARY(512);
    PRINT '- Columnas varbinary de persona.persona verificadas/añadidas.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Añadiendo columnas a persona.persona: ' + ERROR_MESSAGE();
END CATCH
GO

-- 2.3. Encriptar datos (solo si no están ya encriptados)
BEGIN TRY
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    
    UPDATE persona.persona
    SET
        nombre_completo_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), nombre_completo),
        nro_doc_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), nro_doc),
        direccion_cifrada = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), direccion)
    WHERE nombre_completo_cifrado IS NULL AND nombre_completo IS NOT NULL; 

    PRINT '- Datos de persona.persona encriptados.';
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END TRY
BEGIN CATCH
    PRINT 'ERROR Encriptando datos en persona.persona: ' + ERROR_MESSAGE();
    IF (EXISTS (SELECT * FROM sys.open_keys WHERE key_name = 'SK_DatosSensibles'))
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
END CATCH
GO

-- 2.4. Eliminar columnas plaintext (si aún existen)
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona') AND name = 'nombre_completo')
        ALTER TABLE persona.persona DROP COLUMN nombre_completo;
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona') AND name = 'nro_doc')
        ALTER TABLE persona.persona DROP COLUMN nro_doc;
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona') AND name = 'direccion')
        ALTER TABLE persona.persona DROP COLUMN direccion;
    PRINT '- Columnas plaintext de persona.persona eliminadas.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Eliminando columnas plaintext de persona.persona: ' + ERROR_MESSAGE();
END CATCH
GO

-- 2.5. Renombrar columnas
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona') AND name = 'nombre_completo_cifrado')
        EXEC sp_rename 'persona.persona.nombre_completo_cifrado', 'nombre_completo', 'COLUMN';
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona') AND name = 'nro_doc_cifrado')
        EXEC sp_rename 'persona.persona.nro_doc_cifrado', 'nro_doc', 'COLUMN';
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona') AND name = 'direccion_cifrada')
        EXEC sp_rename 'persona.persona.direccion_cifrada', 'direccion', 'COLUMN';
    PRINT '- Columnas encriptadas de persona.persona renombradas.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Renombrando columnas de persona.persona: ' + ERROR_MESSAGE();
END CATCH
GO

----------------------------------------------------------------
-- 3. MIGRACIÓN DE DATOS: persona.persona_contacto
----------------------------------------------------------------
PRINT '3. Encriptando tabla persona.persona_contacto (valor)';

-- 3.1. Dropear constraint UQ
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('persona.persona_contacto') AND name = 'UQ_persona_contacto')
    BEGIN
        ALTER TABLE persona.persona_contacto DROP CONSTRAINT UQ_persona_contacto;
        PRINT '- Constraint UQ_persona_contacto eliminada.';
    END
END TRY
BEGIN CATCH
    PRINT 'ERROR Dropeando UQ_persona_contacto: ' + ERROR_MESSAGE();
END CATCH
GO

-- 3.2. Añadir columna temporal
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona_contacto') AND name = 'valor_cifrado')
        ALTER TABLE persona.persona_contacto ADD valor_cifrado VARBINARY(512);
    PRINT '- Columna varbinary añadida a persona.persona_contacto.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Añadiendo columna a persona.persona_contacto: ' + ERROR_MESSAGE();
END CATCH
GO

-- 3.3. Encriptar datos
BEGIN TRY
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    
    UPDATE persona.persona_contacto
    SET valor_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), valor)
    WHERE valor_cifrado IS NULL AND valor IS NOT NULL;
    
    PRINT '- Datos de persona.persona_contacto encriptados.';
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END TRY
BEGIN CATCH
    PRINT 'ERROR Encriptando datos en persona.persona_contacto: ' + ERROR_MESSAGE();
    IF (EXISTS (SELECT * FROM sys.open_keys WHERE key_name = 'SK_DatosSensibles'))
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
END CATCH
GO

-- 3.4. Eliminar columna plaintext
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona_contacto') AND name = 'valor')
        ALTER TABLE persona.persona_contacto DROP COLUMN valor;
    PRINT '- Columna plaintext de persona.persona_contacto eliminada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Eliminando columna plaintext de persona.persona_contacto: ' + ERROR_MESSAGE();
END CATCH
GO

-- 3.5. Renombrar columna
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('persona.persona_contacto') AND name = 'valor_cifrado')
        EXEC sp_rename 'persona.persona_contacto.valor_cifrado', 'valor', 'COLUMN';
    PRINT '- Columna encriptada renombrada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Renombrando columna de persona.persona_contacto: ' + ERROR_MESSAGE();
END CATCH
GO

----------------------------------------------------------------
-- 4. MIGRACIÓN DE DATOS: administracion.cuenta_bancaria
----------------------------------------------------------------
PRINT '4. Encriptando tabla administracion.cuenta_bancaria (cbu_cvu, alias)';

-- 4.1. Dropear constraint UQ
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('administracion.cuenta_bancaria') AND name = 'UQ_cuenta_cbu')
    BEGIN
        ALTER TABLE administracion.cuenta_bancaria DROP CONSTRAINT UQ_cuenta_cbu;
        PRINT '- Constraint UQ_cuenta_cbu eliminada.';
    END
END TRY
BEGIN CATCH
    PRINT 'ERROR Dropeando UQ_cuenta_cbu: ' + ERROR_MESSAGE();
END CATCH
GO

-- 4.2. Añadir columnas temporales
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.cuenta_bancaria') AND name = 'cbu_cvu_cifrado')
        ALTER TABLE administracion.cuenta_bancaria ADD cbu_cvu_cifrado VARBINARY(128);
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.cuenta_bancaria') AND name = 'alias_cifrado')
        ALTER TABLE administracion.cuenta_bancaria ADD alias_cifrado VARBINARY(256);
    PRINT '- Columnas varbinary añadidas a cuenta_bancaria.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Añadiendo columnas a cuenta_bancaria: ' + ERROR_MESSAGE();
END CATCH
GO

-- 4.3. Encriptar datos
BEGIN TRY
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    
    UPDATE administracion.cuenta_bancaria
    SET 
        cbu_cvu_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), cbu_cvu),
        alias_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), alias)
    WHERE cbu_cvu_cifrado IS NULL AND cbu_cvu IS NOT NULL;
    
    PRINT '- Datos de cuenta_bancaria encriptados.';
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END TRY
BEGIN CATCH
    PRINT 'ERROR Encriptando datos en cuenta_bancaria: ' + ERROR_MESSAGE();
    IF (EXISTS (SELECT * FROM sys.open_keys WHERE key_name = 'SK_DatosSensibles'))
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
END CATCH
GO

-- 4.4. Eliminar columnas plaintext
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.cuenta_bancaria') AND name = 'cbu_cvu')
        ALTER TABLE administracion.cuenta_bancaria DROP COLUMN cbu_cvu;
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.cuenta_bancaria') AND name = 'alias')
        ALTER TABLE administracion.cuenta_bancaria DROP COLUMN alias;
    PRINT '- Columnas plaintext de cuenta_bancaria eliminadas.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Eliminando columnas plaintext de cuenta_bancaria: ' + ERROR_MESSAGE();
END CATCH
GO

-- 4.5. Renombrar columnas
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.cuenta_bancaria') AND name = 'cbu_cvu_cifrado')
        EXEC sp_rename 'administracion.cuenta_bancaria.cbu_cvu_cifrado', 'cbu_cvu', 'COLUMN';
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.cuenta_bancaria') AND name = 'alias_cifrado')
        EXEC sp_rename 'administracion.cuenta_bancaria.alias_cifrado', 'alias', 'COLUMN';
    PRINT '- Columnas encriptadas de cuenta_bancaria renombradas.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Renombrando columnas de cuenta_bancaria: ' + ERROR_MESSAGE();
END CATCH
GO

----------------------------------------------------------------
-- 5. MIGRACIÓN DE DATOS: banco.banco_movimiento
----------------------------------------------------------------
PRINT '5. Encriptando tabla banco.banco_movimiento (cbu_origen)';

-- 5.1. Dropear el índice que bloquea la columna
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID('banco.banco_movimiento') AND name = 'IX_movimiento_cbu')
    BEGIN
        DROP INDEX IX_movimiento_cbu ON banco.banco_movimiento;
        PRINT '- Índice IX_movimiento_cbu eliminado.';
    END
END TRY
BEGIN CATCH
    PRINT 'ERROR Dropeando IX_movimiento_cbu: ' + ERROR_MESSAGE();
END CATCH
GO

-- 5.2. Añadir columna temporal
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('banco.banco_movimiento') AND name = 'cbu_origen_cifrado')
        ALTER TABLE banco.banco_movimiento ADD cbu_origen_cifrado VARBINARY(128);
    PRINT '- Columna varbinary añadida a banco_movimiento.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Añadiendo columna a banco_movimiento: ' + ERROR_MESSAGE();
END CATCH
GO

-- 5.3. Encriptar datos
BEGIN TRY
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    
    UPDATE banco.banco_movimiento
    SET cbu_origen_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), cbu_origen)
    WHERE cbu_origen_cifrado IS NULL AND cbu_origen IS NOT NULL;
    
    PRINT '- Datos de banco_movimiento encriptados.';
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END TRY
BEGIN CATCH
    PRINT 'ERROR Encriptando datos en banco_movimiento: ' + ERROR_MESSAGE();
    IF (EXISTS (SELECT * FROM sys.open_keys WHERE key_name = 'SK_DatosSensibles'))
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
END CATCH
GO

-- 5.4. Eliminar columna plaintext
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('banco.banco_movimiento') AND name = 'cbu_origen')
        ALTER TABLE banco.banco_movimiento DROP COLUMN cbu_origen;
    PRINT '- Columna plaintext de banco_movimiento eliminada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Eliminando columna plaintext de banco_movimiento: ' + ERROR_MESSAGE();
END CATCH
GO

-- 5.5. Renombrar columna
BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('banco.banco_movimiento') AND name = 'cbu_origen_cifrado')
        EXEC sp_rename 'banco.banco_movimiento.cbu_origen_cifrado', 'cbu_origen', 'COLUMN';
    PRINT '- Columna encriptada de banco_movimiento renombrada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Renombrando columna de banco_movimiento: ' + ERROR_MESSAGE();
END CATCH
GO

----------------------------------------------------------------
-- 6. MIGRACIÓN DE DATOS: PII Restantes (Admins, Consorcios, Proveedores)
----------------------------------------------------------------
PRINT '6. Encriptando datos PII restantes (CUITs, Domicilios, etc.)';

-- 6.1. administracion.administracion (cuit, domicilio, email, telefono)
PRINT '--- Encriptando administracion.administracion ---';
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'cuit_cifrado')
        ALTER TABLE administracion.administracion ADD cuit_cifrado VARBINARY(128);
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'domicilio_cifrado')
        ALTER TABLE administracion.administracion ADD domicilio_cifrado VARBINARY(512);
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'email_cifrado')
        ALTER TABLE administracion.administracion ADD email_cifrado VARBINARY(512);
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'telefono_cifrado')
        ALTER TABLE administracion.administracion ADD telefono_cifrado VARBINARY(128);
END TRY
BEGIN CATCH
    PRINT 'ERROR Añadiendo columnas a administracion.administracion: ' + ERROR_MESSAGE();
END CATCH
GO

BEGIN TRY
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    UPDATE administracion.administracion
    SET
        cuit_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), cuit),
        domicilio_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), domicilio),
        email_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), email),
        telefono_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), telefono)
    WHERE cuit_cifrado IS NULL AND cuit IS NOT NULL;
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END TRY
BEGIN CATCH
    PRINT 'ERROR Encriptando datos en administracion.administracion: ' + ERROR_MESSAGE();
    IF (EXISTS (SELECT * FROM sys.open_keys WHERE key_name = 'SK_DatosSensibles'))
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
END CATCH
GO

BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'cuit')
        ALTER TABLE administracion.administracion DROP COLUMN cuit;
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'domicilio')
        ALTER TABLE administracion.administracion DROP COLUMN domicilio;
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'email')
        ALTER TABLE administracion.administracion DROP COLUMN email;
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'telefono')
        ALTER TABLE administracion.administracion DROP COLUMN telefono;
END TRY
BEGIN CATCH
    PRINT 'ERROR Eliminando columnas plaintext de administracion.administracion: ' + ERROR_MESSAGE();
END CATCH
GO

BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'cuit_cifrado')
        EXEC sp_rename 'administracion.administracion.cuit_cifrado', 'cuit', 'COLUMN';
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'domicilio_cifrado')
        EXEC sp_rename 'administracion.administracion.domicilio_cifrado', 'domicilio', 'COLUMN';
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'email_cifrado')
        EXEC sp_rename 'administracion.administracion.email_cifrado', 'email', 'COLUMN';
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.administracion') AND name = 'telefono_cifrado')
        EXEC sp_rename 'administracion.administracion.telefono_cifrado', 'telefono', 'COLUMN';
    PRINT '- Tabla administracion.administracion encriptada y renombrada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Renombrando columnas de administracion.administracion: ' + ERROR_MESSAGE();
END CATCH
GO

-- 6.2. administracion.consorcio (cuit, domicilio)
PRINT '--- Encriptando administracion.consorcio ---';
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.consorcio') AND name = 'cuit_cifrado')
        ALTER TABLE administracion.consorcio ADD cuit_cifrado VARBINARY(128);
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.consorcio') AND name = 'domicilio_cifrado')
        ALTER TABLE administracion.consorcio ADD domicilio_cifrado VARBINARY(512);
END TRY
BEGIN CATCH
    PRINT 'ERROR Añadiendo columnas a administracion.consorcio: ' + ERROR_MESSAGE();
END CATCH
GO

BEGIN TRY
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    UPDATE administracion.consorcio
    SET
        cuit_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), cuit),
        domicilio_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), domicilio)
    WHERE cuit_cifrado IS NULL AND cuit IS NOT NULL;
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END TRY
BEGIN CATCH
    PRINT 'ERROR Encriptando datos en administracion.consorcio: ' + ERROR_MESSAGE();
    IF (EXISTS (SELECT * FROM sys.open_keys WHERE key_name = 'SK_DatosSensibles'))
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
END CATCH
GO

BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.consorcio') AND name = 'cuit')
        ALTER TABLE administracion.consorcio DROP COLUMN cuit;
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.consorcio') AND name = 'domicilio')
        ALTER TABLE administracion.consorcio DROP COLUMN domicilio;
END TRY
BEGIN CATCH
    PRINT 'ERROR Eliminando columnas plaintext de administracion.consorcio: ' + ERROR_MESSAGE();
END CATCH
GO

BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.consorcio') AND name = 'cuit_cifrado')
        EXEC sp_rename 'administracion.consorcio.cuit_cifrado', 'cuit', 'COLUMN';
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('administracion.consorcio') AND name = 'domicilio_cifrado')
        EXEC sp_rename 'administracion.consorcio.domicilio_cifrado', 'domicilio', 'COLUMN';
    PRINT '- Tabla administracion.consorcio encriptada y renombrada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Renombrando columnas de administracion.consorcio: ' + ERROR_MESSAGE();
END CATCH
GO

-- 6.3. expensa.proveedor (cuit)
PRINT '--- Encriptando expensa.proveedor ---';
BEGIN TRY
    IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('expensa.proveedor') AND name = 'cuit_cifrado')
        ALTER TABLE expensa.proveedor ADD cuit_cifrado VARBINARY(128);
END TRY
BEGIN CATCH
    PRINT 'ERROR Añadiendo columna a expensa.proveedor: ' + ERROR_MESSAGE();
END CATCH
GO

BEGIN TRY
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    UPDATE expensa.proveedor
    SET cuit_cifrado = ENCRYPTBYKEY(KEY_GUID('SK_DatosSensibles'), cuit)
    WHERE cuit_cifrado IS NULL AND cuit IS NOT NULL;
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END TRY
BEGIN CATCH
    PRINT 'ERROR Encriptando datos en expensa.proveedor: ' + ERROR_MESSAGE();
    IF (EXISTS (SELECT * FROM sys.open_keys WHERE key_name = 'SK_DatosSensibles'))
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
END CATCH
GO

BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('expensa.proveedor') AND name = 'cuit')
        ALTER TABLE expensa.proveedor DROP COLUMN cuit;
END TRY
BEGIN CATCH
    PRINT 'ERROR Eliminando columna plaintext de expensa.proveedor: ' + ERROR_MESSAGE();
END CATCH
GO

BEGIN TRY
    IF EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('expensa.proveedor') AND name = 'cuit_cifrado')
        EXEC sp_rename 'expensa.proveedor.cuit_cifrado', 'cuit', 'COLUMN';
    PRINT '- Tabla expensa.proveedor encriptada y renombrada.';
END TRY
BEGIN CATCH
    PRINT 'ERROR Renombrando columna de expensa.proveedor: ' + ERROR_MESSAGE();
END CATCH
GO


PRINT '--- ENCRIPTACION FINALIZADA ---';
GO