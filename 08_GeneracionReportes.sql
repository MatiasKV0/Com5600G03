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



--GENERACION DE REPORTES

USE Com5600G03
GO

--REPORTE 1 
-- Se desea analizar el flujo de caja en forma semanal. Debe presentar la recaudación por pagos ordinarios y extraordinarios de cada semana, 
-- el promedio en el periodo, y el acumulado progresivo.  

CREATE OR ALTER PROCEDURE expensa.Reporte_RecaudacionSemanal
    @FechaInicio DATE = NULL,
    @FechaFin DATE = NULL,
    @ConsorcioId INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE para calcular pagos por semana
    WITH PagosPorSemana AS (
        SELECT 
            DATEPART(YEAR, p.fecha) AS anio,
            DATEPART(WEEK, p.fecha) AS semana,
            DATEADD(DAY, 1 - DATEPART(WEEKDAY, p.fecha), p.fecha) AS inicio_semana,
            DATEADD(DAY, 7 - DATEPART(WEEKDAY, p.fecha), p.fecha) AS fin_semana,
            SUM(CASE WHEN p.tipo = 'ORDINARIO' THEN p.importe ELSE 0 END) AS pagos_ordinarios,
            SUM(CASE WHEN p.tipo = 'EXTRAORDINARIO' THEN p.importe ELSE 0 END) AS pagos_extraordinarios,
            SUM(p.importe) AS total_semana
        FROM banco.pago p
        INNER JOIN unidad_funcional.unidad_funcional uf ON p.uf_id = uf.uf_id
        WHERE p.fecha BETWEEN @FechaInicio AND @FechaFin
            AND (@ConsorcioId IS NULL OR uf.consorcio_id = @ConsorcioId)
        GROUP BY 
            DATEPART(YEAR, p.fecha),
            DATEPART(WEEK, p.fecha),
            DATEADD(DAY, 1 - DATEPART(WEEKDAY, p.fecha), p.fecha),
            DATEADD(DAY, 7 - DATEPART(WEEKDAY, p.fecha), p.fecha)
    ),
    PromediosYAcumulados AS (
        SELECT 
            anio,
            semana,
            inicio_semana,
            fin_semana,
            pagos_ordinarios,
            pagos_extraordinarios,
            total_semana,
            AVG(pagos_ordinarios) OVER () AS promedio_ordinarios,
            AVG(pagos_extraordinarios) OVER () AS promedio_extraordinarios,
            AVG(total_semana) OVER () AS promedio_total,
            SUM(pagos_ordinarios) OVER (ORDER BY anio, semana ROWS UNBOUNDED PRECEDING) AS acumulado_ordinarios,
            SUM(pagos_extraordinarios) OVER (ORDER BY anio, semana ROWS UNBOUNDED PRECEDING) AS acumulado_extraordinarios,
            SUM(total_semana) OVER (ORDER BY anio, semana ROWS UNBOUNDED PRECEDING) AS acumulado_total
        FROM PagosPorSemana
    )
    SELECT 
        anio AS Año,
        semana AS Semana,
        CONVERT(VARCHAR(10), inicio_semana, 103) AS Inicio_Semana,
        CONVERT(VARCHAR(10), fin_semana, 103) AS Fin_Semana,
		pagos_ordinarios, 
		pagos_extraordinarios, 
		total_semana, 
		promedio_ordinarios, 
		promedio_extraordinarios, 
		promedio_total, 
		acumulado_ordinarios, 
		acumulado_extraordinarios, 
		acumulado_total
    FROM PromediosYAcumulados
    ORDER BY anio, semana;

END;
GO


	 
------------------------------------------------------------------------------------------------
--REPORTE 2
--Presente el total de recaudación por mes y departamento en formato de tabla cruzada.
--------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE expensa.Reporte_RecaudacionMesDepartamentos
    @Anio INT = NULL,
    @ConsorcioId INT = NULL,
    @MesInicio INT = 1,
    @MesFin INT = 12
AS
BEGIN
    SET NOCOUNT ON;

    IF @MesInicio < 1 OR @MesInicio > 12 OR @MesFin < 1 OR @MesFin > 12 OR @MesInicio > @MesFin
    BEGIN
        RAISERROR('Los parámetros de mes deben estar entre 1 y 12, y MesInicio debe ser menor o igual a MesFin', 16, 1);
        RETURN;
    END;

    -- CTE para obtener recaudación por mes y departamento
    WITH RecaudacionBase AS (
        SELECT 
            uf.depto AS Departamento,
            MONTH(p.fecha) AS Mes,
            SUM(p.importe) AS Total_Recaudado
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
        ISNULL([1],0) AS Enero,
        ISNULL([2],0) AS Febrero,
        ISNULL([3],0) AS Marzo,
        ISNULL([4],0) AS Abril,
        ISNULL([5],0) AS Mayo,
        ISNULL([6],0) AS Junio,
        ISNULL([7],0) AS Julio,
        ISNULL([8],0) AS Agosto,
        ISNULL([9],0) AS Septiembre,
        ISNULL([10],0) AS Octubre,
        ISNULL([11],0) AS Noviembre,
        ISNULL([12],0) AS Diciembre,
       
        (ISNULL([1], 0) + ISNULL([2], 0) + ISNULL([3], 0) + ISNULL([4], 0) + 
         ISNULL([5], 0) + ISNULL([6], 0) + ISNULL([7], 0) + ISNULL([8], 0) + 
         ISNULL([9], 0) + ISNULL([10], 0) + ISNULL([11], 0) + ISNULL([12], 0)) AS Total_anual
	 FROM RecaudacionBase
		PIVOT (
			SUM(Total_Recaudado)
			FOR Mes IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
		) AS Cruzado
		ORDER BY Departamento;
	END;
GO



----------------------------------------------------------------------------------
--REPORTE 3: Presente un cuadro cruzado con la recaudación total desagregada 
--según su procedencia (ordinario, extraordinario, etc.) según el periodo. 
---------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE expensa.Reporte_RecaudacionPorTipoPeriodo
    @Anio INT = NULL,
    @ConsorcioId INT = NULL,
    @TipoPago VARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE para obtener recaudación por tipo y periodo
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
    -- Generar resultado en formato XML
    SELECT 
        TipoPago AS [@tipo],
        Periodo AS [@periodo],
        TotalRecaudado AS [@total]
    FROM RecaudacionPorTipo
    ORDER BY Periodo, TipoPago
    FOR XML PATH('Recaudacion'), ROOT('Reportes');
END;
GO


----------------------------------------------------------------------------------------
-- REPORTE 4: Obtenga los 5 (cinco) meses de mayores gastos y los 5 (cinco) de mayores ingresos.  
-----------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE expensa.Reporte_TopMesesGastosIngresos
    @Anio INT = NULL,
    @ConsorcioId INT = NULL,
    @TopN INT = 5
AS
BEGIN
    SET NOCOUNT ON;

    -- CTE para calcular gastos por periodo
    WITH GastosPorPeriodo AS (
        SELECT 
            p.periodo_id,
            c.nombre AS Consorcio,
            p.anio,
            p.mes,
            CONCAT(p.anio, '-', RIGHT('0' + CAST(p.mes AS VARCHAR(2)), 2)) AS Periodo,
            SUM(g.importe) AS TotalGastos
        FROM expensa.periodo p
        INNER JOIN administracion.consorcio c ON p.consorcio_id = c.consorcio_id
        LEFT JOIN expensa.gasto g ON p.periodo_id = g.periodo_id
        WHERE (@Anio IS NULL OR p.anio = @Anio)
            AND (@ConsorcioId IS NULL OR p.consorcio_id = @ConsorcioId)
        GROUP BY p.periodo_id, c.nombre, p.anio, p.mes
    ),
    -- CTE para calcular ingresos por periodo
    IngresosPorPeriodo AS (
        SELECT 
            p.periodo_id,
            c.nombre AS Consorcio,
            p.anio,
            p.mes,
            CONCAT(p.anio, '-', RIGHT('0' + CAST(p.mes AS VARCHAR(2)), 2)) AS Periodo,
            SUM(pg.importe) AS TotalIngresos
        FROM expensa.periodo p
        INNER JOIN administracion.consorcio c ON p.consorcio_id = c.consorcio_id
        LEFT JOIN unidad_funcional.unidad_funcional uf ON c.consorcio_id = uf.consorcio_id
        LEFT JOIN banco.pago pg ON uf.uf_id = pg.uf_id 
            AND YEAR(pg.fecha) = p.anio 
            AND MONTH(pg.fecha) = p.mes
        WHERE (@Anio IS NULL OR p.anio = @Anio)
            AND (@ConsorcioId IS NULL OR p.consorcio_id = @ConsorcioId)
        GROUP BY p.periodo_id, c.nombre, p.anio, p.mes
    )
    -- Top 5 mayores gastos
    SELECT 
        'MAYORES GASTOS' AS Categoria,
        Consorcio,
        Periodo,
        ISNULL(TotalGastos,0) AS Monto
    FROM (
        SELECT 
            Consorcio,
            Periodo,
            TotalGastos,
            ROW_NUMBER() OVER (ORDER BY TotalGastos DESC) AS Ranking
        FROM GastosPorPeriodo
    ) AS TopGastos
    WHERE Ranking <= @TopN

    UNION ALL

    -- Top 5 mayores ingresos
    SELECT 
        'MAYORES INGRESOS' AS Categoria,
        Consorcio,
        Periodo,
        ISNULL(TotalIngresos,0) AS Monto
    FROM (
        SELECT 
            Consorcio,
            Periodo,
            TotalIngresos,
            ROW_NUMBER() OVER (ORDER BY TotalIngresos DESC) AS Ranking
        FROM IngresosPorPeriodo
    ) AS TopIngresos
    WHERE Ranking <= @TopN
    ORDER BY Categoria, Monto DESC;
END;
GO
-------------------------------------------------------------------------
