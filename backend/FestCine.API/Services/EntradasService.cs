using FestCine.API.Data;
using FestCine.API.DTOs;
using Microsoft.Data.SqlClient;

namespace FestCine.API.Services;

public class EntradasService
{
    private readonly EntradasRepository _repo;

    public EntradasService(EntradasRepository repo) => _repo = repo;

    public async Task<(ComprarEntradaResponseDto? Result, string? Error)> ComprarEntradaAsync(
        ComprarEntradaRequestDto request)
    {
        try
        {
            var result = await _repo.ComprarEntradaAsync(request);
            return (result, null);
        }
        catch (SqlException ex)
        {
            return (null, SqlExceptionHandler.ObtenerMensajeAmigable(ex));
        }
    }

    public async Task<(ComprarMultipleResponseDto? Result, string? Error)> ComprarMultipleAsync(
        ComprarMultipleRequestDto request)
    {
        try
        {
            var result = await _repo.ComprarMultipleAsync(request);
            return (result, null);
        }
        catch (SqlException ex)
        {
            return (null, SqlExceptionHandler.ObtenerMensajeAmigable(ex));
        }
    }
}
