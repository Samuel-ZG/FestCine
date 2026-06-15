using FestCine.API.DTOs;
using FestCine.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace FestCine.API.Controllers;

[ApiController]
[Route("api/reportes")]
public class ReportesController : ControllerBase
{
    private readonly ReportesService _service;

    public ReportesController(ReportesService service) => _service = service;

    /// <summary>GET /api/reportes/ranking?codEdicion=edi_2026</summary>
    [HttpGet("ranking")]
    public async Task<ActionResult<ApiResponse<IEnumerable<RankingPeliculaDto>>>> ObtenerRanking(
        [FromQuery] string codEdicion = "edi_2026")
    {
        var data = await _service.ObtenerRankingAsync(codEdicion);
        return Ok(ApiResponse<IEnumerable<RankingPeliculaDto>>.Ok(data));
    }

    /// <summary>GET /api/reportes/acta-premiacion?codEdicion=edi_2026</summary>
    [HttpGet("acta-premiacion")]
    public async Task<ActionResult<ApiResponse<IEnumerable<ActaPremiacionDto>>>> ObtenerActaPremiacion(
        [FromQuery] string codEdicion = "edi_2026")
    {
        var data = await _service.ObtenerActaPremiacionAsync(codEdicion);
        return Ok(ApiResponse<IEnumerable<ActaPremiacionDto>>.Ok(data));
    }

    /// <summary>GET /api/reportes/informe-financiero</summary>
    [HttpGet("informe-financiero")]
    public async Task<ActionResult<ApiResponse<InformeFinancieroDto>>> ObtenerInformeFinanciero()
    {
        var data = await _service.ObtenerInformeFinancieroAsync();
        return Ok(ApiResponse<InformeFinancieroDto>.Ok(data));
    }
}
