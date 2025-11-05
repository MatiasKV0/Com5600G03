/*
------------------------------------------------------------
Trabajo Práctico Integrador
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


-- IMPORTAR TABLA CONSORCIOS DE CSV. Originalmente estos datos se encuentran en una tabla excel, se pide que exporte la hoja como csv para poder realizar la importacion

USE Com5600G03;
GO


CREATE OR ALTER PROCEDURE administracion.ImportarConsorcios
    @RutaArchivo NVARCHAR(300)
AS
BEGIN
    SET NOCOUNT ON;




    -- Tabla temporal con la estructura EXACTA del CSV
    CREATE TABLE #Consorcios (
        consorcioId VARCHAR(100), 
        nombreConsorcio VARCHAR(200),
        domicilio VARCHAR(200),
        cantUF INT,
        m2total NUMERIC(12,2)
    );



	----bulk insert en la tabla temporal----
    DECLARE @SQL NVARCHAR(MAX) = '
        BULK INSERT #Consorcios
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIELDTERMINATOR = '';'',
            ROWTERMINATOR = ''\n'',
			CODEPAGE =''65001'',
            FIRSTROW = 2
        );
    ';
    EXEC (@SQL);



	---insertar consorcios
	INSERT INTO administracion.consorcio(nombre, domicilio,superficie_total_m2,fecha_alta)
	SELECT 
		LTRIM(RTRIM(c.nombreConsorcio)),
        LTRIM(RTRIM(c.domicilio)),
		m2total,
		GETDATE() AS fecha_alta
	FROM #Consorcios c
	WHERE NOT EXISTS(
		SELECT 1 FROM administracion.consorcio a where a.nombre=c.nombreConsorcio
	);



    DROP TABLE #Consorcios;

END;
GO

EXEC administracion.ImportarConsorcios 
    @RutaArchivo = 'C:\Users\lauti\OneDrive\Desktop\Altos de SaintJust\datos varios(Consorcios).csv';
GO

select consorcio_id,nombre,domicilio,superficie_total_m2,fecha_alta from administracion.consorcio
GO


--delete from administracion.consorcio
