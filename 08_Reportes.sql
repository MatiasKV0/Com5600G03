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

CREATE OR ALTER PROCEDURE expensa.Reporte_FlujoCajaSemanal
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
-- 3. Reporte con rango de fechas específico de todos los consorcios
EXEC expensa.Reporte_FlujoCajaSemanal 
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-11-11';

-- 4. Reporte completo: consorcio específico + rango de fechas
EXEC expensa.Reporte_FlujoCajaSemanal 
    @FechaInicio = '2025-01-01',
    @FechaFin = '2025-05-05',
    @ConsorcioId = 1;