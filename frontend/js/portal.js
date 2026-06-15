// ============================================================
// Portal de Asistente
// Lookup por email → muestra dashboard, entradas y abonos
// ============================================================

const Portal = (() => {

  let _data = null; // AsistentePortalDto

  // ── Lookup ────────────────────────────────────────────
  async function buscar() {
    const email = document.getElementById('inp-email-lookup').value.trim();
    if (!email) { showLookupFeedback('error', 'Ingresa tu correo electrónico.'); return; }

    const btn = document.getElementById('btn-lookup');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span>';

    try {
      const data = await API.asistente.portal(email);
      _data = data;
      renderDashboard(data);
      document.getElementById('portal-lookup').style.display    = 'none';
      document.getElementById('portal-dashboard').style.display = 'block';
    } catch (err) {
      showLookupFeedback('error', err.message);
    } finally {
      btn.disabled = false;
      btn.innerHTML = 'Buscar';
    }
  }

  function showLookupFeedback(type, msg) {
    const el   = document.getElementById('lookup-feedback');
    const icon = type === 'error' ? '❌' : '✅';
    el.innerHTML = `<div class="alert alert-${type}"><span class="alert-icon">${icon}</span>${msg}</div>`;
  }

  // ── Dashboard ─────────────────────────────────────────
  function renderDashboard(data) {
    // Sidebar
    const initials = (data.nombres[0] || '') + (data.apellidos[0] || '');
    document.getElementById('portal-avatar').textContent  = initials.toUpperCase();
    document.getElementById('portal-nombre').textContent  = `${data.nombres} ${data.apellidos}`;
    document.getElementById('portal-email-disp').textContent = data.email;

    // Stats
    document.getElementById('stat-entradas').textContent = data.totalEntradas;
    document.getElementById('stat-abonos').textContent   = data.totalAbonos;
    document.getElementById('stat-acred').textContent    = '—';

    // Entradas preview (max 3)
    const preview = data.entradas.slice(0, 3);
    document.getElementById('dashboard-entradas-preview').innerHTML =
      preview.length ? preview.map(renderEntradaCard).join('') :
      '<div class="empty-state"><div class="es-icon">🎟️</div><div class="es-text">No tienes entradas aún.</div></div>';

    // Listas completas
    document.getElementById('lista-entradas').innerHTML =
      data.entradas.length ? data.entradas.map(renderEntradaCard).join('') :
      '<div class="empty-state"><div class="es-icon">🎟️</div><div class="es-text">No tienes entradas registradas.</div></div>';

    document.getElementById('lista-abonos').innerHTML =
      data.abonos.length ? data.abonos.map(renderAbonoCard).join('') :
      '<div class="empty-state"><div class="es-icon">🎫</div><div class="es-text">No tienes abonos aún. Puedes comprar uno aquí.</div></div>';

    // Cargar abonos disponibles para comprar
    cargarAbonos();
  }

  function renderEntradaCard(e) {
    const fecha = e.fechaHoraInicio
      ? new Date(e.fechaHoraInicio).toLocaleString('es-BO', {
          weekday:'short', day:'2-digit', month:'short', hour:'2-digit', minute:'2-digit'
        })
      : '—';
    const asiento = (e.fila && e.numero) ? ` · Asiento ${e.fila}${e.numero}` : '';
    return `
      <div class="entrada-portal-card">
        <div class="epc-left">
          <div class="epc-titulo">${e.pelicula ?? 'Evento'}</div>
          <div class="epc-meta">${fecha}${asiento ? ` · ${e.nombreSala ?? ''}` : ''} ${asiento}</div>
          <div class="epc-code">${e.codEntrada}${e.codigoValidacion ? ' · VAL: ' + e.codigoValidacion : ''}</div>
        </div>
        <div class="epc-right">
          <span class="badge badge-green">Bs. ${Number(e.precioPagado).toFixed(2)}</span>
        </div>
      </div>`;
  }

  function renderAbonoCard(a) {
    return `
      <div class="abono-portal-card">
        <div>
          <div class="apc-nombre">🎫 ${a.nombreAbono}</div>
          <div class="apc-codigo">${a.codCompraAbono} · ACC: ${a.codigoAcceso}</div>
          <span class="badge badge-green" style="margin-top:.4rem">${a.estadoPago}</span>
        </div>
        <div class="apc-precio">Bs. ${Number(a.precioPagado).toFixed(2)}</div>
      </div>`;
  }

  // ── Secciones portal ──────────────────────────────────
  function showSection(id, btn) {
    document.querySelectorAll('.portal-section').forEach(s => s.classList.remove('active'));
    document.querySelectorAll('.portal-nav-btn').forEach(b => b.classList.remove('active'));
    document.getElementById('section-' + id).classList.add('active');
    if (btn) btn.classList.add('active');
  }

  // ── Comprar abono ─────────────────────────────────────
  async function cargarAbonos() {
    const sel = document.getElementById('sel-abono-tipo');
    try {
      const abonos = CONFIG.ABONOS;
      if (!abonos || !abonos.length) { sel.innerHTML = '<option value="">No hay abonos configurados</option>'; return; }
      sel.innerHTML = '<option value="">-- Elige tipo de abono --</option>' +
        abonos.map(a => `<option value="${a.cod}" data-precio="${a.precio}">${a.nombre} — Bs. ${a.precio.toFixed(2)}</option>`).join('');
      sel.addEventListener('change', () => {
        const opt = sel.options[sel.selectedIndex];
        document.getElementById('inp-precio-abono').value = opt.value ? `Bs. ${parseFloat(opt.dataset.precio).toFixed(2)}` : '—';
      });
    } catch (e) {
      sel.innerHTML = '<option value="">Error al cargar</option>';
    }
  }

  async function comprarAbono(e) {
    e.preventDefault();
    const sel = document.getElementById('sel-abono-tipo');
    if (!sel.value || !_data) return;

    setAbonoBtn(true);
    document.getElementById('feedback-abono').innerHTML = '';

    try {
      const result = await API.abonos.vender({
        codAsistente: _data.codAsistente,
        codAbono:     sel.value,
        metodoPago:   'Tarjeta',
      });

      document.getElementById('feedback-abono').innerHTML = `
        <div class="alert alert-success">
          <span class="alert-icon">✅</span>
          <div>
            <strong>¡Abono comprado exitosamente!</strong><br>
            Código de acceso: <code>${result.codigoAcceso}</code><br>
            Total pagado: Bs. ${Number(result.montoPagado).toFixed(2)}
          </div>
        </div>`;

      // Recargar portal para reflejar nuevo abono
      setTimeout(async () => {
        const data = await API.asistente.portal(_data.email);
        _data = data;
        renderDashboard(data);
        showSection('abonos', null);
        document.querySelectorAll('.portal-nav-btn').forEach(b => {
          if (b.textContent.includes('abonos')) b.classList.add('active');
          else b.classList.remove('active');
        });
      }, 1500);

    } catch (err) {
      document.getElementById('feedback-abono').innerHTML =
        `<div class="alert alert-error"><span class="alert-icon">❌</span>${err.message}</div>`;
    } finally {
      setAbonoBtn(false);
    }
  }

  function setAbonoBtn(loading) {
    const btn = document.getElementById('btn-comprar-abono');
    btn.disabled = loading;
    btn.innerHTML = loading ? '<span class="spinner"></span> Procesando...' : '🎫 Comprar abono';
  }

  // ── Cerrar sesión ─────────────────────────────────────
  function cerrar() {
    _data = null;
    document.getElementById('portal-dashboard').style.display = 'none';
    document.getElementById('portal-lookup').style.display    = 'block';
    document.getElementById('inp-email-lookup').value         = '';
    document.getElementById('lookup-feedback').innerHTML      = '';
  }

  function init() {
    document.getElementById('inp-email-lookup').addEventListener('keydown', e => {
      if (e.key === 'Enter') buscar();
    });
  }

  return { buscar, showSection, comprarAbono, cerrar, init };
})();

document.addEventListener('DOMContentLoaded', Portal.init);
