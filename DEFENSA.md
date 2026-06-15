# FestCine — Guión de Defensa del Trabajo Final

> **Cómo usar este documento:** Cada sección corresponde a una etapa de la exposición.
> Las frases en *cursiva* son sugerencias de lo que puedes decir en voz alta.
> Las cajas `PREGUNTA PROBABLE` anticipan lo que el docente puede preguntar.

---

## 0. Apertura (1 minuto)

*"El trabajo que presentamos es FestCine: un sistema de gestión para un festival internacional de cine independiente. La aplicación reemplaza hojas de cálculo por una solución cliente-servidor completa, con lógica de negocio centralizada en el servidor de base de datos SQL Server y una interfaz web que la consume."*

*"El stack elegido es: SQL Server con T-SQL para la base de datos, ASP.NET Core 9 Web API con Dapper como backend, y JavaScript, HTML y CSS puros en el frontend. Ninguna pantalla contiene SQL ni lógica de negocio: todo está en el servidor."*

---

## 1. Fase 1 — Modelo de Datos y Normalización

### 1.1 Diagrama entidad-relación (resumen verbal)

El modelo tiene **41 tablas** organizadas en 5 grupos:

| Grupo | Tablas clave |
|---|---|
| **Catálogos** (sin FK) | Formatos, EstadosPeliculas, Paises, Generos, Roles, Tarifas, Abonos |
| **Catálogo cinematográfico** | Peliculas, Personas, Participaciones (N:M con rol), PeliculasGeneros (N:M) |
| **Agenda y sedes** | Sedes, Salas, Proyecciones, EventosParalelos |
| **Competición** | CategoriasCompeticion, CategoriasEdiciones, JuradosCategorias, Evaluaciones, GanadoresPremios |
| **Clientes y ventas** | Asistentes, Acreditaciones, Entradas, Abonos, ComprasAbonos, CodigosAcceso, Pagos |
| **Logística** | Hoteles, Habitaciones, Alojamientos, Vuelos, Traslados, Patrocinios |

### 1.2 Normalización hasta 3FN

**Primera Forma Normal (1FN):**
- Todos los atributos son atómicos.
- La relación película-géneros (muchos a muchos) se normalizó en la tabla `PeliculasGeneros` en lugar de guardar géneros como lista en un campo de texto.
- La relación persona-película-rol se separó en `Participaciones`, evitando que una persona apareciera N veces en una misma columna.

**Segunda Forma Normal (2FN):**
- Ninguna tabla tiene dependencias parciales. Las tablas puente como `PeliculasGeneros (CodPelicula, CodGenero)` o `JuradosCategorias (CodPersona, CodCategoria)` no tienen atributos adicionales que dependan solo de una parte de la clave compuesta.
- En `Participaciones`, el atributo `Biografia` va en `Personas`, no en la tabla puente, porque depende solo de la persona.

**Tercera Forma Normal (3FN):**
- No hay dependencias transitivas. Por ejemplo: el precio de una tarifa vive en `Tarifas`; `Entradas` solo guarda `CodTarifa` y `PrecioPagado` (precio capturado al momento de la compra, que es un hecho histórico, no una dependencia transitiva).
- El nombre de una sala no está en `Proyecciones`; `Proyecciones` tiene `CodSala` que referencia a `Salas`.

**Decisión de desnormalización documentada:**
- `Entradas.PrecioPagado` y `ComprasAbonos.PrecioPagado`: guardamos el precio al momento de la compra aunque `Tarifas.Precio` y `Abonos.Precio` ya existen. Justificación: un precio puede cambiar para futuras ediciones del festival; el valor histórico de cada transacción debe quedar inmutable.
- `Pagos` es una tabla centralizada de auditoría financiera. Podría inferirse de `Entradas` y `ComprasAbonos`, pero mantenerla separada facilita el reporte financiero con una sola query sobre una sola tabla.

---

```
PREGUNTA PROBABLE:
"¿Por qué tienen PrecioPagado en Entradas si ya tienen el precio en Tarifas?"

RESPUESTA:
"Es un hecho histórico. Si el año siguiente la tarifa Estudiante sube de Bs. 30 a Bs. 45,
los reportes de la edición anterior deben seguir mostrando Bs. 30.
No es desnormalización por rendimiento sino por corrección semántica: son dos cosas distintas
— el precio vigente y el precio cobrado — y ambas deben existir."
```

---

## 2. Fase 2 — DDL y DML

### 2.1 Decisiones de implementación DDL

**Tipo de dato `CHAR(20)` para PKs:**  
Claves legibles y manejables como `asis_14`, `proy_01`, `sala_08`. Facilita las demos en vivo y los inserts de prueba sin necesidad de secuencias o identidades.

**`DATETIME2(0)` en Proyecciones y EventosParalelos:**  
Se eligió un solo campo `FechaHoraInicio / FechaHoraFin` en lugar de columnas `Fecha DATE + Hora TIME` separadas. Esto permite:
- Calcular solapamientos en el trigger con una sola comparación de rangos.
- Soportar proyecciones que cruzan la medianoche (`proy_05`: 22:30 del 20-ago → 00:05 del 21-ago).

**Restricción XOR en `Entradas`:**
```sql
CONSTRAINT CK_Entradas_XOR CHECK (
    (CodProyeccion IS NOT NULL AND CodEvento IS NULL) OR
    (CodProyeccion IS NULL     AND CodEvento IS NOT NULL)
)
```
Una entrada es exactamente para una proyección **o** para un evento paralelo, nunca ambas ni ninguna.

**Restricción similar en `Pagos`:**  
Un pago referencia exactamente una entrada individual **o** una compra de abono.

**`Evaluaciones.Puntuacion DECIMAL(4,2) CHECK BETWEEN 1 AND 10`:**  
Permite decimales (ej. 8.50) con margen de precisión, restringido al rango válido del enunciado.

**`Salas.Capacidad INT CHECK (Capacidad > 0)`:**  
Garantía en el servidor de que ninguna sala puede tener aforo cero o negativo.

**`Asistentes.Email UNIQUE`:**  
Impide registrar el mismo correo dos veces independientemente del código.

### 2.2 Datos de prueba DML

| Entidad | Cantidad |
|---|---|
| Asistentes | 20 (`asis_01` a `asis_20`) |
| Películas | 7 (`pel_01` a `pel_07`) todas en estado Seleccionada |
| Salas | 8 (incluye `sala_08` cap=3, para demostrar sala llena) |
| Proyecciones | 13 (incluye cruce de medianoche en `proy_05`) |
| Entradas vendidas | 23 (ent_08/09/10 llenan `sala_08`/`proy_13` exactamente) |
| Compras de abono | 7 |
| Pagos registrados | 30 (23 Entrada + 7 Abono) |

---

```
PREGUNTA PROBABLE:
"¿Por qué usan CHAR(20) y no INT IDENTITY para las PKs?"

RESPUESTA:
"Decisión de legibilidad para un sistema académico. CHAR(20) como asis_14 es autodescriptivo
en las demos. En producción usaríamos UNIQUEIDENTIFIER o INT IDENTITY según el volumen.
El motor igualmente crea el índice clustered sobre la PK sin diferencia funcional para
el número de registros que maneja FestCine."
```

---

## 3. Fase 3 — DQL, Vistas y Programación del Servidor

### 3.1 Las 7 vistas y su propósito

| Vista | Usa | La consume |
|---|---|---|
| `vw_PeliculasCartelera` | `STRING_AGG` para géneros | Taquilla y Agenda (dropdown películas) |
| `vw_ProyeccionesDisponibles` | `LEFT JOIN Entradas + COUNT` para cupo | Taquilla (dropdown funciones) |
| `vw_TarifasActivas` | Catálogo simple | Taquilla (dropdown tarifa) |
| `vw_RankingPeliculas` | `GROUP BY + ISNULL + NULLIF` | Reporte DQL 1 + Módulo Reportes |
| `vw_ActaPremiacion` | `LEFT JOIN Evaluaciones + AVG` | Reporte DQL 2 + Módulo Reportes |
| `vw_InformeFinanciero` | `CASE + GROUP BY` en Pagos | Reporte DQL 3 + Módulo Reportes |
| `vw_AsientosPorProyeccion` | `JOIN Asientos + LEFT JOIN Entradas` | Taquilla (mapa de asientos) |

**`vw_AsientosPorProyeccion` — cómo calcula el estado de cada butaca:**
```sql
CASE WHEN e.CodEntrada IS NOT NULL THEN 'Ocupado' ELSE 'Libre' END AS Estado
```
Hace `JOIN Asientos + Proyecciones` para listar todas las butacas de la sala, y un `LEFT JOIN Entradas` para ver cuáles ya están vendidas. Si el LEFT JOIN devuelve NULL, el asiento está libre. La vista se consulta cada vez que el usuario abre el mapa — no hay estado cacheado.

**Cálculo de `CupoDisponible` en `vw_ProyeccionesDisponibles`:**
```sql
s.Capacidad - COUNT(e.CodEntrada) AS CupoDisponible
```
Solo se cuentan entradas individuales (`Entradas`), no usos de abono (`UsosAbonos`).
Esta decisión es consistente con cómo `sp_ComprarEntrada` verifica el aforo.

### 3.2 Reportes DQL avanzados

**Ranking — función de ventana `RANK()`:**
```sql
RANK() OVER (ORDER BY r.TotalAsistentes DESC, r.PctOcupacion DESC) AS Posicion
```
`RANK()` produce empates con saltos (1,1,3...) en lugar de `ROW_NUMBER()` que nunca empata.
Semánticamente más correcto para un ranking de festival.

**Informe financiero — `SUM() OVER()`:**
```sql
SUM(TotalRecaudado) OVER (PARTITION BY TipoVenta) AS SubtotalTipoVenta,
SUM(TotalRecaudado) OVER ()                        AS GrandTotal
```
Las funciones de ventana calculan subtotales y gran total en una sola pasada sobre la vista,
sin necesidad de subconsultas ni UNION.

### 3.3 P1 — `sp_ComprarEntrada`

Flujo interno del procedimiento:
1. Obtener `Capacidad` de la sala (JOIN Proyecciones → Salas).
2. Contar entradas vendidas para esa proyección.
3. Si `Vendidas >= Capacidad` → `RAISERROR` con mensaje de usuario, `RETURN`.
4. Obtener precio de la tarifa.
5. Si se pasó `@CodAsiento` (opcional): verificar que pertenezca a la sala y que no esté ocupado.
6. Generar IDs únicos con `LEFT('e_' + REPLACE(CAST(NEWID()...), '-', ''), 20)` y `CodigoValidacion`.
7. `BEGIN TRANSACTION` → `INSERT Entradas` + `INSERT Pagos` → `COMMIT`.
8. `SELECT` final con `CodEntrada`, `PrecioPagado`, `CodigoValidacion`, `Mensaje`.

---

```
PREGUNTA PROBABLE:
"¿Por qué verifican el aforo antes de la transacción y no dentro?"

RESPUESTA:
"Es un patrón fail-fast. La verificación previa es una lectura rápida que evita abrir
una transacción si ya sabemos que va a fallar. Técnicamente podría haber una condición
de carrera entre la verificación y el INSERT en un sistema de alta concurrencia;
en ese caso se agregaría SELECT con UPDLOCK. Para el volumen de FestCine la lógica
actual es suficiente y más legible."
```

### 3.4 P2 — `sp_ComprarEntradasMultiples` (compra de N asientos)

Procedimiento nuevo que el wizard de taquilla llama cuando el usuario confirma su selección de asientos.

**Lo que hace de diferente a `sp_ComprarEntrada`:**
1. **Busca o crea el Asistente por Email** — no requiere que el asistente exista previamente; si el email no está registrado, genera un `CodAsistente` nuevo con `NEWID()` e inserta en `Asistentes`.
2. **Itera con cursor** sobre una lista CSV de asientos (`@ListaAsientos = 'asi_01_A01,asi_01_A02'`), usando `STRING_SPLIT`.
3. **Por cada asiento**: verifica que pertenezca a la sala de la proyección → verifica que no esté ya ocupado → inserta en `Entradas` + `Pagos`.
4. **Todo en una sola transacción**: si un asiento falla a mitad del cursor, el `CATCH` hace `ROLLBACK` de todos los que ya se insertaron.
5. **Devuelve 2 result sets**: el primero es la lista de entradas generadas; el segundo es la info del asistente. El backend los lee con `QueryMultipleAsync` de Dapper.

**Índice único filtrado que protege la integridad:**
```sql
CREATE UNIQUE INDEX UQ_Entradas_Proyeccion_Asiento
ON Entradas (CodProyeccion, CodAsiento)
WHERE CodProyeccion IS NOT NULL AND CodAsiento IS NOT NULL;
```
Aunque el SP ya verifica antes de insertar, este índice es la red de seguridad: si dos requests llegan al mismo tiempo, solo uno puede insertar el mismo asiento — el segundo recibirá un error de constraint único.

---

```
PREGUNTA PROBABLE:
"¿Por qué verifican el asiento en el SP si ya tienen el índice único?"

RESPUESTA:
"El índice es la garantía a nivel de base de datos — nunca falla.
La verificación previa en el SP es para dar un mensaje de error legible al usuario
('El asiento ya fue tomado. Seleccione otro.') en lugar del mensaje técnico de SQL Server
sobre violación de índice único. Son dos capas de defensa con propósitos distintos."
```

---

### 3.5 T1 — `sp_VenderAbono` (transacción atómica)

Los tres pasos que deben ser atómicos:
```
1. INSERT ComprasAbonos   ← registra la venta
2. INSERT CodigosAcceso   ← genera el código único de acceso
3. INSERT Pagos           ← emite la factura/registro de pago
```

Si cualquiera falla (datos inconsistentes, violación de UNIQUE en `CodigoGenerado`):
```sql
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    RAISERROR(@Err, 16, 1);
END CATCH
```
El `ROLLBACK` revierte los tres inserts. El cliente recibe el error y lo muestra al usuario.

**Código de acceso generado:**
```
ACC-{CodAsistente}-{AÑO}-{8 chars aleatorios}
ej: ACC-asis_15-2026-A3F7B2C1
```
Único porque `CodigosAcceso.CodigoGenerado` tiene restricción `UNIQUE`.

---

```
PREGUNTA PROBABLE:
"¿Qué pasa si el NEWID() genera el mismo código dos veces?"

RESPUESTA:
"La probabilidad es de 1 en 2^122 — prácticamente cero. Pero si ocurriera, la restricción
UNIQUE en CodigosAcceso.CodigoGenerado lanzaría una violación de constraint, el CATCH
haría ROLLBACK y el cliente recibiría el error. El usuario podría reintentar la compra."
```

### 3.6 TR1 — `trg_ControlAgenda_Proyecciones`

**Por qué `INSTEAD OF INSERT` y no `BEFORE INSERT`:**
SQL Server no tiene triggers BEFORE INSERT. El equivalente es `INSTEAD OF INSERT`:
el trigger intercepta la operación *antes* de que el dato llegue a la tabla.
Si no hay conflicto, el propio trigger ejecuta el INSERT real.
Si hay conflicto, hace `RAISERROR` + `RETURN` sin insertar nada.

**Fórmula de solapamiento con buffer de 30 minutos:**
```
newStart < existingEnd + 30min  AND  existingStart < newEnd + 30min
```
Dos rangos `[A, B]` y `[C, D]` se solapan si y solo si `A < D` y `C < B`.
El buffer de limpieza extiende el `D` efectivo 30 minutos.

**Demostración con los datos de prueba:**
- `proy_06` ocupa `sala_06` de `19:00` a `21:00` el 2026-08-21.
- Buffer: `21:00 + 30 min = 21:30`.
- Intento de insertar `proy_test2` que inicia a `21:20`:
  - `21:20 < 21:30` ✅ y `19:00 < 23:30` ✅ → **CONFLICTO DETECTADO → BLOQUEADO**.
- Insertar `proy_test1` el `2026-08-22 09:00` en la misma sala:
  - No hay ninguna proyección ese día en sala_06 → **PERMITIDO**.

**Soporte para INSERT batch:**
El trigger usa `CURSOR LOCAL FAST_FORWARD FOR SELECT ... FROM INSERTED`
porque `INSERTED` puede tener múltiples filas si se insertan N proyecciones en un solo statement.
Procesa cada fila individualmente; si alguna falla, hace RAISERROR y abandona el cursor.

---

```
PREGUNTA PROBABLE:
"¿El trigger dentro del trigger no causa recursión infinita?"

RESPUESTA:
"No. El INSERT que hace el trigger dentro de su propio cuerpo sobre la tabla Proyecciones
no dispara el trigger nuevamente porque SQL Server, en modo INSTEAD OF, no recursa
por defecto. La opción RECURSIVE_TRIGGERS de la base de datos controla la recursión
directa, pero en triggers INSTEAD OF el motor simplemente ejecuta el INSERT real sin
volver a pasar por el trigger."
```

---

## 4. Fase 4 — Backend ASP.NET Core Web API

### 4.1 Arquitectura de capas

```
HTTP Request
     │
     ▼
[Controller]   ← Solo recibe, valida tipos y devuelve HTTP codes
     │
     ▼
[Service]      ← Captura SqlException → mensaje amigable
     │
     ▼
[Repository]   ← Dapper: llama vista o SP, mapea resultado a DTO
     │
     ▼
SQL Server     ← Toda la lógica de negocio vive aquí
```

**Por qué Dapper y no Entity Framework:**
- El enunciado exige que la lógica resida en el servidor (SPs, vistas, triggers).
- EF tiende a generar SQL propio y abstrae el acceso, lo que podría inducir a escribir lógica en C# en lugar de en el servidor.
- Dapper es un micro-ORM: mapea resultados a DTOs sin generar SQL por su cuenta. Es la herramienta correcta para este patrón.

### 4.2 Manejo de errores SQL → respuesta HTTP

Todos los `RAISERROR` del servidor llegan al cliente C# como `SqlException`.
El `SqlExceptionHandler` extrae `ex.Message` (el texto del RAISERROR) y lo devuelve al frontend como `ApiResponse<T>.Fail(mensaje)` con HTTP 409 Conflict.

```csharp
// EntradasService.cs
catch (SqlException ex)
{
    return (null, SqlExceptionHandler.ObtenerMensajeAmigable(ex));
}
// EntradasController.cs
if (error is not null)
    return Conflict(ApiResponse<ComprarEntradaResponseDto>.Fail(error));
```

### 4.3 Contrato `ApiResponse<T>`

Toda respuesta tiene la misma forma, sea éxito o error:
```json
{ "success": true,  "data": { ... }, "message": null }
{ "success": false, "data": null,    "message": "Lo sentimos, no hay aforo..." }
```
El frontend siempre lee `json.success` antes de usar `json.data`.

### 4.4 Endpoints implementados

| Método | Ruta | Mecanismo servidor |
|---|---|---|
| GET | `/api/peliculas/cartelera` | `vw_PeliculasCartelera` |
| GET | `/api/proyecciones/pelicula/{cod}` | `vw_ProyeccionesDisponibles` |
| GET | `/api/proyecciones/{cod}/asientos` | `vw_AsientosPorProyeccion` |
| GET | `/api/tarifas` | `vw_TarifasActivas` |
| POST | `/api/entradas/comprar` | `sp_ComprarEntrada` |
| POST | `/api/entradas/comprar-multiple` | `sp_ComprarEntradasMultiples` |
| POST | `/api/abonos/vender` | `sp_VenderAbono` |
| POST | `/api/proyecciones/programar` | `INSERT → trg_ControlAgenda` |
| GET | `/api/asistente/portal?email=...` | SELECT directo Asistentes + Entradas + ComprasAbonos |
| GET | `/api/reportes/ranking` | `vw_RankingPeliculas` + `RANK()` |
| GET | `/api/reportes/acta-premiacion` | `vw_ActaPremiacion` |
| GET | `/api/reportes/informe-financiero` | `vw_InformeFinanciero` + `SUM() OVER()` |

---

```
PREGUNTA PROBABLE:
"¿Por qué devuelven 409 Conflict en lugar de 400 Bad Request para los errores del servidor?"

RESPUESTA:
"400 Bad Request indica que el problema está en el formato o los datos del request HTTP.
409 Conflict es más preciso: el request está bien formado, pero genera un conflicto
con el estado actual del servidor — sala llena, cruce de horario.
Es la semántica correcta según RFC 9110."
```

---

## 5. Fase 5 — Frontend JavaScript/HTML/CSS

### 5.1 Principio de diseño: sin lógica de negocio en el cliente

- El archivo `api.js` centraliza todos los `fetch`. Los módulos no hacen peticiones directamente.
- `config.js` contiene la URL base y los catálogos de referencia estáticos (salas, abonos).
- Ningún archivo `.js` contiene SQL ni validaciones de negocio (cupo, conflicto de horario).
- Las validaciones de los formularios son solo de formato: campos vacíos, fecha fin > fecha inicio.

### 5.2 Flujo de la Taquilla (Módulo 1)

```
1. Carga → GET /api/peliculas/cartelera     → puebla <select> Películas
         → GET /api/tarifas                 → puebla <select> Tarifas
2. Usuario elige película
         → GET /api/proyecciones/pelicula/{cod} → puebla <select> Funciones
           (muestra cupo: 🟢 disponible / 🟡 últimos lugares / 🔴 sin cupo)
3. Usuario confirma → POST /api/entradas/comprar
   a. Éxito (200): muestra ticket con CodEntrada y precio
   b. Error (409): muestra mensaje del servidor (ej. "no hay aforo disponible")
```

### 5.3 Flujo de la Agenda (Módulo 2)

```
1. Carga → GET /api/peliculas/cartelera → puebla <select> Películas
         → Salas estáticas de config.js → puebla <select> Salas
2. Admin completa: película, sala, fecha/hora inicio y fin
3. Click "Programar" → POST /api/proyecciones/programar
   a. Éxito (200): muestra confirmación + agrega a panel "Programadas en esta sesión"
   b. Error 409 del TR1: muestra el mensaje de conflicto del trigger en pantalla
```

### 5.4 Manejo del error de TR1 en el frontend

```javascript
// agenda.js
} catch (err) {
  showAlert('error',
    `<strong>Conflicto de agenda detectado por el servidor:</strong><br>${err.message}`);
}
```
El mensaje que redactó el trigger llega intacto al usuario:
> *"Conflicto de agenda: la sala "Patio Historico" ya tiene una proyeccion programada en ese horario (considere los 30 min de limpieza)."*

---

## 6. Plan de demostración en vivo

### Orden recomendado (≈ 8 minutos)

**Paso 1 — Taquilla: compra exitosa (P1)**
1. Abrir `taquilla.html`
2. Asistente: `asis_14`, Película: cualquiera que cargue en `proy_01`
3. Seleccionar la función en `sala_01` (cap=100, ~4 entradas vendidas → cupo amplio)
4. Tarifa: General
5. Confirmar → aparece ticket con CodEntrada y precio
6. *"El SP verificó el aforo, insertó en Entradas y en Pagos de forma atómica."*

**Paso 2 — Taquilla: sala llena (P1 rechaza)**
1. Mismo asistente, Película: `El Ocaso del Sol` (`proy_13`)
2. La función en `Sala Mini Demo` aparece con 🔴 SIN CUPO
3. Intentar confirmar de todas formas (desde consola o editando el select)
4. El backend devuelve 409, la UI muestra: *"Lo sentimos, no hay aforo disponible para esta funcion."*
5. *"El mensaje vino del RAISERROR de sp_ComprarEntrada, no del frontend."*

**Paso 3 — Agenda: proyección válida (TR1 permite)**
1. Abrir `agenda.html`
2. Sala: `Patio Historico`, Inicio: `2026-08-22 09:00`, Fin: `2026-08-22 11:00`
3. Clic en "Programar" → aparece en "Programadas en esta sesión"
4. *"El trigger ejecutó el INSERT porque no había conflicto."*

**Paso 4 — Agenda: cruce de horario (TR1 bloquea)**
1. Misma sala, Inicio: `2026-08-21 21:20`, Fin: `2026-08-21 23:00`
2. Clic en "Programar" → error en pantalla con el mensaje del trigger
3. *"proy_06 termina a las 21:00 más 30 minutos de limpieza da 21:30. Nuestra función empieza a las 21:20 — dentro del buffer. El trigger lo detectó y canceló el INSERT antes de que tocara la tabla."*

**Paso 5 — Reportes**
1. Abrir `reportes.html`
2. Tab Ranking → mostrar barras de ocupación
3. Tab Informe Financiero → mostrar subtotales y gran total

---

## 7. Preguntas frecuentes anticipadas

**"¿Qué pasa si cae la conexión a mitad de la transacción T1?"**
> SQL Server revierte automáticamente cualquier transacción abierta cuando la conexión se cierra. El BEGIN TRANSACTION sin COMMIT hace ROLLBACK implícito. Los tres inserts son atómicos: o están todos o no está ninguno.

**"¿Por qué no usaron procedimientos almacenados para los reportes también?"**
> El enunciado solo especifica procedimientos para operaciones transaccionales (P1 y T1). Los reportes son consultas de solo lectura sobre vistas, que ya encapsulan la lógica SQL. Llamar un SP de solo lectura que internamente hiciera SELECT sobre la vista no añadiría valor.

**"¿Cómo saben que el cupo en la vista está actualizado en tiempo real?"**
> `vw_ProyeccionesDisponibles` calcula `Capacidad - COUNT(Entradas)` en cada ejecución. No hay cache ni columna desnormalizada. Cada vez que el frontend pide las proyecciones, la vista re-cuenta las entradas vendidas en ese instante.

**"¿Qué pasa si dos usuarios compran la última entrada al mismo tiempo?"**
> Es una condición de carrera (race condition). Con la implementación actual podría haber una sobreventa de un ticket. La solución completa sería agregar `WITH (UPDLOCK, ROWLOCK)` al SELECT del aforo dentro del stored procedure, o implementar optimistic concurrency. Para el alcance de este trabajo, el patrón fail-fast es suficiente.

**"¿Por qué el trigger verifica también EventosParalelos?"**
> Una sala puede usarse tanto para proyecciones como para eventos paralelos (masterclasses, talleres). Si el trigger solo revisara `Proyecciones`, un evento podría solaparse con una proyección en la misma sala. El enunciado indica que las salas son compartidas.

**"¿Qué significa 3NF en términos prácticos para este modelo?"**
> Significa que si actualizo el nombre de un país en la tabla `Paises`, ese cambio se refleja automáticamente en todas las películas de ese país — no hay copias del nombre dispersas. Y que no existe ningún atributo que dependa de otro atributo que no sea clave.

---

## 8. Asunciones documentadas

Conforme al enunciado (sección 4), las siguientes asunciones se tomaron de forma explícita:

1. **Aforo:** Solo las entradas individuales (`Entradas`) cuentan para el cupo de una sala. Los abonos (`ComprasAbonos`) son pases generales que no reducen el aforo de una proyección específica al momento de la compra.

2. **Precio histórico:** `Entradas.PrecioPagado` y `ComprasAbonos.PrecioPagado` registran el precio efectivamente cobrado en el momento de la transacción, no el precio vigente del catálogo.

3. **Reembolsos:** No se implementó lógica de reembolso. Las entradas y abonos se consideran no reembolsables una vez emitidos.

4. **Habitaciones de hotel:** Se modela `Hoteles → Habitaciones → Alojamientos` con check-in/check-out, asumiendo que cada habitación tiene número único por hotel.

5. **Buffer de limpieza:** Se estableció en 30 minutos como tiempo mínimo entre el fin de una proyección y el inicio de la siguiente en la misma sala, tal como indica el enunciado.

6. **Código de acceso:** Se genera uno por compra de abono. Un solo código da derecho a todos los beneficios del abono. No se generan códigos por película individual.

7. **Tarifa $0 para VIP:** Se soporta mediante `Tarifas.Precio = 0.00` con `CHECK (Precio >= 0)`. La entrada se registra igualmente para control de aforo, con `Pagos.Monto = 0.00`.

8. **Edición activa:** El frontend usa `edi_2026` como edición fija. En producción habría un endpoint o configuración para determinar la edición activa.

---

## 9. Resumen del stack y archivos entregados

```
FestCine/
├── sql/
│   ├── 01_DDL.sql              ← 41+ tablas, PascalCase, constraints completas
│   ├── 02_DML.sql              ← Datos de prueba consistentes con demos
│   ├── 03_DQL_Programacion.sql ← 6 vistas + 3 DQL + sp_ComprarEntrada
│   │                               + sp_VenderAbono + trg_ControlAgenda
│   └── 04_Migracion_Asientos.sql ← Tabla Asientos (1203 butacas), vw_AsientosPorProyeccion
│                                     sp_ComprarEntradasMultiples, índice único filtrado
├── backend/
│   └── FestCine.API/           ← ASP.NET Core 9, Dapper, sin EF
│       ├── Controllers/        ← 7 controllers REST
│       ├── Services/           ← Capa de manejo de SqlException
│       ├── Data/               ← 9 repositorios con Dapper
│       └── DTOs/               ← Contratos tipados entrada/salida
└── frontend/
    ├── index.html              ← Landing con 4 módulos
    ├── taquilla.html           ← Módulo 1: Wizard 5 pasos con mapa de asientos
    ├── agenda.html             ← Módulo 2: Administrador
    ├── portal.html             ← Módulo 3: Portal del asistente (lookup por email)
    ├── reportes.html           ← Módulo 4: Reportes
    ├── css/styles.css          ← Tema morado/blanco (CSS puro)
    └── js/
        ├── config.js           ← URL de la API y catálogos estáticos
        ├── api.js              ← Cliente centralizado (0 SQL en el cliente)
        ├── taquilla.js         ← Wizard: película → función → asientos → datos → comprobante
        ├── portal.js           ← Lookup por email, entradas, abonos, comprar abono
        ├── agenda.js           ← Flujo de programación + demo TR1
        └── reportes.js         ← 3 reportes con tabs y tablas dinámicas
```

---

*Fin del guión de defensa — FestCine.*
