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

PRINT '--- INICIANDO MODIFICACION ---';
GO

----------------------------------------------------------------
-- PARTE 1: OBJETOS DE LA API (DÓLAR)
----------------------------------------------------------------
PRINT '--- Parte 1: Creando Objetos de la API Dólar ---';
GO

-- Habilitar OLE Automation
PRINT 'Configurando OLE Automation Procedures...';
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;
RECONFIGURE;
GO

-- Crear la tabla de cotización
IF NOT EXISTS (
    SELECT 1 FROM sys.objects o 
    JOIN sys.schemas s ON o.schema_id = s.schema_id 
    WHERE o.name = 'cotizacion_dolar' 
    AND s.name = 'administracion' 
    AND o.type = 'U'
)
BEGIN
    CREATE TABLE administracion.cotizacion_dolar (
        id INT IDENTITY(1,1) PRIMARY KEY,
        moneda VARCHAR(3) NOT NULL,
        casa VARCHAR(50) NOT NULL,
        nombre VARCHAR(50) NOT NULL,
        compra DECIMAL(18, 2) NOT NULL,
        venta DECIMAL(18, 2) NOT NULL,
        fecha_actualizacion DATETIME2 NOT NULL,
        fecha_registro_local DATETIME DEFAULT GETDATE()
    );
    PRINT 'Tabla administracion.cotizacion_dolar creada';
END
ELSE
BEGIN
    PRINT 'Tabla administracion.cotizacion_dolar ya existe';
END
GO

-- Crear el SP para consumir la API
CREATE OR ALTER PROCEDURE administracion.ActualizarCotizacionDolarOficial
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @obj INT;
    DECLARE @url VARCHAR(255) = 'https://dolarapi.com/v1/dolares/oficial';
    DECLARE @jsonResponse NVARCHAR(MAX);
    DECLARE @hr INT;
    DECLARE @status INT;
    DECLARE @errorMsg NVARCHAR(4000);

    BEGIN TRY
        EXEC @hr = sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @obj OUT;
        IF @hr <> 0 
        BEGIN
            RAISERROR('Error al crear objeto HTTP.', 16, 1);
            RETURN -1;
        END

        EXEC @hr = sp_OAMethod @obj, 'open', NULL, 'GET', @url, 'false';
        IF @hr <> 0 
        BEGIN
            EXEC sp_OADestroy @obj;
            RAISERROR('Error al abrir conexión HTTP', 16, 1);
            RETURN -1;
        END

        EXEC @hr = sp_OAMethod @obj, 'setTimeouts', NULL, 5000, 5000, 10000, 10000;
        EXEC @hr = sp_OAMethod @obj, 'send';
        IF @hr <> 0 
        BEGIN
            EXEC sp_OADestroy @obj;
            RAISERROR('Error al enviar request HTTP', 16, 1);
            RETURN -1;
        END

        EXEC @hr = sp_OAGetProperty @obj, 'status', @status OUT;
        IF @status <> 200
        BEGIN
            EXEC sp_OADestroy @obj;
            SET @errorMsg = 'La API retornó status: ' + CAST(@status AS VARCHAR(10));
            RAISERROR(@errorMsg, 16, 1);
            RETURN -1;
        END

        EXEC @hr = sp_OAGetProperty @obj, 'responseText', @jsonResponse OUT;
        IF @hr <> 0 OR @jsonResponse IS NULL
        BEGIN
            EXEC sp_OADestroy @obj;
            RAISERROR('Error al obtener respuesta de la API', 16, 1);
            RETURN -1;
        END

        EXEC sp_OADestroy @obj;

        INSERT INTO administracion.cotizacion_dolar (
            moneda, casa, nombre, compra, venta, fecha_actualizacion
        )
        SELECT
            moneda, casa, nombre, compra, venta, fechaActualizacion
        FROM OPENJSON(@jsonResponse)
        WITH (
            moneda VARCHAR(3) '$.moneda',
            casa VARCHAR(50) '$.casa',
            nombre VARCHAR(50) '$.nombre',
            compra DECIMAL(18, 2) '$.compra',
            venta DECIMAL(18, 2) '$.venta',
            fechaActualizacion DATETIME2 '$.fechaActualizacion'
        ) AS jsonValues
        WHERE NOT EXISTS (
            SELECT 1 FROM administracion.cotizacion_dolar 
            WHERE fecha_actualizacion = jsonValues.fechaActualizacion
        );

        PRINT 'Cotización actualizada exitosamente desde la API';
        RETURN 0;

    END TRY
    BEGIN CATCH
        IF @obj IS NOT NULL EXEC sp_OADestroy @obj;
        SET @errorMsg = ERROR_MESSAGE();
        RETURN -1;
    END CATCH
END
GO

PRINT 'SP administracion.ActualizarCotizacionDolarOficial creado/actualizado.';
GO

----------------------------------------------------------------
-- PARTE 2: MODIFICACIÓN DE SPs DE REPORTES (CON CORRECCIONES)
----------------------------------------------------------------
PRINT '--- Parte 2: Modificando SPs de Reportes para Cifrado ---';
GO

-- 1. expensa.Reporte_RecaudacionSemanal
CREATE OR ALTER PROCEDURE expensa.Reporte_RecaudacionSemanal
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @ConsorcioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    -- (Lógica del SP)
    WITH PagosPorSemana AS (
        SELECT 
            DATEPART(YEAR, p.fecha) AS anio, DATEPART(WEEK, p.fecha) AS semana,
            DATEADD(DAY, 1 - DATEPART(WEEKDAY, p.fecha), p.fecha) AS inicio_semana,
            DATEADD(DAY, 7 - DATEPART(WEEKDAY, p.fecha), p.fecha) AS fin_semana,
            SUM(CASE WHEN p.tipo = 'ORDINARIO' THEN p.importe ELSE 0 END) AS pagos_ordinarios,
            SUM(CASE WHEN p.tipo = 'EXTRAORDINARIO' THEN p.importe ELSE 0 END) AS pagos_extraordinarios,
            SUM(p.importe) AS total_semana
        FROM banco.pago p
        INNER JOIN unidad_funcional.unidad_funcional uf ON p.uf_id = uf.uf_id
        WHERE p.fecha BETWEEN @FechaInicio AND @FechaFin
            AND (@ConsorcioId IS NULL OR uf.consorcio_id = @ConsorcioId)
        GROUP BY DATEPART(YEAR, p.fecha), DATEPART(WEEK, p.fecha),
            DATEADD(DAY, 1 - DATEPART(WEEKDAY, p.fecha), p.fecha),
            DATEADD(DAY, 7 - DATEPART(WEEKDAY, p.fecha), p.fecha)
    ),
    PromediosYAcumulados AS (
        SELECT anio, semana, inicio_semana, fin_semana, pagos_ordinarios, pagos_extraordinarios, total_semana,
            AVG(pagos_ordinarios) OVER () AS promedio_ordinarios,
            AVG(pagos_extraordinarios) OVER () AS promedio_extraordinarios,
            AVG(total_semana) OVER () AS promedio_total,
            SUM(pagos_ordinarios) OVER (ORDER BY anio, semana ROWS UNBOUNDED PRECEDING) AS acumulado_ordinarios,
            SUM(pagos_extraordinarios) OVER (ORDER BY anio, semana ROWS UNBOUNDED PRECEDING) AS acumulado_extraordinarios,
            SUM(total_semana) OVER (ORDER BY anio, semana ROWS UNBOUNDED PRECEDING) AS acumulado_total
        FROM PagosPorSemana
    )
    SELECT 
        anio AS Año, semana AS Semana, CONVERT(VARCHAR(10), inicio_semana, 103) AS Inicio_Semana,
        CONVERT(VARCHAR(10), fin_semana, 103) AS Fin_Semana,
        pagos_ordinarios, pagos_extraordinarios, total_semana, 
        promedio_ordinarios, promedio_extraordinarios, promedio_total, 
        acumulado_ordinarios, acumulado_extraordinarios, acumulado_total
    FROM PromediosYAcumulados
    ORDER BY anio, semana;
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO 

PRINT 'SP expensa.Reporte_RecaudacionSemanal modificado.';
GO 

-- 2. expensa.Reporte_RecaudacionMesDepartamentos
CREATE OR ALTER PROCEDURE expensa.Reporte_RecaudacionMesDepartamentos
    @Anio INT = NULL,
    @ConsorcioId INT = NULL,
    @MesInicio INT = 1,
    @MesFin INT = 12
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    IF @MesInicio < 1 OR @MesInicio > 12 OR @MesFin < 1 OR @MesFin > 12 OR @MesInicio > @MesFin
    BEGIN
        RAISERROR('Los parámetros de mes deben estar entre 1 y 12', 16, 1);
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
        RETURN;
    END;
    WITH RecaudacionBase AS (
        SELECT uf.depto AS Departamento, MONTH(p.fecha) AS Mes, SUM(p.importe) AS Total_Recaudado
        FROM banco.pago p
        INNER JOIN unidad_funcional.unidad_funcional uf ON p.uf_id = uf.uf_id
        WHERE YEAR(p.fecha) = @Anio
            AND MONTH(p.fecha) BETWEEN @MesInicio AND @MesFin
            AND (@ConsorcioId IS NULL OR uf.consorcio_id = @ConsorcioId)
            AND uf.depto IS NOT NULL
        GROUP BY uf.depto, MONTH(p.fecha)
    )
    SELECT 
        Departamento,
        ISNULL([1],0) AS Enero, ISNULL([2],0) AS Febrero, ISNULL([3],0) AS Marzo,
        ISNULL([4],0) AS Abril, ISNULL([5],0) AS Mayo, ISNULL([6],0) AS Junio,
        ISNULL([7],0) AS Julio, ISNULL([8],0) AS Agosto, ISNULL([9],0) AS Septiembre,
        ISNULL([10],0) AS Octubre, ISNULL([11],0) AS Noviembre, ISNULL([12],0) AS Diciembre,
        (ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + 
         ISNULL([5], 0) + ISNULL([6], 0) + ISNULL([7], 0) + ISNULL([8], 0) + 
         ISNULL([9], 0) + ISNULL([10], 0) + ISNULL([11], 0) + ISNULL([12], 0)) AS Total_anual
     FROM RecaudacionBase
        PIVOT (SUM(Total_Recaudado) FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])) AS Cruzado
        ORDER BY Departamento;
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO 

PRINT 'SP expensa.Reporte_RecaudacionMesDepartamentos modificado.';
GO 

-- 3. expensa.Reporte_RecaudacionPorTipoPeriodo
CREATE OR ALTER PROCEDURE expensa.Reporte_RecaudacionPorTipoPeriodo
    @Anio INT = NULL,
    @ConsorcioId INT = NULL,
    @TipoPago VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    WITH RecaudacionPorTipo AS (
        SELECT 
            p.tipo AS TipoPago,
            CONCAT(YEAR(p.fecha), '-', RIGHT('0' + CAST(MONTH(p.fecha) AS VARCHAR(2)), 2)) AS Periodo,
            SUM(p.importe) AS TotalRecaudado
        FROM banco.pago p
        INNER JOIN unidad_funcional.unidad_funcional uf ON p.uf_id = uf.uf_id
        WHERE (@Anio IS NULL OR YEAR(p.fecha) = @Anio)
            AND (@ConsorcioId IS NULL OR uf.consorcio_id = @ConsorcioId)
            AND (@TipoPago IS NULL OR p.tipo = @TipoPago)
        GROUP BY p.tipo, YEAR(p.fecha), MONTH(p.fecha)
    )
    SELECT TipoPago AS [@tipo], Periodo AS [@periodo], TotalRecaudado AS [@total]
    FROM RecaudacionPorTipo
    ORDER BY Periodo, TipoPago
    FOR XML PATH('Recaudacion'), ROOT('Reportes');
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO 

PRINT 'SP expensa.Reporte_RecaudacionPorTipoPeriodo modificado.';
GO 

-- 4. expensa.Reporte_TopMesesGastosIngresos
CREATE OR ALTER PROCEDURE expensa.Reporte_TopMesesGastosIngresos
    @Anio INT = NULL,
    @ConsorcioId INT = NULL,
    @TopN INT = 5
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    WITH GastosPorPeriodo AS (
        SELECT p.periodo_id, c.nombre AS Consorcio, p.anio, p.mes,
            CONCAT(p.anio, '-', RIGHT('0' + CAST(p.mes AS VARCHAR(2)), 2)) AS Periodo,
            SUM(g.importe) AS TotalGastos
        FROM expensa.periodo p
        INNER JOIN administracion.consorcio c ON p.consorcio_id = c.consorcio_id
        LEFT JOIN expensa.gasto g ON p.periodo_id = g.periodo_id
        WHERE (@Anio IS NULL OR p.anio = @Anio) AND (@ConsorcioId IS NULL OR p.consorcio_id = @ConsorcioId)
        GROUP BY p.periodo_id, c.nombre, p.anio, p.mes
    ),
    IngresosPorPeriodo AS (
        SELECT p.periodo_id, c.nombre AS Consorcio, p.anio, p.mes,
            CONCAT(p.anio, '-', RIGHT('0' + CAST(p.mes AS VARCHAR(2)), 2)) AS Periodo,
            SUM(pg.importe) AS TotalIngresos
        FROM expensa.periodo p
        INNER JOIN administracion.consorcio c ON p.consorcio_id = c.consorcio_id
        LEFT JOIN unidad_funcional.unidad_funcional uf ON c.consorcio_id = uf.consorcio_id
        LEFT JOIN banco.pago pg ON uf.uf_id = pg.uf_id AND YEAR(pg.fecha) = p.anio AND MONTH(pg.fecha) = p.mes
        WHERE (@Anio IS NULL OR p.anio = @Anio) AND (@ConsorcioId IS NULL OR p.consorcio_id = @ConsorcioId)
        GROUP BY p.periodo_id, c.nombre, p.anio, p.mes
    )
    SELECT 'MAYORES GASTOS' AS Categoria, Consorcio, Periodo, ISNULL(TotalGastos,0) AS Monto
    FROM (SELECT Consorcio, Periodo, TotalGastos, ROW_NUMBER() OVER (ORDER BY TotalGastos DESC) AS Ranking FROM GastosPorPeriodo) AS TopGastos
    WHERE Ranking <= @TopN
    UNION ALL
    SELECT 'MAYORES INGRESOS' AS Categoria, Consorcio, Periodo, ISNULL(TotalIngresos,0) AS Monto
    FROM (SELECT Consorcio, Periodo, TotalIngresos, ROW_NUMBER() OVER (ORDER BY TotalIngresos DESC) AS Ranking FROM IngresosPorPeriodo) AS TopIngresos
    WHERE Ranking <= @TopN
    ORDER BY Categoria, Monto DESC;
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO 

PRINT 'SP expensa.Reporte_TopMesesGastosIngresos modificado.';
GO

-- 5. expensa.Reporte_Top3Morosos
CREATE OR ALTER PROCEDURE expensa.Reporte_Top3Morosos
    @ConsorcioId INT,
    @TopN INT,
    @Rol VARCHAR(50) = 'PROPIETARIO'
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    WITH DeudaPorUF AS (
        SELECT uf.uf_id, uf.codigo AS Unidad_Funcional, SUM(eu.deuda_anterior + eu.interes_mora) AS DeudaTotal
        FROM expensa.expensa_uf eu
        JOIN expensa.periodo per ON eu.periodo_id = per.periodo_id
        JOIN unidad_funcional.unidad_funcional uf ON eu.uf_id = uf.uf_id
        WHERE uf.consorcio_id = @ConsorcioId AND (eu.deuda_anterior > 0 OR eu.interes_mora > 0)
        GROUP BY uf.uf_id, uf.codigo
    ),
    ContactosPreferidos AS (
        SELECT pc.persona_id,
            STRING_AGG(
                CASE pc.tipo
                    WHEN 'email' THEN 'Email: ' + CONVERT(VARCHAR(200), DECRYPTBYKEY(pc.valor))
                    WHEN 'telefono' THEN 'Tel: ' + CONVERT(VARCHAR(200), DECRYPTBYKEY(pc.valor))
                END, ', '
            ) AS Contactos
        FROM persona.persona_contacto pc
        WHERE pc.es_preferido = 1
        GROUP BY pc.persona_id
    )
    SELECT TOP (@TopN)
        d.Unidad_Funcional,
        CONVERT(VARCHAR(200), DECRYPTBYKEY(p.nombre_completo)) AS Propietario,
        p.tipo_doc AS TipoDocumento,
        CONVERT(VARCHAR(40), DECRYPTBYKEY(p.nro_doc)) AS NroDocumento,
        CONVERT(VARCHAR(250), DECRYPTBYKEY(p.direccion)) AS Direccion,
        cp.Contactos,
        d.DeudaTotal
    FROM DeudaPorUF d
    JOIN unidad_funcional.uf_persona_vinculo upv ON d.uf_id = upv.uf_id AND upv.rol = @Rol AND upv.fecha_hasta IS NULL
    JOIN persona.persona p ON upv.persona_id = p.persona_id
    LEFT JOIN ContactosPreferidos cp ON p.persona_id = cp.persona_id
    ORDER BY d.DeudaTotal DESC;
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO 

PRINT 'SP expensa.Reporte_Top3Morosos modificado.';
GO

-- 6. expensa.Reporte_FechasPagosUF (CON CORRECCIÓN DATEDIFF)
CREATE OR ALTER PROCEDURE expensa.Reporte_FechasPagosUF
    @ConsorcioId INT,
    @UFCodigo INT,
    @TipoPago VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    WITH PagosOrdenados AS (
        SELECT p.pago_id, p.fecha AS FechaPago, LAG(p.fecha) OVER (ORDER BY p.fecha) AS FechaPagoAnterior, p.tipo
        FROM banco.pago p
        INNER JOIN unidad_funcional.unidad_funcional uf ON p.uf_id = uf.uf_id
        WHERE uf.consorcio_id = @ConsorcioId AND uf.codigo = @UFCodigo AND p.tipo = @TipoPago
    )
    SELECT 
        p.tipo AS [@tipo_pago],
        CONVERT(VARCHAR(10), FechaPago, 103) AS [@fecha_pago],
        CASE WHEN p.FechaPagoAnterior IS NULL THEN 'Primer pago' ELSE CONVERT(VARCHAR(10), p.FechaPagoAnterior, 103) END AS [@fecha_pago_anterior],
        CASE WHEN p.FechaPagoAnterior IS NULL THEN NULL ELSE DATEDIFF(DAY, p.FechaPagoAnterior, p.FechaPago) END AS [@dias_desde_ultimo_pago]
    FROM PagosOrdenados p
    ORDER BY p.FechaPago
    FOR XML PATH('Pago'), ROOT('Reporte_Pagos');
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO 

PRINT 'SP expensa.Reporte_FechasPagosUF modificado y corregido.';
GO 

-- 7. expensa.Reporte7_DeudaPeriodo_ARS_USD
CREATE OR ALTER PROCEDURE expensa.Reporte7_DeudaPeriodo_ARS_USD
    @ConsorcioId INT = NULL,
    @Anio INT = NULL,
    @Mes INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    OPEN SYMMETRIC KEY SK_DatosSensibles DECRYPTION BY CERTIFICATE CertParaDatosSensibles;
    IF @ConsorcioId IS NULL OR @Anio IS NULL OR @Mes IS NULL
    BEGIN
        PRINT ' Debe proporcionar ConsorcioId, Año y Mes';
        CLOSE SYMMETRIC KEY SK_DatosSensibles;
        RETURN; 
    END
    DECLARE @CotizacionVenta DECIMAL(18, 2);
    DECLARE @FechaCotizacion DATETIME2;
    SELECT TOP 1 @CotizacionVenta = venta, @FechaCotizacion = fecha_actualizacion
    FROM administracion.cotizacion_dolar
    WHERE casa = 'oficial'
    ORDER BY fecha_actualizacion DESC;
    IF @CotizacionVenta IS NULL OR @CotizacionVenta = 0
    BEGIN
        SET @CotizacionVenta = 1500.00;
        PRINT ' ADVERTENCIA: No hay cotización de API disponible';
    END
    SELECT 
        c.nombre AS Consorcio,
        CONCAT(@Anio, '-', RIGHT('0' + CAST(@Mes AS VARCHAR(2)), 2)) AS Periodo,
        uf.codigo AS UnidadFuncional,
        ISNULL(CONVERT(VARCHAR(200), DECRYPTBYKEY(pna.nombre_completo)), 'Desconocido') AS Propietario,
        ISNULL(SUM(eu.deuda_anterior), 0) AS DeudaAnterior_ARS,
        ISNULL(SUM(eu.interes_mora), 0) AS InteresMora_ARS,
        ISNULL(SUM(eu.deuda_anterior + eu.interes_mora), 0) AS DeudaTotal_ARS,
        ROUND(ISNULL(SUM(eu.deuda_anterior), 0) / @CotizacionVenta, 2) AS DeudaAnterior_USD,
        ROUND(ISNULL(SUM(eu.interes_mora), 0) / @CotizacionVenta, 2) AS InteresMora_USD,
        ROUND(ISNULL(SUM(eu.deuda_anterior + eu.interes_mora), 0) / @CotizacionVenta, 2) AS DeudaTotal_USD,
        @CotizacionVenta AS TasaCambio_ARS_USD,
        @FechaCotizacion AS FechaCotizacion
    FROM expensa.periodo p
    INNER JOIN administracion.consorcio c ON p.consorcio_id = c.consorcio_id
    INNER JOIN expensa.expensa_uf eu ON p.periodo_id = eu.periodo_id
    INNER JOIN unidad_funcional.unidad_funcional uf ON eu.uf_id = uf.uf_id
    LEFT JOIN unidad_funcional.uf_persona_vinculo upv ON uf.uf_id = upv.uf_id AND upv.rol = 'PROPIETARIO' AND upv.fecha_hasta IS NULL
    LEFT JOIN persona.persona pna ON upv.persona_id = pna.persona_id
    WHERE p.consorcio_id = @ConsorcioId AND p.anio = @Anio AND p.mes = @Mes
    GROUP BY c.nombre, uf.codigo, pna.nombre_completo
    HAVING SUM(eu.deuda_anterior + eu.interes_mora) > 0
    ORDER BY DeudaTotal_ARS DESC;
    CLOSE SYMMETRIC KEY SK_DatosSensibles;
END;
GO 

PRINT 'SP expensa.Reporte7_DeudaPeriodo_ARS_USD modificado.';
GO

----------------------------------------------------------------
-- PARTE 3: FIRMA DE STORED PROCEDURES
----------------------------------------------------------------
PRINT '--- Parte 3: Firmando SPs de Reportes ---';
GO

ADD SIGNATURE TO expensa.Reporte_RecaudacionSemanal
BY CERTIFICATE CertParaDatosSensibles;
PRINT 'SP expensa.Reporte_RecaudacionSemanal firmado.';
GO

ADD SIGNATURE TO expensa.Reporte_RecaudacionMesDepartamentos
BY CERTIFICATE CertParaDatosSensibles;
PRINT 'SP expensa.Reporte_RecaudacionMesDepartamentos firmado.';
GO

ADD SIGNATURE TO expensa.Reporte_RecaudacionPorTipoPeriodo
BY CERTIFICATE CertParaDatosSensibles;
PRINT 'SP expensa.Reporte_RecaudacionPorTipoPeriodo firmado.';
GO

ADD SIGNATURE TO expensa.Reporte_TopMesesGastosIngresos
BY CERTIFICATE CertParaDatosSensibles;
PRINT 'SP expensa.Reporte_TopMesesGastosIngresos firmado.';
GO

ADD SIGNATURE TO expensa.Reporte_Top3Morosos
BY CERTIFICATE CertParaDatosSensibles;
PRINT 'SP expensa.Reporte_Top3Morosos firmado.';
GO

ADD SIGNATURE TO expensa.Reporte_FechasPagosUF
BY CERTIFICATE CertParaDatosSensibles;
PRINT 'SP expensa.Reporte_FechasPagosUF firmado.';
GO

ADD SIGNATURE TO expensa.Reporte7_DeudaPeriodo_ARS_USD
BY CERTIFICATE CertParaDatosSensibles;
PRINT 'SP expensa.Reporte7_DeudaPeriodo_ARS_USD firmado.';
GO

PRINT '--- SCRIPT 14 (Versión Corregida) FINALIZADO ---';
GO