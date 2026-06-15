
-- ============================================================
-- FestCine - DDL Completo
-- Convencion: PascalCase en tablas y columnas
-- Motor: SQL Server (T-SQL)
-- Nota: Este script rehace toda la estructura desde cero.
--       Ejecutar en una base de datos vacia o nueva.
-- ============================================================

-- ============================================================
-- LIMPIEZA (DROP en orden inverso de dependencias FK)
-- ============================================================
IF OBJECT_ID('CodigosAcceso',    'U') IS NOT NULL DROP TABLE CodigosAcceso;
IF OBJECT_ID('Pagos',            'U') IS NOT NULL DROP TABLE Pagos;
IF OBJECT_ID('UsosAbonos',       'U') IS NOT NULL DROP TABLE UsosAbonos;
IF OBJECT_ID('ComprasAbonos',    'U') IS NOT NULL DROP TABLE ComprasAbonos;
IF OBJECT_ID('Entradas',         'U') IS NOT NULL DROP TABLE Entradas;
IF OBJECT_ID('Asientos',         'U') IS NOT NULL DROP TABLE Asientos;
IF OBJECT_ID('Acreditaciones',   'U') IS NOT NULL DROP TABLE Acreditaciones;
IF OBJECT_ID('GanadoresPremios', 'U') IS NOT NULL DROP TABLE GanadoresPremios;
IF OBJECT_ID('Evaluaciones',     'U') IS NOT NULL DROP TABLE Evaluaciones;
IF OBJECT_ID('JuradosCategorias','U') IS NOT NULL DROP TABLE JuradosCategorias;
IF OBJECT_ID('PeliculasCategorias','U') IS NOT NULL DROP TABLE PeliculasCategorias;
IF OBJECT_ID('CategoriasEdiciones','U') IS NOT NULL DROP TABLE CategoriasEdiciones;
IF OBJECT_ID('EventosExpositores','U') IS NOT NULL DROP TABLE EventosExpositores;
IF OBJECT_ID('EventosParalelos', 'U') IS NOT NULL DROP TABLE EventosParalelos;
IF OBJECT_ID('Proyecciones',     'U') IS NOT NULL DROP TABLE Proyecciones;
IF OBJECT_ID('Patrocinios',      'U') IS NOT NULL DROP TABLE Patrocinios;
IF OBJECT_ID('Vuelos',           'U') IS NOT NULL DROP TABLE Vuelos;
IF OBJECT_ID('Traslados',        'U') IS NOT NULL DROP TABLE Traslados;
IF OBJECT_ID('Alojamientos',     'U') IS NOT NULL DROP TABLE Alojamientos;
IF OBJECT_ID('Participaciones',  'U') IS NOT NULL DROP TABLE Participaciones;
IF OBJECT_ID('PeliculasGeneros', 'U') IS NOT NULL DROP TABLE PeliculasGeneros;
IF OBJECT_ID('Peliculas',        'U') IS NOT NULL DROP TABLE Peliculas;
IF OBJECT_ID('Personas',         'U') IS NOT NULL DROP TABLE Personas;
IF OBJECT_ID('Habitaciones',     'U') IS NOT NULL DROP TABLE Habitaciones;
IF OBJECT_ID('Salas',            'U') IS NOT NULL DROP TABLE Salas;
IF OBJECT_ID('Sedes',            'U') IS NOT NULL DROP TABLE Sedes;
IF OBJECT_ID('EdicionesFestivales','U') IS NOT NULL DROP TABLE EdicionesFestivales;
IF OBJECT_ID('Patrocinadores',   'U') IS NOT NULL DROP TABLE Patrocinadores;
IF OBJECT_ID('Hoteles',          'U') IS NOT NULL DROP TABLE Hoteles;
IF OBJECT_ID('Abonos',           'U') IS NOT NULL DROP TABLE Abonos;
IF OBJECT_ID('Tarifas',          'U') IS NOT NULL DROP TABLE Tarifas;
IF OBJECT_ID('TiposAcreditaciones','U') IS NOT NULL DROP TABLE TiposAcreditaciones;
IF OBJECT_ID('Asistentes',       'U') IS NOT NULL DROP TABLE Asistentes;
IF OBJECT_ID('Premios',          'U') IS NOT NULL DROP TABLE Premios;
IF OBJECT_ID('CategoriasCompeticion','U') IS NOT NULL DROP TABLE CategoriasCompeticion;
IF OBJECT_ID('TiposEventos',     'U') IS NOT NULL DROP TABLE TiposEventos;
IF OBJECT_ID('Roles',            'U') IS NOT NULL DROP TABLE Roles;
IF OBJECT_ID('Generos',          'U') IS NOT NULL DROP TABLE Generos;
IF OBJECT_ID('Paises',           'U') IS NOT NULL DROP TABLE Paises;
IF OBJECT_ID('ClasificacionesEdades','U') IS NOT NULL DROP TABLE ClasificacionesEdades;
IF OBJECT_ID('EstadosPeliculas', 'U') IS NOT NULL DROP TABLE EstadosPeliculas;
IF OBJECT_ID('Formatos',         'U') IS NOT NULL DROP TABLE Formatos;
GO

-- ============================================================
-- NIVEL 1 — CATÁLOGOS (sin dependencias FK)
-- ============================================================

CREATE TABLE Formatos (
    CodFormato   CHAR(20)     NOT NULL,
    TipoFormato  VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Formatos PRIMARY KEY (CodFormato)
);
GO

-- Renombrado de "estados" a "EstadosPeliculas" para mayor claridad semantica
CREATE TABLE EstadosPeliculas (
    CodEstado    CHAR(20)     NOT NULL,
    NombreEstado VARCHAR(255) NOT NULL,
    CONSTRAINT PK_EstadosPeliculas PRIMARY KEY (CodEstado)
);
GO

CREATE TABLE ClasificacionesEdades (
    CodClasificacion CHAR(20) NOT NULL,
    EdadMinima       INT      NOT NULL,
    EdadMaxima       INT      NOT NULL,
    CONSTRAINT PK_ClasificacionesEdades PRIMARY KEY (CodClasificacion),
    CONSTRAINT CK_ClasificacionesEdades_Rango
        CHECK (EdadMinima >= 0 AND EdadMaxima <= 120 AND EdadMinima <= EdadMaxima)
);
GO

CREATE TABLE Paises (
    CodPais    CHAR(20)     NOT NULL,
    NombrePais VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Paises PRIMARY KEY (CodPais)
);
GO

CREATE TABLE Generos (
    CodGenero    CHAR(20)     NOT NULL,
    NombreGenero VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Generos PRIMARY KEY (CodGenero)
);
GO

CREATE TABLE Roles (
    CodRol    CHAR(20)     NOT NULL,
    NombreRol VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Roles PRIMARY KEY (CodRol)
);
GO

CREATE TABLE TiposEventos (
    CodTipoEvento    CHAR(20)     NOT NULL,
    NombreTipoEvento VARCHAR(255) NOT NULL,
    CONSTRAINT PK_TiposEventos PRIMARY KEY (CodTipoEvento)
);
GO

CREATE TABLE CategoriasCompeticion (
    CodCategoria    CHAR(20)     NOT NULL,
    NombreCategoria VARCHAR(255) NOT NULL,
    Descripcion     VARCHAR(500) NOT NULL,
    CONSTRAINT PK_CategoriasCompeticion PRIMARY KEY (CodCategoria)
);
GO

CREATE TABLE Premios (
    CodPremio    CHAR(20)     NOT NULL,
    NombrePremio VARCHAR(255) NOT NULL,
    Descripcion  VARCHAR(500) NOT NULL,
    CONSTRAINT PK_Premios PRIMARY KEY (CodPremio)
);
GO

CREATE TABLE Asistentes (
    CodAsistente CHAR(20)     NOT NULL,
    Nombres      VARCHAR(255) NOT NULL,
    Apellidos    VARCHAR(255) NOT NULL,
    Telefono     VARCHAR(20),
    Email        VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Asistentes  PRIMARY KEY (CodAsistente),
    CONSTRAINT UQ_Asistentes_Email UNIQUE (Email)
);
GO

CREATE TABLE TiposAcreditaciones (
    CodTipoAcreditacion CHAR(20)     NOT NULL,
    Nombre              VARCHAR(255) NOT NULL,
    CONSTRAINT PK_TiposAcreditaciones PRIMARY KEY (CodTipoAcreditacion)
);
GO

CREATE TABLE Tarifas (
    CodTarifa CHAR(20)      NOT NULL,
    Nombre    VARCHAR(255)  NOT NULL,
    Precio    DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_Tarifas PRIMARY KEY (CodTarifa),
    CONSTRAINT CK_Tarifas_Precio CHECK (Precio >= 0)
);
GO

CREATE TABLE Abonos (
    CodAbono    CHAR(20)      NOT NULL,
    Nombre      VARCHAR(255)  NOT NULL,
    Precio      DECIMAL(10,2) NOT NULL,
    Descripcion VARCHAR(500)  NOT NULL,
    CONSTRAINT PK_Abonos PRIMARY KEY (CodAbono),
    CONSTRAINT CK_Abonos_Precio CHECK (Precio >= 0)
);
GO

CREATE TABLE Hoteles (
    CodHotel  CHAR(20)     NOT NULL,
    Nombre    VARCHAR(255) NOT NULL,
    Direccion VARCHAR(500) NOT NULL,
    CONSTRAINT PK_Hoteles PRIMARY KEY (CodHotel)
);
GO

CREATE TABLE Patrocinadores (
    CodPatrocinador CHAR(20)     NOT NULL,
    Nombre          VARCHAR(255) NOT NULL,
    Contacto        VARCHAR(255) NOT NULL,
    CONSTRAINT PK_Patrocinadores PRIMARY KEY (CodPatrocinador)
);
GO

CREATE TABLE EdicionesFestivales (
    CodEdicion  CHAR(20) NOT NULL,
    Anio        INT      NOT NULL,
    FechaInicio DATE     NOT NULL,
    FechaFin    DATE     NOT NULL,
    CONSTRAINT PK_EdicionesFestivales PRIMARY KEY (CodEdicion),
    CONSTRAINT CK_EdicionesFestivales_Fechas CHECK (FechaInicio <= FechaFin)
);
GO

-- ============================================================
-- NIVEL 2 — ENTIDADES CON FK A CATÁLOGOS
-- ============================================================

CREATE TABLE Sedes (
    CodSede    CHAR(20)     NOT NULL,
    NombreSede VARCHAR(255) NOT NULL,
    Direccion  VARCHAR(500) NOT NULL,
    CodPais    CHAR(20)     NOT NULL,
    CONSTRAINT PK_Sedes         PRIMARY KEY (CodSede),
    CONSTRAINT FK_Sedes_Paises  FOREIGN KEY (CodPais) REFERENCES Paises(CodPais)
);
GO

CREATE TABLE Salas (
    CodSala    CHAR(20)     NOT NULL,
    NombreSala VARCHAR(255) NOT NULL,
    Capacidad  INT          NOT NULL,
    CodSede    CHAR(20)     NOT NULL,
    CONSTRAINT PK_Salas           PRIMARY KEY (CodSala),
    CONSTRAINT FK_Salas_Sedes     FOREIGN KEY (CodSede) REFERENCES Sedes(CodSede),
    CONSTRAINT CK_Salas_Capacidad CHECK (Capacidad > 0)
);
GO

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
GO

CREATE TABLE Habitaciones (
    CodHabitacion CHAR(20)    NOT NULL,
    Numero        VARCHAR(50) NOT NULL,
    CodHotel      CHAR(20)    NOT NULL,
    CONSTRAINT PK_Habitaciones        PRIMARY KEY (CodHabitacion),
    CONSTRAINT FK_Habitaciones_Hoteles FOREIGN KEY (CodHotel) REFERENCES Hoteles(CodHotel)
);
GO

CREATE TABLE Peliculas (
    CodPelicula      CHAR(20)      NOT NULL,
    Titulo           VARCHAR(255)  NOT NULL,
    AnioProduccion   INT           NOT NULL,
    Duracion         INT           NOT NULL,    -- minutos
    Sinopsis         VARCHAR(1000) NOT NULL,
    CodFormato       CHAR(20)      NOT NULL,
    CodEstado        CHAR(20)      NOT NULL,
    CodClasificacion CHAR(20)      NOT NULL,
    CodPais          CHAR(20)      NOT NULL,
    CONSTRAINT PK_Peliculas PRIMARY KEY (CodPelicula),
    CONSTRAINT FK_Peliculas_Formatos
        FOREIGN KEY (CodFormato) REFERENCES Formatos(CodFormato),
    CONSTRAINT FK_Peliculas_EstadosPeliculas
        FOREIGN KEY (CodEstado) REFERENCES EstadosPeliculas(CodEstado),
    CONSTRAINT FK_Peliculas_ClasificacionesEdades
        FOREIGN KEY (CodClasificacion) REFERENCES ClasificacionesEdades(CodClasificacion),
    CONSTRAINT FK_Peliculas_Paises
        FOREIGN KEY (CodPais) REFERENCES Paises(CodPais),
    CONSTRAINT CK_Peliculas_Duracion CHECK (Duracion > 0)
);
GO

CREATE TABLE PeliculasGeneros (
    CodPeliculaGenero CHAR(20) NOT NULL,
    CodPelicula       CHAR(20) NOT NULL,
    CodGenero         CHAR(20) NOT NULL,
    CONSTRAINT PK_PeliculasGeneros PRIMARY KEY (CodPeliculaGenero),
    CONSTRAINT FK_PeliculasGeneros_Peliculas
        FOREIGN KEY (CodPelicula) REFERENCES Peliculas(CodPelicula),
    CONSTRAINT FK_PeliculasGeneros_Generos
        FOREIGN KEY (CodGenero) REFERENCES Generos(CodGenero),
    CONSTRAINT UQ_PeliculasGeneros_PeliculaGenero UNIQUE (CodPelicula, CodGenero)
);
GO

CREATE TABLE Personas (
    Ci        CHAR(20)      NOT NULL,
    Nombres   VARCHAR(255)  NOT NULL,
    Apellidos VARCHAR(255)  NOT NULL,
    FechaNac  DATE,
    Email     VARCHAR(255)  NOT NULL,
    Telefono  VARCHAR(20),
    Biografia VARCHAR(1000) NOT NULL,
    CodPais   CHAR(20)      NOT NULL,
    CONSTRAINT PK_Personas        PRIMARY KEY (Ci),
    CONSTRAINT FK_Personas_Paises FOREIGN KEY (CodPais) REFERENCES Paises(CodPais),
    CONSTRAINT UQ_Personas_Email  UNIQUE (Email)
);
GO

CREATE TABLE Participaciones (
    CodParticipacion CHAR(20) NOT NULL,
    CodPelicula      CHAR(20) NOT NULL,
    Ci               CHAR(20) NOT NULL,
    CodRol           CHAR(20) NOT NULL,
    CONSTRAINT PK_Participaciones PRIMARY KEY (CodParticipacion),
    CONSTRAINT FK_Participaciones_Peliculas
        FOREIGN KEY (CodPelicula) REFERENCES Peliculas(CodPelicula),
    CONSTRAINT FK_Participaciones_Personas
        FOREIGN KEY (Ci) REFERENCES Personas(Ci),
    CONSTRAINT FK_Participaciones_Roles
        FOREIGN KEY (CodRol) REFERENCES Roles(CodRol),
    -- Una persona no puede tener el mismo rol dos veces en la misma pelicula
    CONSTRAINT UQ_Participaciones_PeliculaPersonaRol UNIQUE (CodPelicula, Ci, CodRol)
);
GO

-- ============================================================
-- NIVEL 3 — TABLAS OPERATIVAS PRINCIPALES
-- Cambio clave: fecha+hora_inicio+hora_fin → FechaHoraInicio/Fin DATETIME2
-- Motivo: el trigger TR1 necesita comparar rangos completos de fecha-hora
-- para detectar cruces que puedan cruzar medianoche.
-- ============================================================

CREATE TABLE Proyecciones (
    CodProyeccion   CHAR(20)     NOT NULL,
    FechaHoraInicio DATETIME2(0) NOT NULL,
    FechaHoraFin    DATETIME2(0) NOT NULL,
    SesionQa        VARCHAR(255),           -- NULL = sin sesion Q&A
    CodPelicula     CHAR(20)     NOT NULL,
    CodSala         CHAR(20)     NOT NULL,
    CodEdicion      CHAR(20)     NOT NULL,
    CONSTRAINT PK_Proyecciones PRIMARY KEY (CodProyeccion),
    CONSTRAINT FK_Proyecciones_Peliculas
        FOREIGN KEY (CodPelicula) REFERENCES Peliculas(CodPelicula),
    CONSTRAINT FK_Proyecciones_Salas
        FOREIGN KEY (CodSala) REFERENCES Salas(CodSala),
    CONSTRAINT FK_Proyecciones_EdicionesFestivales
        FOREIGN KEY (CodEdicion) REFERENCES EdicionesFestivales(CodEdicion),
    CONSTRAINT CK_Proyecciones_Horario CHECK (FechaHoraInicio < FechaHoraFin)
);
GO

-- Cambio clave: se agrega FechaHoraFin (antes solo existia hora de inicio).
-- Necesario para validar cruces de sala con proyecciones y otros eventos.
CREATE TABLE EventosParalelos (
    CodEvento       CHAR(20)      NOT NULL,
    NombreEvento    VARCHAR(255)  NOT NULL,
    Descripcion     VARCHAR(500)  NOT NULL,
    FechaHoraInicio DATETIME2(0)  NOT NULL,
    FechaHoraFin    DATETIME2(0)  NOT NULL,
    Aforo           INT           NOT NULL,
    Costo           DECIMAL(10,2),          -- NULL = gratuito
    CodTipoEvento   CHAR(20)      NOT NULL,
    CodSala         CHAR(20)      NOT NULL,
    CodEdicion      CHAR(20)      NOT NULL,
    CONSTRAINT PK_EventosParalelos PRIMARY KEY (CodEvento),
    CONSTRAINT FK_EventosParalelos_TiposEventos
        FOREIGN KEY (CodTipoEvento) REFERENCES TiposEventos(CodTipoEvento),
    CONSTRAINT FK_EventosParalelos_Salas
        FOREIGN KEY (CodSala) REFERENCES Salas(CodSala),
    CONSTRAINT FK_EventosParalelos_EdicionesFestivales
        FOREIGN KEY (CodEdicion) REFERENCES EdicionesFestivales(CodEdicion),
    CONSTRAINT CK_EventosParalelos_Aforo   CHECK (Aforo > 0),
    CONSTRAINT CK_EventosParalelos_Costo   CHECK (Costo IS NULL OR Costo >= 0),
    CONSTRAINT CK_EventosParalelos_Horario CHECK (FechaHoraInicio < FechaHoraFin)
);
GO

CREATE TABLE EventosExpositores (
    CodEventoExpositor CHAR(20) NOT NULL,
    CodEvento          CHAR(20) NOT NULL,
    Ci                 CHAR(20) NOT NULL,
    CONSTRAINT PK_EventosExpositores PRIMARY KEY (CodEventoExpositor),
    CONSTRAINT FK_EventosExpositores_EventosParalelos
        FOREIGN KEY (CodEvento) REFERENCES EventosParalelos(CodEvento),
    CONSTRAINT FK_EventosExpositores_Personas
        FOREIGN KEY (Ci) REFERENCES Personas(Ci),
    CONSTRAINT UQ_EventosExpositores_EventoPersona UNIQUE (CodEvento, Ci)
);
GO

-- ============================================================
-- NIVEL 4 — COMPETICIÓN
-- ============================================================

CREATE TABLE CategoriasEdiciones (
    CodCategoriaEdicion CHAR(20) NOT NULL,
    CodCategoria        CHAR(20) NOT NULL,
    CodEdicion          CHAR(20) NOT NULL,
    CONSTRAINT PK_CategoriasEdiciones PRIMARY KEY (CodCategoriaEdicion),
    CONSTRAINT FK_CategoriasEdiciones_CategoriasCompeticion
        FOREIGN KEY (CodCategoria) REFERENCES CategoriasCompeticion(CodCategoria),
    CONSTRAINT FK_CategoriasEdiciones_EdicionesFestivales
        FOREIGN KEY (CodEdicion) REFERENCES EdicionesFestivales(CodEdicion),
    -- Una categoria aparece una sola vez por edicion
    CONSTRAINT UQ_CategoriasEdiciones_CategoriaEdicion UNIQUE (CodCategoria, CodEdicion)
);
GO

CREATE TABLE PeliculasCategorias (
    CodPeliculaCategoria CHAR(20) NOT NULL,
    CodPelicula          CHAR(20) NOT NULL,
    CodCategoriaEdicion  CHAR(20) NOT NULL,
    CONSTRAINT PK_PeliculasCategorias PRIMARY KEY (CodPeliculaCategoria),
    CONSTRAINT FK_PeliculasCategorias_Peliculas
        FOREIGN KEY (CodPelicula) REFERENCES Peliculas(CodPelicula),
    CONSTRAINT FK_PeliculasCategorias_CategoriasEdiciones
        FOREIGN KEY (CodCategoriaEdicion) REFERENCES CategoriasEdiciones(CodCategoriaEdicion),
    -- Una pelicula compite una sola vez por categoria-edicion
    CONSTRAINT UQ_PeliculasCategorias_PeliculaCategoria UNIQUE (CodPelicula, CodCategoriaEdicion)
);
GO

CREATE TABLE JuradosCategorias (
    CodJuradoCategoria  CHAR(20) NOT NULL,
    Ci                  CHAR(20) NOT NULL,
    CodCategoriaEdicion CHAR(20) NOT NULL,
    CONSTRAINT PK_JuradosCategorias PRIMARY KEY (CodJuradoCategoria),
    CONSTRAINT FK_JuradosCategorias_Personas
        FOREIGN KEY (Ci) REFERENCES Personas(Ci),
    CONSTRAINT FK_JuradosCategorias_CategoriasEdiciones
        FOREIGN KEY (CodCategoriaEdicion) REFERENCES CategoriasEdiciones(CodCategoriaEdicion),
    -- Un jurado no puede asignarse dos veces a la misma categoria
    CONSTRAINT UQ_JuradosCategorias_JuradoCategoria UNIQUE (Ci, CodCategoriaEdicion)
);
GO

CREATE TABLE Evaluaciones (
    CodEvaluacion       CHAR(20)     NOT NULL,
    Puntuacion          DECIMAL(4,2) NOT NULL,
    Comentario          VARCHAR(500) NOT NULL,
    Ci                  CHAR(20)     NOT NULL,
    CodPelicula         CHAR(20)     NOT NULL,
    CodCategoriaEdicion CHAR(20)     NOT NULL,
    CONSTRAINT PK_Evaluaciones PRIMARY KEY (CodEvaluacion),
    CONSTRAINT FK_Evaluaciones_Personas
        FOREIGN KEY (Ci) REFERENCES Personas(Ci),
    CONSTRAINT FK_Evaluaciones_Peliculas
        FOREIGN KEY (CodPelicula) REFERENCES Peliculas(CodPelicula),
    CONSTRAINT FK_Evaluaciones_CategoriasEdiciones
        FOREIGN KEY (CodCategoriaEdicion) REFERENCES CategoriasEdiciones(CodCategoriaEdicion),
    CONSTRAINT CK_Evaluaciones_Puntuacion
        CHECK (Puntuacion >= 1 AND Puntuacion <= 10),
    -- Un jurado evalua una pelicula una sola vez por categoria
    CONSTRAINT UQ_Evaluaciones_JuradoPeliculaCategoria
        UNIQUE (Ci, CodPelicula, CodCategoriaEdicion)
);
GO

CREATE TABLE GanadoresPremios (
    CodGanadorPremio    CHAR(20) NOT NULL,
    CodPelicula         CHAR(20) NOT NULL,
    CodPremio           CHAR(20) NOT NULL,
    CodCategoriaEdicion CHAR(20) NOT NULL,
    CONSTRAINT PK_GanadoresPremios PRIMARY KEY (CodGanadorPremio),
    CONSTRAINT FK_GanadoresPremios_Peliculas
        FOREIGN KEY (CodPelicula) REFERENCES Peliculas(CodPelicula),
    CONSTRAINT FK_GanadoresPremios_Premios
        FOREIGN KEY (CodPremio) REFERENCES Premios(CodPremio),
    CONSTRAINT FK_GanadoresPremios_CategoriasEdiciones
        FOREIGN KEY (CodCategoriaEdicion) REFERENCES CategoriasEdiciones(CodCategoriaEdicion),
    -- Un mismo premio no puede otorgarse dos veces en la misma categoria-edicion
    CONSTRAINT UQ_GanadoresPremios_PremioCategoria UNIQUE (CodPremio, CodCategoriaEdicion)
);
GO

-- ============================================================
-- NIVEL 5 — VENTA Y ACCESO
-- ============================================================

CREATE TABLE Acreditaciones (
    CodAcreditacion     CHAR(20) NOT NULL,
    FechaEmision        DATE     NOT NULL,
    FechaVencimiento    DATE     NOT NULL,
    CodAsistente        CHAR(20) NOT NULL,
    CodTipoAcreditacion CHAR(20) NOT NULL,
    CodEdicion          CHAR(20) NOT NULL,
    CONSTRAINT PK_Acreditaciones PRIMARY KEY (CodAcreditacion),
    CONSTRAINT FK_Acreditaciones_Asistentes
        FOREIGN KEY (CodAsistente) REFERENCES Asistentes(CodAsistente),
    CONSTRAINT FK_Acreditaciones_TiposAcreditaciones
        FOREIGN KEY (CodTipoAcreditacion) REFERENCES TiposAcreditaciones(CodTipoAcreditacion),
    CONSTRAINT FK_Acreditaciones_EdicionesFestivales
        FOREIGN KEY (CodEdicion) REFERENCES EdicionesFestivales(CodEdicion),
    CONSTRAINT CK_Acreditaciones_Fechas CHECK (FechaEmision <= FechaVencimiento)
);
GO

-- ComprasAbonos: se agregan PrecioPagado, MetodoPago y EstadoPago
-- para soportar la transaccion T1 y el informe financiero.
CREATE TABLE ComprasAbonos (
    CodCompraAbono CHAR(20)      NOT NULL,
    FechaCompra    DATE          NOT NULL,
    PrecioPagado   DECIMAL(10,2) NOT NULL,
    MetodoPago     VARCHAR(100)  NOT NULL,
    EstadoPago     VARCHAR(50)   NOT NULL CONSTRAINT DF_ComprasAbonos_EstadoPago DEFAULT 'Completado',
    CodAsistente   CHAR(20)      NOT NULL,
    CodAbono       CHAR(20)      NOT NULL,
    CONSTRAINT PK_ComprasAbonos PRIMARY KEY (CodCompraAbono),
    CONSTRAINT FK_ComprasAbonos_Asistentes
        FOREIGN KEY (CodAsistente) REFERENCES Asistentes(CodAsistente),
    CONSTRAINT FK_ComprasAbonos_Abonos
        FOREIGN KEY (CodAbono) REFERENCES Abonos(CodAbono),
    CONSTRAINT CK_ComprasAbonos_PrecioPagado
        CHECK (PrecioPagado >= 0),
    CONSTRAINT CK_ComprasAbonos_EstadoPago
        CHECK (EstadoPago IN ('Completado', 'Pendiente', 'Fallido'))
);
GO

-- Tabla nueva: CodigosAcceso generados al comprar un abono (requerido por T1)
CREATE TABLE CodigosAcceso (
    CodAcceso       CHAR(20)     NOT NULL,
    CodCompraAbono  CHAR(20)     NOT NULL,
    CodigoGenerado  VARCHAR(100) NOT NULL,
    FechaGeneracion DATETIME2(0) NOT NULL CONSTRAINT DF_CodigosAcceso_FechaGen DEFAULT GETDATE(),
    Usado           BIT          NOT NULL CONSTRAINT DF_CodigosAcceso_Usado DEFAULT 0,
    CONSTRAINT PK_CodigosAcceso PRIMARY KEY (CodAcceso),
    CONSTRAINT FK_CodigosAcceso_ComprasAbonos
        FOREIGN KEY (CodCompraAbono) REFERENCES ComprasAbonos(CodCompraAbono),
    -- El codigo generado debe ser unico en todo el sistema
    CONSTRAINT UQ_CodigosAcceso_CodigoGenerado UNIQUE (CodigoGenerado)
);
GO

-- Entradas individuales: se agrega CHECK para garantizar que apunta
-- exactamente a una proyeccion O a un evento, nunca a ambos ni a ninguno.
CREATE TABLE Entradas (
    CodEntrada       CHAR(20)      NOT NULL,
    FechaCompra      DATE          NOT NULL,
    PrecioPagado     DECIMAL(10,2) NOT NULL,
    CodAsistente     CHAR(20)      NOT NULL,
    CodTarifa        CHAR(20)      NOT NULL,
    CodProyeccion    CHAR(20)      NULL,
    CodEvento        CHAR(20)      NULL,
    CodAsiento       CHAR(20)      NULL,
    CodigoValidacion VARCHAR(50)   NULL,
    CONSTRAINT PK_Entradas PRIMARY KEY (CodEntrada),
    CONSTRAINT FK_Entradas_Asistentes
        FOREIGN KEY (CodAsistente) REFERENCES Asistentes(CodAsistente),
    CONSTRAINT FK_Entradas_Tarifas
        FOREIGN KEY (CodTarifa) REFERENCES Tarifas(CodTarifa),
    CONSTRAINT FK_Entradas_Proyecciones
        FOREIGN KEY (CodProyeccion) REFERENCES Proyecciones(CodProyeccion),
    CONSTRAINT FK_Entradas_EventosParalelos
        FOREIGN KEY (CodEvento) REFERENCES EventosParalelos(CodEvento),
    CONSTRAINT FK_Entradas_Asientos
        FOREIGN KEY (CodAsiento) REFERENCES Asientos(CodAsiento),
    CONSTRAINT CK_Entradas_PrecioPagado CHECK (PrecioPagado >= 0),
    CONSTRAINT CK_Entradas_DestinoUnico CHECK (
        (CodProyeccion IS NOT NULL AND CodEvento IS NULL) OR
        (CodProyeccion IS NULL     AND CodEvento IS NOT NULL)
    )
);
GO

CREATE UNIQUE INDEX UQ_Entradas_Proyeccion_Asiento
    ON Entradas (CodProyeccion, CodAsiento)
    WHERE CodProyeccion IS NOT NULL AND CodAsiento IS NOT NULL;
GO

-- UsosAbonos: misma restriccion que Entradas (proyeccion XOR evento)
CREATE TABLE UsosAbonos (
    CodUsoAbono    CHAR(20) NOT NULL,
    FechaUso       DATE     NOT NULL,
    CodCompraAbono CHAR(20) NOT NULL,
    CodProyeccion  CHAR(20) NULL,
    CodEvento      CHAR(20) NULL,
    CONSTRAINT PK_UsosAbonos PRIMARY KEY (CodUsoAbono),
    CONSTRAINT FK_UsosAbonos_ComprasAbonos
        FOREIGN KEY (CodCompraAbono) REFERENCES ComprasAbonos(CodCompraAbono),
    CONSTRAINT FK_UsosAbonos_Proyecciones
        FOREIGN KEY (CodProyeccion) REFERENCES Proyecciones(CodProyeccion),
    CONSTRAINT FK_UsosAbonos_EventosParalelos
        FOREIGN KEY (CodEvento) REFERENCES EventosParalelos(CodEvento),
    CONSTRAINT CK_UsosAbonos_DestinoUnico CHECK (
        (CodProyeccion IS NOT NULL AND CodEvento IS NULL) OR
        (CodProyeccion IS NULL     AND CodEvento IS NOT NULL)
    )
);
GO

-- Tabla nueva: Pagos — fuente unica de verdad para el informe financiero.
-- Referencia a Entradas o ComprasAbonos (nunca a ambos).
CREATE TABLE Pagos (
    CodPago        CHAR(20)      NOT NULL,
    FechaPago      DATETIME2(0)  NOT NULL,
    Monto          DECIMAL(10,2) NOT NULL,
    MetodoPago     VARCHAR(100)  NOT NULL,
    EstadoPago     VARCHAR(50)   NOT NULL CONSTRAINT DF_Pagos_EstadoPago DEFAULT 'Completado',
    TipoVenta      VARCHAR(20)   NOT NULL,  -- 'Entrada' | 'Abono'
    CodEntrada     CHAR(20)      NULL,
    CodCompraAbono CHAR(20)      NULL,
    CONSTRAINT PK_Pagos PRIMARY KEY (CodPago),
    CONSTRAINT FK_Pagos_Entradas
        FOREIGN KEY (CodEntrada) REFERENCES Entradas(CodEntrada),
    CONSTRAINT FK_Pagos_ComprasAbonos
        FOREIGN KEY (CodCompraAbono) REFERENCES ComprasAbonos(CodCompraAbono),
    CONSTRAINT CK_Pagos_Monto CHECK (Monto >= 0),
    CONSTRAINT CK_Pagos_TipoVenta CHECK (TipoVenta IN ('Entrada', 'Abono')),
    CONSTRAINT CK_Pagos_ReferenciaUnica CHECK (
        (CodEntrada IS NOT NULL AND CodCompraAbono IS NULL) OR
        (CodEntrada IS NULL     AND CodCompraAbono IS NOT NULL)
    )
);
GO

-- ============================================================
-- NIVEL 6 — LOGÍSTICA E HISTÓRICO
-- ============================================================

CREATE TABLE Alojamientos (
    CodAlojamiento CHAR(20) NOT NULL,
    FechaCheckin   DATE     NOT NULL,
    FechaCheckout  DATE     NOT NULL,
    Ci             CHAR(20) NOT NULL,
    CodHabitacion  CHAR(20) NOT NULL,
    CodEdicion     CHAR(20) NOT NULL,
    CONSTRAINT PK_Alojamientos PRIMARY KEY (CodAlojamiento),
    CONSTRAINT FK_Alojamientos_Personas
        FOREIGN KEY (Ci) REFERENCES Personas(Ci),
    CONSTRAINT FK_Alojamientos_Habitaciones
        FOREIGN KEY (CodHabitacion) REFERENCES Habitaciones(CodHabitacion),
    CONSTRAINT FK_Alojamientos_EdicionesFestivales
        FOREIGN KEY (CodEdicion) REFERENCES EdicionesFestivales(CodEdicion),
    CONSTRAINT CK_Alojamientos_Fechas CHECK (FechaCheckin < FechaCheckout)
);
GO

CREATE TABLE Traslados (
    CodTraslado  CHAR(20)     NOT NULL,
    Fecha        DATE         NOT NULL,
    Hora         TIME(0)      NOT NULL,
    TipoTraslado VARCHAR(255) NOT NULL,
    Observacion  VARCHAR(500),
    Ci           CHAR(20)     NOT NULL,
    CodEdicion   CHAR(20)     NOT NULL,
    CONSTRAINT PK_Traslados PRIMARY KEY (CodTraslado),
    CONSTRAINT FK_Traslados_Personas
        FOREIGN KEY (Ci) REFERENCES Personas(Ci),
    CONSTRAINT FK_Traslados_EdicionesFestivales
        FOREIGN KEY (CodEdicion) REFERENCES EdicionesFestivales(CodEdicion)
);
GO

CREATE TABLE Vuelos (
    CodVuelo     CHAR(20)     NOT NULL,
    Aerolinea    VARCHAR(255) NOT NULL,
    Origen       VARCHAR(255) NOT NULL,
    Destino      VARCHAR(255) NOT NULL,
    FechaSalida  DATE         NOT NULL,
    FechaLlegada DATE         NOT NULL,
    CodTraslado  CHAR(20)     NOT NULL,
    CONSTRAINT PK_Vuelos PRIMARY KEY (CodVuelo),
    CONSTRAINT FK_Vuelos_Traslados FOREIGN KEY (CodTraslado) REFERENCES Traslados(CodTraslado),
    CONSTRAINT CK_Vuelos_Fechas CHECK (FechaSalida <= FechaLlegada)
);
GO

CREATE TABLE Patrocinios (
    CodPatrocinio   CHAR(20)      NOT NULL,
    TipoAporte      VARCHAR(20)   NOT NULL,  -- 'Economico' | 'Especie'
    DescripcionAporte VARCHAR(255),           -- detalle del aporte en especie
    Monto           DECIMAL(15,2),           -- NULL si es en especie
    CodEdicion      CHAR(20)      NOT NULL,
    CodPatrocinador CHAR(20)      NOT NULL,
    CONSTRAINT PK_Patrocinios PRIMARY KEY (CodPatrocinio),
    CONSTRAINT FK_Patrocinios_EdicionesFestivales
        FOREIGN KEY (CodEdicion) REFERENCES EdicionesFestivales(CodEdicion),
    CONSTRAINT FK_Patrocinios_Patrocinadores
        FOREIGN KEY (CodPatrocinador) REFERENCES Patrocinadores(CodPatrocinador),
    CONSTRAINT CK_Patrocinios_TipoAporte
        CHECK (TipoAporte IN ('Economico', 'Especie'))
);
GO
