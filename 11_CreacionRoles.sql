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

--CREACION DE ROLES PARA LA BD.

USE Com5600G03;
GO


IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Administrativo General' AND type = 'R')
BEGIN
    CREATE ROLE [Administrativo General];
    PRINT '- Rol "Administrativo General" creado';
END
ELSE
    PRINT '- Rol "Administrativo General" ya existe';
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Administrativo Bancario' AND type = 'R')
BEGIN
    CREATE ROLE [Administrativo Bancario];
    PRINT '- Rol "Administrativo Bancario" creado';
END
ELSE
    PRINT '- Rol "Administrativo Bancario" ya existe';
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Administrativo Operativo' AND type = 'R')
BEGIN
    CREATE ROLE [Administrativo Operativo];
    PRINT '- Rol "Administrativo Operativo" creado';
END
ELSE
    PRINT '- Rol "Administrativo Operativo" ya existe';
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'Sistemas' AND type = 'R')
BEGIN
    CREATE ROLE [Sistemas];
    PRINT '- Rol "Sistemas" creado';
END
ELSE
    PRINT '- Rol "Sistemas" ya existe';
GO

----------------------------------------------------------------
-- 2. PERMISOS PARA "ADMINISTRATIVO GENERAL"
----------------------------------------------------------------

-- GRANT permisos correctos
GRANT EXECUTE ON administracion.ImportarConsorcios TO [Administrativo General];
GRANT EXECUTE ON administracion.ImportarArchivoUF TO [Administrativo General];
GRANT EXECUTE ON unidad_funcional.ImportarUnidadesFuncionales TO [Administrativo General];
GRANT EXECUTE ON persona.ImportarInquilinosPropietarios TO [Administrativo General];
GRANT EXECUTE ON administracion.CrearPeriodos TO [Administrativo General];

-- DENY explícito a operaciones bancarias
DENY EXECUTE ON banco.ImportarYConciliarPagos TO [Administrativo General];
DENY EXECUTE ON administracion.ImportarGastos TO [Administrativo General];
DENY EXECUTE ON administracion.CargarProveedores TO [Administrativo General];
DENY EXECUTE ON administracion.CargarTipoGastos TO [Administrativo General];
DENY EXECUTE ON expensa.LlenarExpensas TO [Administrativo General];

PRINT '- Permisos asignados correctamente';
GO

----------------------------------------------------------------
-- 3. PERMISOS PARA "ADMINISTRATIVO BANCARIO"
----------------------------------------------------------------

-- GRANT permisos correctos
GRANT EXECUTE ON banco.ImportarYConciliarPagos TO [Administrativo Bancario];

-- DENY explícito a importaciones que no le corresponden
DENY EXECUTE ON administracion.ImportarConsorcios TO [Administrativo Bancario];
DENY EXECUTE ON administracion.ImportarArchivoUF TO [Administrativo Bancario];
DENY EXECUTE ON unidad_funcional.ImportarUnidadesFuncionales TO [Administrativo Bancario];
DENY EXECUTE ON persona.ImportarInquilinosPropietarios TO [Administrativo Bancario];
DENY EXECUTE ON administracion.ImportarGastos TO [Administrativo Bancario];
DENY EXECUTE ON administracion.CargarProveedores TO [Administrativo Bancario];
DENY EXECUTE ON administracion.CargarTipoGastos TO [Administrativo Bancario];
DENY EXECUTE ON expensa.LlenarExpensas TO [Administrativo Bancario];
DENY EXECUTE ON administracion.CrearPeriodos TO [Administrativo Bancario];

PRINT '- Permisos asignados correctamente';
GO

----------------------------------------------------------------
-- 4. PERMISOS PARA "ADMINISTRATIVO OPERATIVO"
----------------------------------------------------------------
-- GRANT permisos correctos
GRANT EXECUTE ON administracion.ImportarGastos TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.CargarProveedores TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.CargarTipoGastos TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.LlenarExpensas TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.CrearPeriodos TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.ImportarArchivoUF TO [Administrativo Operativo];
GRANT EXECUTE ON unidad_funcional.ImportarUnidadesFuncionales TO [Administrativo Operativo];
GRANT EXECUTE ON persona.ImportarInquilinosPropietarios TO [Administrativo Operativo];

-- DENY explícito a operaciones bancarias y consorcios
DENY EXECUTE ON banco.ImportarYConciliarPagos TO [Administrativo Operativo];
DENY EXECUTE ON administracion.ImportarConsorcios TO [Administrativo Operativo];


PRINT '- Permisos asignados correctamente';
GO

----------------------------------------------------------------
-- 5. PERMISOS PARA "SISTEMAS"
---------------------------------------------------------------
-- Permisos de SOLO LECTURA sobre todos los esquemas

DENY EXECUTE ON administracion.ImportarConsorcios TO [Sistemas];
DENY EXECUTE ON administracion.ImportarArchivoUF TO [Sistemas];
DENY EXECUTE ON unidad_funcional.ImportarUnidadesFuncionales TO [Sistemas];
DENY EXECUTE ON persona.ImportarInquilinosPropietarios TO [Sistemas];
DENY EXECUTE ON banco.ImportarYConciliarPagos TO [Sistemas];
DENY EXECUTE ON administracion.ImportarGastos TO [Sistemas];
DENY EXECUTE ON administracion.CargarProveedores TO [Sistemas];
DENY EXECUTE ON administracion.CargarTipoGastos TO [Sistemas];
DENY EXECUTE ON expensa.LlenarExpensas TO [Sistemas];
DENY EXECUTE ON administracion.CrearPeriodos TO [Sistemas];
PRINT '- Permisos asignados correctamente';
GO




--LISTAR TODOS LOS ROLES CREADOS

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



-- PERMISOS SOBRE STORED PROCEDURES

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

-- LISTADO DE TODOS LOS SP Y SU ACCESO POR ROL

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
