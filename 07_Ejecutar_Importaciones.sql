USE Com5600G03;
GO

PRINT '=== INICIO DE IMPORTACIONES ===';
PRINT '';

-- 1. Consorcios
PRINT '1. Importando Consorcios...';
EXEC administracion.ImportarConsorcios 
    @RutaArchivo = 'C:\_temp\datos varios(Consorcios).csv';
PRINT '';

-- 2. Unidades Funcionales
PRINT '2. Importando UF...';
EXEC administracion.ImportarArchivoUF
    @RutaArchivo = 'C:\_temp\UF por consorcio.txt';
PRINT '';

-- 3. Tipos de Gasto
PRINT '3. Cargando Tipos de Gasto...';
EXEC administracion.CargarTipoGastos;
PRINT '';

EXEC administracion.CrearPeriodos @Anio = 2025;

-- 4. Proveedores
PRINT '4. Importando Proveedores...';
EXEC administracion.CargarProveedores
    @RutaArchivo = 'C:\_temp\datos varios(Proveedores).csv';
PRINT '';

-- 5. Gastos
PRINT '5. Importando Gastos...';
EXEC administracion.ImportarGastos
    @RutaArchivo = 'C:\_temp\Servicios.Servicios.json';
PRINT '';

-- 6. Cuentas
PRINT '6. Importando Cuentas...';
EXEC unidad_funcional.ImportarUnidadesFuncionales 
     @RutaArchivo='C:\_temp\Inquilino-propietarios-UF.csv';
PRINT '';

-- 7. Personas
PRINT '7. Importando Inquilinos y Propietarios...';
EXEC persona.ImportarInquilinosPropietarios 
    @RutaArchivo='C:\_temp\Inquilino-propietarios-datos.csv';
PRINT '';

-- 8. Pagos
PRINT '8. Importando Pagos...';

IF NOT EXISTS (
    SELECT 1 FROM administracion.consorcio_cuenta_bancaria 
    WHERE consorcio_id = 1 AND cuenta_id = 1
)
BEGIN
    INSERT INTO administracion.consorcio_cuenta_bancaria (consorcio_id, cuenta_id, es_principal)
    VALUES (1, 1, 1);
    
    PRINT 'Vínculo consorcio-cuenta (1-1) creado.';
END
ELSE
BEGIN
    PRINT 'El vínculo consorcio-cuenta (1-1) ya existía. Omitiendo.';
END
GO

EXEC banco.ImportarYConciliarPagos
    @RutaArchivo='C:\_temp\pagos_consorcios.csv',
    @IdCuentaDestino = 1;
PRINT '';

PRINT '=== FIN DE IMPORTACIONES ===';

/*
select * from administracion.administracion
select * from administracion.consorcio
select * from administracion.consorcio_cuenta_bancaria
select * from administracion.cuenta_bancaria

select * from banco.banco_movimiento
select * from banco.pago

select * from expensa.envio_documento
select * from expensa.expensa_uf
select * from expensa.expensa_uf_detalle
select * from expensa.expensa_uf_interes
select * from expensa.gasto
select * from expensa.gasto_item
select * from expensa.sub_tipo_gasto
select * from expensa.tipo_gasto
select * from expensa.periodo
select * from expensa.proveedor

select * from persona.persona
select * from persona.persona_contacto

select * from unidad_funcional.baulera
select * from unidad_funcional.cochera
select * from unidad_funcional.uf_cuenta
select * from unidad_funcional.uf_persona_vinculo
select * from unidad_funcional.unidad_funcional
*/