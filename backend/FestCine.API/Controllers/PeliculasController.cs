using FestCine.API.DTOs;
using FestCine.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace FestCine.API.Controllers;

[ApiController]
[Route("api/peliculas")]
public class PeliculasController : ControllerBase
{
    private readonly PeliculasService _service;

    public PeliculasController(PeliculasService service) => _service = service;

    /// <summary>GET /api/peliculas/cartelera — películas activas para la taquilla</summary>
    [HttpGet("cartelera")]
    public async Task<ActionResult<ApiResponse<IEnumerable<PeliculaDto>>>> ObtenerCartelera()
    {
        var data = await _service.ObtenerCarteleraAsync();
        return Ok(ApiResponse<IEnumerable<PeliculaDto>>.Ok(data));
    }
}
