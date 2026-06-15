// ============================================================
// Módulo 3: Reportes DQL
// Tres pestañas: Ranking | Acta Premiación | Informe Financiero
// Todas las consultas van contra vistas del servidor (solo GET)
// ============================================================

const Reportes = (() => {

  // ── Tabs ──────────────────────────────────────────────
  function initTabs() {
    document.querySelectorAll('.tab-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById(btn.dataset.tab).classList.add('active');
      });
    });
  }

  // ── Helper: tabla genérica ────────────────────────────
  function renderTabla(containerId, cols, rows, rowFn) {
    const container = document.getElementById(containerId);
    if (!rows || rows.length === 0) {
      container.innerHTML = '<p class="alert alert-info"><span class="alert-icon">ℹ️</span>No hay datos disponibles.</p>';
      return;
    }
    const encabezados = cols.map(c => `<th>${c}</th>`).join('');
    const filas       = rows.map(rowFn).join('');
    container.innerHTML = `
      <div class="table-wrap">
        <table>
          <thead><tr>${encabezados}</tr></thead>
          <tbody>${filas}</tbody>
        </table>
      </div>`;
  }

  function setLoadingBtn(btnId, loading, labelOff) {
    const btn = document.getElementById(btnId);
    btn.disabled  = loading;
    btn.innerHTML = loading
      ? '<span class="spinner"></span> Cargando...'
      : labelOff;
  }

  // ── Reporte 1: Ranking de películas ──────────────────
  async function cargarRanking() {
    setLoadingBtn('btn-ranking', true, '🔄 Actualizar ranking');
    try {
      const data = await API.reportes.ranking(CONFIG.EDICION_ACTUAL);

      renderTabla('tabla-ranking',
        ['#', 'Película', 'Funciones', 'Asistentes', 'Capacidad total', 'Ocupación'],
        data,
        row => {
          const pct  = Number(row.pctOcupacion);
          const cls  = pct >= 80 ? 'high' : pct >= 50 ? 'mid' : '';
          const rnkCls = row.posicion === 1 ? 'rank-1'
                       : row.posicion === 2 ? 'rank-2'
                       : row.posicion === 3 ? 'rank-3' : 'rank-n';
          return `
            <tr>
              <td><span class="rank-num ${rnkCls}">${row.posicion}</span></td>
              <td style="font-weight:600;color:var(--text)">${row.titulo}</td>
              <td>${row.totalProyecciones}</td>
              <td>${row.totalAsistentes}</td>
              <td>${row.capacidadTotal}</td>
              <td>
                <div class="occ-bar-wrap">
                  <div class="occ-bar">
                    <div class="occ-bar-fill ${cls}" style="width:${Math.min(pct,100)}%"></div>
                  </div>
                  <span style="font-weight:700;min-width:48px">${pct.toFixed(1)}%</span>
                </div>
              </td>
            </tr>`;
        });
    } catch (err) {
      document.getElementById('tabla-ranking').innerHTML =
        `<div class="alert alert-error"><span class="alert-icon">❌</span>${err.message}</div>`;
    } finally {
      setLoadingBtn('btn-ranking', false, '🔄 Actualizar ranking');
    }
  }

  // ── Reporte 2: Acta de premiación ────────────────────
  async function cargarActa() {
    setLoadingBtn('btn-acta', true, '🔄 Actualizar acta');
    try {
      const data = await API.reportes.actaPremiacion(CONFIG.EDICION_ACTUAL);

      renderTabla('tabla-acta',
        ['Categoría', 'Premio', 'Película ganadora', 'Promedio votación', 'Votos'],
        data,
        row => {
          const prom = row.promedioVotacion != null
            ? `<span class="badge badge-gold">⭐ ${Number(row.promedioVotacion).toFixed(2)}</span>`
            : '<span class="badge badge-gray">Sin eval.</span>';
          return `
            <tr>
              <td><span class="badge badge-gray">${row.categoria}</span></td>
              <td style="color:var(--accent);font-weight:600">🏆 ${row.premio}</td>
              <td style="font-weight:600;color:var(--text)">${row.titulo}</td>
              <td>${prom}</td>
              <td>${row.totalVotos ?? '—'}</td>
            </tr>`;
        });
    } catch (err) {
      document.getElementById('tabla-acta').innerHTML =
        `<div class="alert alert-error"><span class="alert-icon">❌</span>${err.message}</div>`;
    } finally {
      setLoadingBtn('btn-acta', false, '🔄 Actualizar acta');
    }
  }

  // ── Reporte 3: Informe financiero ────────────────────
  async function cargarFinanciero() {
    setLoadingBtn('btn-financiero', true, '🔄 Actualizar informe');
    try {
      const data = await API.reportes.informeFinanciero();

      renderTabla('tabla-financiero-tipoventa',
        ['Tipo de venta', 'Cantidad vendida', 'Monto bruto', 'Descuento total', 'Total recaudado'],
        data.porTipoVenta,
        row => `
          <tr>
            <td>
              <span class="badge ${row.tipoVenta === 'Entrada' ? 'badge-green' : 'badge-gold'}">
                ${row.tipoVenta}
              </span>
            </td>
            <td>${row.cantidadVendida}</td>
            <td>Bs. ${Number(row.montoBruto).toFixed(2)}</td>
            <td>Bs. ${Number(row.descuentoTotal).toFixed(2)}</td>
            <td>Bs. ${Number(row.totalRecaudado).toFixed(2)}</td>
          </tr>`);

      renderTabla('tabla-financiero-tarifa',
        ['Tarifa / Concepto', 'Cantidad vendida', 'Precio original', 'Descuento aplicado', 'Total recaudado'],
        data.porTarifa,
        row => `
          <tr>
            <td>
              ${row.concepto}
              ${row.esPromoAplicada ? '<span class="badge badge-gold" style="margin-left:.4rem">Promo</span>' : ''}
            </td>
            <td>${row.cantidadVendida}</td>
            <td>Bs. ${Number(row.montoOriginal).toFixed(2)}</td>
            <td>Bs. ${Number(row.descuentoAplicado).toFixed(2)}</td>
            <td>Bs. ${Number(row.totalRecaudado).toFixed(2)}</td>
          </tr>`);

    } catch (err) {
      document.getElementById('tabla-financiero-tipoventa').innerHTML =
        `<div class="alert alert-error"><span class="alert-icon">❌</span>${err.message}</div>`;
      document.getElementById('tabla-financiero-tarifa').innerHTML = '';
    } finally {
      setLoadingBtn('btn-financiero', false, '🔄 Actualizar informe');
    }
  }

  // ── Init ──────────────────────────────────────────────
  function init() {
    initTabs();

    document.getElementById('btn-ranking').addEventListener('click', cargarRanking);
    document.getElementById('btn-acta').addEventListener('click', cargarActa);
    document.getElementById('btn-financiero').addEventListener('click', cargarFinanciero);

    // Cargar ranking automáticamente al abrir la página
    cargarRanking();
  }

  return { init };
})();

document.addEventListener('DOMContentLoaded', Reportes.init);
