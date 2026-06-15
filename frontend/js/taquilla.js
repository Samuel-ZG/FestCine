// ============================================================
// Taquilla — Wizard de 6 pasos
// Paso 1: Película → Paso 2: Función → Paso 3: Tarifa + cantidad
// → Paso 4: Asientos → Paso 5: Datos → Paso 6: Comprobante
// ============================================================

const Taquilla = (() => {

  // ── Estado ────────────────────────────────────────────
  const state = {
    step:       1,
    pelicula:   null,
    proyeccion: null,
    asientos:   [],      // todos los asientos de la sala (de API)
    seleccionados: [],   // codAsiento seleccionados
    tarifa:     null,
    tarifas:    [],
    cantidad:   1,
  };

  // ── Navegación entre pasos ────────────────────────────
  function goTo(n) {
    state.step = n;
    document.querySelectorAll('.wizard-panel').forEach((p, i) => {
      p.classList.toggle('active', i + 1 === n);
    });
    document.querySelectorAll('#step-indicator .wizard-step-item').forEach((el, i) => {
      const step = i + 1;
      el.classList.toggle('done',   step < n);
      el.classList.toggle('active', step === n);
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function goBack(n) { goTo(n); }

  // ── Helpers UI ─────────────────────────────────────────
  function fmt(isoStr) {
    const d = new Date(isoStr);
    return d.toLocaleString('es-BO', {
      weekday: 'short', day: '2-digit', month: 'short',
      hour: '2-digit', minute: '2-digit',
    });
  }

  function setBtn(id, loading, label) {
    const b = document.getElementById(id);
    if (!b) return;
    b.disabled = loading;
    b.innerHTML = loading ? '<span class="spinner"></span> Procesando...' : label;
  }

  function showFeedback(id, type, msg) {
    const el = document.getElementById(id);
    if (!el) return;
    const icon = type === 'success' ? '✅' : type === 'warn' ? '⚠️' : type === 'info' ? 'ℹ️' : '❌';
    el.innerHTML = `<div class="alert alert-${type}"><span class="alert-icon">${icon}</span>${msg}</div>`;
  }

  // ── PASO 1: Cartelera ─────────────────────────────────
  async function cargarCartelera() {
    const grid = document.getElementById('cartelera-grid');
    try {
      const peliculas = await API.peliculas.cartelera();
      if (!peliculas.length) {
        grid.innerHTML = '<div class="alert alert-info"><span class="alert-icon">ℹ️</span>No hay películas en cartelera.</div>';
        return;
      }
      grid.innerHTML = peliculas.map(p => `
        <div class="pelicula-card" data-cod="${p.codPelicula}" onclick="Taquilla.selectPelicula(this, ${JSON.stringify(p).replace(/"/g, '&quot;')})">
          <div class="pc-titulo">${p.titulo}</div>
          <div class="pc-meta">
            <span class="badge badge-purple">${p.formato}</span>
            <span class="badge badge-gray">${p.duracion} min</span>
            <span class="badge badge-gray">${p.paisOrigen}</span>
          </div>
          <div style="margin-top:.6rem;font-size:.78rem;color:var(--text-muted)">${p.estado}</div>
        </div>`).join('');
    } catch (e) {
      grid.innerHTML = `<div class="alert alert-error"><span class="alert-icon">❌</span>${e.message}</div>`;
    }
  }

  function selectPelicula(el, pelicula) {
    document.querySelectorAll('.pelicula-card').forEach(c => c.classList.remove('selected'));
    el.classList.add('selected');
    state.pelicula = pelicula;
    cargarProyecciones(pelicula.codPelicula, pelicula.titulo);
  }

  // ── PASO 2: Proyecciones ──────────────────────────────
  async function cargarProyecciones(codPelicula, titulo) {
    const list = document.getElementById('proyecciones-list');
    document.getElementById('pelicula-seleccionada').textContent = `Película: ${titulo}`;
    list.innerHTML = '<div class="alert alert-info"><span class="alert-icon"><span class="spinner"></span></span> Cargando funciones...</div>';

    try {
      const proyecciones = await API.proyecciones.porPelicula(codPelicula);
      goTo(2);

      if (!proyecciones.length) {
        list.innerHTML = '<div class="alert alert-warn"><span class="alert-icon">⚠️</span>No hay funciones disponibles para esta película.</div>';
        return;
      }

      list.innerHTML = proyecciones.map(p => {
        const cupo  = p.cupoDisponible;
        const badge = cupo === 0
          ? `<span class="badge badge-red">Sin cupo</span>`
          : cupo <= 5
            ? `<span class="badge badge-gold">⚠️ ${cupo} lugares</span>`
            : `<span class="badge badge-green">🟢 ${cupo} lugares</span>`;
        const disabled = cupo === 0 ? 'disabled' : '';
        return `
          <div class="proyeccion-item ${disabled}" ${disabled ? '' : `onclick="Taquilla.selectProyeccion(${JSON.stringify(p).replace(/"/g, '&quot;')})"`}>
            <div>
              <div class="pi-fecha">${fmt(p.fechaHoraInicio)}</div>
              <div class="pi-sala">${p.nombreSala} · ${p.nombreSede}</div>
            </div>
            <div class="pi-cupo">${badge}</div>
          </div>`;
      }).join('');
    } catch (e) {
      list.innerHTML = `<div class="alert alert-error"><span class="alert-icon">❌</span>${e.message}</div>`;
    }
  }

  function selectProyeccion(proy) {
    state.proyeccion = proy;
    cargarTarifas();
  }

  // ── PASO 3: Tarifa y cantidad ─────────────────────────
  async function cargarTarifas() {
    const grid = document.getElementById('tarifas-grid');
    const btn  = document.getElementById('btn-continuar-3');
    const inpCantidad = document.getElementById('inp-cantidad');

    state.tarifa   = null;
    state.cantidad = 1;
    inpCantidad.value = 1;
    btn.disabled = true;
    document.getElementById('feedback-3').innerHTML = '';

    goTo(3);

    grid.innerHTML = '<div class="alert alert-info"><span class="alert-icon"><span class="spinner"></span></span> Cargando tarifas...</div>';

    try {
      state.tarifas = await API.tarifas.activas();
      grid.innerHTML = state.tarifas.map(t => `
        <div class="pelicula-card" data-cod="${t.codTarifa}" onclick="Taquilla.selectTarifa(this, ${JSON.stringify(t).replace(/"/g, '&quot;')})">
          <div class="pc-titulo">${t.nombre}</div>
          <div class="pc-meta">
            <span class="badge badge-purple">Bs. ${Number(t.precio).toFixed(2)}</span>
            <span class="badge badge-gray">${t.categoriaAsiento}</span>
          </div>
        </div>`).join('');
    } catch (e) {
      grid.innerHTML = `<div class="alert alert-error"><span class="alert-icon">❌</span>${e.message}</div>`;
    }
  }

  function selectTarifa(el, tarifa) {
    document.querySelectorAll('#tarifas-grid .pelicula-card').forEach(c => c.classList.remove('selected'));
    el.classList.add('selected');
    state.tarifa = tarifa;
    updateStep3Continue();
  }

  function updateStep3Continue() {
    const btn = document.getElementById('btn-continuar-3');
    const cantidad = parseInt(document.getElementById('inp-cantidad').value, 10);
    btn.disabled = !state.tarifa || !Number.isInteger(cantidad) || cantidad < 1;
  }

  function step3Continue() {
    const cantidad = parseInt(document.getElementById('inp-cantidad').value, 10);

    if (!state.tarifa) {
      showFeedback('feedback-3', 'error', 'Debes elegir una tarifa.');
      return;
    }
    if (!Number.isInteger(cantidad) || cantidad < 1) {
      showFeedback('feedback-3', 'error', 'La cantidad de entradas debe ser un número entero mayor o igual a 1.');
      return;
    }

    state.cantidad = cantidad;
    document.getElementById('feedback-3').innerHTML = '';
    cargarAsientos(state.proyeccion);
  }

  // ── PASO 4: Asientos ───────────────────────────────────
  async function cargarAsientos(proy) {
    const map = document.getElementById('seat-map');
    document.getElementById('funcion-seleccionada-label').textContent =
      `${fmt(proy.fechaHoraInicio)} · ${proy.nombreSala}`;

    document.getElementById('sum-pelicula').textContent = state.pelicula?.titulo ?? '';
    document.getElementById('sum-meta').textContent     = `${fmt(proy.fechaHoraInicio)} · ${proy.nombreSala}`;
    document.getElementById('sum-tarifa').textContent   =
      `${state.tarifa.nombre} · Bs. ${Number(state.tarifa.precio).toFixed(2)} c/u · Cantidad: ${state.cantidad}`;

    state.seleccionados = [];
    document.getElementById('feedback-4').innerHTML = '';
    goTo(4);

    map.innerHTML = '<div class="alert alert-info"><span class="alert-icon"><span class="spinner"></span></span> Cargando mapa...</div>';

    try {
      state.asientos = await API.proyecciones.asientos(proy.codProyeccion);
      renderSeatMap();
      updateSeatSummary();
    } catch (e) {
      map.innerHTML = `<div class="alert alert-error"><span class="alert-icon">❌</span>${e.message}</div>`;
    }
  }

  function esCompatible(tipoAsiento) {
    return state.tarifa.categoriaAsiento === 'Ambas' || tipoAsiento === state.tarifa.categoriaAsiento;
  }

  function renderSeatMap() {
    const map = document.getElementById('seat-map');
    // Agrupar por fila
    const rows = {};
    state.asientos.forEach(a => {
      if (!rows[a.fila]) rows[a.fila] = [];
      rows[a.fila].push(a);
    });

    map.innerHTML = Object.keys(rows).sort().map(fila => {
      const seats = rows[fila].map(a => {
        let cls;
        if (state.seleccionados.includes(a.codAsiento)) {
          cls = 'seleccionado';
        } else if (a.estado === 'Ocupado') {
          cls = 'ocupado';
        } else if (!esCompatible(a.tipoAsiento)) {
          cls = 'no-disponible';
        } else {
          cls = 'libre';
        }
        return `<div class="seat ${cls}"
          title="Asiento ${a.fila}${a.numero}"
          onclick="Taquilla.toggleSeat('${a.codAsiento}','${a.fila}',${a.numero},'${a.estado}','${a.tipoAsiento}')">${a.numero}</div>`;
      }).join('');
      return `<div class="seat-row"><div class="row-label">${fila}</div><div class="row-seats">${seats}</div></div>`;
    }).join('');
  }

  function toggleSeat(cod, fila, num, estado, tipo) {
    if (estado === 'Ocupado') return;
    if (!esCompatible(tipo)) return;

    const idx = state.seleccionados.indexOf(cod);
    if (idx === -1) {
      if (state.seleccionados.length >= state.cantidad) {
        showFeedback('feedback-4', 'warn',
          `Ya seleccionaste el máximo de ${state.cantidad} asiento(s). Quita uno para elegir otro.`);
        return;
      }
      state.seleccionados.push(cod);
    } else {
      state.seleccionados.splice(idx, 1);
    }
    renderSeatMap();
    updateSeatSummary();
  }

  function updateSeatSummary() {
    const list = document.getElementById('selected-seats-list');
    const btn  = document.getElementById('btn-continuar-4');

    if (!state.seleccionados.length) {
      list.innerHTML = '<p style="font-size:.82rem;color:var(--text-muted);text-align:center;padding:.5rem 0">Haz clic en un asiento libre</p>';
    } else {
      list.innerHTML = state.seleccionados.map(cod => {
        const a = state.asientos.find(x => x.codAsiento === cod);
        return `<div class="selected-seat-tag">
          <span>Asiento ${a?.fila ?? ''}${a?.numero ?? ''}</span>
          <span class="remove-seat" onclick="Taquilla.removeSeat('${cod}')">✕</span>
        </div>`;
      }).join('');
    }

    const total = state.tarifa.precio * state.seleccionados.length;
    document.getElementById('sum-total').textContent = `Bs. ${total.toFixed(2)}`;

    const faltan = state.cantidad - state.seleccionados.length;
    if (faltan > 0) {
      showFeedback('feedback-4', 'warn',
        `Selecciona ${faltan} asiento(s) más (${state.seleccionados.length}/${state.cantidad}).`);
    } else {
      document.getElementById('feedback-4').innerHTML = '';
    }

    btn.disabled = state.seleccionados.length !== state.cantidad;
  }

  function removeSeat(cod) {
    const idx = state.seleccionados.indexOf(cod);
    if (idx !== -1) state.seleccionados.splice(idx, 1);
    renderSeatMap();
    updateSeatSummary();
  }

  function step4Continue() {
    goTo(5);
    renderResumenPre();
  }

  // ── PASO 5: Datos ──────────────────────────────────────
  function renderResumenPre() {
    const div = document.getElementById('resumen-precompra');
    if (!div) return;
    const p   = state.proyeccion;
    const t   = state.tarifa;
    const n   = state.seleccionados.length;
    const tot = (t.precio * n).toFixed(2);
    const asientos = state.seleccionados.map(cod => {
      const a = state.asientos.find(x => x.codAsiento === cod);
      return a ? `Asiento ${a.fila}${a.numero}` : cod;
    }).join(', ');

    div.innerHTML = `
      <div style="background:var(--surface-3);border-radius:var(--radius-sm);padding:1rem;font-size:.85rem;color:var(--text-muted)">
        <strong style="color:var(--text)">${state.pelicula?.titulo}</strong><br>
        ${p ? fmt(p.fechaHoraInicio) + ' · ' + p.nombreSala : ''}<br>
        Tarifa: <strong>${t.nombre}</strong> · Bs. ${Number(t.precio).toFixed(2)} c/u<br>
        Asientos: <strong style="color:var(--accent)">${asientos}</strong> (${n})<br>
        <strong style="font-size:1rem;color:var(--text)">Total: Bs. ${tot}</strong>
      </div>`;
  }

  // Avisa si el correo ingresado ya tiene una cuenta registrada, sin
  // autocompletar nombres/teléfono (la decisión final la toma el backend).
  async function checkEmailExistente() {
    const email  = document.getElementById('inp-email').value.trim();
    const notice = document.getElementById('email-notice');
    if (!notice) return;
    if (!email) { notice.innerHTML = ''; return; }

    try {
      const data = await API.asistente.existe(email);
      if (data.existe) {
        notice.innerHTML = `<div class="alert alert-info"><span class="alert-icon">ℹ️</span>
          Este correo ya está registrado. La compra se vinculará a la cuenta existente.
          Inicia sesión para ver tus entradas en <a href="portal.html">Mi portal</a>.</div>`;
      } else {
        notice.innerHTML = '';
      }
    } catch {
      notice.innerHTML = '';
    }
  }

  // ── PASO 6: Comprar ────────────────────────────────────
  async function comprar(e) {
    e.preventDefault();

    const request = {
      nombres:       document.getElementById('inp-nombres').value.trim(),
      apellidos:     document.getElementById('inp-apellidos').value.trim(),
      email:         document.getElementById('inp-email').value.trim(),
      telefono:      document.getElementById('inp-telefono').value.trim() || null,
      codProyeccion: state.proyeccion.codProyeccion,
      codTarifa:     state.tarifa.codTarifa,
      codAsientos:   state.seleccionados,
    };

    setBtn('btn-comprar', true, '');
    goTo(6);

    try {
      const data = await API.entradas.comprarMultiple(request);
      renderComprobante(data);
    } catch (err) {
      document.getElementById('area-comprobante').innerHTML =
        `<div class="alert alert-error"><span class="alert-icon">❌</span>${err.message}</div>
         <div style="margin-top:1rem">
           <button class="btn btn-ghost" onclick="Taquilla.goBack(5)">← Volver e intentar</button>
         </div>`;
    }
  }

  function renderComprobante(data) {
    const fechaStr = data.fechaHoraInicio
      ? new Date(data.fechaHoraInicio).toLocaleString('es-BO', {
          weekday:'long', day:'2-digit', month:'long', year:'numeric',
          hour:'2-digit', minute:'2-digit'
        })
      : '—';

    const entradasHtml = data.entradas.map(e => {
      const precioHtml = e.esPromoAplicada
        ? `<span style="text-decoration:line-through;color:var(--text-muted);margin-right:.4rem">Bs. ${Number(e.precioOriginal).toFixed(2)}</span>
           <span class="ei-value">Bs. ${Number(e.precioPagado).toFixed(2)}</span>
           <span class="badge badge-gold" style="margin-left:.4rem">🎉 -50% promo miércoles</span>`
        : `<span class="ei-value">Bs. ${Number(e.precioPagado).toFixed(2)}</span>`;
      return `
      <div class="entrada-item">
        <div><span class="ei-label">Código de entrada</span><span class="ei-code">${e.codEntrada}</span></div>
        <div><span class="ei-label">Asiento</span><span class="ei-value">${e.fila}${e.numero}</span></div>
        <div><span class="ei-label">Precio</span>${precioHtml}</div>
        <div style="grid-column:1/-1"><span class="ei-label">Código de validación</span><span class="ei-code">${e.codigoValidacion}</span></div>
      </div>`;
    }).join('');

    const descuentoHtml = data.totalDescuento > 0
      ? `<div class="comprobante-total" style="color:var(--accent)">
           <span>Descuento total (promo miércoles)</span>
           <span>- Bs. ${Number(data.totalDescuento).toFixed(2)}</span>
         </div>`
      : '';

    document.getElementById('area-comprobante').innerHTML = `
      <div class="comprobante-card" id="comprobante-print">
        <div class="comprobante-header">
          <div class="comprobante-icon">✅</div>
          <div>
            <h2>¡Compra confirmada!</h2>
            <p>${data.entradas.length} entrada(s) para ${data.nombreAsistente}</p>
          </div>
        </div>

        <div class="comprobante-entradas">${entradasHtml}</div>

        <div class="comprobante-info">
          <div><span class="ci-label">Película</span><span class="ci-value">${data.pelicula}</span></div>
          <div><span class="ci-label">Fecha y hora</span><span class="ci-value">${fechaStr}</span></div>
          <div><span class="ci-label">Sala</span><span class="ci-value">${data.nombreSala}</span></div>
          <div><span class="ci-label">Sede</span><span class="ci-value">${data.nombreSede}</span></div>
          <div><span class="ci-label">Asistente</span><span class="ci-value">${data.nombreAsistente}</span></div>
          <div><span class="ci-label">Email</span><span class="ci-value">${data.email}</span></div>
        </div>

        ${descuentoHtml}

        <div class="comprobante-total">
          <span>Total pagado</span>
          <span>Bs. ${Number(data.totalPagado).toFixed(2)}</span>
        </div>

        <div class="comprobante-actions">
          <button class="btn btn-primary" onclick="window.print()">🖨️ Imprimir</button>
          <a href="portal.html" class="btn btn-secondary">Ver mi portal →</a>
        </div>
      </div>`;
  }

  function reiniciar() {
    state.step          = 1;
    state.pelicula      = null;
    state.proyeccion    = null;
    state.asientos      = [];
    state.seleccionados = [];
    state.tarifa        = null;
    state.cantidad      = 1;
    document.getElementById('form-datos')?.reset();
    document.getElementById('resumen-precompra').innerHTML = '';
    document.getElementById('feedback-5').innerHTML = '';
    document.getElementById('email-notice').innerHTML = '';
    goTo(1);
  }

  // ── Init ──────────────────────────────────────────────
  function init() {
    cargarCartelera();
    document.getElementById('inp-cantidad').addEventListener('input', updateStep3Continue);
    document.getElementById('inp-email').addEventListener('blur', checkEmailExistente);
  }

  return {
    init, goBack, selectPelicula, selectProyeccion,
    selectTarifa, step3Continue,
    toggleSeat, removeSeat, step4Continue,
    comprar, reiniciar,
  };
})();

document.addEventListener('DOMContentLoaded', Taquilla.init);
