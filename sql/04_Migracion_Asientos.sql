-- ============================================================
-- FestCine - Migración: Tabla Asientos + Compra Múltiple
-- Ejecutar sobre la base de datos FestCine existente.
-- Idempotente: verifica existencia antes de crear/alterar.
-- ============================================================

-- ============================================================
-- PASO 1: TABLA Asientos
-- ============================================================
IF OBJECT_ID('Asientos', 'U') IS NULL
BEGIN
    CREATE TABLE Asientos (
        CodAsiento  CHAR(20)    NOT NULL,
        CodSala     CHAR(20)    NOT NULL,
        Fila        CHAR(2)     NOT NULL,
        Numero      INT         NOT NULL,
        TipoAsiento VARCHAR(50) NOT NULL CONSTRAINT DF_Asientos_Tipo   DEFAULT 'Estandar',
        Activo      BIT         NOT NULL CONSTRAINT DF_Asientos_Activo DEFAULT 1,
        CONSTRAINT PK_Asientos PRIMARY KEY (CodAsiento),
        CONSTRAINT FK_Asientos_Salas FOREIGN KEY (CodSala) REFERENCES Salas(CodSala),
        CONSTRAINT UQ_Asientos_Sala_Fila_Num UNIQUE (CodSala, Fila, Numero)
    );
    PRINT 'Tabla Asientos creada.';
END
ELSE
    PRINT 'Tabla Asientos ya existe, se omite.';
GO

-- ============================================================
-- PASO 2: SEED DE ASIENTOS POR SALA
-- sala_01=10x10 sala_02=10x25 sala_03=10x30 sala_04=10x15
-- sala_05=8x10  sala_06=10x12 sala_07=10x20 sala_08=1x3
-- Filas A y B son VIP; el resto Estandar.
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM Asientos)
BEGIN
    DECLARE @SalaNum   VARCHAR(2);
    DECLARE @MaxFila   INT;
    DECLARE @MaxCol    INT;
    DECLARE @FilaOrd   INT;
    DECLARE @ColNum    INT;
    DECLARE @FilaLetra CHAR(1);

    DECLARE @Config TABLE (SalaNum VARCHAR(2), MaxFila INT, MaxCol INT);
    INSERT INTO @Config VALUES
        ('01', 10, 10), ('02', 10, 25), ('03', 10, 30),
        ('04', 10, 15), ('05',  8, 10), ('06', 10, 12),
        ('07', 10, 20), ('08',  1,  3);

    DECLARE salasCur CURSOR LOCAL FAST_FORWARD FOR
        SELECT SalaNum, MaxFila, MaxCol FROM @Config;
    OPEN salasCur;
    FETCH NEXT FROM salasCur INTO @SalaNum, @MaxFila, @MaxCol;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @FilaOrd = 1;
        WHILE @FilaOrd <= @MaxFila
        BEGIN
            SET @FilaLetra = CHAR(64 + @FilaOrd);   -- 65='A', 66='B', ...
            SET @ColNum = 1;
            WHILE @ColNum <= @MaxCol
            BEGIN
                INSERT INTO Asientos (CodAsiento, CodSala, Fila, Numero, TipoAsiento, Activo)
                VALUES (
                    'asi_' + @SalaNum + '_' + @FilaLetra
                          + RIGHT('0' + CAST(@ColNum AS VARCHAR(2)), 2),
                    'sala_' + @SalaNum,
                    @FilaLetra,
                    @ColNum,
                    CASE WHEN @FilaLetra IN ('A','B') THEN 'VIP' ELSE 'Estandar' END,
                    1
                );
                SET @ColNum = @ColNum + 1;
            END;
            SET @FilaOrd = @FilaOrd + 1;
        END;
        FETCH NEXT FROM salasCur INTO @SalaNum, @MaxFila, @MaxCol;
    END;
    CLOSE salasCur; DEALLOCATE salasCur;
    PRINT 'Asientos sembrados exitosamente.';
END
ELSE
    PRINT 'Asientos ya existían, se omite seed.';
GO

-- ============================================================
-- PASO 3: NUEVAS COLUMNAS EN ENTRADAS
-- ============================================================
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Entradas') AND name = 'CodAsiento')
BEGIN
    ALTER TABLE Entradas ADD CodAsiento CHAR(20) NULL;
    PRINT 'Columna CodAsiento agregada a Entradas.';
END
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('Entradas') AND name = 'CodigoValidacion')
BEGIN
    ALTER TABLE Entradas ADD CodigoValidacion VARCHAR(50) NULL;
    PRINT 'Columna CodigoValidacion agregada a Entradas.';
END
GO

-- FK Entradas → Asientos
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_Entradas_Asientos')
BEGIN
    ALTER TABLE Entradas
        ADD CONSTRAINT FK_Entradas_Asientos
            FOREIGN KEY (CodAsiento) REFERENCES Asientos(CodAsiento);
    PRINT 'FK Entradas → Asientos agregada.';
END
GO

-- Índice único: cada asiento puede venderse solo una vez por proyección
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Entradas_Proyeccion_Asiento')
BEGIN
    CREATE UNIQUE INDEX UQ_Entradas_Proyeccion_Asiento
        ON Entradas (CodProyeccion, CodAsiento)
        WHERE CodProyeccion IS NOT NULL AND CodAsiento IS NOT NULL;
    PRINT 'Índice único (CodProyeccion, CodAsiento) creado.';
END
GO

-- ============================================================
-- PASO 4: VISTA vw_AsientosPorProyeccion
-- ============================================================
IF OBJECT_ID('vw_AsientosPorProyeccion', 'V') IS NOT NULL
    DROP VIEW vw_AsientosPorProyeccion;
GO

CREATE VIEW vw_AsientosPorProyeccion AS
SELECT
    a.CodAsiento,
    a.CodSala,
    a.Fila,
    a.Numero,
    a.TipoAsiento,
    pr.CodProyeccion,
    CASE WHEN e.CodEntrada IS NOT NULL THEN 'Ocupado' ELSE 'Libre' END AS Estado
FROM Asientos a
JOIN Proyecciones pr ON pr.CodSala      = a.CodSala
LEFT JOIN Entradas e ON e.CodProyeccion = pr.CodProyeccion
                    AND e.CodAsiento    = a.CodAsiento
WHERE a.Activo = 1;
GO

-- ============================================================
-- PASO 5: ACTUALIZAR sp_ComprarEntrada
-- Acepta @CodAsiento opcional y genera CodigoValidacion.
-- Backward-compatible: si no se pasa @CodAsiento funciona igual.
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
    DECLARE @Precio           DECIMAL(10,2);
    DECLARE @CodEntrada       CHAR(20);
    DECLARE @CodPago          CHAR(20);
    DECLARE @CodigoValidacion VARCHAR(50);

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

    SELECT @Precio = Precio FROM Tarifas WHERE CodTarifa = @CodTarifa;
    IF @Precio IS NULL
    BEGIN
        RAISERROR('La tarifa especificada no existe.', 16, 1); RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM Asistentes WHERE CodAsistente = @CodAsistente)
    BEGIN
        RAISERROR('El asistente especificado no existe.', 16, 1); RETURN;
    END;

    IF @CodAsiento IS NOT NULL
    BEGIN
        IF NOT EXISTS (
            SELECT 1 FROM Asientos a
            JOIN Proyecciones pr ON pr.CodSala = a.CodSala
            WHERE a.CodAsiento = @CodAsiento AND pr.CodProyeccion = @CodProyeccion AND a.Activo = 1
        )
        BEGIN
            RAISERROR('El asiento no pertenece a esta funcion.', 16, 1); RETURN;
        END;
        IF EXISTS (
            SELECT 1 FROM Entradas WHERE CodProyeccion = @CodProyeccion AND CodAsiento = @CodAsiento
        )
        BEGIN
            RAISERROR('El asiento seleccionado ya esta ocupado. Elija otro.', 16, 1); RETURN;
        END;
    END;

    SET @CodEntrada       = LEFT('e_'   + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);
    SET @CodPago          = LEFT('p_'   + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);
    SET @CodigoValidacion = LEFT('VAL-' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', ''), 20);

    BEGIN TRY
        BEGIN TRANSACTION;

            INSERT INTO Entradas
                (CodEntrada, FechaCompra, PrecioPagado, CodAsistente,
                 CodTarifa, CodProyeccion, CodEvento, CodAsiento, CodigoValidacion)
            VALUES
                (@CodEntrada, CAST(GETDATE() AS DATE), @Precio, @CodAsistente,
                 @CodTarifa, @CodProyeccion, NULL, @CodAsiento, @CodigoValidacion);

            INSERT INTO Pagos
                (CodPago, FechaPago, Monto, MetodoPago, EstadoPago, TipoVenta, CodEntrada, CodCompraAbono)
            VALUES
                (@CodPago, GETDATE(), @Precio, 'Sistema-Taquilla', 'Completado', 'Entrada', @CodEntrada, NULL);

        COMMIT TRANSACTION;

        SELECT
            @CodEntrada       AS CodEntrada,
            @Precio           AS PrecioPagado,
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

-- ============================================================
-- PASO 6: sp_ComprarEntradasMultiples
-- Compra atómica de N asientos. Crea el Asistente si no existe
-- (búsqueda por Email). Toda la operación en una sola TXN.
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

    DECLARE @CodAsistente CHAR(20);
    DECLARE @PrecioPagado DECIMAL(10,2);
    DECLARE @Capacidad    INT;
    DECLARE @Vendidas     INT;
    DECLARE @NumAsientos  INT;
    DECLARE @CodAsiento   CHAR(20);
    DECLARE @CodEntrada   CHAR(20);
    DECLARE @CodPago      CHAR(20);
    DECLARE @CodVal       VARCHAR(50);

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

        -- 2. Precio de la tarifa
        SELECT @PrecioPagado = Precio FROM Tarifas WHERE CodTarifa = @CodTarifa;
        IF @PrecioPagado IS NULL
        BEGIN
            RAISERROR('La tarifa especificada no existe.', 16, 1); RETURN;
        END;

        -- 3. Verificar aforo total
        SELECT @Capacidad = s.Capacidad
        FROM Proyecciones pr JOIN Salas s ON s.CodSala = pr.CodSala
        WHERE pr.CodProyeccion = @CodProyeccion;

        IF @Capacidad IS NULL
        BEGIN
            RAISERROR('La proyeccion especificada no existe.', 16, 1); RETURN;
        END;

        SELECT @Vendidas    = COUNT(*) FROM Entradas WHERE CodProyeccion = @CodProyeccion;
        SELECT @NumAsientos = COUNT(*) FROM STRING_SPLIT(@ListaAsientos, ',') WHERE TRIM(value) <> '';

        IF (@Vendidas + @NumAsientos) > @Capacidad
        BEGIN
            RAISERROR('No hay suficiente aforo para la cantidad de asientos solicitados.', 16, 1); RETURN;
        END;

        -- 4. Tabla temporal de resultados
        CREATE TABLE #EntradasGen (
            CodEntrada       CHAR(20),
            CodAsiento       CHAR(20),
            Fila             CHAR(2),
            Numero           INT,
            CodigoValidacion VARCHAR(50),
            PrecioPagado     DECIMAL(10,2)
        );

        -- 5. Procesar cada asiento
        DECLARE curA CURSOR LOCAL FAST_FORWARD FOR
            SELECT TRIM(value) FROM STRING_SPLIT(@ListaAsientos, ',') WHERE TRIM(value) <> '';
        OPEN curA;
        FETCH NEXT FROM curA INTO @CodAsiento;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM Asientos a
                JOIN Proyecciones pr ON pr.CodSala = a.CodSala
                WHERE a.CodAsiento = @CodAsiento AND pr.CodProyeccion = @CodProyeccion AND a.Activo = 1
            )
                RAISERROR('El asiento "%s" no pertenece a la sala de esta funcion.', 16, 1, @CodAsiento);

            IF EXISTS (
                SELECT 1 FROM Entradas
                WHERE CodProyeccion = @CodProyeccion AND CodAsiento = @CodAsiento
            )
                RAISERROR('El asiento "%s" ya fue tomado. Seleccione otro.', 16, 1, @CodAsiento);

            SET @CodEntrada = LEFT('e_'   + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);
            SET @CodPago    = LEFT('p_'   + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);
            SET @CodVal     = LEFT('VAL-' + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);

            INSERT INTO Entradas
                (CodEntrada, FechaCompra, PrecioPagado, CodAsistente,
                 CodTarifa, CodProyeccion, CodEvento, CodAsiento, CodigoValidacion)
            VALUES
                (@CodEntrada, CAST(GETDATE() AS DATE), @PrecioPagado, @CodAsistente,
                 @CodTarifa, @CodProyeccion, NULL, @CodAsiento, @CodVal);

            INSERT INTO Pagos
                (CodPago, FechaPago, Monto, MetodoPago, EstadoPago, TipoVenta, CodEntrada, CodCompraAbono)
            VALUES
                (@CodPago, GETDATE(), @PrecioPagado, 'Online', 'Completado', 'Entrada', @CodEntrada, NULL);

            INSERT INTO #EntradasGen (CodEntrada, CodAsiento, Fila, Numero, CodigoValidacion, PrecioPagado)
            SELECT @CodEntrada, a.CodAsiento, a.Fila, a.Numero, @CodVal, @PrecioPagado
            FROM Asientos a WHERE a.CodAsiento = @CodAsiento;

            FETCH NEXT FROM curA INTO @CodAsiento;
        END;
        CLOSE curA; DEALLOCATE curA;

        -- ResultSet 1: entradas generadas
        SELECT CodEntrada, CodAsiento, Fila, Numero, CodigoValidacion, PrecioPagado FROM #EntradasGen;

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

PRINT '=== Migración completada exitosamente ===';
