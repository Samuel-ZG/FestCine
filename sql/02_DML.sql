use FestCine

-- ============================================================
-- FestCine - DML Completo (datos de prueba)
-- Ejecutar DESPUÉS de 01_DDL.sql
-- Cumple: 20 asistentes, 13 proyecciones, 3+ salas,
--         5+ peliculas, ventas suficientes para ranking,
--         informe financiero y caso de sala llena.
-- ============================================================

-- ============================================================
-- NIVEL 1 — CATÁLOGOS
-- ============================================================

INSERT INTO Formatos (CodFormato, TipoFormato) VALUES
('form_01', 'Digital DCP 2K'),
('form_02', 'Digital DCP 4K'),
('form_03', 'Cinta 35mm'),
('form_04', 'Cinta 70mm'),
('form_05', 'IMAX'),
('form_06', 'Web-DL Calidad Alta'),
('form_07', 'MP4 Cortometrajes');
GO

INSERT INTO EstadosPeliculas (CodEstado, NombreEstado) VALUES
('est_01', 'Postulada'),
('est_02', 'En Revision'),
('est_03', 'Seleccionada'),
('est_04', 'Rechazada'),
('est_05', 'Retirada por Produccion'),
('est_06', 'Premiada'),
('est_07', 'Mencion Especial');
GO

INSERT INTO ClasificacionesEdades (CodClasificacion, EdadMinima, EdadMaxima) VALUES
('clas_01', 0,  99),
('clas_02', 7,  99),
('clas_03', 10, 99),
('clas_04', 13, 99),
('clas_05', 16, 99),
('clas_06', 18, 99),
('clas_07', 21, 99);
GO

INSERT INTO Paises (CodPais, NombrePais) VALUES
('pais_01', 'Bolivia'),
('pais_02', 'Argentina'),
('pais_03', 'Chile'),
('pais_04', 'Brasil'),
('pais_05', 'Mexico'),
('pais_06', 'Espana'),
('pais_07', 'Colombia');
GO

INSERT INTO Generos (CodGenero, NombreGenero) VALUES
('gen_01', 'Drama'),
('gen_02', 'Documental'),
('gen_03', 'Thriller Psicologico'),
('gen_04', 'Comedia Negra'),
('gen_05', 'Terror'),
('gen_06', 'Ciencia Ficcion'),
('gen_07', 'Animacion Independiente');
GO

INSERT INTO Roles (CodRol, NombreRol) VALUES
('rol_01', 'Director Principal'),
('rol_02', 'Productor Ejecutivo'),
('rol_03', 'Guionista'),
('rol_04', 'Actor Principal'),
('rol_05', 'Actriz Principal'),
('rol_06', 'Director de Fotografia'),
('rol_07', 'Compositor Banda Sonora');
GO

INSERT INTO TiposEventos (CodTipoEvento, NombreTipoEvento) VALUES
('tev_01', 'Masterclass'),
('tev_02', 'Taller Practico'),
('tev_03', 'Panel de Discusion'),
('tev_04', 'Coctel de Inauguracion'),
('tev_05', 'Alfombra Roja'),
('tev_06', 'Rueda de Prensa'),
('tev_07', 'Concierto de Clausura');
GO

INSERT INTO CategoriasCompeticion (CodCategoria, NombreCategoria, Descripcion) VALUES
('cat_01', 'Mejor Largometraje',   'Premio principal del festival a la mejor cinta de ficcion'),
('cat_02', 'Mejor Documental',     'Reconocimiento al mejor trabajo de no-ficcion'),
('cat_03', 'Mejor Cortometraje',   'Premio a producciones menores a 30 minutos'),
('cat_04', 'Premio del Publico',   'Galardón elegido por votacion de los asistentes'),
('cat_05', 'Mejor Direccion',      'Premio tecnico al director mas destacado'),
('cat_06', 'Mejor Actuacion',      'Reconocimiento mixto al mejor actor o actriz'),
('cat_07', 'Mejor Guion Original', 'Premio a la historia y narrativa');
GO

INSERT INTO Premios (CodPremio, NombrePremio, Descripcion) VALUES
('prem_01', 'Estatuilla de Oro',       'Galardón fisico y premio en efectivo de $5000'),
('prem_02', 'Estatuilla de Plata',     'Galardón fisico para el segundo lugar'),
('prem_03', 'Gran Premio del Jurado',  'Reconocimiento unanime de los expertos'),
('prem_04', 'Beca de Produccion',      'Financiamiento parcial para el proximo proyecto'),
('prem_05', 'Diploma de Honor',        'Certificado oficial del festival'),
('prem_06', 'Trofeo Revelacion',       'Entregado a nuevos talentos menores de 25 años'),
('prem_07', 'Claqueta Conmemorativa',  'Recuerdo oficial del festival');
GO

-- 20 asistentes (minimo requerido por el enunciado)
INSERT INTO Asistentes (CodAsistente, Nombres, Apellidos, Telefono, Email) VALUES
('asis_01', 'Javier',    'Salazar',    '77011223', 'javier.s@email.com'),
('asis_02', 'Camila',    'Rios',       '78099887', 'camila.r@email.com'),
('asis_03', 'Leonardo',  'Vaca',       '75566443', 'leo.vaca@email.com'),
('asis_04', 'Mariana',   'Ortiz',      '71122334', 'mar.ortiz@email.com'),
('asis_05', 'Fernando',  'Perez',      '79988776', 'fer.perez@email.com'),
('asis_06', 'Lucia',     'Guzman',     '70001111', 'lucia.g@email.com'),
('asis_07', 'Andres',    'Molina',     '76655443', 'andres.m@email.com'),
('asis_08', 'Roberto',   'Castro',     '71234567', 'roberto.c@email.com'),
('asis_09', 'Diana',     'Flores',     '72345678', 'diana.f@email.com'),
('asis_10', 'Miguel',    'Torres',     '73456789', 'miguel.t@email.com'),
('asis_11', 'Patricia',  'Ramos',      '74567890', 'patricia.r@email.com'),
('asis_12', 'Carlos',    'Medina',     '75678901', 'carlos.m@email.com'),
('asis_13', 'Valentina', 'Suarez',     '76789012', 'valentina.s@email.com'),
('asis_14', 'Jorge',     'Herrera',    '77890123', 'jorge.h@email.com'),
('asis_15', 'Natalia',   'Vargas',     '78901234', 'natalia.v@email.com'),
('asis_16', 'Pablo',     'Mendoza',    '79012345', 'pablo.m@email.com'),
('asis_17', 'Carmen',    'Quispe',     '70123456', 'carmen.q@email.com'),
('asis_18', 'Diego',     'Gutierrez',  '71234560', 'diego.g@email.com'),
('asis_19', 'Sofia',     'Alvarado',   '72345609', 'sofia.a@email.com'),
('asis_20', 'Marcos',    'Paredes',    '73456098', 'marcos.p@email.com');
GO

INSERT INTO TiposAcreditaciones (CodTipoAcreditacion, Nombre) VALUES
('tac_01', 'Prensa Local'),
('tac_02', 'Prensa Internacional'),
('tac_03', 'Industria Cinematografica'),
('tac_04', 'VIP Estelar'),
('tac_05', 'Miembro del Jurado'),
('tac_06', 'Staff y Organizacion'),
('tac_07', 'Voluntario Oficial');
GO

INSERT INTO Tarifas (CodTarifa, Nombre, Precio) VALUES
('tar_01', 'Entrada General',       45.00),
('tar_02', 'Entrada Estudiante',    25.00),
('tar_03', 'Tarifa 3ra Edad',       20.00),
('tar_04', 'Acceso VIP',           100.00),
('tar_05', 'Preventa Anticipada',   35.00),
('tar_06', 'Promocion 2x1',         22.50),
('tar_07', 'Gratuita Acreditados',   0.00);
GO

INSERT INTO Abonos (CodAbono, Nombre, Precio, Descripcion) VALUES
('abo_01', 'Abono Total',        300.00, 'Acceso ilimitado a todas las funciones del festival'),
('abo_02', 'Abono Fin de Semana',150.00, 'Valido para funciones de viernes a domingo'),
('abo_03', 'Abono Estudiante',   200.00, 'Acceso ilimitado con carnet universitario'),
('abo_04', 'Pase VIP',           500.00, 'Acceso total sin fila mas Cocteles'),
('abo_05', 'Abono 3 Dias',       120.00, 'Acceso por 72 horas consecutivas'),
('abo_06', 'Pack Galas',         180.00, 'Acceso exclusivo a inauguracion y clausura'),
('abo_07', 'Abono Matinal',      100.00, 'Valido solo para funciones antes de las 14:00');
GO

INSERT INTO Hoteles (CodHotel, Nombre, Direccion) VALUES
('hot_01', 'Hotel Los Tajibos',  'Av. San Martin, 3er Anillo Interno'),
('hot_02', 'Marriott Hotel',     'Cuarto Anillo, Equipetrol Norte'),
('hot_03', 'Camino Real',        'Av. San Martin y 4to Anillo'),
('hot_04', 'Hotel Cortez',       'Av. Cristobal de Mendoza, 2do Anillo'),
('hot_05', 'Radisson Hotel',     'Urubo, Av. Principal'),
('hot_06', 'Buganvillas Suites', 'Av. Roca y Coronado, 3er Anillo'),
('hot_07', 'Hotel Yotau',        'Av. San Martin y 2do Anillo');
GO

INSERT INTO Patrocinadores (CodPatrocinador, Nombre, Contacto) VALUES
('pat_01', 'Banco Ganadero',              'patrocinios@bancoganadero.com.bo'),
('pat_02', 'Cerveceria Boliviana Nacional','eventos@cbn.com.bo'),
('pat_03', 'Viva',                        'marketing@viva.com.bo'),
('pat_04', 'Boliviana de Aviacion BoA',   'comercial@boa.bo'),
('pat_05', 'Coca Cola',                   'rp@cocacola.bo'),
('pat_06', 'Avicola Sofia',               'rrpp@sofia.com.bo'),
('pat_07', 'Samsung Bolivia',             'auspicios@samsung.bo');
GO

INSERT INTO EdicionesFestivales (CodEdicion, Anio, FechaInicio, FechaFin) VALUES
('edi_2020', 2020, '2020-08-10', '2020-08-20'),
('edi_2021', 2021, '2021-08-12', '2021-08-22'),
('edi_2022', 2022, '2022-08-15', '2022-08-25'),
('edi_2023', 2023, '2023-08-14', '2023-08-24'),
('edi_2024', 2024, '2024-08-10', '2024-08-20'),
('edi_2025', 2025, '2025-08-16', '2025-08-26'),
('edi_2026', 2026, '2026-08-15', '2026-08-25');
GO

-- ============================================================
-- NIVEL 2 — SEDES, SALAS, HABITACIONES, PELÍCULAS, PERSONAS
-- ============================================================

INSERT INTO Sedes (CodSede, NombreSede, Direccion, CodPais) VALUES
('sede_01', 'Cine Center',      '2do Anillo y Av. El Trompillo',  'pais_01'),
('sede_02', 'Teatro CBA',       'Calle Sucre Nro 340',            'pais_01'),
('sede_03', 'Cinemark Ventura', '4to Anillo y Av. San Martin',    'pais_01'),
('sede_04', 'Centro AECID',     'Calle Arenales',                 'pais_01'),
('sede_05', 'Casa de la Cultura','Plaza 24 de Septiembre',        'pais_01'),
('sede_06', 'Museo de Arte',    'Calle Sucre esq Potosi',         'pais_01'),
('sede_07', 'Multicine',        'Av. Las Americas',               'pais_01');
GO

-- sala_08: sala de capacidad reducida para demostrar sala llena en P1
INSERT INTO Salas (CodSala, NombreSala, Capacidad, CodSede) VALUES
('sala_01', 'Sala VIP Center',      100, 'sede_01'),
('sala_02', 'Auditorio Principal',  250, 'sede_02'),
('sala_03', 'Sala XD Ventura',      300, 'sede_03'),
('sala_04', 'Teatro Abierto',       150, 'sede_04'),
('sala_05', 'Salon Central',         80, 'sede_05'),
('sala_06', 'Patio Historico',      120, 'sede_06'),
('sala_07', 'Sala Normal Multicine',200, 'sede_07'),
('sala_08', 'Sala Mini Demo',         3, 'sede_01');  -- capacidad 3 para prueba de aforo
GO

INSERT INTO Habitaciones (CodHabitacion, Numero, CodHotel) VALUES
('hab_01', 'Suite 101',      'hot_01'),
('hab_02', 'Presidencial',   'hot_02'),
('hab_03', 'Doble 205',      'hot_03'),
('hab_04', 'Ejecutiva 410',  'hot_04'),
('hab_05', 'Suite 515',      'hot_05'),
('hab_06', 'Sencilla 102',   'hot_06'),
('hab_07', 'Penthouse',      'hot_07');
GO

INSERT INTO Peliculas (CodPelicula, Titulo, AnioProduccion, Duracion, Sinopsis,
                       CodFormato, CodEstado, CodClasificacion, CodPais) VALUES
('pel_01', 'Sombras del Illimani', 2025, 115, 'Un viaje mistico por los Andes bolivianos.',
           'form_01', 'est_03', 'clas_04', 'pais_01'),
('pel_02', 'El Ultimo Tango',      2024,  90, 'Drama de dos bailarines en decadencia.',
           'form_02', 'est_03', 'clas_05', 'pais_02'),
('pel_03', 'Desierto Rojo',        2026, 130, 'Documental sobre el desierto de Atacama.',
           'form_05', 'est_03', 'clas_01', 'pais_03'),
('pel_04', 'Favela en Llamas',     2025, 105, 'Thriller de accion en Rio de Janeiro.',
           'form_01', 'est_03', 'clas_06', 'pais_04'),
('pel_05', 'La Llorona Vuelve',    2026,  95, 'Horror folklorico moderno.',
           'form_02', 'est_03', 'clas_06', 'pais_05'),
('pel_06', 'Olas de Madrid',       2025, 120, 'Comedia romantica en la capital espanola.',
           'form_01', 'est_03', 'clas_04', 'pais_06'),
('pel_07', 'Cafe Amargo',          2026,  25, 'Cortometraje sobre la recoleccion de cafe.',
           'form_07', 'est_03', 'clas_01', 'pais_07');
GO

INSERT INTO Personas (Ci, Nombres, Apellidos, FechaNac, Email, Telefono, Biografia, CodPais) VALUES
('ci_01','Rodrigo','Bellot',     '1980-05-15','rbellot@cine.bo',      '70011223','Director y productor cruceno',          'pais_01'),
('ci_02','Ricardo','Darin',      '1957-01-16','rdarin@actores.ar',     '11223344','Leyenda del cine argentino',            'pais_02'),
('ci_03','Pedro',  'Pascal',     '1975-04-02','ppascal@hollywood.cl',  '55667788','Actor chileno internacional',           'pais_03'),
('ci_04','Wagner', 'Moura',      '1976-06-27','wmoura@brasil.br',      '99887766','Actor y director brasileno',            'pais_04'),
('ci_05','Guillermo','Del Toro', '1964-10-09','gdeltoro@cine.mx',      '44556677','Maestro del terror y fantasia',         'pais_05'),
('ci_06','Penelope','Cruz',      '1974-04-28','pcruz@actrices.es',     '33445566','Ganadora del Oscar espanola',           'pais_06'),
('ci_07','Sofia',  'Vergara',    '1972-07-10','svergara@tv.co',        '22334455','Actriz y comediante colombiana',        'pais_07');
GO

INSERT INTO PeliculasGeneros (CodPeliculaGenero, CodPelicula, CodGenero) VALUES
('pgen_01','pel_01','gen_01'),
('pgen_02','pel_02','gen_01'),
('pgen_03','pel_03','gen_02'),
('pgen_04','pel_04','gen_03'),
('pgen_05','pel_05','gen_05'),
('pgen_06','pel_06','gen_04'),
('pgen_07','pel_07','gen_02');
GO

INSERT INTO Participaciones (CodParticipacion, CodPelicula, Ci, CodRol) VALUES
('part_01','pel_01','ci_01','rol_01'),
('part_02','pel_02','ci_02','rol_04'),
('part_03','pel_03','ci_03','rol_04'),
('part_04','pel_04','ci_04','rol_01'),
('part_05','pel_05','ci_05','rol_01'),
('part_06','pel_06','ci_06','rol_05'),
('part_07','pel_07','ci_07','rol_05');
GO

-- ============================================================
-- NIVEL 3 — PROYECCIONES Y EVENTOS PARALELOS
-- FechaHoraFin = FechaHoraInicio + Duracion pelicula (en minutos)
-- proy_05 cruza medianoche: DATETIME2 lo maneja correctamente
-- proy_13 -> sala_08 (cap. 3): se llenara con ent_08/09/10 para demo P1
-- ============================================================

INSERT INTO Proyecciones (CodProyeccion, FechaHoraInicio, FechaHoraFin, SesionQa, CodPelicula, CodSala, CodEdicion) VALUES
-- Proyecciones originales (7)
('proy_01','2026-08-16 19:00:00','2026-08-16 20:55:00','Si, con Rodrigo Bellot','pel_01','sala_01','edi_2026'),
('proy_02','2026-08-17 21:30:00','2026-08-17 23:00:00', NULL,                   'pel_02','sala_02','edi_2026'),
('proy_03','2026-08-18 18:00:00','2026-08-18 20:10:00','Si, formato libre',     'pel_03','sala_03','edi_2026'),
('proy_04','2026-08-19 20:00:00','2026-08-19 21:45:00', NULL,                   'pel_04','sala_04','edi_2026'),
('proy_05','2026-08-20 22:30:00','2026-08-21 00:05:00','Foro debate',           'pel_05','sala_05','edi_2026'),
('proy_06','2026-08-21 19:00:00','2026-08-21 21:00:00', NULL,                   'pel_06','sala_06','edi_2026'),
('proy_07','2026-08-22 16:00:00','2026-08-22 16:25:00','Si',                    'pel_07','sala_07','edi_2026'),
-- Proyecciones adicionales para llegar a 10+ y probar ranking
('proy_08','2026-08-18 10:00:00','2026-08-18 11:55:00', NULL,                   'pel_01','sala_04','edi_2026'),
('proy_09','2026-08-20 16:00:00','2026-08-20 17:30:00', NULL,                   'pel_02','sala_03','edi_2026'),
('proy_10','2026-08-22 18:00:00','2026-08-22 20:10:00', NULL,                   'pel_03','sala_01','edi_2026'),
('proy_11','2026-08-23 19:00:00','2026-08-23 20:45:00', NULL,                   'pel_04','sala_07','edi_2026'),
('proy_12','2026-08-24 17:00:00','2026-08-24 17:25:00','Si',                    'pel_07','sala_02','edi_2026'),
-- proy_13: en sala_08 (cap. 3). Se insertan exactamente 3 entradas → sala llena
('proy_13','2026-08-17 15:00:00','2026-08-17 15:25:00', NULL,                   'pel_07','sala_08','edi_2026');
GO

-- Eventos paralelos con FechaHoraInicio y FechaHoraFin.
-- Los horarios se coordinaron para no chocar con las proyecciones en las mismas salas.
INSERT INTO EventosParalelos (CodEvento, NombreEvento, Descripcion, FechaHoraInicio, FechaHoraFin,
                               Aforo, Costo, CodTipoEvento, CodSala, CodEdicion) VALUES
('epar_01','Taller de Guion',       'Creacion de personajes con Del Toro',
 '2026-08-18 10:00:00','2026-08-18 13:00:00',  50, 100.00,'tev_02','sala_02','edi_2026'),
('epar_02','Noche de Gala',         'Apertura oficial del FestCine',
 '2026-08-15 20:00:00','2026-08-15 23:00:00', 200,   NULL,'tev_04','sala_01','edi_2026'),
('epar_03','Masterclass de Actuacion','Impartida por Ricardo Darin',
 '2026-08-19 11:00:00','2026-08-19 13:00:00', 150,  80.00,'tev_01','sala_03','edi_2026'),
('epar_04','Alfombra Roja',         'Cierre del festival',
 '2026-08-25 18:00:00','2026-08-25 20:00:00', 300,   NULL,'tev_05','sala_01','edi_2026'),
('epar_05','Cine y Tecnologia',     'Impacto del Streaming en el cine independiente',
 '2026-08-20 15:00:00','2026-08-20 17:00:00', 100,  25.00,'tev_03','sala_04','edi_2026'),
('epar_06','Rueda de Prensa',       'Directores internacionales',
 '2026-08-16 09:00:00','2026-08-16 11:00:00',  80,   0.00,'tev_06','sala_05','edi_2026'),
('epar_07','Concierto Sinfonico',   'Musica de peliculas en vivo',
 '2026-08-25 21:00:00','2026-08-25 23:30:00', 250,  50.00,'tev_07','sala_02','edi_2026');
GO

-- ============================================================
-- NIVEL 4 — COMPETICIÓN
-- ============================================================

INSERT INTO CategoriasEdiciones (CodCategoriaEdicion, CodCategoria, CodEdicion) VALUES
('catedi_01','cat_01','edi_2026'),  -- Mejor Largometraje 2026
('catedi_02','cat_02','edi_2026'),  -- Mejor Documental 2026
('catedi_03','cat_03','edi_2026'),  -- Mejor Cortometraje 2026
('catedi_04','cat_04','edi_2026'),  -- Premio del Publico 2026
('catedi_05','cat_05','edi_2026'),  -- Mejor Direccion 2026
('catedi_06','cat_06','edi_2026'),  -- Mejor Actuacion 2026
('catedi_07','cat_01','edi_2025');  -- Mejor Largometraje 2025 (historico)
GO

INSERT INTO PeliculasCategorias (CodPeliculaCategoria, CodPelicula, CodCategoriaEdicion) VALUES
('pcat_01','pel_01','catedi_01'),
('pcat_02','pel_02','catedi_01'),
('pcat_03','pel_03','catedi_02'),
('pcat_04','pel_04','catedi_04'),
('pcat_05','pel_05','catedi_05'),
('pcat_06','pel_06','catedi_06'),
('pcat_07','pel_07','catedi_03');
GO

INSERT INTO JuradosCategorias (CodJuradoCategoria, Ci, CodCategoriaEdicion) VALUES
('jur_01','ci_01','catedi_02'),
('jur_02','ci_02','catedi_01'),
('jur_03','ci_03','catedi_03'),
('jur_04','ci_04','catedi_05'),
('jur_05','ci_05','catedi_06'),
('jur_06','ci_06','catedi_04'),
('jur_07','ci_07','catedi_01');
GO

INSERT INTO Evaluaciones (CodEvaluacion, Puntuacion, Comentario, Ci, CodPelicula, CodCategoriaEdicion) VALUES
('eval_01', 9.50,'Excelente narrativa visual y direccion', 'ci_02','pel_01','catedi_01'),
('eval_02', 8.00,'Buena quimica, pero guion predecible',  'ci_07','pel_02','catedi_01'),
('eval_03',10.00,'Fotografia espectacular del desierto',  'ci_01','pel_03','catedi_02'),
('eval_04', 7.50,'Mucha accion, poco desarrollo',         'ci_06','pel_04','catedi_04'),
('eval_05', 9.00,'Aterradora y brillante',                'ci_04','pel_05','catedi_05'),
('eval_06', 8.50,'Las actuaciones salvan la obra',        'ci_05','pel_06','catedi_06'),
('eval_07', 9.20,'Corto directo al corazon',              'ci_03','pel_07','catedi_03');
GO

INSERT INTO GanadoresPremios (CodGanadorPremio, CodPelicula, CodPremio, CodCategoriaEdicion) VALUES
('gan_01','pel_01','prem_01','catedi_01'),  -- Sombras del Illimani: Estatuilla de Oro (Mejor Largometraje)
('gan_02','pel_03','prem_03','catedi_02'),  -- Desierto Rojo: Gran Premio del Jurado (Mejor Documental)
('gan_03','pel_07','prem_04','catedi_03'),  -- Cafe Amargo: Beca de Produccion (Mejor Cortometraje)
('gan_04','pel_04','prem_05','catedi_04'),  -- Favela en Llamas: Diploma de Honor (Premio Publico)
('gan_05','pel_05','prem_06','catedi_05'),  -- La Llorona Vuelve: Trofeo Revelacion (Mejor Direccion)
('gan_06','pel_06','prem_07','catedi_06'),  -- Olas de Madrid: Claqueta Conmemorativa (Mejor Actuacion)
('gan_07','pel_02','prem_02','catedi_01');  -- El Ultimo Tango: Estatuilla de Plata (Largometraje 2do lugar)
GO

-- ============================================================
-- NIVEL 5 — ACREDITACIONES, LOGÍSTICA
-- ============================================================

INSERT INTO Acreditaciones (CodAcreditacion, FechaEmision, FechaVencimiento,
                             CodAsistente, CodTipoAcreditacion, CodEdicion) VALUES
('acre_01','2026-08-01','2026-08-30','asis_01','tac_01','edi_2026'),
('acre_02','2026-08-05','2026-08-30','asis_02','tac_02','edi_2026'),
('acre_03','2026-08-10','2026-08-30','asis_03','tac_03','edi_2026'),
('acre_04','2026-08-12','2026-08-30','asis_04','tac_04','edi_2026'),
('acre_05','2026-08-13','2026-08-30','asis_05','tac_05','edi_2026'),
('acre_06','2026-08-14','2026-08-30','asis_06','tac_06','edi_2026'),
('acre_07','2026-08-14','2026-08-30','asis_07','tac_07','edi_2026');
GO

INSERT INTO EventosExpositores (CodEventoExpositor, CodEvento, Ci) VALUES
('eexp_01','epar_01','ci_05'),
('eexp_02','epar_03','ci_02'),
('eexp_03','epar_05','ci_01'),
('eexp_04','epar_05','ci_04'),
('eexp_05','epar_06','ci_06'),
('eexp_06','epar_06','ci_07'),
('eexp_07','epar_02','ci_03');
GO

INSERT INTO Alojamientos (CodAlojamiento, FechaCheckin, FechaCheckout, Ci, CodHabitacion, CodEdicion) VALUES
('aloj_01','2026-08-14','2026-08-26','ci_01','hab_01','edi_2026'),
('aloj_02','2026-08-14','2026-08-20','ci_02','hab_02','edi_2026'),
('aloj_03','2026-08-15','2026-08-25','ci_03','hab_03','edi_2026'),
('aloj_04','2026-08-15','2026-08-26','ci_04','hab_04','edi_2026'),
('aloj_05','2026-08-16','2026-08-22','ci_05','hab_05','edi_2026'),
('aloj_06','2026-08-14','2026-08-26','ci_06','hab_06','edi_2026'),
('aloj_07','2026-08-18','2026-08-25','ci_07','hab_07','edi_2026');
GO

INSERT INTO Traslados (CodTraslado, Fecha, Hora, TipoTraslado, Observacion, Ci, CodEdicion) VALUES
('tras_01','2026-08-14','14:30:00','Llegada Internacional','Recoger Viru Viru P3',    'ci_02','edi_2026'),
('tras_02','2026-08-20','08:00:00','Salida Internacional', 'Transporte VIP Hotel',    'ci_02','edi_2026'),
('tras_03','2026-08-15','16:00:00','Llegada Internacional','Atraso de vuelo previsto','ci_03','edi_2026'),
('tras_04','2026-08-15','21:00:00','Llegada Internacional','Vuelo nocturno',          'ci_04','edi_2026'),
('tras_05','2026-08-16','10:00:00','Llegada Internacional','Maletas extras',          'ci_05','edi_2026'),
('tras_06','2026-08-14','09:00:00','Llegada Internacional','VIP',                     'ci_06','edi_2026'),
('tras_07','2026-08-18','11:00:00','Llegada Internacional','Recoger',                 'ci_07','edi_2026');
GO

INSERT INTO Vuelos (CodVuelo, Aerolinea, Origen, Destino, FechaSalida, FechaLlegada, CodTraslado) VALUES
('vue_01','Aerolineas Arg','Bs As',     'Santa Cruz','2026-08-14','2026-08-14','tras_01'),
('vue_02','Aerolineas Arg','Santa Cruz','Bs As',     '2026-08-20','2026-08-20','tras_02'),
('vue_03','LATAM',         'Santiago',  'Santa Cruz','2026-08-15','2026-08-15','tras_03'),
('vue_04','BoA',           'Sao Paulo', 'Santa Cruz','2026-08-15','2026-08-15','tras_04'),
('vue_05','Aeromexico',    'CDMX',      'Santa Cruz','2026-08-16','2026-08-16','tras_05'),
('vue_06','Iberia',        'Madrid',    'Santa Cruz','2026-08-13','2026-08-14','tras_06'),
('vue_07','Avianca',       'Bogota',    'Santa Cruz','2026-08-18','2026-08-18','tras_07');
GO

INSERT INTO Patrocinios (CodPatrocinio, TipoAporte, DescripcionAporte, Monto, CodEdicion, CodPatrocinador) VALUES
('patroc_01','Economico', NULL,                   20000.00,'edi_2026','pat_01'),
('patroc_02','Especie',   'Provision de cerveza', NULL,    'edi_2026','pat_02'),
('patroc_03','Economico', NULL,                   15000.00,'edi_2026','pat_03'),
('patroc_04','Especie',   'Pasajes aereos',       NULL,    'edi_2026','pat_04'),
('patroc_05','Economico', NULL,                   10000.00,'edi_2026','pat_05'),
('patroc_06','Especie',   'Catering del evento',  NULL,    'edi_2026','pat_06'),
('patroc_07','Especie',   'Pantallas LED',        NULL,    'edi_2026','pat_07');
GO

-- ============================================================
-- NIVEL 6 — VENTAS (ComprasAbonos, Entradas, UsosAbonos, Pagos, CodigosAcceso)
-- ============================================================

-- ComprasAbonos con los nuevos campos requeridos
INSERT INTO ComprasAbonos (CodCompraAbono, FechaCompra, PrecioPagado, MetodoPago, EstadoPago,
                            CodAsistente, CodAbono) VALUES
('cabo_01','2026-07-01',300.00,'Tarjeta Credito', 'Completado','asis_01','abo_01'),
('cabo_02','2026-07-15',150.00,'Efectivo',         'Completado','asis_02','abo_02'),
('cabo_03','2026-07-20',200.00,'Tarjeta Credito',  'Completado','asis_03','abo_03'),
('cabo_04','2026-07-25',500.00,'Transferencia',    'Completado','asis_04','abo_04'),
('cabo_05','2026-08-01',120.00,'Efectivo',         'Completado','asis_05','abo_05'),
('cabo_06','2026-08-05',180.00,'Tarjeta Debito',   'Completado','asis_06','abo_06'),
('cabo_07','2026-08-10',100.00,'Efectivo',         'Completado','asis_07','abo_07');
GO

-- CodigosAcceso: un codigo unico por compra de abono (requerido por T1)
INSERT INTO CodigosAcceso (CodAcceso, CodCompraAbono, CodigoGenerado, FechaGeneracion, Usado) VALUES
('acc_01','cabo_01','ACC-ASIS01-2026-A1F3','2026-07-01 10:00:00',0),
('acc_02','cabo_02','ACC-ASIS02-2026-B2E4','2026-07-15 11:00:00',0),
('acc_03','cabo_03','ACC-ASIS03-2026-C3D5','2026-07-20 14:00:00',0),
('acc_04','cabo_04','ACC-ASIS04-2026-D4C6','2026-07-25 09:00:00',0),
('acc_05','cabo_05','ACC-ASIS05-2026-E5B7','2026-08-01 08:30:00',0),
('acc_06','cabo_06','ACC-ASIS06-2026-F6A8','2026-08-05 16:00:00',0),
('acc_07','cabo_07','ACC-ASIS07-2026-G7Z9','2026-08-10 12:00:00',0);
GO

-- Entradas individuales:
-- ent_01 a ent_07: datos originales corregidos (PrecioPagado = Precio de la Tarifa)
-- ent_08 a ent_10: llenan sala_08 (proy_13, cap. 3) para demo del procedimiento P1
-- ent_11 a ent_23: ventas adicionales para ranking e informe financiero
-- ent_22: tarifa gratuita para acreditado (requerido por enunciado)
INSERT INTO Entradas (CodEntrada, FechaCompra, PrecioPagado, CodAsistente, CodTarifa, CodProyeccion, CodEvento) VALUES
-- ent_01 a ent_07 (originales, corregidos)
('ent_01','2026-08-10', 45.00,'asis_01','tar_01','proy_01', NULL),
('ent_02','2026-08-11', 25.00,'asis_02','tar_02','proy_02', NULL),
('ent_03','2026-08-12',100.00,'asis_03','tar_04', NULL,    'epar_01'),
('ent_04','2026-08-13', 35.00,'asis_04','tar_05','proy_04', NULL),
('ent_05','2026-08-14',100.00,'asis_05','tar_04', NULL,    'epar_03'),
('ent_06','2026-08-15',  0.00,'asis_06','tar_07','proy_05', NULL),  -- gratuita acreditado
('ent_07','2026-08-16', 50.00,'asis_07','tar_01', NULL,    'epar_07'),
-- ent_08 a ent_10: llenan sala_08 (proy_13, capacidad=3) EXACTAMENTE
('ent_08','2026-08-15', 45.00,'asis_08','tar_01','proy_13', NULL),
('ent_09','2026-08-15', 25.00,'asis_09','tar_02','proy_13', NULL),
('ent_10','2026-08-15', 45.00,'asis_10','tar_01','proy_13', NULL),
-- ent_11 en adelante: datos para ranking y financiero
('ent_11','2026-08-16', 45.00,'asis_11','tar_01','proy_01', NULL),
('ent_12','2026-08-16', 25.00,'asis_12','tar_02','proy_01', NULL),
('ent_13','2026-08-16', 45.00,'asis_13','tar_01','proy_01', NULL),
('ent_14','2026-08-17', 45.00,'asis_14','tar_01','proy_02', NULL),
('ent_15','2026-08-17', 20.00,'asis_15','tar_03','proy_02', NULL),
('ent_16','2026-08-18', 35.00,'asis_16','tar_05','proy_03', NULL),
('ent_17','2026-08-18', 45.00,'asis_17','tar_01','proy_03', NULL),
('ent_18','2026-08-19', 25.00,'asis_18','tar_02','proy_04', NULL),
('ent_19','2026-08-18', 45.00,'asis_19','tar_01','proy_08', NULL),
('ent_20','2026-08-18', 35.00,'asis_20','tar_05','proy_08', NULL),
('ent_21','2026-08-22', 45.00,'asis_11','tar_01','proy_10', NULL),
('ent_22','2026-08-20',  0.00,'asis_12','tar_07','proy_09', NULL),  -- gratuita acreditado
('ent_23','2026-08-23', 45.00,'asis_13','tar_01','proy_11', NULL);
GO

-- UsosAbonos: registra cada uso de un abono en una proyeccion o evento
INSERT INTO UsosAbonos (CodUsoAbono, FechaUso, CodCompraAbono, CodProyeccion, CodEvento) VALUES
('uabo_01','2026-08-16','cabo_01','proy_01', NULL),
('uabo_02','2026-08-17','cabo_01','proy_02', NULL),
('uabo_03','2026-08-18','cabo_02', NULL,    'epar_01'),
('uabo_04','2026-08-19','cabo_03','proy_04', NULL),
('uabo_05','2026-08-20','cabo_04', NULL,    'epar_05'),
('uabo_06','2026-08-21','cabo_05','proy_06', NULL),
('uabo_07','2026-08-22','cabo_06','proy_07', NULL),
-- Usos adicionales para enriquecer el ranking
('uabo_08','2026-08-16','cabo_01','proy_01', NULL),  -- cabo_01 usa proy_01 de nuevo (abono total)
('uabo_09','2026-08-18','cabo_03','proy_08', NULL),
('uabo_10','2026-08-23','cabo_04','proy_11', NULL);
GO

-- Pagos: un registro por cada venta (entrada o abono).
-- Permite el informe financiero con desglose por tipo de venta.
INSERT INTO Pagos (CodPago, FechaPago, Monto, MetodoPago, EstadoPago, TipoVenta, CodEntrada, CodCompraAbono) VALUES
-- Pagos de entradas individuales
('pago_01','2026-08-10 10:00:00', 45.00,'Efectivo',       'Completado','Entrada','ent_01',NULL),
('pago_02','2026-08-11 11:30:00', 25.00,'Tarjeta Debito', 'Completado','Entrada','ent_02',NULL),
('pago_03','2026-08-12 09:00:00',100.00,'Tarjeta Credito','Completado','Entrada','ent_03',NULL),
('pago_04','2026-08-13 15:00:00', 35.00,'Efectivo',       'Completado','Entrada','ent_04',NULL),
('pago_05','2026-08-14 12:00:00',100.00,'Tarjeta Credito','Completado','Entrada','ent_05',NULL),
('pago_06','2026-08-15 08:00:00',  0.00,'Gratuito',       'Completado','Entrada','ent_06',NULL),
('pago_07','2026-08-16 17:00:00', 50.00,'Efectivo',       'Completado','Entrada','ent_07',NULL),
('pago_08','2026-08-15 10:00:00', 45.00,'Efectivo',       'Completado','Entrada','ent_08',NULL),
('pago_09','2026-08-15 10:05:00', 25.00,'Efectivo',       'Completado','Entrada','ent_09',NULL),
('pago_10','2026-08-15 10:10:00', 45.00,'Tarjeta Debito', 'Completado','Entrada','ent_10',NULL),
('pago_11','2026-08-16 19:30:00', 45.00,'Efectivo',       'Completado','Entrada','ent_11',NULL),
('pago_12','2026-08-16 19:35:00', 25.00,'Tarjeta Debito', 'Completado','Entrada','ent_12',NULL),
('pago_13','2026-08-16 19:40:00', 45.00,'Efectivo',       'Completado','Entrada','ent_13',NULL),
('pago_14','2026-08-17 20:00:00', 45.00,'Tarjeta Credito','Completado','Entrada','ent_14',NULL),
('pago_15','2026-08-17 20:05:00', 20.00,'Efectivo',       'Completado','Entrada','ent_15',NULL),
('pago_16','2026-08-18 17:00:00', 35.00,'Tarjeta Debito', 'Completado','Entrada','ent_16',NULL),
('pago_17','2026-08-18 17:05:00', 45.00,'Efectivo',       'Completado','Entrada','ent_17',NULL),
('pago_18','2026-08-19 19:00:00', 25.00,'Tarjeta Debito', 'Completado','Entrada','ent_18',NULL),
('pago_19','2026-08-18 09:00:00', 45.00,'Efectivo',       'Completado','Entrada','ent_19',NULL),
('pago_20','2026-08-18 09:05:00', 35.00,'Tarjeta Credito','Completado','Entrada','ent_20',NULL),
('pago_21','2026-08-22 17:00:00', 45.00,'Efectivo',       'Completado','Entrada','ent_21',NULL),
('pago_22','2026-08-20 15:00:00',  0.00,'Gratuito',       'Completado','Entrada','ent_22',NULL),
('pago_23','2026-08-23 18:00:00', 45.00,'Tarjeta Credito','Completado','Entrada','ent_23',NULL),
-- Pagos de abonos
('pago_ab1','2026-07-01 10:00:00',300.00,'Tarjeta Credito','Completado','Abono',NULL,'cabo_01'),
('pago_ab2','2026-07-15 11:00:00',150.00,'Efectivo',       'Completado','Abono',NULL,'cabo_02'),
('pago_ab3','2026-07-20 14:00:00',200.00,'Tarjeta Credito','Completado','Abono',NULL,'cabo_03'),
('pago_ab4','2026-07-25 09:00:00',500.00,'Transferencia',  'Completado','Abono',NULL,'cabo_04'),
('pago_ab5','2026-08-01 08:30:00',120.00,'Efectivo',       'Completado','Abono',NULL,'cabo_05'),
('pago_ab6','2026-08-05 16:00:00',180.00,'Tarjeta Debito', 'Completado','Abono',NULL,'cabo_06'),
('pago_ab7','2026-08-10 12:00:00',100.00,'Efectivo',       'Completado','Abono',NULL,'cabo_07');
GO
