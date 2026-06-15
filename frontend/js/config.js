// Configuración global del cliente frontend
const CONFIG = {
  API_BASE: 'http://localhost:5000',
  EDICION_ACTUAL: 'edi_2026',

  // Datos de referencia estáticos (catálogos que no cambian en tiempo de ejecución)
  SALAS: [
    { cod: 'sala_01', nombre: 'Sala VIP Center',        capacidad: 100 },
    { cod: 'sala_02', nombre: 'Auditorio Principal',     capacidad: 250 },
    { cod: 'sala_03', nombre: 'Sala XD Ventura',         capacidad: 300 },
    { cod: 'sala_04', nombre: 'Teatro Abierto',          capacidad: 150 },
    { cod: 'sala_05', nombre: 'Salon Central',           capacidad:  80 },
    { cod: 'sala_06', nombre: 'Patio Historico',         capacidad: 120 },
    { cod: 'sala_07', nombre: 'Sala Normal Multicine',   capacidad: 200 },
    { cod: 'sala_08', nombre: 'Sala Mini Demo (cap. 3)', capacidad:   3 },
  ],

  ABONOS: [
    { cod: 'abo_01', nombre: 'Abono Total Festival',      precio: 250.00 },
    { cod: 'abo_02', nombre: 'Abono Fin de Semana',       precio: 120.00 },
    { cod: 'abo_03', nombre: 'Abono Cortometrajes',       precio:  80.00 },
    { cod: 'abo_04', nombre: 'Abono Prensa',              precio:   0.00 },
    { cod: 'abo_05', nombre: 'Abono VIP',                 precio: 350.00 },
    { cod: 'abo_06', nombre: 'Abono Estudiante',          precio:  60.00 },
    { cod: 'abo_07', nombre: 'Abono Industria',           precio: 180.00 },
  ],
};
