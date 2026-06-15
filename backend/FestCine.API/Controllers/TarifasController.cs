using FestCine.API.DTOs;
using FestCine.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace FestCine.API.Controllers;

[ApiController]
[Route("api/tarifas")]
public class TarifasController : ControllerBase
{
    private readonly TarifasService _service;

    public TarifasController(TarifasService service) => _service = service;

    /// <summary>GET /api/tarifas — catálogo de tarifas activas</summary>
    [HttpGet]
    public async Task<ActionResult<ApiResponse<IEnumerable<TarifaDto>>>> ObtenerTarifas()
    {
        var data = await _service.ObtenerActivasAsync();
        return Ok(ApiResponse<IEnumerable<TarifaDto>>.Ok(data));
    }
}
