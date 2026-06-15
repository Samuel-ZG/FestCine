-- ============================================================
-- FestCine - Migración: Tarifas↔Asientos, Promoción miércoles,
-- columnas de descuento en Entradas e Informe financiero en 2 vistas.
-- Ejecutar sobre la base de datos FestCine existente.
-- Idempotente: verifica existencia antes de crear/alterar.
-- ============================================================

-- SET options requeridos por SQL Server para crear columnas calculadas PERSISTED.
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

-- ============================================================
-- SECCIÓN 1: Tarifas.CategoriaAsiento + vw_TarifasActivas
-- ============================================================

-- PASO 1: Columna CategoriaAsiento en Tarifas
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Tarifas') AND name = 'CategoriaAsiento')
BEGIN
    ALTER TABLE Tarifas ADD CategoriaAsiento VARCHAR(20) NULL;
    PRINT 'Columna CategoriaAsiento agregada a Tarifas.';
END
ELSE
    PRINT 'Columna CategoriaAsiento ya existe en Tarifas, se omite.';
GO

-- PASO 2: Clasificación de tarifas existentes (idempotente)
-- Entrada General, Estudiante, 3ra Edad y Preventa Anticipada -> asientos Estandar
UPDATE Tarifas SET CategoriaAsiento = 'Estandar'
WHERE CodTarifa IN ('tar_01', 'tar_02', 'tar_03', 'tar_05');

-- Acceso VIP -> solo asientos VIP
UPDATE Tarifas SET CategoriaAsiento = 'VIP'
WHERE CodTarifa = 'tar_04';

-- Gratuita Acreditados -> cualquier categoría de asiento
UPDATE Tarifas SET CategoriaAsiento = 'Ambas'
WHERE CodTarifa = 'tar_07';

-- Promocion 2x1 -> tarifa legado, sin categoría, oculta de vw_TarifasActivas
UPDATE Tarifas
SET CategoriaAsiento = NULL,
    Nombre = 'Promocion 2x1 (legado, no disponible)'
WHERE CodTarifa = 'tar_06';

PRINT 'CategoriaAsiento clasificada para tarifas existentes.';
GO

-- PASO 3: Vista vw_TarifasActivas (incluye CategoriaAsiento, excluye tarifas legado)
IF OBJECT_ID('vw_TarifasActivas', 'V') IS NOT NULL
    DROP VIEW vw_TarifasActivas;
GO

CREATE VIEW vw_TarifasActivas AS
SELECT
    CodTarifa,
    Nombre,
    Precio,
    CategoriaAsiento
FROM Tarifas
WHERE CategoriaAsiento IS NOT NULL;
GO

PRINT '=== Sección 1 completada ===';

-- ============================================================
-- SECCIÓN 2: Descuentos en Entradas + Promoción "Miércoles 50%"
-- ============================================================

-- PASO 1: Columnas PrecioOriginal y EsPromoAplicada en Entradas
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Entradas') AND name = 'PrecioOriginal')
BEGIN
    ALTER TABLE Entradas ADD PrecioOriginal DECIMAL(10,2) NULL;
    PRINT 'Columna PrecioOriginal agregada a Entradas.';
END
ELSE
    PRINT 'Columna PrecioOriginal ya existe en Entradas, se omite.';
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Entradas') AND name = 'EsPromoAplicada')
BEGIN
    ALTER TABLE Entradas ADD EsPromoAplicada BIT NOT NULL CONSTRAINT DF_Entradas_EsPromo DEFAULT 0;
    PRINT 'Columna EsPromoAplicada agregada a Entradas.';
END
ELSE
    PRINT 'Columna EsPromoAplicada ya existe en Entradas, se omite.';
GO

-- Backfill idempotente: filas históricas sin PrecioOriginal -> = PrecioPagado (descuento 0)
UPDATE Entradas SET PrecioOriginal = PrecioPagado WHERE PrecioOriginal IS NULL;
PRINT 'Backfill de PrecioOriginal completado.';
GO

-- PASO 2: Columna calculada DescuentoAplicado (PrecioOriginal - PrecioPagado)
-- ISNULL por seguridad ante datos historicos donde PrecioOriginal pudiera quedar NULL.
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Entradas') AND name = 'DescuentoAplicado')
BEGIN
    ALTER TABLE Entradas ADD DescuentoAplicado AS (ISNULL(PrecioOriginal, PrecioPagado) - PrecioPagado) PERSISTED;
    PRINT 'Columna calculada DescuentoAplicado agregada a Entradas.';
END
ELSE
    PRINT 'Columna DescuentoAplicado ya existe en Entradas, se omite.';
GO

-- ============================================================
-- PASO 3: sp_ComprarEntradasMultiples (validaciones completas + promo)
-- ============================================================
IF OBJECT_ID('sp_ComprarEntradasMultiples', 'P') IS NOT NULL
    DROP PROCEDURE sp_ComprarEntradasMultiples;
GO

CREATE PROCEDURE sp_ComprarEntradasMultiples
    @Nombres       VARCHAR(255),
    @Apellidos     VARCHAR(255),
    @Email         VARCHAR(255),
    @Telefono      VARCHAR(20)  = NULL,
    @CodProyeccion CHAR(20),
    @CodTarifa     CHAR(20),
    @ListaAsientos VARCHAR(MAX)   -- CSV: 'asi_01_A01,asi_01_A02'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CodAsistente    CHAR(20);
    DECLARE @PrecioTarifa    DECIMAL(10,2);
    DECLARE @CategoriaTarifa VARCHAR(20);
    DECLARE @Capacidad       INT;
    DECLARE @Vendidas        INT;
    DECLARE @NumAsientos     INT;
    DECLARE @NumDistintos    INT;
    DECLARE @CodAsiento      VARCHAR(20);
    DECLARE @TipoAsiento     VARCHAR(50);
    DECLARE @CodEntrada      CHAR(20);
    DECLARE @CodPago         CHAR(20);
    DECLARE @CodVal          VARCHAR(50);

    -- Promo "Miercoles 50%": ajustar estas constantes si cambia la regla.
    -- Aplica unicamente a Entrada General (tar_01), miercoles 10:00-18:00.
    DECLARE @DiaPromoISO     TINYINT      = 3;          -- ISO 1=Lunes..7=Domingo. 3=Miercoles
    DECLARE @HoraPromoInicio TIME         = '10:00:00';
    DECLARE @HoraPromoFin    TIME         = '18:00:00';
    DECLARE @PorcentajePromo DECIMAL(5,2) = 50.0;
    DECLARE @CodTarifaPromo  VARCHAR(10)  = 'tar_01';   -- Entrada General unicamente

    DECLARE @Ahora     DATETIME2(0) = GETDATE();
    DECLARE @DiaHoyISO TINYINT      = ((DATEPART(WEEKDAY,@Ahora)+@@DATEFIRST-2)%7)+1;
    DECLARE @HoraHoy   TIME         = CAST(@Ahora AS TIME);
    DECLARE @EsPromo   BIT;
    DECLARE @PrecioFinal DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Buscar o crear Asistente por Email
        SELECT @CodAsistente = CodAsistente
        FROM Asistentes WHERE Email = @Email;

        IF @CodAsistente IS NULL
        BEGIN
            SET @CodAsistente = LEFT('asis_' + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);
            INSERT INTO Asistentes (CodAsistente, Nombres, Apellidos, Email, Telefono)
            VALUES (@CodAsistente, @Nombres, @Apellidos, @Email, @Telefono);
        END;

        -- 2. Tarifa: precio de lista y categoria de asiento compatible
        SELECT @PrecioTarifa = Precio, @CategoriaTarifa = CategoriaAsiento
        FROM Tarifas WHERE CodTarifa = @CodTarifa;

        IF @PrecioTarifa IS NULL
            RAISERROR('La tarifa especificada no existe.', 16, 1);

        IF @CategoriaTarifa IS NULL
            RAISERROR('La tarifa especificada no esta disponible para venta.', 16, 1);

        -- 3. Proyeccion y aforo
        SELECT @Capacidad = s.Capacidad
        FROM Proyecciones pr JOIN Salas s ON s.CodSala = pr.CodSala
        WHERE pr.CodProyeccion = @CodProyeccion;

        IF @Capacidad IS NULL
            RAISERROR('La proyeccion especificada no existe.', 16, 1);

        SELECT @Vendidas    = COUNT(*) FROM Entradas WHERE CodProyeccion = @CodProyeccion;
        SELECT @NumAsientos  = COUNT(*)               FROM STRING_SPLIT(@ListaAsientos, ',') WHERE TRIM(value) <> '';
        SELECT @NumDistintos = COUNT(DISTINCT TRIM(value)) FROM STRING_SPLIT(@ListaAsientos, ',') WHERE TRIM(value) <> '';

        -- 4. Validaciones de la lista de asientos
        IF @NumAsientos = 0
            RAISERROR('Debe seleccionar al menos un asiento.', 16, 1);

        IF @NumAsientos <> @NumDistintos
            RAISERROR('La lista de asientos contiene asientos duplicados.', 16, 1);

        IF (@Vendidas + @NumAsientos) > @Capacidad
            RAISERROR('No hay suficiente aforo para la cantidad de asientos solicitados.', 16, 1);

        -- 5. Promocion "Miercoles 50%" (una sola vez, aplica a toda la compra)
        SET @EsPromo = CASE WHEN @DiaHoyISO = @DiaPromoISO
                              AND @HoraHoy >= @HoraPromoInicio AND @HoraHoy < @HoraPromoFin
                              AND @CodTarifa = @CodTarifaPromo
                             THEN 1 ELSE 0 END;

        SET @PrecioFinal = CASE WHEN @EsPromo = 1
                                 THEN ROUND(@PrecioTarifa * (1 - @PorcentajePromo/100.0), 2)
                                 ELSE @PrecioTarifa END;

        -- 6. Tabla temporal de resultados
        CREATE TABLE #EntradasGen (
            CodEntrada       CHAR(20),
            CodAsiento       CHAR(20),
            Fila             CHAR(2),
            Numero           INT,
            CodigoValidacion VARCHAR(50),
            PrecioPagado     DECIMAL(10,2),
            PrecioOriginal   DECIMAL(10,2),
            EsPromoAplicada  BIT
        );

        -- 7. Procesar cada asiento: existe, pertenece a la sala, libre y compatible con la tarifa
        DECLARE curA CURSOR LOCAL FAST_FORWARD FOR
            SELECT TRIM(value) FROM STRING_SPLIT(@ListaAsientos, ',') WHERE TRIM(value) <> '';
        OPEN curA;
        FETCH NEXT FROM curA INTO @CodAsiento;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SELECT @TipoAsiento = a.TipoAsiento
            FROM Asientos a
            WHERE a.CodAsiento = @CodAsiento AND a.Activo = 1;

            IF @TipoAsiento IS NULL
                RAISERROR('El asiento "%s" no existe.', 16, 1, @CodAsiento);

            IF NOT EXISTS (
                SELECT 1 FROM Asientos a
                JOIN Proyecciones pr ON pr.CodSala = a.CodSala
                WHERE a.CodAsiento = @CodAsiento AND pr.CodProyeccion = @CodProyeccion
            )
                RAISERROR('El asiento "%s" no pertenece a la sala de esta funcion.', 16, 1, @CodAsiento);

            IF EXISTS (
                SELECT 1 FROM Entradas
                WHERE CodProyeccion = @CodProyeccion AND CodAsiento = @CodAsiento
            )
                RAISERROR('El asiento "%s" ya fue tomado. Seleccione otro.', 16, 1, @CodAsiento);

            IF @CategoriaTarifa <> 'Ambas' AND @TipoAsiento <> @CategoriaTarifa
                RAISERROR('El asiento "%s" (tipo %s) no es compatible con la tarifa seleccionada.', 16, 1, @CodAsiento, @TipoAsiento);

            SET @CodEntrada = LEFT('e_'   + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);
            SET @CodPago    = LEFT('p_'   + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);
            SET @CodVal     = LEFT('VAL-' + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);

            INSERT INTO Entradas
                (CodEntrada, FechaCompra, PrecioPagado, PrecioOriginal, EsPromoAplicada, CodAsistente,
                 CodTarifa, CodProyeccion, CodEvento, CodAsiento, CodigoValidacion)
            VALUES
                (@CodEntrada, CAST(GETDATE() AS DATE), @PrecioFinal, @PrecioTarifa, @EsPromo, @CodAsistente,
                 @CodTarifa, @CodProyeccion, NULL, @CodAsiento, @CodVal);

            INSERT INTO Pagos
                (CodPago, FechaPago, Monto, MetodoPago, EstadoPago, TipoVenta, CodEntrada, CodCompraAbono)
            VALUES
                (@CodPago, GETDATE(), @PrecioFinal, 'Online', 'Completado', 'Entrada', @CodEntrada, NULL);

            INSERT INTO #EntradasGen (CodEntrada, CodAsiento, Fila, Numero, CodigoValidacion, PrecioPagado, PrecioOriginal, EsPromoAplicada)
            SELECT @CodEntrada, a.CodAsiento, a.Fila, a.Numero, @CodVal, @PrecioFinal, @PrecioTarifa, @EsPromo
            FROM Asientos a WHERE a.CodAsiento = @CodAsiento;

            FETCH NEXT FROM curA INTO @CodAsiento;
        END;
        CLOSE curA; DEALLOCATE curA;

        -- ResultSet 1: entradas generadas
        SELECT CodEntrada, CodAsiento, Fila, Numero, CodigoValidacion, PrecioPagado, PrecioOriginal, EsPromoAplicada FROM #EntradasGen;

        -- ResultSet 2: info del asistente
        SELECT CodAsistente, Nombres, Apellidos, Email FROM Asistentes WHERE CodAsistente = @CodAsistente;

        COMMIT TRANSACTION;
        DROP TABLE #EntradasGen;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        IF CURSOR_STATUS('global','curA') >= 0 BEGIN CLOSE curA; DEALLOCATE curA; END;
        IF OBJECT_ID('tempdb..#EntradasGen') IS NOT NULL DROP TABLE #EntradasGen;
        DECLARE @ErrMsg NVARCHAR(2048) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg, 16, 1);
    END CATCH;
END;
GO

-- ============================================================
-- PASO 4: sp_ComprarEntrada (compra individual - requisito P1)
-- CREATE OR ALTER para alinearlo con la categoria de tarifa y la
-- promocion "Miercoles 50%" (mismas constantes que la version multiple).
-- ============================================================
CREATE OR ALTER PROCEDURE sp_ComprarEntrada
    @CodAsistente  CHAR(20),
    @CodProyeccion CHAR(20),
    @CodTarifa     CHAR(20),
    @CodAsiento    CHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Capacidad        INT;
    DECLARE @Vendidas         INT;
    DECLARE @PrecioTarifa     DECIMAL(10,2);
    DECLARE @CategoriaTarifa  VARCHAR(20);
    DECLARE @TipoAsiento      VARCHAR(50);
    DECLARE @CodEntrada       CHAR(20);
    DECLARE @CodPago          CHAR(20);
    DECLARE @CodigoValidacion VARCHAR(50);

    -- Promo "Miercoles 50%": mismas constantes que sp_ComprarEntradasMultiples
    DECLARE @DiaPromoISO     TINYINT      = 3;
    DECLARE @HoraPromoInicio TIME         = '10:00:00';
    DECLARE @HoraPromoFin    TIME         = '18:00:00';
    DECLARE @PorcentajePromo DECIMAL(5,2) = 50.0;
    DECLARE @CodTarifaPromo  VARCHAR(10)  = 'tar_01';

    DECLARE @Ahora     DATETIME2(0) = GETDATE();
    DECLARE @DiaHoyISO TINYINT      = ((DATEPART(WEEKDAY,@Ahora)+@@DATEFIRST-2)%7)+1;
    DECLARE @HoraHoy   TIME         = CAST(@Ahora AS TIME);
    DECLARE @EsPromo   BIT;
    DECLARE @PrecioFinal DECIMAL(10,2);

    SELECT @Capacidad = s.Capacidad
    FROM Proyecciones pr
    JOIN Salas s ON s.CodSala = pr.CodSala
    WHERE pr.CodProyeccion = @CodProyeccion;

    IF @Capacidad IS NULL
    BEGIN
        RAISERROR('La proyeccion especificada no existe.', 16, 1); RETURN;
    END;

    SELECT @Vendidas = COUNT(*) FROM Entradas WHERE CodProyeccion = @CodProyeccion;

    IF @Vendidas >= @Capacidad
    BEGIN
        RAISERROR('Lo sentimos, no hay aforo disponible para esta funcion.', 16, 1); RETURN;
    END;

    SELECT @PrecioTarifa = Precio, @CategoriaTarifa = CategoriaAsiento
    FROM Tarifas WHERE CodTarifa = @CodTarifa;

    IF @PrecioTarifa IS NULL
    BEGIN
        RAISERROR('La tarifa especificada no existe.', 16, 1); RETURN;
    END;

    IF @CategoriaTarifa IS NULL
    BEGIN
        RAISERROR('La tarifa especificada no esta disponible para venta.', 16, 1); RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Asistentes WHERE CodAsistente = @CodAsistente)
    BEGIN
        RAISERROR('El asistente especificado no existe.', 16, 1); RETURN;
    END;

    IF @CodAsiento IS NOT NULL
    BEGIN
        SELECT @TipoAsiento = a.TipoAsiento
        FROM Asientos a
        JOIN Proyecciones pr ON pr.CodSala = a.CodSala
        WHERE a.CodAsiento = @CodAsiento AND pr.CodProyeccion = @CodProyeccion AND a.Activo = 1;

        IF @TipoAsiento IS NULL
        BEGIN
            RAISERROR('El asiento no pertenece a esta funcion.', 16, 1); RETURN;
        END;

        IF EXISTS (
            SELECT 1 FROM Entradas WHERE CodProyeccion = @CodProyeccion AND CodAsiento = @CodAsiento
        )
        BEGIN
            RAISERROR('El asiento seleccionado ya esta ocupado. Elija otro.', 16, 1); RETURN;
        END;

        IF @CategoriaTarifa <> 'Ambas' AND @TipoAsiento <> @CategoriaTarifa
        BEGIN
            RAISERROR('El asiento no es compatible con la tarifa seleccionada.', 16, 1); RETURN;
        END;
    END;

    -- Promocion "Miercoles 50%" (depende de la tarifa, no del asiento)
    SET @EsPromo = CASE WHEN @DiaHoyISO = @DiaPromoISO
                          AND @HoraHoy >= @HoraPromoInicio AND @HoraHoy < @HoraPromoFin
                          AND @CodTarifa = @CodTarifaPromo
                         THEN 1 ELSE 0 END;

    SET @PrecioFinal = CASE WHEN @EsPromo = 1
                             THEN ROUND(@PrecioTarifa * (1 - @PorcentajePromo/100.0), 2)
                             ELSE @PrecioTarifa END;

    SET @CodEntrada       = LEFT('e_'   + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);
    SET @CodPago          = LEFT('p_'   + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);
    SET @CodigoValidacion = LEFT('VAL-' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO Entradas
                (CodEntrada, FechaCompra, PrecioPagado, PrecioOriginal, EsPromoAplicada, CodAsistente,
                 CodTarifa, CodProyeccion, CodEvento, CodAsiento, CodigoValidacion)
            VALUES
                (@CodEntrada, CAST(GETDATE() AS DATE), @PrecioFinal, @PrecioTarifa, @EsPromo, @CodAsistente,
                 @CodTarifa, @CodProyeccion, NULL, @CodAsiento, @CodigoValidacion);

            INSERT INTO Pagos
                (CodPago, FechaPago, Monto, MetodoPago, EstadoPago, TipoVenta, CodEntrada, CodCompraAbono)
            VALUES
                (@CodPago, GETDATE(), @PrecioFinal, 'Sistema-Taquilla', 'Completado', 'Entrada', @CodEntrada, NULL);

        COMMIT TRANSACTION;

        SELECT
            @CodEntrada       AS CodEntrada,
            @PrecioFinal      AS PrecioPagado,
            @PrecioTarifa     AS PrecioOriginal,
            @EsPromo          AS EsPromoAplicada,
            @CodigoValidacion AS CodigoValidacion,
            'Entrada adquirida exitosamente.' AS Mensaje;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err1 VARCHAR(500) = ERROR_MESSAGE();
        RAISERROR(@Err1, 16, 1);
    END CATCH;
END;
GO

PRINT '=== Sección 2 completada ===';

-- ============================================================
-- SECCIÓN 3: Informe financiero en 2 vistas
-- No se elimina vw_InformeFinanciero (queda como vista legada,
-- referenciada por la consulta DQL 3 y la documentación).
-- ============================================================

IF OBJECT_ID('vw_InformeFinancieroPorTipoVenta', 'V') IS NOT NULL
    DROP VIEW vw_InformeFinancieroPorTipoVenta;
GO

-- Tabla 1: por tipo de venta (Entrada / Abono) - bruto, descuento, neto
CREATE VIEW vw_InformeFinancieroPorTipoVenta AS
SELECT
    pg.TipoVenta,
    COUNT(pg.CodPago) AS CantidadVendida,
    SUM(CASE WHEN pg.TipoVenta='Entrada' THEN ISNULL(e.PrecioOriginal, pg.Monto) ELSE pg.Monto END) AS MontoBruto,
    SUM(CASE WHEN pg.TipoVenta='Entrada' THEN ISNULL(e.PrecioOriginal, pg.Monto) - ISNULL(e.PrecioPagado, pg.Monto) ELSE 0 END) AS DescuentoTotal,
    SUM(pg.Monto) AS TotalRecaudado
FROM Pagos pg
LEFT JOIN Entradas e ON e.CodEntrada = pg.CodEntrada
WHERE pg.EstadoPago = 'Completado'
GROUP BY pg.TipoVenta;
GO

IF OBJECT_ID('vw_InformeFinancieroPorTarifa', 'V') IS NOT NULL
    DROP VIEW vw_InformeFinancieroPorTarifa;
GO

-- Tabla 2: por tarifa, separando ventas con promo miercoles como fila distinta
CREATE VIEW vw_InformeFinancieroPorTarifa AS
SELECT
    CASE
        WHEN pg.TipoVenta='Entrada' AND e.EsPromoAplicada=1 THEN t.Nombre + ' - Promo miercoles 50%'
        WHEN pg.TipoVenta='Entrada' THEN t.Nombre
        WHEN pg.TipoVenta='Abono'   THEN a.Nombre
        ELSE 'Desconocido'
    END AS Concepto,
    pg.TipoVenta,
    ISNULL(e.EsPromoAplicada,0) AS EsPromoAplicada,
    COUNT(pg.CodPago) AS CantidadVendida,
    SUM(ISNULL(e.PrecioOriginal, pg.Monto)) AS MontoOriginal,
    SUM(ISNULL(e.PrecioOriginal, pg.Monto) - pg.Monto) AS DescuentoAplicado,
    SUM(pg.Monto) AS TotalRecaudado
FROM Pagos pg
LEFT JOIN Entradas e       ON e.CodEntrada      = pg.CodEntrada
LEFT JOIN Tarifas t        ON t.CodTarifa       = e.CodTarifa
LEFT JOIN ComprasAbonos ca ON ca.CodCompraAbono = pg.CodCompraAbono
LEFT JOIN Abonos a         ON a.CodAbono        = ca.CodAbono
WHERE pg.EstadoPago = 'Completado'
GROUP BY
    CASE WHEN pg.TipoVenta='Entrada' AND e.EsPromoAplicada=1 THEN t.Nombre + ' - Promo miercoles 50%'
         WHEN pg.TipoVenta='Entrada' THEN t.Nombre
         WHEN pg.TipoVenta='Abono'   THEN a.Nombre
         ELSE 'Desconocido' END,
    pg.TipoVenta, ISNULL(e.EsPromoAplicada,0);
GO

PRINT '=== Sección 3 completada ===';
