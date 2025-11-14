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

/*

==================================================
---------–-- Politica de Respaldo –---------------
==================================================

Con el fin de mantener protegida la informacion del sistema de expensas y asegurar que pueda recuperarse ante fallos o errores,
se propone una politica de respaldo que combina distintos tipos de copias segun el nivel de detalle que se necesite en cada momento. 
La idea es contar con un esquema equilibrado, que permita restaurar la base de datos sin pérdida significativa de informacion 
y sin afectar el rendimiento general del sistema durante su uso diario.

==================================================
–------- Frecuencia de los Backups –--------------
==================================================

El plan contempla tres tipos de respaldos:

	Backup Completo (FULL): se realizara una vez por semana, idealmente los domingos entre las 02:00 y las 03:00 AM,
	cuando no hay actividad. Este respaldo guarda toda la base de datos y sirve como punto principal de recuperacion.

	Backup Diferencial: se ejecutara todos los dias alrededor de las 03:00 AM. Este respaldo registra unicamente 
	lo que cambio desde el ultimo FULL, por lo que reduce tiempo y espacio respecto a repetir la copia completa diariamente.

	Backup del Log de Transacciones: se tomara cada 1 hora dentro del horario laboral, por ejemplo 
	entre las 08:00 y las 20:00. Esto permite conservar un historial muy reciente de operaciones y facilita 
	regresar a un estado cercano en caso de algun fallo.

==================================================
---------------Definicion del RPO-----------------
==================================================

A partir de este esquema, el punto maximo aceptable de perdida de datos (RPO) se establece en 1 hora. 
Esto implica que, en caso de un fallo inesperado, como maximo se perderia la informacion generada en la ultima hora.
Es un valor adecuado para el sistema del consorcio, donde la mayoria de las operaciones relevantes se cargan en momentos
puntuales del dia y no de forma continua.

==================================================
------------– Motivos de la Eleccion –-----------
==================================================

La combinacion de un FULL semanal, diferenciales diarios y logs frecuentes permite un equilibrio
entre seguridad y eficiencia. Los FULL permiten tener una copia completa sin cargar de mas al servidor, 
los diferenciales aceleran la restauracion y reducen la cantidad de archivos necesarios, 
y los respaldos del log permiten reconstruir la informacion mas reciente sin perder operaciones importantes.
Ademas, mantener copias en un medio externo ayuda a protegerse frente a fallas fisicas del servidor o situaciones imprevistas.
Todo este esquema permite volver a la actividad normal rapidamente y con minimos riesgos de perdida de datos.


*/