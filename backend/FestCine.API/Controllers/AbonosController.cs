using FestCine.API.DTOs;
using FestCine.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace FestCine.API.Controllers;

[ApiController]
[Route("api/abonos")]
public class AbonosController : ControllerBase
{
    private readonly AbonosService _service;

    public AbonosController(AbonosService service) => _service = service;

    /// <summary>
    /// POST /api/abonos/vender — invoca sp_VenderAbono (transacción atómica T1).
    /// Devuelve el código de acceso generado o el error de ROLLBACK.
    /// </summary>
    [HttpPost("vender")]
    public async Task<ActionResult<ApiResponse<VenderAbonoResponseDto>>> Vender(
        [FromBody] VenderAbonoRequestDto request)
    {
        var (result, error) = await _service.VenderAbonoAsync(request);

        if (error is not null)
            return Conflict(ApiResponse<VenderAbonoResponseDto>.Fail(error));

        return Ok(ApiResponse<VenderAbonoResponseDto>.Ok(result!));
    }
}
