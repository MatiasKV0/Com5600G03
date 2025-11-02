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

/*
INSERT INTO administracion.consorcio_cuenta_bancaria (consorcio_id, cuenta_id, es_principal)
VALUES (1, 1, 1);
*/

USE Com5600G03;
GO

CREATE OR ALTER PROCEDURE financiero.ImportarYConciliarPagos
    @RutaArchivo NVARCHAR(500),
    @IdCuentaDestino INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @consorcio_id INT;
    SELECT @consorcio_id = consorcio_id 
    FROM administracion.consorcio_cuenta_bancaria 
    WHERE cuenta_id = @IdCuentaDestino;

    IF @consorcio_id IS NULL
    BEGIN
        PRINT 'Error: El ID de cuenta destino ' + CAST(@IdCuentaDestino AS VARCHAR) + ' no se encontró o no está vinculado a un consorcio.';
        PRINT 'Por favor, ejecute el INSERT en [administracion.consorcio_cuenta_bancaria] primero.';
        RETURN -1;
    END;

    IF OBJECT_ID('tempdb..#PagosCSV') IS NOT NULL DROP TABLE #PagosCSV;
    CREATE TABLE #PagosCSV (
        id_pago_externo VARCHAR(50),
        fecha_texto VARCHAR(20),
        cbu_origen VARCHAR(40),
        valor_texto VARCHAR(50)
    );

    DECLARE @SQL NVARCHAR(MAX);
    SET @SQL = '
        BULK INSERT #PagosCSV
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n'',
            FIRSTROW = 2,
            CODEPAGE = ''65001'' -- UTF-8
        );
    ';
    BEGIN TRY
        EXEC (@SQL);
    END TRY
    BEGIN CATCH
        PRINT 'Error al cargar el CSV: ' + ERROR_MESSAGE();
        DROP TABLE #PagosCSV;
        RETURN -1;
    END CATCH;

    IF OBJECT_ID('tempdb..#PagosProcesados') IS NOT NULL DROP TABLE #PagosProcesados;
    SELECT
        ufc.uf_id, 
        LTRIM(RTRIM(csv.cbu_origen)) AS cbu_origen,
        CONVERT(DATE, LTRIM(RTRIM(csv.fecha_texto)), 103) AS fecha_pago,
        TRY_CAST(
            REPLACE(REPLACE(LTRIM(RTRIM(csv.valor_texto)), '$', ''), '.', '')
        AS NUMERIC(14, 2)) AS importe_pago,
        csv.id_pago_externo,
        CASE WHEN ufc.uf_id IS NULL THEN 'CBU de origen no vinculado a una UF' ELSE NULL END AS motivo_no_vinculado
    INTO #PagosProcesados
    FROM #PagosCSV csv
    LEFT JOIN administracion.cuenta_bancaria cb 
        ON csv.cbu_origen = cb.cbu_cvu
    LEFT JOIN unidad_funcional.uf_cuenta ufc 
        ON cb.cuenta_id = ufc.cuenta_id AND ufc.fecha_hasta IS NULL; 
        
    DECLARE @MovimientosInsertados TABLE (
        movimiento_id INT,
        cbu_origen VARCHAR(40),
        fecha DATE,
        importe NUMERIC(14,2)
    );

    INSERT INTO financiero.banco_movimiento (
        consorcio_id,
        cuenta_id,
        cbu_origen,
        fecha,
        importe,
        estado_conciliacion
    )
    OUTPUT 
        inserted.movimiento_id, 
        inserted.cbu_origen, 
        inserted.fecha, 
        inserted.importe
    INTO @MovimientosInsertados
    SELECT
        @consorcio_id,
        @IdCuentaDestino,
        p.cbu_origen,
        p.fecha_pago,
        p.importe_pago,
        CASE WHEN p.uf_id IS NOT NULL THEN 'Conciliado' ELSE 'Pendiente' END
    FROM #PagosProcesados p
    WHERE 
        p.importe_pago IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM financiero.banco_movimiento bm
            WHERE bm.cuenta_id = @IdCuentaDestino
              AND bm.cbu_origen = p.cbu_origen
              AND bm.fecha = p.fecha_pago
              AND bm.importe = p.importe_pago
        );
      
    INSERT INTO financiero.pago (
        uf_id,
        fecha,
        importe,
        tipo,
        movimiento_id, 
        motivo_no_asociado,
        created_by
    )
    SELECT
        p.uf_id, 
        p.fecha_pago,
        p.importe_pago,
        'Transferencia',
        mi.movimiento_id,
        p.motivo_no_vinculado,
        'SP_Importar'
    FROM #PagosProcesados p
    JOIN @MovimientosInsertados mi
        ON p.cbu_origen = mi.cbu_origen
       AND p.fecha_pago = mi.fecha
       AND p.importe_pago = mi.importe
    WHERE
        NOT EXISTS (
            SELECT 1 FROM financiero.pago fp
            WHERE fp.movimiento_id = mi.movimiento_id
        );
      
    DROP TABLE #PagosCSV;
    DROP TABLE #PagosProcesados;

END;
GO

EXEC financiero.ImportarYConciliarPagos
    @RutaArchivo='C:\Users\matia\OneDrive\Escritorio\Consorcios\pagos_consorcios.csv',
    @IdCuentaDestino = 1;
GO