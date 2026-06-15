using FestCine.API.Data;
using FestCine.API.DTOs;

namespace FestCine.API.Services;

public class PeliculasService
{
    private readonly PeliculasRepository _repo;

    public PeliculasService(PeliculasRepository repo) => _repo = repo;

    public Task<IEnumerable<PeliculaDto>> ObtenerCarteleraAsync() =>
        _repo.ObtenerCarteleraAsync();
}
