using FestCine.API.Data;
using FestCine.API.DTOs;
using Microsoft.Data.SqlClient;

namespace FestCine.API.Services;

public class ProyeccionesService
{
    private readonly ProyeccionesRepository _repo;
    private readonly PeliculasRepository _peliculasRepo;

    public ProyeccionesService(ProyeccionesRepository repo, PeliculasRepository peliculasRepo)
    {
        _repo = repo;
        _peliculasRepo = peliculasRepo;
    }

    public Task<IEnumerable<ProyeccionDto>> ObtenerPorPeliculaAsync(string codPelicula) =>
        _repo.ObtenerPorPeliculaAsync(codPelicula);

    public async Task<(bool Ok, string? Error)> ProgramarProyeccionAsync(ProgramarProyeccionDto dto)
    {
        try
        {
            var duracion = await _peliculasRepo.ObtenerDuracionAsync(dto.CodPelicula);
            var fechaHoraFin = dto.FechaHoraInicio.AddMinutes(duracion);

            await _repo.ProgramarProyeccionAsync(dto, fechaHoraFin);
            return (true, null);
        }
        catch (SqlException ex)
        {
            // TR1 lanza RAISERROR con el mensaje de conflicto de agenda
            return (false, SqlExceptionHandler.ObtenerMensajeAmigable(ex));
        }
    }
}
