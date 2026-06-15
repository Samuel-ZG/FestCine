using FestCine.API.Data;
using FestCine.API.DTOs;

namespace FestCine.API.Services;

public class TarifasService
{
    private readonly TarifasRepository _repo;

    public TarifasService(TarifasRepository repo) => _repo = repo;

    public Task<IEnumerable<TarifaDto>> ObtenerActivasAsync() =>
        _repo.ObtenerActivas();
}
