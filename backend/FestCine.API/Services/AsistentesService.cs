using FestCine.API.Data;
using FestCine.API.DTOs;

namespace FestCine.API.Services;

public class AsistentesService
{
    private readonly AsistentesRepository _repo;

    public AsistentesService(AsistentesRepository repo) => _repo = repo;

    public async Task<bool> ExisteAsync(string email)
        => await _repo.ExisteAsync(email);

    public async Task<AsistentePortalDto?> ObtenerPortalAsync(string email)
        => await _repo.ObtenerPortalAsync(email);
}
