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
--  Reporte con rango de fechas específico de todos los consorcios
EXEC expensa.Reporte_RecaudacionSemanal
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-11-11';

-- Reporte completo: consorcio específico + rango de fechas
EXEC expensa.Reporte_RecaudacionSemanal
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-05-05',
    @ConsorcioId = 1;

	 
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

-- REPORTE 2: Recaudación por Mes y Departamento
EXEC expensa.Reporte_RecaudacionMesDepartamentos
    @Anio = 2025,
    @ConsorcioId = 2,
    @MesInicio = 1,
    @MesFin = 6;

----------------------------------------------------------------------------------
--REPORTE 3: Presente un cuadro cruzado con la recaudación total desagregada 
--según su procedencia (ordinario, extraordinario, etc.) según el periodo. 
---------------------------------------------------------------------------------
