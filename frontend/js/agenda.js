// ============================================================
// Módulo 2: Panel de Control de Agenda (Administrador)
// Flujo: Película + Sala + Fecha/Hora → Programar
// Invoca: INSERT Proyecciones → Trigger TR1 valida conflictos
// ============================================================

const Agenda = (() => {

  const selPelicula   = document.getElementById('sel-pelicula');
  const selSala       = document.getElementById('sel-sala');
  const inpInicio     = document.getElementById('inp-inicio');
  const inpFin        = document.getElementById('inp-fin');
  const inpSesionQa   = document.getElementById('inp-sesion-qa');
  const btnProgramar  = document.getElementById('btn-programar');
  const areaFeedback  = document.getElementById('area-feedback');
  const listaReciente = document.getElementById('lista-reciente');

  // IDs programadas en esta sesión (para panel de actividad)
  const programadas = [];

  // Duración (minutos) por película, para calcular la hora de fin
  const duraciones = {};

  // ── Helpers ───────────────────────────────────────────
  function setLoading(loading) {
    btnProgramar.disabled = loading;
    btnProgramar.innerHTML = loading
      ? '<span class="spinner"></span> Programando...'
      : '📅 Programar proyección';
  }

  function showAlert(type, msg) {
    const icon = type === 'success' ? '✅' : type === 'error' ? '⛔' : 'ℹ️';
    areaFeedback.innerHTML = `
      <div class="alert alert-${type}">
        <span class="alert-icon">${icon}</span>
        <div>${msg}</div>
      </div>`;
  }

  function generarCodProyeccion() {
    // Genera un ID único de 20 caracteres para la nueva proyección
    const ts  = Date.now().toString(36).toUpperCase();
    const rnd = Math.random().toString(36).substring(2, 7).toUpperCase();
    return ('PR_' + ts + rnd).substring(0, 20);
  }

  function formatFechaCorta(isoStr) {
    const d = new Date(isoStr);
    return d.toLocaleString('es-BO', {
      day: '2-digit', month: 'short', year: 'numeric',
      hour: '2-digit', minute: '2-digit',
    });
  }

  // ── Poblar selects ────────────────────────────────────
  async function cargarPeliculas() {
    selPelicula.innerHTML = '<option value="">Cargando...</option>';
    try {
      const peliculas = await API.peliculas.cartelera();
      selPelicula.innerHTML = '<option value="">-- Película --</option>';
      peliculas.forEach(p => {
        duraciones[p.codPelicula] = p.duracion;
        const opt = document.createElement('option');
        opt.value       = p.codPelicula;
        opt.textContent = `${p.titulo} (${p.duracion} min)`;
        selPelicula.appendChild(opt);
      });
    } catch {
      selPelicula.innerHTML = '<option value="">Error al cargar</option>';
    }
  }

  function cargarSalas() {
    selSala.innerHTML = '<option value="">-- Sala --</option>';
    CONFIG.SALAS.forEach(s => {
      const opt = document.createElement('option');
      opt.value       = s.cod;
      opt.textContent = `${s.nombre} (cap. ${s.capacidad})`;
      selSala.appendChild(opt);
    });
  }

  // ── Calcular fin = inicio + duración de la película ───
  function recalcularFin() {
    const duracion = duraciones[selPelicula.value];
    if (!inpInicio.value || !duracion) {
      inpFin.value = '';
      return;
    }
    const fin = new Date(inpInicio.value);
    fin.setMinutes(fin.getMinutes() + duracion);
    inpFin.value = fin.toISOString().slice(0, 16);
  }

  // ── Programar ─────────────────────────────────────────
  async function onProgramar(e) {
    e.preventDefault();
    areaFeedback.innerHTML = '';

    const codPelicula = selPelicula.value;
    const codSala     = selSala.value;
    const inicio      = inpInicio.value;
    const fin         = inpFin.value;

    if (!codPelicula || !codSala || !inicio) {
      showAlert('error', 'Debe completar Película, Sala y Fecha de Inicio.');
      return;
    }

    if (!fin) {
      showAlert('error', 'No se pudo calcular la hora de fin. Verifique la película seleccionada.');
      return;
    }

    const dto = {
      codProyeccion:  generarCodProyeccion(),
      codPelicula,
      codSala,
      fechaHoraInicio: new Date(inicio).toISOString(),
      sesionQa:        inpSesionQa.value.trim() || null,
      codEdicion:      CONFIG.EDICION_ACTUAL,
    };

    setLoading(true);

    try {
      await API.proyecciones.programar(dto);

      const salaLabel = CONFIG.SALAS.find(s => s.cod === codSala)?.nombre ?? codSala;
      const pelLabel  = selPelicula.options[selPelicula.selectedIndex].text;

      showAlert('success',
        `✅ Proyección programada correctamente.<br>
         <strong>${pelLabel}</strong> en <strong>${salaLabel}</strong><br>
         📅 ${formatFechaCorta(inicio)} → ${formatFechaCorta(fin)}`);

      // Registrar en actividad reciente
      programadas.unshift({ cod: dto.codProyeccion, pelicula: pelLabel, sala: salaLabel, inicio });
      renderActividad();

      // Limpiar formulario
      document.getElementById('form-agenda').reset();
    } catch (err) {
      // ⛔ TR1 bloqueó la inserción por conflicto de agenda
      showAlert('error',
        `<strong>Conflicto de agenda detectado por el servidor:</strong><br>${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  // ── Panel de actividad reciente ───────────────────────
  function renderActividad() {
    if (programadas.length === 0) {
      listaReciente.innerHTML = '<p style="color:var(--text-muted);font-size:.9rem">No hay proyecciones programadas en esta sesión.</p>';
      return;
    }
    listaReciente.innerHTML = programadas.map(p => `
      <div style="display:flex;justify-content:space-between;align-items:center;
                  padding:.65rem .85rem;background:var(--surface-2);border-radius:6px;
                  border:1px solid var(--border);margin-bottom:.5rem;">
        <div>
          <div style="font-weight:600;color:var(--text)">${p.pelicula}</div>
          <div style="font-size:.82rem;color:var(--text-muted)">${p.sala} · ${formatFechaCorta(p.inicio)}</div>
        </div>
        <span class="badge badge-green">Programada</span>
      </div>`).join('');
  }

  // ── Init ──────────────────────────────────────────────
  function init() {
    cargarPeliculas();
    cargarSalas();
    renderActividad();
    selPelicula.addEventListener('change', recalcularFin);
    inpInicio.addEventListener('change', recalcularFin);
    document.getElementById('form-agenda').addEventListener('submit', onProgramar);
  }

  return { init };
})();

document.addEventListener('DOMContentLoaded', Agenda.init);
