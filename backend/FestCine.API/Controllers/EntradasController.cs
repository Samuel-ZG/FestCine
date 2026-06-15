using FestCine.API.DTOs;
using FestCine.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace FestCine.API.Controllers;

[ApiController]
[Route("api/entradas")]
public class EntradasController : ControllerBase
{
    private readonly EntradasService _service;

    public EntradasController(EntradasService service) => _service = service;

    /// <summary>POST /api/entradas/comprar — entrada individual (sp_ComprarEntrada)</summary>
    [HttpPost("comprar")]
    public async Task<ActionResult<ApiResponse<ComprarEntradaResponseDto>>> Comprar(
        [FromBody] ComprarEntradaRequestDto request)
    {
        var (result, error) = await _service.ComprarEntradaAsync(request);
        if (error is not null)
            return Conflict(ApiResponse<ComprarEntradaResponseDto>.Fail(error));
        return Ok(ApiResponse<ComprarEntradaResponseDto>.Ok(result!));
    }

    /// <summary>
    /// POST /api/entradas/comprar-multiple — compra atómica de N asientos.
    /// Crea o reutiliza el Asistente por email. Invoca sp_ComprarEntradasMultiples.
    /// Devuelve 409 con mensaje amigable si hay conflicto de aforo o asiento.
    /// </summary>
    [HttpPost("comprar-multiple")]
    public async Task<ActionResult<ApiResponse<ComprarMultipleResponseDto>>> ComprarMultiple(
        [FromBody] ComprarMultipleRequestDto request)
    {
        if (request.CodAsientos is null || request.CodAsientos.Count == 0)
            return BadRequest(ApiResponse<ComprarMultipleResponseDto>.Fail(
                "Debe seleccionar al menos un asiento."));

        var (result, error) = await _service.ComprarMultipleAsync(request);
        if (error is not null)
            return Conflict(ApiResponse<ComprarMultipleResponseDto>.Fail(error));
        return Ok(ApiResponse<ComprarMultipleResponseDto>.Ok(result!));
    }
}
