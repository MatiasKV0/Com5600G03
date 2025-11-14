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

--VERIFICACION DE ROLES Y PERMISOS

USE Com5600G03;
GO



-- =================================================================
-- 1. LISTAR TODOS LOS ROLES CREADOS
-- =================================================================

SELECT 
    name AS 'Rol',
    type_desc AS 'Tipo',
    create_date AS 'Fecha Creación',
    modify_date AS 'Última Modificación'
FROM sys.database_principals
WHERE type = 'R' 
    AND name IN (
        'Administrativo General', 
        'Administrativo Bancario', 
        'Administrativo Operativo', 
        'Sistemas'
    )
ORDER BY name;


-- =================================================================
-- 2. PERMISOS POR ROL - VISTA RESUMIDA
-- =================================================================

SELECT 
    rol.name AS 'Rol',
    COUNT(DISTINCT CASE WHEN perm.permission_name = 'SELECT' THEN perm.major_id END) AS 'Permisos SELECT',
    COUNT(DISTINCT CASE WHEN perm.permission_name = 'INSERT' THEN perm.major_id END) AS 'Permisos INSERT',
    COUNT(DISTINCT CASE WHEN perm.permission_name = 'UPDATE' THEN perm.major_id END) AS 'Permisos UPDATE',
    COUNT(DISTINCT CASE WHEN perm.permission_name = 'DELETE' THEN perm.major_id END) AS 'Permisos DELETE',
    COUNT(DISTINCT CASE WHEN perm.permission_name = 'EXECUTE' THEN perm.major_id END) AS 'Permisos EXECUTE'
FROM sys.database_principals rol
LEFT JOIN sys.database_permissions perm ON rol.principal_id = perm.grantee_principal_id
    AND perm.state = 'G' -- GRANT
WHERE rol.type = 'R' 
    AND rol.name IN (
        'Administrativo General', 
        'Administrativo Bancario', 
        'Administrativo Operativo', 
        'Sistemas'
    )
GROUP BY rol.name
ORDER BY rol.name;


-- =================================================================
-- 3. PERMISOS SOBRE ESQUEMAS - DETALLADO
-- =================================================================

SELECT 
    rol.name AS 'Rol',
    sch.name AS 'Esquema',
    perm.permission_name AS 'Permiso',
    perm.state_desc AS 'Estado'
FROM sys.database_principals rol
INNER JOIN sys.database_permissions perm ON rol.principal_id = perm.grantee_principal_id
INNER JOIN sys.schemas sch ON perm.major_id = sch.schema_id
WHERE rol.type = 'R' 
    AND rol.name IN (
        'Administrativo General', 
        'Administrativo Bancario', 
        'Administrativo Operativo', 
        'Sistemas'
    )
    AND perm.class = 3 -- Schema
ORDER BY rol.name, sch.name, perm.permission_name;


-- =================================================================
-- 4. PERMISOS DENEGADOS (DENY) - IMPORTANTE
-- =================================================================
SELECT 
    rol.name AS 'Rol',
    CASE perm.class
        WHEN 0 THEN 'Base de Datos'
        WHEN 1 THEN OBJECT_NAME(perm.major_id)
        WHEN 3 THEN SCHEMA_NAME(perm.major_id)
    END AS 'Objeto',
    perm.permission_name AS 'Permiso Denegado',
    perm.state_desc AS 'Estado'
FROM sys.database_principals rol
INNER JOIN sys.database_permissions perm ON rol.principal_id = perm.grantee_principal_id
WHERE rol.type = 'R' 
    AND rol.name IN (
        'Administrativo General', 
        'Administrativo Bancario', 
        'Administrativo Operativo', 
        'Sistemas'
    )
    AND perm.state = 'D' -- DENY
ORDER BY rol.name, Objeto;

-- =================================================================
-- 5. PERMISOS SOBRE STORED PROCEDURES
-- =================================================================
SELECT 
    rol.name AS 'Rol',
    SCHEMA_NAME(obj.schema_id) AS 'Esquema',
    obj.name AS 'Stored Procedure',
    perm.permission_name AS 'Permiso',
    perm.state_desc AS 'Estado'
FROM sys.database_principals rol
INNER JOIN sys.database_permissions perm ON rol.principal_id = perm.grantee_principal_id
INNER JOIN sys.objects obj ON perm.major_id = obj.object_id
WHERE rol.type = 'R' 
    AND rol.name IN (
        'Administrativo General', 
        'Administrativo Bancario', 
        'Administrativo Operativo', 
        'Sistemas'
    )
    AND obj.type = 'P' -- Stored Procedure
    AND perm.class = 1 -- Object
ORDER BY rol.name, SCHEMA_NAME(obj.schema_id), obj.name;


-- =================================================================
-- 6. COMPARATIVA DE PERMISOS POR ROL (TABLA CRUZADA)
-- =================================================================
WITH PermisosRoles AS (
    SELECT 
        rol.name AS Rol,
        'Ver datos (SELECT)' AS Accion,
        CASE WHEN EXISTS (
            SELECT 1 FROM sys.database_permissions p
            WHERE p.grantee_principal_id = rol.principal_id
                AND p.permission_name = 'SELECT'
                AND p.state = 'G'
        ) THEN 'V' ELSE 'X' END AS Permitido
    FROM sys.database_principals rol
    WHERE rol.name IN ('Administrativo General', 'Administrativo Bancario', 'Administrativo Operativo', 'Sistemas')
    
    UNION ALL
    
    SELECT 
        rol.name,
        'Modificar UF y Personas' AS Accion,
        CASE WHEN EXISTS (
            SELECT 1 FROM sys.database_permissions p
            INNER JOIN sys.schemas s ON p.major_id = s.schema_id
            WHERE p.grantee_principal_id = rol.principal_id
                AND s.name IN ('unidad_funcional', 'persona')
                AND p.permission_name IN ('INSERT', 'UPDATE', 'DELETE')
                AND p.state = 'G'
                AND p.class = 3
        ) THEN 'V' ELSE 'X' END
    FROM sys.database_principals rol
    WHERE rol.name IN ('Administrativo General', 'Administrativo Bancario', 'Administrativo Operativo', 'Sistemas')
    
    UNION ALL
    
    SELECT 
        rol.name,
        'Gestionar Pagos (Bancario)' AS Accion,
        CASE WHEN EXISTS (
            SELECT 1 FROM sys.database_permissions p
            INNER JOIN sys.schemas s ON p.major_id = s.schema_id
            WHERE p.grantee_principal_id = rol.principal_id
                AND s.name = 'banco'
                AND p.permission_name IN ('INSERT', 'UPDATE', 'DELETE')
                AND p.state = 'G'
                AND p.class = 3
        ) THEN 'V' ELSE 'X' END
    FROM sys.database_principals rol
    WHERE rol.name IN ('Administrativo General', 'Administrativo Bancario', 'Administrativo Operativo', 'Sistemas')
    
    UNION ALL
    
    SELECT 
        rol.name,
        'Gestionar Gastos' AS Accion,
        CASE WHEN EXISTS (
            SELECT 1 FROM sys.database_permissions p
            INNER JOIN sys.schemas s ON p.major_id = s.schema_id
            WHERE p.grantee_principal_id = rol.principal_id
                AND s.name = 'expensa'
                AND p.permission_name IN ('INSERT', 'UPDATE')
                AND p.state = 'G'
                AND p.class = 3
        ) THEN 'V' ELSE 'X' END
    FROM sys.database_principals rol
    WHERE rol.name IN ('Administrativo General', 'Administrativo Bancario', 'Administrativo Operativo', 'Sistemas')
    
    UNION ALL
    
    SELECT 
        rol.name,
        'Ejecutar Reportes' AS Accion,
        CASE WHEN EXISTS (
            SELECT 1 FROM sys.database_permissions p
            INNER JOIN sys.objects o ON p.major_id = o.object_id
            WHERE p.grantee_principal_id = rol.principal_id
                AND o.name LIKE 'Reporte%'
                AND p.permission_name = 'EXECUTE'
                AND p.state = 'G'
        ) THEN 'V' ELSE 'X' END
    FROM sys.database_principals rol
    WHERE rol.name IN ('Administrativo General', 'Administrativo Bancario', 'Administrativo Operativo', 'Sistemas')
)
SELECT 
    Accion,
    MAX(CASE WHEN Rol = 'Administrativo General' THEN Permitido END) AS 'Adm. General',
    MAX(CASE WHEN Rol = 'Administrativo Bancario' THEN Permitido END) AS 'Adm. Bancario',
    MAX(CASE WHEN Rol = 'Administrativo Operativo' THEN Permitido END) AS 'Adm. Operativo',
    MAX(CASE WHEN Rol = 'Sistemas' THEN Permitido END) AS 'Sistemas'
FROM PermisosRoles
GROUP BY Accion
ORDER BY Accion;


-- =================================================================
-- 7. LISTADO DE TODOS LOS SP Y SU ACCESO POR ROL
-- =================================================================
SELECT 
    SCHEMA_NAME(p.schema_id) AS 'Esquema',
    p.name AS 'Stored Procedure',
    MAX(CASE WHEN rol.name = 'Administrativo General' THEN 
        CASE WHEN perm.state = 'G' THEN 'GRANT' 
             WHEN perm.state = 'D' THEN 'DENY' 
             ELSE '-' END 
    END) AS 'Adm. General',
    MAX(CASE WHEN rol.name = 'Administrativo Bancario' THEN 
        CASE WHEN perm.state = 'G' THEN 'GRANT' 
             WHEN perm.state = 'D' THEN 'DENY' 
             ELSE '-' END 
    END) AS 'Adm. Bancario',
    MAX(CASE WHEN rol.name = 'Administrativo Operativo' THEN 
        CASE WHEN perm.state = 'G' THEN 'GRANT' 
             WHEN perm.state = 'D' THEN 'DENY' 
             ELSE '-' END 
    END) AS 'Adm. Operativo',
    MAX(CASE WHEN rol.name = 'Sistemas' THEN 
        CASE WHEN perm.state = 'G' THEN 'GRANT' 
             WHEN perm.state = 'D' THEN 'DENY' 
             ELSE '-' END 
    END) AS 'Sistemas'
FROM sys.objects p
LEFT JOIN sys.database_permissions perm ON p.object_id = perm.major_id
    AND perm.permission_name = 'EXECUTE'
LEFT JOIN sys.database_principals rol ON perm.grantee_principal_id = rol.principal_id
    AND rol.name IN ('Administrativo General', 'Administrativo Bancario', 'Administrativo Operativo', 'Sistemas')
WHERE p.type = 'P' -- Stored Procedures
    AND SCHEMA_NAME(p.schema_id) IN ('administracion', 'banco', 'expensa', 'persona', 'unidad_funcional')
GROUP BY SCHEMA_NAME(p.schema_id), p.name
ORDER BY SCHEMA_NAME(p.schema_id), p.name;



-- VERIFICACIÓN DE SEGREGACIÓN DE FUNCIONES


-- Verificar que Adm. General NO puede importar pagos
IF EXISTS (
    SELECT 1 FROM sys.database_permissions p
    INNER JOIN sys.database_principals rol ON p.grantee_principal_id = rol.principal_id
    INNER JOIN sys.objects o ON p.major_id = o.object_id
    WHERE rol.name = 'Administrativo General'
        AND o.name = 'ImportarYConciliarPagos'
        AND p.state = 'D'
)
    PRINT 'Administrativo General NO puede importar pagos (Correcto)';
ELSE
    PRINT 'ERROR: Administrativo General puede importar pagos';

-- Verificar que Adm. Bancario NO puede modificar UF
IF EXISTS (
    SELECT 1 FROM sys.database_permissions p
    INNER JOIN sys.database_principals rol ON p.grantee_principal_id = rol.principal_id
    INNER JOIN sys.schemas s ON p.major_id = s.schema_id
    WHERE rol.name = 'Administrativo Bancario'
        AND s.name IN ('unidad_funcional', 'persona')
        AND p.permission_name IN ('INSERT', 'UPDATE', 'DELETE')
        AND p.state = 'D'
)
    PRINT 'Administrativo Bancario NO puede modificar UF (Correcto)';
ELSE
    PRINT 'ERROR: Administrativo Bancario puede modificar UF';

-- Verificar que Sistemas es SOLO LECTURA
IF NOT EXISTS (
    SELECT 1 FROM sys.database_permissions p
    INNER JOIN sys.database_principals rol ON p.grantee_principal_id = rol.principal_id
    WHERE rol.name = 'Sistemas'
        AND p.permission_name IN ('INSERT', 'UPDATE', 'DELETE')
        AND p.state = 'G'
)
    PRINT 'Sistemas es SOLO LECTURA (Correcto)';
ELSE
    PRINT 'ERROR: Sistemas tiene permisos de escritura';
