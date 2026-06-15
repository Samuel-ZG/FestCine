# FestCine — Documentación Técnica

**Versión:** 1.0.0  
**Fecha:** Junio 2026  
**Proyecto:** Sistema de Gestión para Festival Internacional de Cine  
**Autor:** Samuel Zarate  
**Estado:** Funcional · Entorno de desarrollo local

---

## Tabla de contenidos

1. [Descripción general](#1-descripción-general)
2. [Arquitectura del sistema](#2-arquitectura-del-sistema)
3. [Modelo de datos](#3-modelo-de-datos)
4. [Base de datos — Objetos programables](#4-base-de-datos--objetos-programables)
5. [API REST — Backend](#5-api-rest--backend)
6. [Frontend — Módulos](#6-frontend--módulos)
7. [Instalación y puesta en marcha](#7-instalación-y-puesta-en-marcha)
8. [Consideraciones técnicas](#8-consideraciones-técnicas)
9. [Limitaciones conocidas](#9-limitaciones-conocidas)
10. [Glosario](#10-glosario)

---

## 1. Descripción general

FestCine es un sistema web de gestión para un festival internacional de cine independiente. Centraliza las operaciones de taquilla, programación de agenda, portal del asistente y reportes estadísticos en una única plataforma cliente-servidor.

### 1.1 Propósito

Reemplazar hojas de cálculo y procesos manuales por una solución integrada que garantice:

- **Integridad de datos** mediante constraints y lógica de negocio en el servidor de base de datos.
- **Transaccionalidad** en operaciones críticas como compra de entradas y venta de abonos.
- **Control de agenda** automático que previene cruces de horario en las salas.
- **Trazabilidad** completa de pagos, entradas y accesos.

### 1.2 Usuarios del sistema

| Perfil | Acceso | Funcionalidad |
|---|---|---|
| **Asistente** | Taquilla, Portal | Comprar entradas con selección de asiento, ver su historial, comprar abonos |
| **Administrador** | Agenda | Programar proyecciones; el sistema bloquea automáticamente los conflictos |
| **Analista** | Reportes | Consultar ranking de películas, acta de premiación e informe financiero |

### 1.3 Alcance

El sistema gestiona una edición del festival (`edi_2026`, 12–19 junio 2026). Incluye:

- Catálogo de películas en competición
- 8 salas con capacidades desde 3 hasta 300 personas
- Venta de entradas individuales con selección de asiento
- Venta de abonos con código de acceso único
- Programación de hasta N proyecciones por día con validación de horario
- 3 reportes estadísticos en tiempo real

---

## 2. Arquitectura del sistema

### 2.1 Stack tecnológico

| Capa | Tecnología | Versión |
|---|---|---|
| Base de datos | SQL Server (T-SQL) | 2019 / 2022 / Express |
| Backend | ASP.NET Core Web API | .NET 9 |
| ORM | Dapper | 2.x |
| Frontend | HTML + CSS + JavaScript | Puro (sin frameworks) |
| Servidor estático | Python http.server | Python 3.x |

### 2.2 Diagrama de capas

```
┌─────────────────────────────────────┐
│           NAVEGADOR WEB             │
│   HTML · CSS · JavaScript puro      │
│   5 páginas · 4 módulos JS          │
│         localhost:8080              │
└──────────────┬──────────────────────┘
               │  HTTP / JSON
               ▼
┌─────────────────────────────────────┐
│        ASP.NET Core 9 Web API       │
│   Controllers → Services → Repos    │
│   Dapper (micro-ORM)                │
│   ApiResponse<T> · SqlException     │
│         localhost:5000              │
└──────────────┬──────────────────────┘
               │  ADO.NET / T-SQL
               ▼
┌─────────────────────────────────────┐
│           SQL SERVER                │
│   41+ tablas · 7 vistas             │
│   3 stored procedures               │
│   1 trigger · 1 índice filtrado     │
│         localhost                   │
└─────────────────────────────────────┘
```

### 2.3 Principio de diseño central

Toda la lógica de negocio reside en la base de datos. El backend es una capa de transporte que:

1. Recibe el request HTTP y lo deserializa a un DTO.
2. Llama a la vista o SP correspondiente mediante Dapper.
3. Si SQL Server lanza un `RAISERROR`, lo captura como `SqlException` y lo convierte en HTTP 409 con el mensaje original.
4. Devuelve `ApiResponse<T>` con `success: true/false` al frontend.

El frontend nunca contiene SQL, validaciones de negocio ni cálculos de precios. Su única responsabilidad es presentar datos y enviar formularios.

---

## 3. Modelo de datos

### 3.1 Grupos de tablas

El modelo está compuesto por **41+ tablas** organizadas en 6 grupos funcionales:

| Grupo | Tablas principales | Descripción |
|---|---|---|
| **Catálogos** | `Formatos`, `EstadosPeliculas`, `Paises`, `Generos`, `Roles`, `Tarifas`, `Abonos`, `TiposAcreditaciones`, `TiposEventos`, `ClasificacionesEdades` | Tablas de referencia sin dependencias externas |
| **Cinematográfico** | `Peliculas`, `Personas`, `Participaciones`, `PeliculasGeneros` | Catálogo de películas y su equipo creativo |
| **Agenda y sedes** | `EdicionesFestivales`, `Sedes`, `Salas`, `Asientos`, `Proyecciones`, `EventosParalelos` | Infraestructura física y programación |
| **Competición** | `CategoriasCompeticion`, `CategoriasEdiciones`, `JuradosCategorias`, `Evaluaciones`, `GanadoresPremios`, `Premios` | Sistema de jurado y premiación |
| **Clientes y ventas** | `Asistentes`, `Acreditaciones`, `Entradas`, `ComprasAbonos`, `CodigosAcceso`, `Pagos`, `UsosAbonos` | Gestión de asistentes y transacciones |
| **Logística** | `Hoteles`, `Habitaciones`, `Alojamientos`, `Vuelos`, `Traslados`, `Patrocinadores`, `Patrocinios` | Soporte para invitados y financiamiento |

### 3.2 Tablas principales y sus relaciones

#### Asientos
```sql
Asientos (CodAsiento PK, CodSala FK, Fila CHAR(2), Numero INT, TipoAsiento, Activo)
UNIQUE (CodSala, Fila, Numero)
```
1203 butacas distribuidas en 8 salas. Generadas con un cursor T-SQL durante la migración.

#### Proyecciones
```sql
Proyecciones (CodProyeccion PK, CodPelicula FK, CodSala FK, CodEdicion FK,
              FechaHoraInicio DATETIME2(0), FechaHoraFin DATETIME2(0), SesionQa)
```
El trigger `trg_ControlAgenda_Proyecciones` protege esta tabla ante inserciones conflictivas.

#### Entradas
```sql
Entradas (CodEntrada PK, FechaCompra DATE, PrecioPagado DECIMAL(10,2),
          CodAsistente FK, CodTarifa FK, CodProyeccion FK NULL, CodEvento FK NULL,
          CodAsiento FK NULL, CodigoValidacion VARCHAR(50) NULL)

CONSTRAINT CK_Entradas_XOR CHECK (
    (CodProyeccion IS NOT NULL AND CodEvento IS NULL) OR
    (CodProyeccion IS NULL     AND CodEvento IS NOT NULL)
)
UNIQUE INDEX UQ_Entradas_Proyeccion_Asiento (CodProyeccion, CodAsiento)
    WHERE CodProyeccion IS NOT NULL AND CodAsiento IS NOT NULL
```
La constraint XOR garantiza que cada entrada pertenezca exactamente a una proyección **o** a un evento paralelo, nunca a ambos. El índice filtrado único evita que el mismo asiento se venda dos veces en la misma proyección.

#### Pagos
```sql
Pagos (CodPago PK, FechaPago DATETIME, Monto DECIMAL(10,2), MetodoPago,
       EstadoPago, TipoVenta, CodEntrada FK NULL, CodCompraAbono FK NULL)

CONSTRAINT CK_Pagos_XOR CHECK (
    (CodEntrada IS NOT NULL AND CodCompraAbono IS NULL) OR
    (CodEntrada IS NULL     AND CodCompraAbono IS NOT NULL)
)
```
Tabla centralizada de auditoría financiera. Cada pago referencia exactamente una venta.

### 3.3 Normalización

**Primera Forma Normal (1FN):** Todos los atributos son atómicos. Las relaciones N:M (película-géneros, persona-película-rol) se resuelven con tablas puente (`PeliculasGeneros`, `Participaciones`).

**Segunda Forma Normal (2FN):** Ninguna tabla tiene dependencias parciales. En `Participaciones (CodPelicula, CodPersona, CodRol)`, la `Biografia` vive en `Personas` porque depende solo de la persona.

**Tercera Forma Normal (3FN):** Sin dependencias transitivas. El nombre de una sala no está en `Proyecciones`; `Proyecciones` guarda `CodSala` y referencia a `Salas`.

**Desnormalización justificada:** `Entradas.PrecioPagado` duplica el precio de `Tarifas.Precio` intencionalmente. Un precio puede cambiar para futuras ediciones; el valor cobrado en cada transacción debe quedar inmutable como hecho histórico.

### 3.4 Decisiones de tipo de dato

| Decisión | Justificación |
|---|---|
| `CHAR(20)` para PKs | Claves legibles (`asis_14`, `proy_01`) que facilitan depuración |
| `DATETIME2(0)` en horarios | Permite proyecciones que cruzan la medianoche; precisión de segundos es suficiente |
| `DECIMAL(10,2)` en montos | Precisión monetaria sin errores de punto flotante |
| `DECIMAL(4,2)` en puntuaciones | Soporta decimales (ej. `8.50`) restringido por `CHECK BETWEEN 1 AND 10` |
| `BIT` en campos booleanos | `Asientos.Activo`, `CodigosAcceso.Usado` |

---

## 4. Base de datos — Objetos programables

### 4.1 Vistas

#### `vw_PeliculasCartelera`
Agrega películas en estado Seleccionada, Premiada o con Mención. Usa `STRING_AGG` para concatenar géneros en un solo campo.

```sql
-- Técnica clave: STRING_AGG
STRING_AGG(g.NombreGenero, ', ') AS Generos
-- Agrupa con GROUP BY para que funcione con el LEFT JOIN a géneros
```

**Consumida por:** Taquilla (dropdown películas), Agenda (dropdown películas).

---

#### `vw_ProyeccionesDisponibles`
Calcula el cupo disponible en tiempo real contando entradas vendidas.

```sql
-- Técnica clave: LEFT JOIN + COUNT + resta
s.Capacidad - COUNT(e.CodEntrada) AS CupoDisponible
```

El `LEFT JOIN` sobre `Entradas` devuelve NULL cuando no hay entradas vendidas, y `COUNT` ignora NULLs, por lo que el cupo inicial es igual a la capacidad total.

**Consumida por:** Taquilla (lista de funciones con indicador de cupo).

---

#### `vw_TarifasActivas`
Vista simple sobre `Tarifas`. Provee el catálogo de precios al formulario de compra.

**Consumida por:** Taquilla (dropdown tarifa), paso 4 del wizard.

---

#### `vw_AsientosPorProyeccion`
Cruza `Asientos` con `Proyecciones` para listar todas las butacas de la sala, y aplica un `LEFT JOIN` a `Entradas` para conocer el estado de cada una.

```sql
-- Técnica clave: CASE con LEFT JOIN
CASE WHEN e.CodEntrada IS NOT NULL THEN 'Ocupado' ELSE 'Libre' END AS Estado
```

No almacena estado — lo calcula en cada consulta. El mapa de asientos siempre refleja el estado actual.

**Consumida por:** Taquilla, paso 3 del wizard (mapa visual de butacas).

---

#### `vw_RankingPeliculas`
Agrega asistentes y porcentaje de ocupación a nivel de película, sumando todas sus proyecciones en la edición.

```sql
-- Técnicas clave: ISNULL + NULLIF + subconsulta correlacionada
ISNULL(SUM(sub.EntradasVendidas), 0)            AS TotalAsistentes,
CAST(
    ISNULL(SUM(sub.EntradasVendidas), 0) * 100.0
    / NULLIF(SUM(s.Capacidad), 0)
AS DECIMAL(5,2))                                AS PctOcupacion
```

`NULLIF` evita la división por cero si una película no tiene proyecciones con capacidad registrada.

**Consumida por:** Reportes, DQL 1.

---

#### `vw_ActaPremiacion`
Lista ganadores por categoría con el promedio de votación del jurado.

```sql
-- Técnica clave: LEFT JOIN + AVG sobre evaluaciones del jurado
CAST(AVG(ev.Puntuacion) AS DECIMAL(4,2)) AS PromedioVotacion,
COUNT(ev.CodEvaluacion)                  AS TotalVotos
```

El `LEFT JOIN` a `Evaluaciones` permite mostrar ganadores aunque no tengan votos del jurado registrados.

**Consumida por:** Reportes, DQL 2.

---

#### `vw_InformeFinanciero`
Desglose financiero agrupado por tipo de venta (Entrada / Abono) y tipo de tarifa o nombre de abono.

```sql
-- Técnica clave: CASE en GROUP BY para unificar dos fuentes de nombre
CASE
    WHEN pg.TipoVenta = 'Entrada' THEN t.Nombre
    WHEN pg.TipoVenta = 'Abono'   THEN a.Nombre
END AS TipoTarifa
```

**Consumida por:** Reportes, DQL 3 (que añade `SUM() OVER()` para subtotales).

---

### 4.2 Consultas DQL

#### DQL 1 — Ranking de películas con función de ventana `RANK()`
```sql
SELECT
    RANK() OVER (ORDER BY r.TotalAsistentes DESC, r.PctOcupacion DESC) AS Posicion,
    r.Titulo, r.TotalProyecciones, r.TotalAsistentes,
    r.CapacidadTotal, r.PctOcupacion
FROM vw_RankingPeliculas r
WHERE r.CodEdicion = 'edi_2026'
ORDER BY Posicion;
```

`RANK()` produce empates con saltos (1, 1, 3) en lugar de `ROW_NUMBER()`. Semánticamente correcto para un ranking de festival donde dos películas pueden empatar.

#### DQL 2 — Acta de premiación
```sql
SELECT ap.NombreCategoria, ap.NombrePremio, ap.PeliculaGanadora,
       ap.PromedioEvaluacion, ap.TotalVotos
FROM vw_ActaPremiacion ap
WHERE ap.CodEdicion = 'edi_2026'
ORDER BY ap.NombreCategoria;
```

#### DQL 3 — Informe financiero con subtotales y gran total
```sql
SELECT
    TipoVenta, TipoTarifa, CantidadTransacciones, TotalRecaudado,
    SUM(TotalRecaudado) OVER (PARTITION BY TipoVenta) AS SubtotalTipoVenta,
    SUM(TotalRecaudado) OVER ()                        AS GrandTotal
FROM vw_InformeFinanciero
ORDER BY TipoVenta, TotalRecaudado DESC;
```

Las funciones de ventana `SUM() OVER()` calculan subtotales por tipo y el gran total global en una sola pasada sobre la vista, sin subconsultas ni `UNION`.

---

### 4.3 Stored Procedures

#### `sp_ComprarEntrada` — Compra individual (P1)

Registra la compra de una entrada para un asistente existente.

**Parámetros:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `@CodAsistente` | `CHAR(20)` | Código del asistente comprador |
| `@CodProyeccion` | `CHAR(20)` | Proyección seleccionada |
| `@CodTarifa` | `CHAR(20)` | Tarifa aplicada |
| `@CodAsiento` | `CHAR(20)` | (Opcional) Butaca específica |

**Flujo interno:**

```
1. Obtener Capacidad de la sala  →  si NULL: RAISERROR proyección no existe
2. Contar Entradas vendidas       →  si >= Capacidad: RAISERROR sin aforo
3. Obtener Precio de la tarifa    →  si NULL: RAISERROR tarifa no existe
4. Verificar Asistente existe     →  si no: RAISERROR asistente no existe
5. Si @CodAsiento proporcionado:
   a. Verificar que pertenezca a la sala de la proyección
   b. Verificar que no esté ya vendido en esa proyección
6. Generar CodEntrada, CodPago, CodigoValidacion con NEWID()
7. BEGIN TRANSACTION
   → INSERT Entradas
   → INSERT Pagos
   COMMIT
8. SELECT CodEntrada, PrecioPagado, CodigoValidacion, Mensaje
```

**Errores posibles (HTTP 409):**

- `"La proyeccion especificada no existe."`
- `"Lo sentimos, no hay aforo disponible para esta funcion."`
- `"La tarifa especificada no existe."`
- `"El asistente especificado no existe."`
- `"El asiento seleccionado ya esta ocupado. Elija otro."`

---

#### `sp_ComprarEntradasMultiples` — Compra múltiple con selección de asientos (P2)

Compra atómica de N butacas. Crea el asistente si no existe (búsqueda por email). Diseñado para el wizard de taquilla.

**Parámetros:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `@Nombres` | `VARCHAR(255)` | Nombre del comprador |
| `@Apellidos` | `VARCHAR(255)` | Apellido del comprador |
| `@Email` | `VARCHAR(255)` | Email (identificador único del asistente) |
| `@Telefono` | `VARCHAR(20)` | (Opcional) Teléfono |
| `@CodProyeccion` | `CHAR(20)` | Proyección seleccionada |
| `@CodTarifa` | `CHAR(20)` | Tarifa aplicada a todos los asientos |
| `@ListaAsientos` | `VARCHAR(MAX)` | CSV de códigos: `'asi_01_A01,asi_01_A02'` |

**Flujo interno:**

```
1. Buscar Asistente por Email → si no existe, crear con NEWID()
2. Obtener precio de la tarifa
3. Verificar aforo total: (vendidas + nuevas) <= capacidad
4. Cursor sobre STRING_SPLIT(@ListaAsientos, ','):
   Por cada asiento:
   a. Verificar que pertenezca a la sala
   b. Verificar que no esté ocupado
   c. INSERT Entradas + INSERT Pagos
   d. Guardar resultado en tabla temporal #EntradasGen
5. COMMIT de toda la transacción
6. ResultSet 1: SELECT * FROM #EntradasGen  (entradas generadas)
7. ResultSet 2: SELECT asistente info       (datos del comprador)
```

**Garantía de atomicidad:** Si cualquier asiento falla (ya ocupado, no pertenece a la sala), el `BEGIN CATCH` hace `ROLLBACK` de todos los inserts anteriores del cursor.

**Protección adicional:** El índice único filtrado `UQ_Entradas_Proyeccion_Asiento` es la segunda línea de defensa ante condiciones de carrera concurrentes.

**Devuelve:** 2 result sets leídos con `QueryMultipleAsync` de Dapper.

---

#### `sp_VenderAbono` — Venta atómica de abono (T1)

Registra la compra de un pase de festival en una transacción que involucra tres tablas. Si cualquier INSERT falla, los tres se revierten.

**Parámetros:**

| Parámetro | Tipo | Descripción |
|---|---|---|
| `@CodAsistente` | `CHAR(20)` | Asistente comprador |
| `@CodAbono` | `CHAR(20)` | Tipo de abono |
| `@MetodoPago` | `VARCHAR(100)` | Método de pago (ej. "Tarjeta") |

**Los tres pasos atómicos:**

```
BEGIN TRANSACTION
  1. INSERT ComprasAbonos  ← registra la venta con precio histórico
  2. INSERT CodigosAcceso  ← genera código legible: ACC-{asistente}-{año}-{8 chars}
  3. INSERT Pagos          ← emite el registro de pago/factura
COMMIT
```

El código de acceso tiene constraint `UNIQUE` en `CodigosAcceso.CodigoGenerado`. Si `NEWID()` produjera una colisión (probabilidad ≈ 2⁻¹²²), el `CATCH` haría `ROLLBACK` y el cliente recibiría un error para reintentar.

**Devuelve:** `CodCompraAbono`, `CodigoAcceso`, `MontoPagado`, `Mensaje`.

---

### 4.4 Trigger

#### `trg_ControlAgenda_Proyecciones` — Control de agenda (TR1)

**Tipo:** `INSTEAD OF INSERT` sobre la tabla `Proyecciones`.

En SQL Server no existe `BEFORE INSERT`. El equivalente es `INSTEAD OF INSERT`: el trigger intercepta la operación antes de que el dato llegue a la tabla. Si no hay conflicto, el propio trigger ejecuta el `INSERT` real. Si hay conflicto, lanza `RAISERROR` y termina sin insertar.

**Fórmula de solapamiento con buffer de limpieza:**

```
nueva_proyección CHOCA CON existente si:
  nuevoInicio < existenteFin + 30 min
  AND existenteInicio < nuevoFin + 30 min
```

Esta es la fórmula estándar de intersección de intervalos `[A,B] ∩ [C,D]` donde se expande `B` (fin del existente) en 30 minutos para incluir el tiempo de limpieza de sala.

**Verifica conflictos contra dos fuentes:**
1. Otras `Proyecciones` en la misma sala
2. `EventosParalelos` en la misma sala (masterclasses, talleres, etc.)

**Soporte para INSERT batch:** Usa `CURSOR LOCAL FAST_FORWARD FOR SELECT ... FROM INSERTED` porque `INSERTED` puede contener múltiples filas si se insertan N proyecciones en un solo statement.

**Datos de prueba para demostración:**

| Escenario | Datos | Resultado |
|---|---|---|
| Sin conflicto | Sala: Patio Historico · 2026-08-22 09:00–11:00 | ✅ Se programa |
| Con conflicto | Sala: Patio Historico · 2026-08-21 21:20–23:00 | ⛔ Bloqueado (`proy_06` termina 21:00 + 30 min = 21:30; 21:20 < 21:30) |

---

## 5. API REST — Backend

### 5.1 Convenciones

- **URL base:** `http://localhost:5000`
- **Formato:** JSON en todos los endpoints
- **Respuesta estándar:**

```json
{ "success": true,  "message": null,      "data": { ... } }
{ "success": false, "message": "Texto del error", "data": null }
```

- **Códigos HTTP usados:**

| Código | Cuándo |
|---|---|
| `200 OK` | Operación exitosa |
| `400 Bad Request` | Parámetros faltantes o inválidos en el request |
| `404 Not Found` | Recurso no encontrado (ej. email sin cuenta) |
| `409 Conflict` | Error de negocio del servidor (sala llena, cruce de horario, asiento ocupado) |
| `500 Internal Server Error` | Error inesperado no capturado |

El código 409 se usa para errores de negocio porque el request está bien formado pero genera un conflicto con el estado actual del servidor (RFC 9110).

### 5.2 Endpoints

#### Películas

**`GET /api/peliculas/cartelera`**

Devuelve películas en estado Seleccionada, Premiada o con Mención.

```json
// Respuesta 200
{
  "success": true,
  "data": [
    {
      "codPelicula": "pel_01",
      "titulo": "Sombras del Illimani",
      "anioProduccion": 2025,
      "duracion": 92,
      "paisOrigen": "Bolivia",
      "formato": "Digital 4K",
      "estado": "Seleccionada",
      "generos": "Drama, Thriller"
    }
  ]
}
```

---

#### Proyecciones

**`GET /api/proyecciones/pelicula/{codPelicula}`**

Devuelve funciones disponibles para una película con cupo en tiempo real.

```json
// Respuesta 200
{
  "success": true,
  "data": [
    {
      "codProyeccion": "proy_01",
      "fechaHoraInicio": "2026-08-16T19:00:00",
      "nombreSala": "Sala VIP Center",
      "nombreSede": "Cine Center",
      "capacidad": 100,
      "entradasVendidas": 4,
      "cupoDisponible": 96
    }
  ]
}
```

---

**`GET /api/proyecciones/{codProyeccion}/asientos`**

Devuelve el mapa completo de butacas de la sala con estado Libre/Ocupado.

```json
// Respuesta 200
{
  "success": true,
  "data": [
    { "codAsiento": "asi_01_A01", "fila": "A", "numero": 1, "tipoAsiento": "VIP",      "estado": "Ocupado" },
    { "codAsiento": "asi_01_A03", "fila": "A", "numero": 3, "tipoAsiento": "VIP",      "estado": "Libre"   },
    { "codAsiento": "asi_01_C05", "fila": "C", "numero": 5, "tipoAsiento": "Estandar", "estado": "Libre"   }
  ]
}
```

---

**`POST /api/proyecciones/programar`**

Programa una nueva proyección. El trigger TR1 valida el horario en el servidor.

```json
// Request
{
  "codProyeccion": "proy_nuevo",
  "codPelicula": "pel_01",
  "codSala": "sala_06",
  "fechaHoraInicio": "2026-08-22T09:00:00",
  "fechaHoraFin": "2026-08-22T11:00:00",
  "sesionQa": null,
  "codEdicion": "edi_2026"
}

// Respuesta 200 — sin conflicto
{ "success": true, "message": "Proyección programada correctamente.", "data": { "codProyeccion": "proy_nuevo" } }

// Respuesta 409 — TR1 bloqueó
{ "success": false, "message": "Conflicto de agenda: la sala \"Patio Historico\" ya tiene una proyeccion programada en ese horario (considere los 30 min de limpieza).", "data": null }
```

---

#### Tarifas

**`GET /api/tarifas`**

Devuelve el catálogo de tarifas activas.

```json
{
  "success": true,
  "data": [
    { "codTarifa": "tar_01", "nombre": "Entrada General",   "precio": 45.00 },
    { "codTarifa": "tar_02", "nombre": "Entrada Estudiante","precio": 30.00 },
    { "codTarifa": "tar_03", "nombre": "Entrada VIP",       "precio": 80.00 }
  ]
}
```

---

#### Entradas

**`POST /api/entradas/comprar`**

Compra individual para un asistente existente (flujo legacy).

```json
// Request
{ "codAsistente": "asis_14", "codProyeccion": "proy_01", "codTarifa": "tar_01" }

// Respuesta 200
{
  "success": true,
  "data": {
    "codEntrada": "e_AF942BDB344E4F29A9",
    "precioPagado": 45.00,
    "codigoValidacion": "VAL-45420F14B5DA",
    "mensaje": "Entrada adquirida exitosamente."
  }
}
```

---

**`POST /api/entradas/comprar-multiple`**

Compra atómica de N asientos. Crea el asistente si no existe.

```json
// Request
{
  "nombres": "María",
  "apellidos": "López",
  "email": "maria@correo.com",
  "telefono": "70012345",
  "codProyeccion": "proy_01",
  "codTarifa": "tar_01",
  "codAsientos": ["asi_01_B03", "asi_01_B04"]
}

// Respuesta 200
{
  "success": true,
  "data": {
    "codAsistente": "asis_C869825FDD22409",
    "nombreAsistente": "María López",
    "email": "maria@correo.com",
    "pelicula": "Sombras del Illimani",
    "fechaHoraInicio": "2026-08-16T19:00:00",
    "nombreSala": "Sala VIP Center",
    "nombreSede": "Cine Center",
    "totalPagado": 90.00,
    "entradas": [
      { "codEntrada": "e_XX1", "codAsiento": "asi_01_B03", "fila": "B", "numero": 3, "codigoValidacion": "VAL-XX1", "precioPagado": 45.00 },
      { "codEntrada": "e_XX2", "codAsiento": "asi_01_B04", "fila": "B", "numero": 4, "codigoValidacion": "VAL-XX2", "precioPagado": 45.00 }
    ]
  }
}

// Respuesta 409 — asiento ocupado
{ "success": false, "message": "El asiento ya fue tomado. Seleccione otro.", "data": null }
```

---

#### Abonos

**`POST /api/abonos/vender`**

Vende un abono invocando `sp_VenderAbono`.

```json
// Request
{ "codAsistente": "asis_14", "codAbono": "abo_01", "metodoPago": "Tarjeta" }

// Respuesta 200
{
  "success": true,
  "data": {
    "codCompraAbono": "ca_XXXX",
    "codigoAcceso": "ACC-asis_14-2026-A3F7B2C1",
    "montoPagado": 250.00,
    "mensaje": "Abono vendido exitosamente. Guarde su codigo de acceso."
  }
}
```

---

#### Portal del asistente

**`GET /api/asistente/portal?email={email}`**

Devuelve el historial completo de un asistente buscando por email.

```json
// Respuesta 200
{
  "success": true,
  "data": {
    "codAsistente": "asis_07",
    "nombres": "Andres",
    "apellidos": "Molina",
    "email": "andres.m@email.com",
    "totalEntradas": 2,
    "totalAbonos": 1,
    "entradas": [ { "codEntrada": "...", "pelicula": "...", "fila": "B", "numero": 3, ... } ],
    "abonos":   [ { "codCompraAbono": "...", "nombreAbono": "Abono Total Festival", "codigoAcceso": "ACC-...", ... } ]
  }
}

// Respuesta 404
{ "success": false, "message": "No se encontró ninguna cuenta con ese correo.", "data": null }
```

---

#### Reportes

**`GET /api/reportes/ranking?codEdicion={cod}`**  
**`GET /api/reportes/acta-premiacion?codEdicion={cod}`**  
**`GET /api/reportes/informe-financiero`**

Cada uno consulta su vista correspondiente y devuelve los datos serializados.

---

### 5.3 Arquitectura de capas del backend

```
Controller  →  solo deserializa el request y devuelve IActionResult
Service     →  captura SqlException, extrae el mensaje del RAISERROR
Repository  →  llama a la vista o SP con Dapper, mapea resultado a DTO
```

**Manejo de errores SQL:**

```csharp
// Service
try { return (await _repo.ComprarMultipleAsync(request), null); }
catch (SqlException ex) { return (null, SqlExceptionHandler.ObtenerMensajeAmigable(ex)); }

// Controller
if (error is not null)
    return Conflict(ApiResponse<T>.Fail(error));
return Ok(ApiResponse<T>.Ok(result));
```

**CORS:** Configurado con `AllowAnyOrigin` para desarrollo local. En producción se debe restringir al dominio del frontend.

---

## 6. Frontend — Módulos

El frontend consiste en 5 páginas HTML independientes. No usa ningún framework. Toda la comunicación con la API pasa por `js/api.js`.

### 6.1 Estructura de archivos

```
frontend/
├── index.html          — Landing page
├── taquilla.html       — Wizard de compra (5 pasos)
├── portal.html         — Portal del asistente
├── agenda.html         — Panel de administración de agenda
├── reportes.html       — Reportes estadísticos
├── css/
│   └── styles.css      — Tema morado/blanco · variables CSS · todos los componentes
└── js/
    ├── config.js       — URL base de la API y catálogos estáticos (salas, abonos)
    ├── api.js          — Cliente HTTP centralizado
    ├── taquilla.js     — State machine del wizard
    ├── portal.js       — Lookup por email y gestión del dashboard
    ├── agenda.js       — Formulario de programación
    └── reportes.js     — Carga y renderizado de las 3 tabs de reportes
```

### 6.2 `api.js` — Cliente centralizado

```javascript
const API = (() => {
  async function _fetch(endpoint, options = {}) {
    const res  = await fetch(CONFIG.API_BASE + endpoint, { ... });
    const json = await res.json();
    if (!json.success) throw new Error(json.message);
    return json.data;
  }
  return {
    peliculas:   { cartelera: () => API.get('/api/peliculas/cartelera') },
    proyecciones: {
      porPelicula: (cod) => API.get(`/api/proyecciones/pelicula/${cod}`),
      asientos:    (cod) => API.get(`/api/proyecciones/${cod}/asientos`),
      programar:   (dto) => API.post('/api/proyecciones/programar', dto),
    },
    entradas: {
      comprar:         (dto) => API.post('/api/entradas/comprar', dto),
      comprarMultiple: (dto) => API.post('/api/entradas/comprar-multiple', dto),
    },
    asistente: {
      portal: (email) => API.get(`/api/asistente/portal?email=${encodeURIComponent(email)}`),
    },
    // ...
  };
})();
```

Si `json.success` es `false`, lanza un `Error` con el mensaje del servidor. Cada módulo JS lo captura en su propio `catch` y lo muestra en pantalla.

### 6.3 Taquilla — Wizard de 5 pasos

```
Paso 1: Películas  →  GET /cartelera          →  grilla de tarjetas
Paso 2: Funciones  →  GET /proyecciones       →  lista con indicador de cupo
Paso 3: Asientos   →  GET /asientos           →  mapa visual de butacas
Paso 4: Datos      →  GET /tarifas            →  formulario + resumen de compra
Paso 5: Comprobante →  POST /comprar-multiple →  ticket con códigos de validación
```

El estado se mantiene en un objeto JavaScript:

```javascript
const state = {
  step: 1, pelicula: null, proyeccion: null,
  asientos: [], seleccionados: [], tarifa: null, tarifas: []
};
```

### 6.4 Portal del asistente

Lookup sin autenticación: el asistente ingresa su email y el sistema devuelve su historial completo. Muestra entradas con sala y fecha, abonos con código de acceso, y permite comprar un nuevo abono desde el mismo portal.

### 6.5 Agenda

Formulario de programación protegido por TR1 en el servidor. El administrador completa película, sala y horario; si hay conflicto, el mensaje del trigger aparece directamente en pantalla.

### 6.6 Reportes

Tres tabs con carga bajo demanda:
- **Ranking** — se carga automáticamente al abrir la página
- **Acta de premiación** — carga al presionar "Actualizar"
- **Informe financiero** — carga al presionar "Actualizar"

---

## 7. Instalación y puesta en marcha

Ver [SETUP.md](SETUP.md) para la guía paso a paso completa.

**Resumen de comandos:**

```powershell
# 1. Base de datos (en orden)
sqlcmd -S localhost -E -C    -i sql\01_DDL.sql              -d FestCine
sqlcmd -S localhost -E -C    -i sql\02_DML.sql              -d FestCine
sqlcmd -S localhost -E -C    -i sql\03_DQL_Programacion.sql -d FestCine
sqlcmd -S localhost -E -C -I -i sql\04_Migracion_Asientos.sql -d FestCine

# 2. Backend (Terminal 1)
cd backend\FestCine.API
dotnet run

# 3. Frontend (Terminal 2)
cd frontend
python -m http.server 8080
```

**URLs de acceso:**

| Recurso | URL |
|---|---|
| Frontend | `http://localhost:8080` |
| API | `http://localhost:5000` |
| Swagger (si habilitado) | `http://localhost:5000/swagger` |

---

## 8. Consideraciones técnicas

### 8.1 Seguridad

| Aspecto | Estado actual | Recomendación para producción |
|---|---|---|
| Autenticación | Sin sistema de auth — portal usa lookup por email | Implementar JWT o session-based auth |
| CORS | `AllowAnyOrigin` (todos los orígenes) | Restringir al dominio del frontend |
| Conexión a BD | `Trusted_Connection` (Windows auth) | Usar usuario SQL Server dedicado con permisos mínimos |
| HTTPS | Solo HTTP en desarrollo | Habilitar certificado TLS y redirigir HTTP → HTTPS |
| Validación de inputs | Validación básica en frontend + constraints en BD | Agregar validación en capa Service del backend |
| Inyección SQL | No hay riesgo — Dapper usa parámetros en todos los casos | Mantener este patrón; nunca concatenar strings en SQL |

### 8.2 Concurrencia

La verificación de aforo en los stored procedures usa un patrón **fail-fast**: primero lee el cupo disponible, luego inserta. En un escenario de alta concurrencia podría ocurrir una condición de carrera donde dos usuarios compren el último asiento simultáneamente.

**Protección implementada:** El índice único filtrado `UQ_Entradas_Proyeccion_Asiento` actúa como barrera final — solo uno de los dos inserts concurrentes puede tener éxito; el otro recibirá un error de violación de constraint único, que el `CATCH` del SP convierte en un mensaje amigable.

**Mejora recomendada para producción:** Agregar `WITH (UPDLOCK, ROWLOCK)` al `SELECT` de verificación de aforo dentro de la transacción.

### 8.3 Rendimiento

- Las vistas no están materializadas — cada consulta ejecuta el SQL completo. Para el volumen de datos del festival (< 10,000 filas en cualquier tabla) el rendimiento es adecuado.
- `vw_AsientosPorProyeccion` hace un JOIN sobre 1203 filas de `Asientos` para cada consulta del mapa. Indexable si se requiere escala.
- El índice clustered sobre `CHAR(20)` PKs es ligeramente menos eficiente que `INT IDENTITY` para inserts secuenciales, pero la diferencia es insignificante para este volumen.

### 8.4 Datos de prueba incluidos

| Entidad | Cantidad |
|---|---|
| Asistentes | 20 (`asis_01` a `asis_20`) |
| Películas | 7 (`pel_01` a `pel_07`) |
| Salas | 8 (capacidades: 3 a 300 butacas) |
| Asientos | 1203 distribuidos en 8 salas |
| Proyecciones | 13 (incluye cruce de medianoche en `proy_05`) |
| Entradas vendidas | 23 (3 llenan exactamente la Sala Mini Demo) |
| Compras de abono | 7 |
| Emails de prueba | `andres.m@email.com`, `lucia.v@email.com`, etc. |

---

## 9. Limitaciones conocidas

| Limitación | Descripción |
|---|---|
| **Sin autenticación** | El portal del asistente accede al historial solo con email. No hay contraseña ni sesión. |
| **Sin panel de admin** | Las acreditaciones (`Acreditaciones`) se gestionarían desde un panel de administración no implementado en este proyecto. |
| **Abonos sin validación en puerta** | La compra genera un `CodigoAcceso` único, pero no existe un endpoint de validación de ese código al momento del ingreso a una función. |
| **Sin reembolsos** | No se implementó lógica de cancelación o reembolso de entradas. |
| **Edición fija** | El frontend usa `edi_2026` como constante. No hay mecanismo para cambiar de edición desde la interfaz. |
| **Despliegue local** | El sistema corre únicamente en entorno local. No está publicado en ningún servidor. |
| **CORS abierto** | La configuración actual permite requests desde cualquier origen. |

---

## 10. Glosario

| Término | Definición |
|---|---|
| **Abono** | Pase de festival que da acceso a múltiples funciones. Genera un `CodigoAcceso` único. |
| **Acreditación** | Credencial especial asignada por el administrador a invitados VIP, prensa o jurado. |
| **Aforo** | Capacidad máxima de una sala. El SP verifica que no se supere al vender entradas. |
| **Buffer de limpieza** | 30 minutos adicionales que el trigger añade al fin de cada proyección para calcular conflictos de sala. |
| **CodigoValidacion** | Código alfanumérico generado por el SP al comprar una entrada. Sirve para verificar la autenticidad del ticket. |
| **Dapper** | Micro-ORM para .NET. Mapea resultados de SQL a objetos C# sin generar SQL propio. |
| **DTO** | Data Transfer Object. Clase C# que define la forma del dato entre capas o con el cliente. |
| **INSTEAD OF INSERT** | Tipo de trigger en SQL Server que reemplaza el INSERT original. El trigger decide si y cómo ejecutar la inserción real. |
| **RAISERROR** | Instrucción T-SQL que lanza un error con mensaje personalizado. El backend lo recibe como `SqlException`. |
| **Tarifa** | Categoría de precio para una entrada (General, Estudiante, VIP, etc.). |
| **Wizard** | Flujo de compra dividido en 5 pasos secuenciales en la página de Taquilla. |
