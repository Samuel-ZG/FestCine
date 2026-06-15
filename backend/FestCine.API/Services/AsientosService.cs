using FestCine.API.Data;
using FestCine.API.DTOs;

namespace FestCine.API.Services;

public class AsientosService
{
    private readonly AsientosRepository _repo;

    public AsientosService(AsientosRepository repo) => _repo = repo;

    public async Task<IEnumerable<AsientoDto>> ObtenerPorProyeccionAsync(string codProyeccion)
        => await _repo.ObtenerPorProyeccionAsync(codProyeccion);
}
