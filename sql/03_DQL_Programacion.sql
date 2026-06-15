use FestCine

-- ============================================================
-- FestCine - Fase 3: Consultas DQL, Vistas y Programacion
-- Convencion: PascalCase | Motor: SQL Server (T-SQL)
-- Ejecutar DESPUES de 01_DDL.sql y 02_DML.sql
-- ============================================================

-- ============================================================
-- LIMPIEZA (re-ejecutar sin errores)
-- ============================================================
IF OBJECT_ID('trg_ControlAgenda_Proyecciones', 'TR') IS NOT NULL
    DROP TRIGGER trg_ControlAgenda_Proyecciones;
GO
IF OBJECT_ID('sp_VenderAbono',    'P') IS NOT NULL DROP PROCEDURE sp_VenderAbono;
IF OBJECT_ID('sp_ComprarEntrada', 'P') IS NOT NULL DROP PROCEDURE sp_ComprarEntrada;
GO
IF OBJECT_ID('vw_InformeFinanciero',      'V') IS NOT NULL DROP VIEW vw_InformeFinanciero;
IF OBJECT_ID('vw_ActaPremiacion',         'V') IS NOT NULL DROP VIEW vw_ActaPremiacion;
IF OBJECT_ID('vw_RankingPeliculas',       'V') IS NOT NULL DROP VIEW vw_RankingPeliculas;
IF OBJECT_ID('vw_TarifasActivas',         'V') IS NOT NULL DROP VIEW vw_TarifasActivas;
IF OBJECT_ID('vw_ProyeccionesDisponibles','V') IS NOT NULL DROP VIEW vw_ProyeccionesDisponibles;
IF OBJECT_ID('vw_PeliculasCartelera',     'V') IS NOT NULL DROP VIEW vw_PeliculasCartelera;
GO

-- ============================================================
-- SECCIÓN 1: VISTAS
-- ============================================================

-- ----------------------------------------------------------
-- V1: Cartelera de peliculas seleccionadas/premiadas
-- Usada por Modulo 1 (Taquilla) y Modulo 2 (Agenda Admin)
-- ----------------------------------------------------------
CREATE VIEW vw_PeliculasCartelera AS
SELECT
    p.CodPelicula,
    p.Titulo,
    p.AnioProduccion,
    p.Duracion,
    pa.NombrePais         AS PaisOrigen,
    f.TipoFormato         AS Formato,
    ep.NombreEstado       AS Estado,
    ce.CodClasificacion,
    ce.EdadMinima,
    STRING_AGG(g.NombreGenero, ', ') AS Generos
FROM Peliculas p
JOIN Paises pa                ON pa.CodPais         = p.CodPais
JOIN Formatos f               ON f.CodFormato        = p.CodFormato
JOIN EstadosPeliculas ep      ON ep.CodEstado        = p.CodEstado
JOIN ClasificacionesEdades ce ON ce.CodClasificacion = p.CodClasificacion
LEFT JOIN PeliculasGeneros pg ON pg.CodPelicula      = p.CodPelicula
LEFT JOIN Generos g           ON g.CodGenero          = pg.CodGenero
WHERE p.CodEstado IN ('est_03', 'est_06', 'est_07')   -- Seleccionada, Premiada, Mencion
GROUP BY
    p.CodPelicula, p.Titulo, p.AnioProduccion, p.Duracion,
    pa.NombrePais, f.TipoFormato, ep.NombreEstado,
    ce.CodClasificacion, ce.EdadMinima;
GO

-- ----------------------------------------------------------
-- V2: Proyecciones con cupo disponible en tiempo real
-- CupoDisponible = Capacidad - Entradas individuales vendidas
-- Nota: UsosAbonos se registran por separado; P1 controla
--       el aforo contando solo Entradas.
-- ----------------------------------------------------------
CREATE VIEW vw_ProyeccionesDisponibles AS
SELECT
    pr.CodProyeccion,
    p.CodPelicula,
    p.Titulo,
    p.Duracion,
    pr.FechaHoraInicio,
    pr.FechaHoraFin,
    pr.SesionQa,
    s.CodSala,
    s.NombreSala,
    sd.NombreSede,
    s.Capacidad,
    COUNT(e.CodEntrada)                       AS EntradasVendidas,
    s.Capacidad - COUNT(e.CodEntrada)         AS CupoDisponible,
    ef.Anio                                   AS EdicionAnio,
    ef.CodEdicion
FROM Proyecciones pr
JOIN Peliculas p            ON p.CodPelicula  = pr.CodPelicula
JOIN Salas s                ON s.CodSala      = pr.CodSala
JOIN Sedes sd               ON sd.CodSede     = s.CodSede
JOIN EdicionesFestivales ef ON ef.CodEdicion  = pr.CodEdicion
LEFT JOIN Entradas e        ON e.CodProyeccion = pr.CodProyeccion
GROUP BY
    pr.CodProyeccion, p.CodPelicula, p.Titulo, p.Duracion,
    pr.FechaHoraInicio, pr.FechaHoraFin, pr.SesionQa,
    s.CodSala, s.NombreSala, sd.NombreSede, s.Capacidad,
    ef.Anio, ef.CodEdicion;
GO

-- ----------------------------------------------------------
-- V3: Catalogo de tarifas (para la taquilla)
-- ----------------------------------------------------------
CREATE VIEW vw_TarifasActivas AS
SELECT
    CodTarifa,
    Nombre,
    Precio
FROM Tarifas;
GO

-- ----------------------------------------------------------
-- V4: Ranking de peliculas por edicion
-- Agrega asistentes reales y % de ocupacion a nivel pelicula
-- (suma de capacidades de todas sus proyecciones vs vendidas)
-- ----------------------------------------------------------
CREATE VIEW vw_RankingPeliculas AS
SELECT
    p.CodPelicula,
    p.Titulo,
    ef.Anio                                         AS EdicionAnio,
    ef.CodEdicion,
    COUNT(DISTINCT pr.CodProyeccion)                AS TotalProyecciones,
    ISNULL(SUM(sub.EntradasVendidas), 0)            AS TotalAsistentes,
    SUM(s.Capacidad)                                AS CapacidadTotal,
    CAST(
        ISNULL(SUM(sub.EntradasVendidas), 0) * 100.0
        / NULLIF(SUM(s.Capacidad), 0)
    AS DECIMAL(5,2))                                AS PctOcupacion
FROM Proyecciones pr
JOIN Peliculas p            ON p.CodPelicula = pr.CodPelicula
JOIN Salas s                ON s.CodSala     = pr.CodSala
JOIN EdicionesFestivales ef ON ef.CodEdicion = pr.CodEdicion
LEFT JOIN (
    SELECT CodProyeccion, COUNT(*) AS EntradasVendidas
    FROM Entradas
    WHERE CodProyeccion IS NOT NULL
    GROUP BY CodProyeccion
) sub ON sub.CodProyeccion = pr.CodProyeccion
GROUP BY p.CodPelicula, p.Titulo, ef.Anio, ef.CodEdicion;
GO

-- ----------------------------------------------------------
-- V5: Acta de premiacion con promedio de evaluaciones del jurado
-- ----------------------------------------------------------
CREATE VIEW vw_ActaPremiacion AS
SELECT
    ef.Anio                                   AS EdicionAnio,
    ef.CodEdicion,
    cc.NombreCategoria                        AS Categoria,
    pr.NombrePremio                           AS Premio,
    p.CodPelicula,
    p.Titulo,
    CAST(AVG(ev.Puntuacion) AS DECIMAL(4,2))  AS PromedioVotacion,
    COUNT(ev.CodEvaluacion)                   AS TotalVotos
FROM GanadoresPremios gp
JOIN Peliculas p              ON p.CodPelicula         = gp.CodPelicula
JOIN Premios pr               ON pr.CodPremio           = gp.CodPremio
JOIN CategoriasEdiciones ce   ON ce.CodCategoriaEdicion = gp.CodCategoriaEdicion
JOIN CategoriasCompeticion cc ON cc.CodCategoria        = ce.CodCategoria
JOIN EdicionesFestivales ef   ON ef.CodEdicion          = ce.CodEdicion
LEFT JOIN Evaluaciones ev     ON ev.CodPelicula         = gp.CodPelicula
                             AND ev.CodCategoriaEdicion  = gp.CodCategoriaEdicion
GROUP BY
    ef.Anio, ef.CodEdicion, cc.NombreCategoria,
    pr.NombrePremio, p.CodPelicula, p.Titulo;
GO

-- ----------------------------------------------------------
-- V6: Informe financiero desglosado por tipo de venta y tarifa
-- Para Entradas muestra la tarifa; para Abonos, el tipo de abono
-- ----------------------------------------------------------
CREATE VIEW vw_InformeFinanciero AS
SELECT
    pg.TipoVenta,
    CASE
        WHEN pg.TipoVenta = 'Entrada' THEN t.Nombre
        WHEN pg.TipoVenta = 'Abono'   THEN a.Nombre
        ELSE 'Desconocido'
    END                       AS TipoTarifa,
    COUNT(pg.CodPago)         AS CantidadTransacciones,
    SUM(pg.Monto)             AS TotalRecaudado
FROM Pagos pg
LEFT JOIN Entradas e       ON e.CodEntrada      = pg.CodEntrada
LEFT JOIN Tarifas t        ON t.CodTarifa       = e.CodTarifa
LEFT JOIN ComprasAbonos ca ON ca.CodCompraAbono = pg.CodCompraAbono
LEFT JOIN Abonos a         ON a.CodAbono        = ca.CodAbono
WHERE pg.EstadoPago = 'Completado'
GROUP BY
    pg.TipoVenta,
    CASE
        WHEN pg.TipoVenta = 'Entrada' THEN t.Nombre
        WHEN pg.TipoVenta = 'Abono'   THEN a.Nombre
        ELSE 'Desconocido'
    END;
GO

-- ============================================================
-- SECCIÓN 2: CONSULTAS DQL REQUERIDAS
-- ============================================================

-- ----------------------------------------------------------
-- DQL 1: Ranking de peliculas mas vistas - Edicion 2026
-- Muestra asistentes reales y % ocupacion de sala por pelicula
-- ----------------------------------------------------------
SELECT
    RANK() OVER (ORDER BY r.TotalAsistentes DESC, r.PctOcupacion DESC) AS Posicion,
    r.Titulo,
    r.TotalProyecciones,
    r.TotalAsistentes,
    r.CapacidadTotal,
    r.PctOcupacion
FROM vw_RankingPeliculas r
WHERE r.CodEdicion = 'edi_2026'
ORDER BY Posicion;
GO

-- ----------------------------------------------------------
-- DQL 2: Acta de premiacion edicion 2026
-- Peliculas ganadoras con promedio de votos del jurado
-- ----------------------------------------------------------
SELECT
    ap.Categoria,          -- era NombreCategoria
    ap.Premio,             -- era NombrePremio
    ap.Titulo,             -- era PeliculaGanadora (el VIEW tiene Titulo y CodPelicula)
    ap.PromedioVotacion,   -- era PromedioEvaluacion
    ap.TotalVotos
FROM vw_ActaPremiacion ap
WHERE ap.CodEdicion = 'edi_2026'
ORDER BY ap.Categoria;
GO
-- ----------------------------------------------------------
-- DQL 3: Informe financiero con subtotales y gran total
-- Desglose por tipo de venta (Entrada / Abono) y tipo de tarifa
-- ----------------------------------------------------------
SELECT
    TipoVenta,
    TipoTarifa,
    CantidadTransacciones,
    TotalRecaudado,
    SUM(TotalRecaudado) OVER (PARTITION BY TipoVenta) AS SubtotalTipoVenta,
    SUM(TotalRecaudado) OVER ()                        AS GrandTotal
FROM vw_InformeFinanciero
ORDER BY TipoVenta, TotalRecaudado DESC;
GO

-- ============================================================
-- SECCIÓN 3: PROCEDIMIENTOS ALMACENADOS
-- ============================================================

-- ----------------------------------------------------------
-- P1: sp_ComprarEntrada
-- Registra la compra de una entrada individual.
-- Verifica aforo disponible antes de insertar.
-- Lanza error descriptivo si la sala esta llena
-- (el cliente ASP.NET captura el SqlException y lo muestra
--  como mensaje amigable en la interfaz).
-- ----------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_ComprarEntrada
    @CodAsistente  CHAR(20),
    @CodProyeccion CHAR(20),
    @CodTarifa     CHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Capacidad  INT;
    DECLARE @Vendidas   INT;
    DECLARE @Precio     DECIMAL(10,2);
    DECLARE @CodEntrada CHAR(20);
    DECLARE @CodPago    CHAR(20);

    -- Obtener capacidad de la sala vinculada a esta proyeccion
    SELECT @Capacidad = s.Capacidad
    FROM Proyecciones pr
    JOIN Salas s ON s.CodSala = pr.CodSala
    WHERE pr.CodProyeccion = @CodProyeccion;

    IF @Capacidad IS NULL
    BEGIN
        RAISERROR('La proyeccion especificada no existe.', 16, 1);
        RETURN;
    END;

    -- Contar entradas individuales ya emitidas para esta proyeccion
    SELECT @Vendidas = COUNT(*)
    FROM Entradas
    WHERE CodProyeccion = @CodProyeccion;

    IF @Vendidas >= @Capacidad
    BEGIN
        RAISERROR('Lo sentimos, no hay aforo disponible para esta funcion.', 16, 1);
        RETURN;
    END;

    -- Obtener precio de la tarifa
    SELECT @Precio = Precio
    FROM Tarifas
    WHERE CodTarifa = @CodTarifa;

    IF @Precio IS NULL
    BEGIN
        RAISERROR('La tarifa especificada no existe.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Asistentes WHERE CodAsistente = @CodAsistente)
    BEGIN
        RAISERROR('El asistente especificado no existe.', 16, 1);
        RETURN;
    END;

    -- Generar codigos unicos usando NEWID() truncado a CHAR(20)
    SET @CodEntrada = LEFT('e_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);
    SET @CodPago    = LEFT('p_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO Entradas
                (CodEntrada, FechaCompra, PrecioPagado, CodAsistente, CodTarifa, CodProyeccion, CodEvento)
            VALUES
                (@CodEntrada, CAST(GETDATE() AS DATE), @Precio, @CodAsistente, @CodTarifa, @CodProyeccion, NULL);

            INSERT INTO Pagos
                (CodPago, FechaPago, Monto, MetodoPago, EstadoPago, TipoVenta, CodEntrada, CodCompraAbono)
            VALUES
                (@CodPago, GETDATE(), @Precio, 'Sistema-Taquilla', 'Completado', 'Entrada', @CodEntrada, NULL);

        COMMIT TRANSACTION;

        SELECT
            @CodEntrada AS CodEntrada,
            @Precio     AS PrecioPagado,
            'Entrada adquirida exitosamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err1 VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR(@Err1, 16, 1);
    END CATCH;
END;
GO

-- ----------------------------------------------------------
-- T1: sp_VenderAbono
-- Venta atomica de un abono.
-- Los tres pasos (ComprasAbonos + CodigosAcceso + Pagos)
-- ocurren dentro de una unica transaccion:
--   si cualquier paso falla → ROLLBACK completo.
-- ----------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_VenderAbono
    @CodAsistente CHAR(20),
    @CodAbono     CHAR(20),
    @MetodoPago   VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PrecioAbono    DECIMAL(10,2);
    DECLARE @CodCompraAbono CHAR(20);
    DECLARE @CodAcceso      CHAR(20);
    DECLARE @CodigoGenerado VARCHAR(100);
    DECLARE @CodPago        CHAR(20);

    -- Validaciones previas a la transaccion (fallo rapido sin abrir TXN)
    SELECT @PrecioAbono = Precio FROM Abonos WHERE CodAbono = @CodAbono;

    IF @PrecioAbono IS NULL
    BEGIN
        RAISERROR('El abono especificado no existe.', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Asistentes WHERE CodAsistente = @CodAsistente)
    BEGIN
        RAISERROR('El asistente especificado no existe.', 16, 1);
        RETURN;
    END;

    -- Generar identificadores unicos para los tres registros atomicos
    SET @CodCompraAbono = LEFT('ca_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);
    SET @CodAcceso      = LEFT('ac_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);
    SET @CodPago        = LEFT('pa_' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);
    -- Codigo de acceso legible: prefijo + asistente + año + 8 chars aleatorios
    SET @CodigoGenerado = 'ACC-' + RTRIM(@CodAsistente) + '-'
                        + CAST(YEAR(GETDATE()) AS VARCHAR(4)) + '-'
                        + LEFT(REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 8);

    BEGIN TRY
        BEGIN TRANSACTION;

            -- Paso 1: registrar la compra (simula pasarela de pago exitosa)
            INSERT INTO ComprasAbonos
                (CodCompraAbono, FechaCompra, PrecioPagado, MetodoPago, EstadoPago, CodAsistente, CodAbono)
            VALUES
                (@CodCompraAbono, CAST(GETDATE() AS DATE), @PrecioAbono,
                 @MetodoPago, 'Completado', @CodAsistente, @CodAbono);

            -- Paso 2: generar el codigo de acceso fisico/digital
            INSERT INTO CodigosAcceso
                (CodAcceso, CodCompraAbono, CodigoGenerado, FechaGeneracion, Usado)
            VALUES
                (@CodAcceso, @CodCompraAbono, @CodigoGenerado, GETDATE(), 0);

            -- Paso 3: emitir la factura (registro de pago)
            INSERT INTO Pagos
                (CodPago, FechaPago, Monto, MetodoPago, EstadoPago, TipoVenta, CodEntrada, CodCompraAbono)
            VALUES
                (@CodPago, GETDATE(), @PrecioAbono, @MetodoPago,
                 'Completado', 'Abono', NULL, @CodCompraAbono);

        COMMIT TRANSACTION;

        SELECT
            @CodCompraAbono AS CodCompraAbono,
            @CodigoGenerado AS CodigoAcceso,
            @PrecioAbono    AS MontoPagado,
            'Abono vendido exitosamente. Guarde su codigo de acceso.' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err2 VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR(@Err2, 16, 1);
    END CATCH;
END;
GO

-- ============================================================
-- SECCIÓN 4: TRIGGER
-- ============================================================

-- ----------------------------------------------------------
-- TR1: trg_ControlAgenda_Proyecciones
-- INSTEAD OF INSERT (equivalente a BEFORE INSERT en SQL Server).
-- Bloquea la insercion si la sala ya esta ocupada por otra
-- proyeccion o evento paralelo, considerando +30 min de
-- limpieza al final de cada evento existente.
--
-- Formula de conflicto (overlap estandar con buffer):
--   nuevoInicio < existenteFin + 30min
--   AND existenteInicio < nuevoFin + 30min
--
-- Uso de cursor: soporta INSERT de multiples filas en un batch.
-- El INSERT dentro del trigger no dispara el trigger de nuevo
-- (comportamiento estandar de INSTEAD OF en SQL Server).
-- ----------------------------------------------------------
CREATE OR ALTER TRIGGER trg_ControlAgenda_Proyecciones
ON Proyecciones
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CodProyeccion   CHAR(20);
    DECLARE @FechaHoraInicio DATETIME2(0);
    DECLARE @FechaHoraFin    DATETIME2(0);
    DECLARE @SesionQa        VARCHAR(255);
    DECLARE @CodPelicula     CHAR(20);
    DECLARE @CodSala         CHAR(20);
    DECLARE @CodEdicion      CHAR(20);

    DECLARE @FinConBuffer    DATETIME2(0);
    DECLARE @Conflictos      INT;
    DECLARE @NombreSala      VARCHAR(255);
    DECLARE @MsgError        VARCHAR(500);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT CodProyeccion, FechaHoraInicio, FechaHoraFin,
               SesionQa, CodPelicula, CodSala, CodEdicion
        FROM INSERTED;

    OPEN cur;
    FETCH NEXT FROM cur
        INTO @CodProyeccion, @FechaHoraInicio, @FechaHoraFin,
             @SesionQa, @CodPelicula, @CodSala, @CodEdicion;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Calcular el fin del bloqueo para la nueva proyeccion
        SET @FinConBuffer = DATEADD(MINUTE, 30, @FechaHoraFin);

        SELECT @NombreSala = NombreSala FROM Salas WHERE CodSala = @CodSala;

        -- ► Conflicto con otras PROYECCIONES en la misma sala
        SELECT @Conflictos = COUNT(*)
        FROM Proyecciones pr
        WHERE pr.CodSala = @CodSala
          AND @FechaHoraInicio < DATEADD(MINUTE, 30, pr.FechaHoraFin)
          AND pr.FechaHoraInicio < @FinConBuffer;

        IF @Conflictos > 0
        BEGIN
            SET @MsgError = 'Conflicto de agenda: la sala "' + ISNULL(@NombreSala, @CodSala)
                + '" ya tiene una proyeccion programada en ese horario'
                + ' (considere los 30 min de limpieza).';
            CLOSE cur; DEALLOCATE cur;
            RAISERROR(@MsgError, 16, 1);
            RETURN;
        END;

        -- ► Conflicto con EVENTOS PARALELOS en la misma sala
        SELECT @Conflictos = COUNT(*)
        FROM EventosParalelos ep
        WHERE ep.CodSala = @CodSala
          AND @FechaHoraInicio < DATEADD(MINUTE, 30, ep.FechaHoraFin)
          AND ep.FechaHoraInicio < @FinConBuffer;

        IF @Conflictos > 0
        BEGIN
            SET @MsgError = 'Conflicto de agenda: la sala "' + ISNULL(@NombreSala, @CodSala)
                + '" ya tiene un evento paralelo programado en ese horario'
                + ' (considere los 30 min de limpieza).';
            CLOSE cur; DEALLOCATE cur;
            RAISERROR(@MsgError, 16, 1);
            RETURN;
        END;

        -- Sin conflicto: realizar el INSERT real en la tabla
        INSERT INTO Proyecciones
            (CodProyeccion, FechaHoraInicio, FechaHoraFin, SesionQa,
             CodPelicula, CodSala, CodEdicion)
        VALUES
            (@CodProyeccion, @FechaHoraInicio, @FechaHoraFin, @SesionQa,
             @CodPelicula, @CodSala, @CodEdicion);

        FETCH NEXT FROM cur
            INTO @CodProyeccion, @FechaHoraInicio, @FechaHoraFin,
                 @SesionQa, @CodPelicula, @CodSala, @CodEdicion;
    END;

    CLOSE cur;
    DEALLOCATE cur;
END;
GO

-- ============================================================
-- SECCIÓN 5: SCRIPTS DE PRUEBA Y DEMOSTRACION
-- ============================================================

-- ► Verificar las vistas
SELECT * FROM vw_PeliculasCartelera;
GO
SELECT * FROM vw_ProyeccionesDisponibles WHERE CodEdicion = 'edi_2026' ORDER BY FechaHoraInicio;
GO
SELECT * FROM vw_TarifasActivas;
GO

-- ► P1 Demo A: compra exitosa (proy_01 sala_01 cap.100, solo 4 vendidas → exito)
EXEC sp_ComprarEntrada 'asis_14', 'proy_01', 'tar_01';
GO

-- ► P1 Demo B: sala llena (proy_13 sala_08 cap.3, ya tiene 3 entradas → ERROR)
-- Mensaje esperado: "Lo sentimos, no hay aforo disponible para esta funcion."
EXEC sp_ComprarEntrada 'asis_14', 'proy_13', 'tar_01';
GO

-- ► T1 Demo: venta atomica de abono (3 inserts en una transaccion)
EXEC sp_VenderAbono 'asis_15', 'abo_02', 'Tarjeta Credito';
GO

-- ► TR1 Demo A: insercion valida (sala_06 libre el 22/08/2026 a las 09:00)
INSERT INTO Proyecciones
    (CodProyeccion, FechaHoraInicio, FechaHoraFin, SesionQa, CodPelicula, CodSala, CodEdicion)
VALUES
    ('proy_test1', '2026-08-22 09:00:00', '2026-08-22 11:00:00',
     NULL, 'pel_01', 'sala_06', 'edi_2026');
GO

-- ► TR1 Demo B: conflicto por buffer de limpieza (ERROR esperado)
-- proy_06 ocupa sala_06 hasta las 21:00 el 21/08.
-- Este intento a las 21:20 cae dentro del buffer de 30 min → BLOQUEADO.
-- Verificacion: 21:20 < (21:00 + 30min = 21:30) → conflicto detectado.
INSERT INTO Proyecciones
    (CodProyeccion, FechaHoraInicio, FechaHoraFin, SesionQa, CodPelicula, CodSala, CodEdicion)
VALUES
    ('proy_test2', '2026-08-21 21:20:00', '2026-08-21 23:00:00',
     NULL, 'pel_02', 'sala_06', 'edi_2026');
GO

-- Limpieza del dato de prueba valido
DELETE FROM Proyecciones WHERE CodProyeccion = 'proy_test1';
GO
