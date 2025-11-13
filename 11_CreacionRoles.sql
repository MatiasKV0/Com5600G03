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

-- Permisos de lectura sobre todos los esquemas
GRANT SELECT ON SCHEMA::administracion TO [Administrativo General];
GRANT SELECT ON SCHEMA::unidad_funcional TO [Administrativo General];
GRANT SELECT ON SCHEMA::expensa TO [Administrativo General];
GRANT SELECT ON SCHEMA::persona TO [Administrativo General];
GRANT SELECT ON SCHEMA::banco TO [Administrativo General];

-- Permisos de actualización sobre datos de UF
GRANT INSERT, UPDATE, DELETE ON SCHEMA::unidad_funcional TO [Administrativo General];
GRANT INSERT, UPDATE, DELETE ON SCHEMA::persona TO [Administrativo General];

-- Permisos sobre administración y consorcios
GRANT INSERT, UPDATE ON SCHEMA::administracion TO [Administrativo General];

-- Permisos para ejecutar reportes
GRANT EXECUTE ON expensa.Reporte_RecaudacionSemanal TO [Administrativo General];
GRANT EXECUTE ON expensa.Reporte_RecaudacionMesDepartamentos TO [Administrativo General];
GRANT EXECUTE ON expensa.Reporte_RecaudacionPorTipoPeriodo TO [Administrativo General];
GRANT EXECUTE ON expensa.Reporte_TopMesesGastosIngresos TO [Administrativo General];
GRANT EXECUTE ON expensa.Reporte_Top3Morosos TO [Administrativo General];
GRANT EXECUTE ON expensa.Reporte_FechasPagosUF TO [Administrativo General];

-- Permisos para procedimientos de gestión de UF
GRANT EXECUTE ON administracion.ImportarConsorcios TO [Administrativo General];
GRANT EXECUTE ON administracion.ImportarArchivoUF TO [Administrativo General];
GRANT EXECUTE ON unidad_funcional.ImportarUnidadesFuncionales TO [Administrativo General];
GRANT EXECUTE ON persona.ImportarInquilinosPropietarios TO [Administrativo General];

-- DENEGAR explícitamente importación bancaria
DENY EXECUTE ON banco.ImportarYConciliarPagos TO [Administrativo General];

PRINT '- Permisos asignados correctamente';
GO

----------------------------------------------------------------
-- 3. PERMISOS PARA "ADMINISTRATIVO BANCARIO"
----------------------------------------------------------------

-- Permisos de lectura sobre todos los esquemas
GRANT SELECT ON SCHEMA::administracion TO [Administrativo Bancario];
GRANT SELECT ON SCHEMA::unidad_funcional TO [Administrativo Bancario];
GRANT SELECT ON SCHEMA::expensa TO [Administrativo Bancario];
GRANT SELECT ON SCHEMA::persona TO [Administrativo Bancario];
GRANT SELECT ON SCHEMA::banco TO [Administrativo Bancario];

-- Permisos completos sobre esquema banco
GRANT INSERT, UPDATE, DELETE ON SCHEMA::banco TO [Administrativo Bancario];

-- Permisos para ejecutar reportes
GRANT EXECUTE ON expensa.Reporte_RecaudacionSemanal TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.Reporte_RecaudacionMesDepartamentos TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.Reporte_RecaudacionPorTipoPeriodo TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.Reporte_TopMesesGastosIngresos TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.Reporte_Top3Morosos TO [Administrativo Bancario];
GRANT EXECUTE ON expensa.Reporte_FechasPagosUF TO [Administrativo Bancario];

-- Permisos para procedimientos bancarios
GRANT EXECUTE ON banco.ImportarYConciliarPagos TO [Administrativo Bancario];

-- DENEGAR explícitamente actualización de UF
DENY INSERT, UPDATE, DELETE ON SCHEMA::unidad_funcional TO [Administrativo Bancario];
DENY INSERT, UPDATE, DELETE ON SCHEMA::persona TO [Administrativo Bancario];
DENY EXECUTE ON administracion.ImportarArchivoUF TO [Administrativo Bancario];
DENY EXECUTE ON unidad_funcional.ImportarUnidadesFuncionales TO [Administrativo Bancario];
DENY EXECUTE ON persona.ImportarInquilinosPropietarios TO [Administrativo Bancario];

PRINT '- Permisos asignados correctamente';
GO

----------------------------------------------------------------
-- 4. PERMISOS PARA "ADMINISTRATIVO OPERATIVO"
----------------------------------------------------------------
-- Permisos de lectura sobre todos los esquemas
GRANT SELECT ON SCHEMA::administracion TO [Administrativo Operativo];
GRANT SELECT ON SCHEMA::unidad_funcional TO [Administrativo Operativo];
GRANT SELECT ON SCHEMA::expensa TO [Administrativo Operativo];
GRANT SELECT ON SCHEMA::persona TO [Administrativo Operativo];
GRANT SELECT ON SCHEMA::banco TO [Administrativo Operativo];

-- Permisos de actualización sobre datos de UF
GRANT INSERT, UPDATE, DELETE ON SCHEMA::unidad_funcional TO [Administrativo Operativo];
GRANT INSERT, UPDATE, DELETE ON SCHEMA::persona TO [Administrativo Operativo];

-- Permisos sobre expensas y gastos
GRANT INSERT, UPDATE ON SCHEMA::expensa TO [Administrativo Operativo];

-- Permisos para ejecutar reportes
GRANT EXECUTE ON expensa.Reporte_RecaudacionSemanal TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.Reporte_RecaudacionMesDepartamentos TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.Reporte_RecaudacionPorTipoPeriodo TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.Reporte_TopMesesGastosIngresos TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.Reporte_Top3Morosos TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.Reporte_FechasPagosUF TO [Administrativo Operativo];

-- Permisos para procedimientos operativos
GRANT EXECUTE ON administracion.ImportarArchivoUF TO [Administrativo Operativo];
GRANT EXECUTE ON unidad_funcional.ImportarUnidadesFuncionales TO [Administrativo Operativo];
GRANT EXECUTE ON persona.ImportarInquilinosPropietarios TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.CargarTipoGastos TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.CargarProveedores TO [Administrativo Operativo];
GRANT EXECUTE ON administracion.ImportarGastos TO [Administrativo Operativo];
GRANT EXECUTE ON expensa.LlenarExpensas TO [Administrativo Operativo];

-- DENEGAR explícitamente importación bancaria
DENY EXECUTE ON banco.ImportarYConciliarPagos TO [Administrativo Operativo];
DENY INSERT, UPDATE, DELETE ON SCHEMA::banco TO [Administrativo Operativo];

PRINT '- Permisos asignados correctamente';
GO

----------------------------------------------------------------
-- 5. PERMISOS PARA "SISTEMAS"
---------------------------------------------------------------
-- Permisos de SOLO LECTURA sobre todos los esquemas
GRANT SELECT ON SCHEMA::administracion TO [Sistemas];
GRANT SELECT ON SCHEMA::unidad_funcional TO [Sistemas];
GRANT SELECT ON SCHEMA::expensa TO [Sistemas];
GRANT SELECT ON SCHEMA::persona TO [Sistemas];
GRANT SELECT ON SCHEMA::banco TO [Sistemas];

-- Permisos para ejecutar reportes
GRANT EXECUTE ON expensa.Reporte_RecaudacionSemanal TO [Sistemas];
GRANT EXECUTE ON expensa.Reporte_RecaudacionMesDepartamentos TO [Sistemas];
GRANT EXECUTE ON expensa.Reporte_RecaudacionPorTipoPeriodo TO [Sistemas];
GRANT EXECUTE ON expensa.Reporte_TopMesesGastosIngresos TO [Sistemas];
GRANT EXECUTE ON expensa.Reporte_Top3Morosos TO [Sistemas];
GRANT EXECUTE ON expensa.Reporte_FechasPagosUF TO [Sistemas];

-- Permisos para ver metadatos del sistema
GRANT VIEW DEFINITION ON SCHEMA::administracion TO [Sistemas];
GRANT VIEW DEFINITION ON SCHEMA::unidad_funcional TO [Sistemas];
GRANT VIEW DEFINITION ON SCHEMA::expensa TO [Sistemas];
GRANT VIEW DEFINITION ON SCHEMA::persona TO [Sistemas];
GRANT VIEW DEFINITION ON SCHEMA::banco TO [Sistemas];

-- DENEGAR explícitamente cualquier modificación
DENY INSERT, UPDATE, DELETE ON SCHEMA::administracion TO [Sistemas];
DENY INSERT, UPDATE, DELETE ON SCHEMA::unidad_funcional TO [Sistemas];
DENY INSERT, UPDATE, DELETE ON SCHEMA::expensa TO [Sistemas];
DENY INSERT, UPDATE, DELETE ON SCHEMA::persona TO [Sistemas];
DENY INSERT, UPDATE, DELETE ON SCHEMA::banco TO [Sistemas];

-- DENEGAR procedimientos de importación
DENY EXECUTE ON administracion.ImportarConsorcios TO [Sistemas];
DENY EXECUTE ON administracion.ImportarArchivoUF TO [Sistemas];
DENY EXECUTE ON unidad_funcional.ImportarUnidadesFuncionales TO [Sistemas];
DENY EXECUTE ON persona.ImportarInquilinosPropietarios TO [Sistemas];
DENY EXECUTE ON banco.ImportarYConciliarPagos TO [Sistemas];
DENY EXECUTE ON administracion.CargarTipoGastos TO [Sistemas];
DENY EXECUTE ON administracion.CargarProveedores TO [Sistemas];
DENY EXECUTE ON administracion.ImportarGastos TO [Sistemas];
DENY EXECUTE ON expensa.LlenarExpensas TO [Sistemas];

PRINT '- Permisos asignados correctamente';
GO
