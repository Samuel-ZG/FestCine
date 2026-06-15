using FestCine.API.DTOs;
using FestCine.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace FestCine.API.Controllers;

[ApiController]
[Route("api/proyecciones")]
public class ProyeccionesController : ControllerBase
{
    private readonly ProyeccionesService _service;
    private readonly AsientosService    _asientos;

    public ProyeccionesController(ProyeccionesService service, AsientosService asientos)
    {
        _service  = service;
        _asientos = asientos;
    }

    /// <summary>GET /api/proyecciones/pelicula/{cod} — funciones disponibles con cupo</summary>
    [HttpGet("pelicula/{codPelicula}")]
    public async Task<ActionResult<ApiResponse<IEnumerable<ProyeccionDto>>>> ObtenerPorPelicula(
        string codPelicula)
    {
        var data = await _service.ObtenerPorPeliculaAsync(codPelicula);
        return Ok(ApiResponse<IEnumerable<ProyeccionDto>>.Ok(data));
    }

    /// <summary>GET /api/proyecciones/{cod}/asientos — mapa de asientos con estado libre/ocupado</summary>
    [HttpGet("{codProyeccion}/asientos")]
    public async Task<ActionResult<ApiResponse<IEnumerable<AsientoDto>>>> ObtenerAsientos(
        string codProyeccion)
    {
        var data = await _asientos.ObtenerPorProyeccionAsync(codProyeccion);
        return Ok(ApiResponse<IEnumerable<AsientoDto>>.Ok(data));
    }

    /// <summary>
    /// POST /api/proyecciones/programar — agenda una nueva proyección.
    /// El trigger TR1 valida conflictos de horario en el servidor (409 Conflict si choca).
    /// </summary>
    [HttpPost("programar")]
    public async Task<ActionResult<ApiResponse<object>>> Programar(
        [FromBody] ProgramarProyeccionDto dto)
    {
        var (ok, error) = await _service.ProgramarProyeccionAsync(dto);
        if (!ok)
            return Conflict(ApiResponse<object>.Fail(error!));
        return Ok(ApiResponse<object>.Ok(new { dto.CodProyeccion },
            "Proyección programada correctamente."));
    }
}
