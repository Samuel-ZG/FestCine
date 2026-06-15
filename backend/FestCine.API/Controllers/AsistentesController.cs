using FestCine.API.DTOs;
using FestCine.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace FestCine.API.Controllers;

[ApiController]
[Route("api/asistente")]
public class AsistentesController : ControllerBase
{
    private readonly AsistentesService _service;

    public AsistentesController(AsistentesService service) => _service = service;

    /// <summary>GET /api/asistente/existe?email=... — solo indica si ya hay una cuenta con ese correo (sin exponer datos personales)</summary>
    [HttpGet("existe")]
    public async Task<ActionResult<ApiResponse<ExisteAsistenteDto>>> Existe([FromQuery] string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return BadRequest(ApiResponse<ExisteAsistenteDto>.Fail("El parámetro 'email' es obligatorio."));

        var existe = await _service.ExisteAsync(email.Trim());
        return Ok(ApiResponse<ExisteAsistenteDto>.Ok(new ExisteAsistenteDto { Existe = existe }));
    }

    /// <summary>GET /api/asistente/portal?email=... — dashboard del asistente</summary>
    [HttpGet("portal")]
    public async Task<ActionResult<ApiResponse<AsistentePortalDto>>> ObtenerPortal([FromQuery] string email)
    {
        if (string.IsNullOrWhiteSpace(email))
            return BadRequest(ApiResponse<AsistentePortalDto>.Fail("El parámetro 'email' es obligatorio."));

        var portal = await _service.ObtenerPortalAsync(email.Trim());

        if (portal is null)
            return NotFound(ApiResponse<AsistentePortalDto>.Fail("No se encontró ninguna cuenta con ese correo."));

        return Ok(ApiResponse<AsistentePortalDto>.Ok(portal));
    }
}
