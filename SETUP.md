# FestCine — Cómo correr el proyecto desde cero

> Guía para una persona que recibe el proyecto en un ZIP/WinRAR y quiere levantarlo en su máquina.

---

## Requisitos previos

Instala estas herramientas antes de empezar. Todas son gratuitas.

| Herramienta | Para qué | Descarga |
|---|---|---|
| **SQL Server Express** | Motor de base de datos | `aka.ms/sqlexpress` (elige "Express") |
| **SSMS** (opcional) | Ver la BD gráficamente | `aka.ms/ssmsfullsetup` |
| **.NET 9 SDK** | Correr el backend | `dot.net/download` → .NET 9 |
| **VS Code** | Editor | `code.visualstudio.com` |
| **Python 3** | Servidor para el frontend | `python.org/downloads` |

### Extensiones de VS Code recomendadas

Abre VS Code → `Ctrl+Shift+X` → busca e instala:

- **C# Dev Kit** (Microsoft) — para el backend
- **SQL Server (mssql)** (Microsoft) — para ver la BD desde VS Code

---

## Paso 1 — Crear la base de datos

Abre una terminal (PowerShell o CMD) y ejecuta los scripts en orden:

```powershell
# 1. Crear la BD y las tablas
sqlcmd -S localhost\SQLEXPRESS -E -C -Q "CREATE DATABASE FestCine"
sqlcmd -S localhost\SQLEXPRESS -E -C -i "sql\01_DDL.sql" -d FestCine

# 2. Insertar datos de prueba
sqlcmd -S localhost\SQLEXPRESS -E -C -i "sql\02_DML.sql" -d FestCine

# 3. Crear vistas, SPs y trigger
sqlcmd -S localhost\SQLEXPRESS -E -C -i "sql\03_DQL_Programacion.sql" -d FestCine

# 4. Crear tabla Asientos + vista de mapa + SP de compra múltiple
sqlcmd -S localhost\SQLEXPRESS -E -C -I -i "sql\04_Migracion_Asientos.sql" -d FestCine

# 5. Tarifas↔Asientos, promoción miércoles y reportes financieros en 2 vistas
sqlcmd -S localhost\SQLEXPRESS -E -C -i "sql\05_Migracion_TarifasPromocionesReportes.sql" -d FestCine
```

> **Nota:** Si SQL Server está instalado como instancia por defecto (no Express), cambia `-S localhost\SQLEXPRESS` por `-S localhost`.

> **Nota:** El script 04 usa la bandera `-I` (mayúscula). Es obligatoria para crear el índice filtrado. Sin ella fallará con un error de `QUOTED_IDENTIFIER`.

---

## Paso 2 — Verificar la cadena de conexión del backend

Abre el archivo:

```
backend/FestCine.API/appsettings.json
```

Verifica que diga:

```json
{
  "ConnectionStrings": {
    "FestCineDb": "Server=localhost;Database=FestCine;Trusted_Connection=True;TrustServerCertificate=True;Encrypt=True;"
  }
}
```

Si tu SQL Server es una instancia con nombre (ej. `DESKTOP-ABC\SQLEXPRESS`), cambia `Server=localhost` por `Server=DESKTOP-ABC\SQLEXPRESS`.

Para encontrar el nombre de tu instancia ejecuta en PowerShell:

```powershell
(Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server").InstalledInstances
```

---

## Paso 3 — Correr el backend

En VS Code, abre una terminal integrada (`Ctrl+\`` `) y ejecuta:

```powershell
cd backend\FestCine.API
dotnet run
```

La primera vez descargará los paquetes NuGet (requiere internet). Cuando veas:

```
Now listening on: http://localhost:5000
```

el backend está listo. **No cierres esta terminal.**

Para verificar que responde, abre otra terminal y ejecuta:

```powershell
curl http://localhost:5000/api/peliculas/cartelera
```

Deberías ver un JSON con `"success": true`.

---

## Paso 4 — Correr el frontend

Abre una **segunda terminal** (sin cerrar la del backend) y ejecuta:

```powershell
cd frontend
python -m http.server 8080
```

Cuando veas `Serving HTTP on 0.0.0.0 port 8080`, abre el navegador en:

```
http://localhost:8080
```

> **¿Por qué no abrir el HTML directo?** Los navegadores bloquean las peticiones `fetch` desde archivos locales (`file://`). El servidor Python resuelve eso sirviendo el frontend por HTTP.

---

## Paso 5 — Probar que todo funciona

| Módulo | URL | Qué hace |
|---|---|---|
| Inicio | `http://localhost:8080/index.html` | Landing del festival |
| Taquilla | `http://localhost:8080/taquilla.html` | Wizard de compra con mapa de asientos |
| Mi Portal | `http://localhost:8080/portal.html` | Dashboard del asistente por email |
| Agenda | `http://localhost:8080/agenda.html` | Programar proyecciones (demo del trigger) |
| Reportes | `http://localhost:8080/reportes.html` | Ranking, acta y finanzas |

---

## Flujo de demo rápida (6 pasos)

**1. Comprar entradas (taquilla.html) — wizard de 6 pasos**
- Elige una película → elige una función → **elige tarifa y cantidad de entradas** → el mapa de asientos solo permite seleccionar asientos compatibles con esa tarifa (p.ej. "Acceso VIP" solo habilita asientos VIP) y exige exactamente la cantidad elegida → completa los datos → confirma
- El comprobante muestra los códigos de validación generados por el SP

**2. Ver el portal (portal.html)**
- Ingresa el email que usaste en la compra → verás las entradas recién compradas

**3. Sala llena**
- En taquilla elige la película "El Ocaso del Sol" → la función en "Sala Mini Demo" aparece con 🔴 SIN CUPO (3/3 vendidas)

**4. Trigger bloquea conflicto de horario (agenda.html)**
- Sala: Patio Historico | Inicio: `2026-08-21 21:20` | Fin: `2026-08-21 23:00`
- Clic en Programar → error del trigger: "proy_06 termina 21:00 + 30 min = 21:30, tu función empieza 21:20 → BLOQUEADO"
- La hora de fin ahora se calcula sola (duración de la película) y no se puede editar.

**5. Promoción "Miércoles 50%" (taquilla.html)**
- Si la compra se hace un **miércoles entre 10:00 y 18:00** (hora del servidor) y la tarifa elegida es **Entrada General**, el precio de esas entradas baja un 50% automáticamente.
- El comprobante muestra el precio original tachado, el badge "🎉 -50% promo miércoles" y el descuento total. Otras tarifas (Estudiante, 3ra Edad, Preventa, VIP, Gratuita) no se ven afectadas aunque sea miércoles.

**6. Reportes (reportes.html)**
- Tab Ranking → barras de ocupación por película
- Tab Informe Financiero → dos tablas: "Recaudación por tipo de venta" (bruto/descuento/neto) y "Recaudación por tipo de tarifa" (las ventas con promo miércoles aparecen como fila separada, p.ej. "Entrada General - Promo miercoles 50%")

---

## Estructura de archivos

```
FestCine/
├── sql/
│   ├── 01_DDL.sql                  ← Tablas y constraints
│   ├── 02_DML.sql                  ← Datos de prueba
│   ├── 03_DQL_Programacion.sql     ← Vistas, SPs, trigger
│   ├── 04_Migracion_Asientos.sql   ← Asientos + mapa + compra múltiple
│   └── 05_Migracion_TarifasPromocionesReportes.sql
│                                    ← Tarifas↔Asientos, promo miércoles, informe financiero en 2 vistas
├── backend/
│   └── FestCine.API/
│       ├── appsettings.json        ← Cadena de conexión ← EDITAR SI ES NECESARIO
│       ├── Controllers/            ← Endpoints REST
│       ├── Services/               ← Lógica de errores SQL
│       ├── Data/                   ← Consultas con Dapper
│       └── DTOs/                   ← Tipos de datos entrada/salida
├── frontend/
│   ├── index.html
│   ├── taquilla.html
│   ├── portal.html
│   ├── agenda.html
│   ├── reportes.html
│   ├── css/styles.css
│   └── js/
│       ├── config.js               ← URL base de la API
│       ├── api.js
│       ├── taquilla.js
│       ├── portal.js
│       ├── agenda.js
│       └── reportes.js
├── DEFENSA.md                      ← Guión de defensa
└── SETUP.md                        ← Este archivo
```

---

## Solución de problemas comunes

**`sqlcmd` no se reconoce como comando**
> Instala el paquete "sqlcmd" separado desde `aka.ms/go-sqlcmd-download` o usa SSMS para ejecutar los scripts manualmente.

**Error al ejecutar el script 04: `QUOTED_IDENTIFIER`**
> Asegúrate de usar la bandera `-I` (mayúscula i) en el comando sqlcmd. Es obligatoria para índices filtrados.
> El script 05 no necesita `-I`: ya incluye los `SET ANSI_NULLS/QUOTED_IDENTIFIER/... ON` requeridos para crear la columna calculada `DescuentoAplicado`.

**Backend error: `A network-related or instance-specific error`**
> SQL Server no está corriendo o el nombre de la instancia en `appsettings.json` es incorrecto. Abre SSMS y verifica el nombre exacto del servidor.

**Frontend muestra `Error desconocido del servidor` en todo**
> El backend no está corriendo o está en un puerto distinto. Verifica que `dotnet run` muestre `listening on http://localhost:5000` y que `config.js` tenga `API_BASE: 'http://localhost:5000'`.

**Python no se reconoce**
> Instala Python 3 desde `python.org` y marca "Add to PATH" durante la instalación. Reinicia la terminal.
