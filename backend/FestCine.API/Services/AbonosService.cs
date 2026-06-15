using FestCine.API.Data;
using FestCine.API.DTOs;
using Microsoft.Data.SqlClient;

namespace FestCine.API.Services;

public class AbonosService
{
    private readonly AbonosRepository _repo;

    public AbonosService(AbonosRepository repo) => _repo = repo;

    public async Task<(VenderAbonoResponseDto? Result, string? Error)> VenderAbonoAsync(
        VenderAbonoRequestDto request)
    {
        try
        {
            var result = await _repo.VenderAbonoAsync(request);
            return (result, null);
        }
        catch (SqlException ex)
        {
            // sp_VenderAbono lanza RAISERROR con ROLLBACK si la transacción falla
            return (null, SqlExceptionHandler.ObtenerMensajeAmigable(ex));
        }
    }
}
