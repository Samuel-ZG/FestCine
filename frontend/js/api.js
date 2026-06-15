// Cliente centralizado para la API REST de FestCine.
// Todo acceso a datos pasa por aquí; los módulos no hacen fetch directamente.

const API = (() => {

  async function _fetch(endpoint, options = {}) {
    const url = CONFIG.API_BASE + endpoint;
    const res = await fetch(url, {
      headers: { 'Content-Type': 'application/json' },
      ...options,
    });

    // Parsear JSON independientemente del status code (200 o 409)
    const json = await res.json();

    if (!json.success) {
      // El mensaje viene directamente del RAISERROR del servidor
      throw new Error(json.message || 'Error desconocido del servidor.');
    }

    return json.data;
  }

  return {
    get:  (endpoint)       => _fetch(endpoint),
    post: (endpoint, body) => _fetch(endpoint, {
      method: 'POST',
      body: JSON.stringify(body),
    }),

    // Endpoints específicos
    peliculas: {
      cartelera: () => API.get('/api/peliculas/cartelera'),
    },
    proyecciones: {
      porPelicula: (cod)  => API.get(`/api/proyecciones/pelicula/${cod}`),
      programar:   (data) => API.post('/api/proyecciones/programar', data),
      asientos:    (cod)  => API.get(`/api/proyecciones/${cod}/asientos`),
    },
    tarifas: {
      activas: () => API.get('/api/tarifas'),
    },
    entradas: {
      comprar:         (data) => API.post('/api/entradas/comprar', data),
      comprarMultiple: (data) => API.post('/api/entradas/comprar-multiple', data),
    },
    asistente: {
      portal: (email) => API.get(`/api/asistente/portal?email=${encodeURIComponent(email)}`),
      existe: (email) => API.get(`/api/asistente/existe?email=${encodeURIComponent(email)}`),
    },
    abonos: {
      vender: (data) => API.post('/api/abonos/vender', data),
    },
    reportes: {
      ranking:           (ed) => API.get(`/api/reportes/ranking?codEdicion=${ed}`),
      actaPremiacion:    (ed) => API.get(`/api/reportes/acta-premiacion?codEdicion=${ed}`),
      informeFinanciero: ()   => API.get('/api/reportes/informe-financiero'),
    },
  };
})();
