# Contenido para el Informe de Proyecto Final — FestCine

> Este documento contiene el contenido redactado para cada sección del informe, siguiendo el orden y los títulos exactos de la plantilla `SI314 - Modelo de documento Informe Proyecto Final.docx`. Solo hay que copiar/pegar cada bloque en su sección correspondiente del Word y aplicar los estilos del documento (Título 3 para los encabezados de sección, Normal/justificado para el cuerpo).

---

## PORTADA — datos a reemplazar

- **PROYECTO:** FestCine — Sistema de Gestión para Festival Internacional de Cine
- **MATERIA:** Base de Datos
- **DOCENTE:** Carlos Wilfredo Egüez Terrazas
- **FECHA:** 14/06/2026
- **SEMESTRE:** Semestre 1/2026
- **ESTUDIANTES Y NRO. DE REGISTRO:** (4 integrantes — reemplazar cada línea por `Nro. de registro - Nombre completo`)
  1. {NroRegistro - NombreEstudiante}
  2. {NroRegistro - NombreEstudiante}
  3. {NroRegistro - NombreEstudiante}
  4. {NroRegistro - NombreEstudiante}

---

## Introducción / enunciado

FestCine es un sistema web de gestión para un festival internacional de cine independiente. Centraliza en una sola plataforma cliente-servidor las operaciones que hoy suelen manejarse en hojas de cálculo separadas: venta de entradas en taquilla, programación de la agenda de proyecciones, portal de autoservicio para los asistentes y reportes estadísticos para la organización.

El sistema gestiona una edición del festival (`edi_2026`, 12 al 19 de junio de 2026) e incluye:

- Catálogo de películas en competición, con géneros, país de origen, formato y estado (Seleccionada, Premiada, Mención).
- 8 salas distribuidas en distintas sedes, con capacidades que van de 3 a 300 butacas (1203 butacas en total).
- Venta de entradas individuales con selección de asiento en un mapa visual de la sala.
- Venta de abonos de festival, que generan un código de acceso único para todas las funciones.
- Programación de proyecciones con validación automática de cruces de horario por sala.
- Tres reportes en tiempo real: ranking de películas, acta de premiación e informe financiero.

El objetivo principal del proyecto no fue solo construir las pantallas, sino diseñar un modelo de datos normalizado y trasladar la lógica de negocio (control de aforo, control de agenda, atomicidad de las ventas) al motor de base de datos, de modo que las reglas se cumplan sin importar desde qué cliente se acceda al sistema.

**Perfiles de usuario:**

| Perfil | Acceso | Funcionalidad |
|---|---|---|
| Asistente | Taquilla, Portal | Comprar entradas con selección de asiento, ver su historial, comprar abonos |
| Administrador | Agenda | Programar proyecciones; el sistema bloquea automáticamente los conflictos de horario |
| Analista | Reportes | Consultar ranking de películas, acta de premiación e informe financiero |

---

## Modelo Conceptual

> Sección dejada como placeholder a propósito (no se generó un diagrama automático). Debe insertarse aquí el **diagrama entidad-relación conceptual**, mostrando las entidades principales y sus relaciones sin detalles de tipos de datos.

Entidades principales a incluir, agrupadas (ver detalle completo del modelo en `DOCUMENTACION.md`, sección 3):

- **Catálogos:** Formatos, EstadosPeliculas, Paises, Generos, Roles, Tarifas, Abonos, TiposAcreditaciones, TiposEventos, ClasificacionesEdades
- **Cinematográfico:** Peliculas, Personas, Participaciones, PeliculasGeneros
- **Agenda y sedes:** EdicionesFestivales, Sedes, Salas, Asientos, Proyecciones, EventosParalelos
- **Competición:** CategoriasCompeticion, CategoriasEdiciones, JuradosCategorias, Evaluaciones, GanadoresPremios, Premios
- **Clientes y ventas:** Asistentes, Acreditaciones, Entradas, ComprasAbonos, CodigosAcceso, Pagos, UsosAbonos
- **Logística:** Hoteles, Habitaciones, Alojamientos, Vuelos, Traslados, Patrocinadores, Patrocinios

`{inserte modelo aquí}`

---

## Modelo lógico

> Sección dejada como placeholder. Debe insertarse aquí el **diagrama entidad-relación lógico** (con atributos, tipos de datos, claves primarias/foráneas y cardinalidades), generado a partir del script `sql/01_DDL.sql`.

`{inserte modelo aquí}`

---

## Consideraciones y decisiones de implementación

**Normalización.** El modelo cumple 3FN:

- *1FN:* todos los atributos son atómicos. Las relaciones N:M (película-géneros, persona-película-rol) se resuelven con tablas puente (`PeliculasGeneros`, `Participaciones`).
- *2FN:* no hay dependencias parciales. En `Participaciones (CodPelicula, CodPersona, CodRol)`, la `Biografia` se guarda en `Personas` porque depende solo de la persona, no de la combinación completa de la clave.
- *3FN:* no hay dependencias transitivas. El nombre de una sala no se repite en `Proyecciones`; la tabla guarda `CodSala` y referencia a `Salas`.

**Desnormalización justificada.** `Entradas.PrecioPagado` duplica intencionalmente el precio de `Tarifas.Precio`. Las tarifas pueden cambiar en futuras ediciones del festival, pero el monto realmente cobrado en cada venta debe quedar fijo como un hecho histórico inmutable, independiente de cambios posteriores en el catálogo de precios.

**Decisiones de tipos de datos:**

| Decisión | Justificación |
|---|---|
| `CHAR(20)` para PKs (`asis_14`, `proy_01`, etc.) | Claves legibles que facilitan la depuración y las pruebas durante el desarrollo |
| `DATETIME2(0)` en horarios | Permite proyecciones que cruzan la medianoche; la precisión de segundos es suficiente |
| `DECIMAL(10,2)` en montos | Precisión monetaria exacta, sin errores de punto flotante |
| `DECIMAL(4,2)` en puntuaciones del jurado | Soporta decimales (ej. 8.50), restringido por `CHECK BETWEEN 1 AND 10` |
| `BIT` en campos booleanos | `Asientos.Activo`, `CodigosAcceso.Usado` |

**Integridad referencial y reglas de negocio en la base de datos:**

- `CK_Entradas_XOR`: cada entrada pertenece a **exactamente una** proyección o a **exactamente un** evento paralelo, nunca a ambos ni a ninguno.
- `CK_Pagos_XOR`: cada pago referencia exactamente una venta (una entrada o una compra de abono).
- Índice único filtrado `UQ_Entradas_Proyeccion_Asiento (CodProyeccion, CodAsiento) WHERE CodProyeccion IS NOT NULL AND CodAsiento IS NOT NULL`: garantiza a nivel de motor que el mismo asiento no pueda venderse dos veces en la misma función, incluso si dos compras llegan al mismo tiempo (segunda línea de defensa ante condiciones de carrera, además de la verificación que hace el stored procedure).

**Centralización de la lógica de negocio.** Toda regla de negocio (aforo disponible, asiento ya ocupado, cruce de horario en agenda, asistente inexistente, etc.) se valida en SQL Server mediante `RAISERROR`. El backend nunca decide si una operación es válida: solo captura la excepción (`SqlException`), recupera el mensaje original y lo devuelve al cliente como HTTP 409 dentro de un `ApiResponse<T>` con `success:false`. Esto evita duplicar reglas de validación en el frontend y en el backend, y asegura que cualquier cliente que use la base de datos (no solo esta API) quede protegido por las mismas restricciones.

**Ajustes realizados durante el desarrollo.** Durante las pruebas se corrigieron dos problemas puntuales sin alterar el alcance general del proyecto:

- El mapa de butacas de la taquilla no quedaba centrado y generaba scroll horizontal en pantallas más pequeñas; se ajustó el layout CSS/HTML/JS del componente de selección de asientos para que se adapte al ancho disponible.
- En el flujo de compra múltiple, si un correo ya existía como asistente, no había aviso previo al usuario. Se agregó el endpoint `GET /api/asistente/existe?email=...` y un aviso en el frontend que informa, antes de confirmar la compra, si el correo ingresado ya corresponde a un asistente registrado.

---

## Modelo físico

> Sección dejada como placeholder. Debe insertarse aquí el **diagrama físico** (tablas con tipos de datos exactos, PK/FK, constraints e índices) o un export del diagrama generado desde SQL Server Management Studio / Azure Data Studio a partir de `sql/01_DDL.sql`.

`{inserte modelo aquí}`

---

## Arquitectura de la solución construida

**Arquitectura de tres capas**, con toda la lógica de negocio concentrada en la base de datos:

```
┌─────────────────────────────────────┐
│           NAVEGADOR WEB              │
│   HTML · CSS · JavaScript puro       │
│   5 páginas · módulos JS por página  │
│         localhost:8080               │
└──────────────┬────────────────────────┘
               │  HTTP / JSON
               ▼
┌─────────────────────────────────────┐
│        ASP.NET Core 9 Web API        │
│   Controllers → Services → Repos     │
│   Dapper (micro-ORM)                 │
│   ApiResponse<T> · SqlException      │
│         localhost:5000               │
└──────────────┬────────────────────────┘
               │  ADO.NET / T-SQL
               ▼
┌─────────────────────────────────────┐
│             SQL SERVER               │
│   41+ tablas · 7 vistas              │
│   3 stored procedures                │
│   1 trigger · 1 índice filtrado      │
│         localhost                    │
└─────────────────────────────────────┘
```

**Herramientas / stack tecnológico:**

| Capa | Tecnología | Versión |
|---|---|---|
| Base de datos | SQL Server (T-SQL) | 2019 / 2022 / Express |
| Backend | ASP.NET Core Web API | .NET 9 |
| ORM | Dapper | 2.x |
| Frontend | HTML + CSS + JavaScript | Puro (sin frameworks) |
| Servidor estático | Python `http.server` | Python 3.x |

**Flujo de una petición** (ejemplo: compra de entradas):

1. El frontend (`taquilla.js`) recopila los datos del wizard y llama a `API.entradas.comprarMultiple(...)` (`frontend/js/api.js`), el único punto del frontend que hace `fetch`.
2. El `EntradasController` recibe el DTO y delega en `EntradasService`.
3. `EntradasService` llama a `EntradasRepository`, que ejecuta `sp_ComprarEntradasMultiples` vía Dapper.
4. Si SQL Server lanza `RAISERROR` (aforo insuficiente, asiento ocupado, etc.), Dapper lo propaga como `SqlException`; el Service lo traduce a un mensaje amigable y el Controller responde `409 Conflict` con `ApiResponse<T>.Fail(mensaje)`.
5. Si todo es correcto, el Controller responde `200 OK` con `ApiResponse<T>.Ok(datos)`.
6. El frontend nunca contiene SQL ni reglas de negocio: solo presenta datos y envía formularios.

**CORS:** configurado con `AllowAnyOrigin` para el entorno de desarrollo local (frontend y backend corren en puertos distintos del mismo equipo).

---

## Implementación

### Scripts de BD (creación de la estructura de la BD, procedimientos, funciones, etc.)

**Extracto de constraints clave (`sql/01_DDL.sql`):**

```sql
-- Entradas: cada entrada pertenece a una proyección O a un evento paralelo, nunca ambos
CREATE TABLE Entradas (
    CodEntrada       CHAR(20)       PRIMARY KEY,
    FechaCompra      DATE           NOT NULL,
    PrecioPagado     DECIMAL(10,2)  NOT NULL,
    CodAsistente     CHAR(20)       NOT NULL REFERENCES Asistentes(CodAsistente),
    CodTarifa        CHAR(20)       NOT NULL REFERENCES Tarifas(CodTarifa),
    CodProyeccion    CHAR(20)       NULL REFERENCES Proyecciones(CodProyeccion),
    CodEvento        CHAR(20)       NULL REFERENCES EventosParalelos(CodEvento),
    CodAsiento       CHAR(20)       NULL REFERENCES Asientos(CodAsiento),
    CodigoValidacion VARCHAR(50)    NULL,
    CONSTRAINT CK_Entradas_XOR CHECK (
        (CodProyeccion IS NOT NULL AND CodEvento IS NULL) OR
        (CodProyeccion IS NULL     AND CodEvento IS NOT NULL)
    )
);

-- Evita vender el mismo asiento dos veces en la misma proyeccion
CREATE UNIQUE INDEX UQ_Entradas_Proyeccion_Asiento
    ON Entradas (CodProyeccion, CodAsiento)
    WHERE CodProyeccion IS NOT NULL AND CodAsiento IS NOT NULL;

-- Pagos: cada pago referencia exactamente una entrada o una compra de abono
CREATE TABLE Pagos (
    CodPago        CHAR(20)       PRIMARY KEY,
    FechaPago      DATETIME       NOT NULL,
    Monto          DECIMAL(10,2)  NOT NULL,
    MetodoPago     VARCHAR(100)   NOT NULL,
    EstadoPago     VARCHAR(50)    NOT NULL,
    TipoVenta      VARCHAR(20)    NOT NULL CHECK (TipoVenta IN ('Entrada','Abono')),
    CodEntrada     CHAR(20)       NULL REFERENCES Entradas(CodEntrada),
    CodCompraAbono CHAR(20)       NULL REFERENCES ComprasAbonos(CodCompraAbono),
    CONSTRAINT CK_Pagos_XOR CHECK (
        (CodEntrada IS NOT NULL AND CodCompraAbono IS NULL) OR
        (CodEntrada IS NULL     AND CodCompraAbono IS NOT NULL)
    )
);
```

**Trigger `trg_ControlAgenda_Proyecciones` — control de agenda (`sql/03_DQL_Programacion.sql`):**

`INSTEAD OF INSERT` sobre `Proyecciones`: SQL Server no tiene `BEFORE INSERT`, así que el trigger intercepta el `INSERT`, valida y, si no hay conflicto, ejecuta él mismo el `INSERT` real.

```sql
CREATE OR ALTER TRIGGER trg_ControlAgenda_Proyecciones
ON Proyecciones
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CodProyeccion CHAR(20), @FechaHoraInicio DATETIME2(0), @FechaHoraFin DATETIME2(0),
            @SesionQa VARCHAR(255), @CodPelicula CHAR(20), @CodSala CHAR(20), @CodEdicion CHAR(20),
            @FinConBuffer DATETIME2(0), @Conflictos INT, @NombreSala VARCHAR(255), @MsgError VARCHAR(500);

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT CodProyeccion, FechaHoraInicio, FechaHoraFin, SesionQa, CodPelicula, CodSala, CodEdicion
        FROM INSERTED;

    OPEN cur;
    FETCH NEXT FROM cur INTO @CodProyeccion, @FechaHoraInicio, @FechaHoraFin, @SesionQa, @CodPelicula, @CodSala, @CodEdicion;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Buffer de limpieza de sala: 30 minutos despues del fin de cada proyeccion
        SET @FinConBuffer = DATEADD(MINUTE, 30, @FechaHoraFin);
        SELECT @NombreSala = NombreSala FROM Salas WHERE CodSala = @CodSala;

        -- Conflicto contra otras proyecciones de la misma sala
        SELECT @Conflictos = COUNT(*)
        FROM Proyecciones pr
        WHERE pr.CodSala = @CodSala
          AND @FechaHoraInicio < DATEADD(MINUTE, 30, pr.FechaHoraFin)
          AND pr.FechaHoraInicio < @FinConBuffer;

        IF @Conflictos > 0
        BEGIN
            SET @MsgError = 'Conflicto de agenda: la sala "' + ISNULL(@NombreSala, @CodSala)
                + '" ya tiene una proyeccion programada en ese horario (considere los 30 min de limpieza).';
            CLOSE cur; DEALLOCATE cur;
            RAISERROR(@MsgError, 16, 1);
            RETURN;
        END;

        -- Conflicto contra eventos paralelos de la misma sala (misma formula)
        SELECT @Conflictos = COUNT(*)
        FROM EventosParalelos ep
        WHERE ep.CodSala = @CodSala
          AND @FechaHoraInicio < DATEADD(MINUTE, 30, ep.FechaHoraFin)
          AND ep.FechaHoraInicio < @FinConBuffer;

        IF @Conflictos > 0
        BEGIN
            SET @MsgError = 'Conflicto de agenda: la sala "' + ISNULL(@NombreSala, @CodSala)
                + '" ya tiene un evento paralelo programado en ese horario (considere los 30 min de limpieza).';
            CLOSE cur; DEALLOCATE cur;
            RAISERROR(@MsgError, 16, 1);
            RETURN;
        END;

        -- Sin conflicto: el propio trigger realiza el INSERT real
        INSERT INTO Proyecciones (CodProyeccion, FechaHoraInicio, FechaHoraFin, SesionQa, CodPelicula, CodSala, CodEdicion)
        VALUES (@CodProyeccion, @FechaHoraInicio, @FechaHoraFin, @SesionQa, @CodPelicula, @CodSala, @CodEdicion);

        FETCH NEXT FROM cur INTO @CodProyeccion, @FechaHoraInicio, @FechaHoraFin, @SesionQa, @CodPelicula, @CodSala, @CodEdicion;
    END;
    CLOSE cur; DEALLOCATE cur;
END;
```

La fórmula de solapamiento es la intersección estándar de intervalos `[A,B] ∩ [C,D]`, expandiendo el fin de cada proyección existente en 30 minutos para el tiempo de limpieza de sala. El trigger valida con `INSERTED` mediante un cursor porque un solo `INSERT` puede traer varias filas.

**Stored procedure `sp_ComprarEntradasMultiples` — compra atómica de N asientos (`sql/04_Migracion_Asientos.sql`):**

Crea al asistente si no existe (busca por email), valida aforo total, y por cada asiento valida que pertenezca a la sala de la función y que no esté ocupado. Si cualquier validación falla, el `CATCH` revierte toda la transacción.

```sql
CREATE PROCEDURE sp_ComprarEntradasMultiples
    @Nombres VARCHAR(255), @Apellidos VARCHAR(255), @Email VARCHAR(255), @Telefono VARCHAR(20) = NULL,
    @CodProyeccion CHAR(20), @CodTarifa CHAR(20), @ListaAsientos VARCHAR(MAX) -- CSV: 'asi_01_A01,asi_01_A02'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CodAsistente CHAR(20), @PrecioPagado DECIMAL(10,2), @Capacidad INT, @Vendidas INT,
            @NumAsientos INT, @CodAsiento CHAR(20), @CodEntrada CHAR(20), @CodPago CHAR(20), @CodVal VARCHAR(50);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Buscar o crear Asistente por Email
        SELECT @CodAsistente = CodAsistente FROM Asistentes WHERE Email = @Email;
        IF @CodAsistente IS NULL
        BEGIN
            SET @CodAsistente = LEFT('asis_' + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);
            INSERT INTO Asistentes (CodAsistente, Nombres, Apellidos, Email, Telefono)
            VALUES (@CodAsistente, @Nombres, @Apellidos, @Email, @Telefono);
        END;

        -- 2. Precio de la tarifa
        SELECT @PrecioPagado = Precio FROM Tarifas WHERE CodTarifa = @CodTarifa;
        IF @PrecioPagado IS NULL RAISERROR('La tarifa especificada no existe.', 16, 1);

        -- 3. Verificar aforo total
        SELECT @Capacidad = s.Capacidad FROM Proyecciones pr JOIN Salas s ON s.CodSala = pr.CodSala
        WHERE pr.CodProyeccion = @CodProyeccion;
        IF @Capacidad IS NULL RAISERROR('La proyeccion especificada no existe.', 16, 1);

        SELECT @Vendidas = COUNT(*) FROM Entradas WHERE CodProyeccion = @CodProyeccion;
        SELECT @NumAsientos = COUNT(*) FROM STRING_SPLIT(@ListaAsientos, ',') WHERE TRIM(value) <> '';
        IF (@Vendidas + @NumAsientos) > @Capacidad
            RAISERROR('No hay suficiente aforo para la cantidad de asientos solicitados.', 16, 1);

        -- 4. Tabla temporal de resultados
        CREATE TABLE #EntradasGen (
            CodEntrada CHAR(20), CodAsiento CHAR(20), Fila CHAR(2), Numero INT,
            CodigoValidacion VARCHAR(50), PrecioPagado DECIMAL(10,2)
        );

        -- 5. Procesar cada asiento del CSV
        DECLARE curA CURSOR LOCAL FAST_FORWARD FOR
            SELECT TRIM(value) FROM STRING_SPLIT(@ListaAsientos, ',') WHERE TRIM(value) <> '';
        OPEN curA;
        FETCH NEXT FROM curA INTO @CodAsiento;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF NOT EXISTS (
                SELECT 1 FROM Asientos a JOIN Proyecciones pr ON pr.CodSala = a.CodSala
                WHERE a.CodAsiento = @CodAsiento AND pr.CodProyeccion = @CodProyeccion AND a.Activo = 1
            )
                RAISERROR('El asiento "%s" no pertenece a la sala de esta funcion.', 16, 1, @CodAsiento);

            IF EXISTS (SELECT 1 FROM Entradas WHERE CodProyeccion = @CodProyeccion AND CodAsiento = @CodAsiento)
                RAISERROR('El asiento "%s" ya fue tomado. Seleccione otro.', 16, 1, @CodAsiento);

            SET @CodEntrada = LEFT('e_' + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);
            SET @CodPago    = LEFT('p_' + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);
            SET @CodVal     = LEFT('VAL-' + REPLACE(CAST(NEWID() AS VARCHAR(36)),'-',''), 20);

            INSERT INTO Entradas (CodEntrada, FechaCompra, PrecioPagado, CodAsistente, CodTarifa, CodProyeccion, CodEvento, CodAsiento, CodigoValidacion)
            VALUES (@CodEntrada, CAST(GETDATE() AS DATE), @PrecioPagado, @CodAsistente, @CodTarifa, @CodProyeccion, NULL, @CodAsiento, @CodVal);

            INSERT INTO Pagos (CodPago, FechaPago, Monto, MetodoPago, EstadoPago, TipoVenta, CodEntrada, CodCompraAbono)
            VALUES (@CodPago, GETDATE(), @PrecioPagado, 'Online', 'Completado', 'Entrada', @CodEntrada, NULL);

            INSERT INTO #EntradasGen (CodEntrada, CodAsiento, Fila, Numero, CodigoValidacion, PrecioPagado)
            SELECT @CodEntrada, a.CodAsiento, a.Fila, a.Numero, @CodVal, @PrecioPagado FROM Asientos a WHERE a.CodAsiento = @CodAsiento;

            FETCH NEXT FROM curA INTO @CodAsiento;
        END;
        CLOSE curA; DEALLOCATE curA;

        SELECT CodEntrada, CodAsiento, Fila, Numero, CodigoValidacion, PrecioPagado FROM #EntradasGen;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
```

**Otros objetos programables incluidos en el proyecto** (detalle completo en `DOCUMENTACION.md`, secciones 4.1–4.4):

- `sp_ComprarEntrada` — compra individual para un asistente existente.
- `sp_VenderAbono` — venta atómica de abono (3 INSERTs: `ComprasAbonos`, `CodigosAcceso`, `Pagos`).
- 7 vistas: `vw_PeliculasCartelera`, `vw_ProyeccionesDisponibles`, `vw_TarifasActivas`, `vw_AsientosPorProyeccion`, `vw_RankingPeliculas`, `vw_ActaPremiacion`, `vw_InformeFinanciero`.
- 3 consultas DQL con funciones de ventana (`RANK()`, `SUM() OVER (PARTITION BY ...)`).

---

### Código de la aplicación

**Patrón Controller → Service → Repository** (ejemplo real: compra múltiple de entradas).

`backend/FestCine.API/Controllers/EntradasController.cs`:

```csharp
[ApiController]
[Route("api/entradas")]
public class EntradasController : ControllerBase
{
    private readonly EntradasService _service;

    public EntradasController(EntradasService service) => _service = service;

    /// POST /api/entradas/comprar — entrada individual (sp_ComprarEntrada)
    [HttpPost("comprar")]
    public async Task<ActionResult<ApiResponse<ComprarEntradaResponseDto>>> Comprar(
        [FromBody] ComprarEntradaRequestDto request)
    {
        var (result, error) = await _service.ComprarEntradaAsync(request);
        if (error is not null)
            return Conflict(ApiResponse<ComprarEntradaResponseDto>.Fail(error));
        return Ok(ApiResponse<ComprarEntradaResponseDto>.Ok(result!));
    }

    /// POST /api/entradas/comprar-multiple — compra atomica de N asientos.
    /// Crea o reutiliza el Asistente por email. Invoca sp_ComprarEntradasMultiples.
    [HttpPost("comprar-multiple")]
    public async Task<ActionResult<ApiResponse<ComprarMultipleResponseDto>>> ComprarMultiple(
        [FromBody] ComprarMultipleRequestDto request)
    {
        if (request.CodAsientos is null || request.CodAsientos.Count == 0)
            return BadRequest(ApiResponse<ComprarMultipleResponseDto>.Fail(
                "Debe seleccionar al menos un asiento."));

        var (result, error) = await _service.ComprarMultipleAsync(request);
        if (error is not null)
            return Conflict(ApiResponse<ComprarMultipleResponseDto>.Fail(error));
        return Ok(ApiResponse<ComprarMultipleResponseDto>.Ok(result!));
    }
}
```

`backend/FestCine.API/Services/EntradasService.cs`:

```csharp
public class EntradasService
{
    private readonly EntradasRepository _repo;

    public EntradasService(EntradasRepository repo) => _repo = repo;

    public async Task<(ComprarMultipleResponseDto? Result, string? Error)> ComprarMultipleAsync(
        ComprarMultipleRequestDto request)
    {
        try
        {
            var result = await _repo.ComprarMultipleAsync(request);
            return (result, null);
        }
        catch (SqlException ex)
        {
            // Traduce el RAISERROR de SQL Server a un mensaje de negocio
            return (null, SqlExceptionHandler.ObtenerMensajeAmigable(ex));
        }
    }
}
```

**Cliente HTTP centralizado del frontend** (`frontend/js/api.js`) — único punto del frontend que hace `fetch`, usado por los 5 módulos de página (`taquilla.js`, `agenda.js`, `portal.js`, `reportes.js`):

```javascript
const API = (() => {
  async function _fetch(endpoint, options = {}) {
    const url = CONFIG.API_BASE + endpoint;
    const res = await fetch(url, {
      headers: { 'Content-Type': 'application/json' },
      ...options,
    });

    const json = await res.json();

    if (!json.success) {
      // El mensaje viene directamente del RAISERROR del servidor
      throw new Error(json.message || 'Error desconocido del servidor.');
    }
    return json.data;
  }

  return {
    get:  (endpoint)       => _fetch(endpoint),
    post: (endpoint, body) => _fetch(endpoint, { method: 'POST', body: JSON.stringify(body) }),

    entradas: {
      comprar:         (data) => API.post('/api/entradas/comprar', data),
      comprarMultiple: (data) => API.post('/api/entradas/comprar-multiple', data),
    },
    asistente: {
      portal: (email) => API.get(`/api/asistente/portal?email=${encodeURIComponent(email)}`),
      existe: (email) => API.get(`/api/asistente/existe?email=${encodeURIComponent(email)}`),
    },
    reportes: {
      ranking:           (ed) => API.get(`/api/reportes/ranking?codEdicion=${ed}`),
      actaPremiacion:    (ed) => API.get(`/api/reportes/acta-premiacion?codEdicion=${ed}`),
      informeFinanciero: ()   => API.get('/api/reportes/informe-financiero'),
    },
    // ... peliculas, proyecciones, tarifas, abonos (ver archivo completo)
  };
})();
```

**Frontend — resumen de módulos:**

- 5 páginas HTML: Taquilla (wizard de compra con mapa de asientos), Agenda (programación de proyecciones), Portal del asistente (historial por email), Reportes (ranking, acta de premiación, informe financiero).
- JavaScript puro, sin frameworks, organizado en un módulo por página más `api.js` (cliente HTTP) y `config.js` (URL base de la API).
- El frontend no contiene SQL ni cálculos de negocio: solo construye el request, llama a `API.*` y renderiza la respuesta o el mensaje de error devuelto por el backend.

---

### Capturas de pantalla

> Sección dejada como marcador para agregar capturas propias. Se recomienda incluir, en este orden:

1. **Taquilla — Paso 1:** selección de película (cartelera).
2. **Taquilla — Paso 2:** selección de función/proyección con cupo disponible.
3. **Taquilla — Paso 3:** mapa de asientos (libres/ocupados).
4. **Taquilla — Paso 4/5:** formulario de datos del comprador + selección de tarifa.
5. **Taquilla — Comprobante final:** entradas generadas con código de validación.
6. **Agenda:** formulario de programación de proyección y ejemplo de bloqueo por conflicto de horario (mensaje del trigger TR1).
7. **Portal del asistente:** historial de entradas y abonos al buscar por email.
8. **Reportes:** las tres vistas — ranking de películas, acta de premiación e informe financiero.

`{imágenes}`

---

## Notas finales para quien arme el documento final

- Los encabezados de sección de este archivo (`##`) corresponden 1 a 1 con los títulos `Título 3` de la plantilla, en el mismo orden.
- El contenido de "Modelo Conceptual", "Modelo lógico" y "Modelo físico" quedó como placeholder porque requiere un diagrama ER (hacerlo en dbdiagram.io, draw.io o el diagramador de SQL Server a partir de `sql/01_DDL.sql`).
- Toda la información ampliada (todas las tablas, las 7 vistas, los 3 SPs completos, el trigger, los 41+ endpoints con ejemplos JSON, limitaciones conocidas y glosario) está en `C:\Users\Samuel\FestCine\DOCUMENTACION.md` y `C:\Users\Samuel\FestCine\DEFENSA.md`, por si se necesita expandir alguna sección.
