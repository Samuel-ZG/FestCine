using FestCine.API.Data;
using FestCine.API.DTOs;

namespace FestCine.API.Services;

public class ReportesService
{
    private readonly ReportesRepository _repo;

    public ReportesService(ReportesRepository repo) => _repo = repo;

    public Task<IEnumerable<RankingPeliculaDto>> ObtenerRankingAsync(string codEdicion = "edi_2026") =>
        _repo.ObtenerRankingAsync(codEdicion);

    public Task<IEnumerable<ActaPremiacionDto>> ObtenerActaPremiacionAsync(string codEdicion = "edi_2026") =>
        _repo.ObtenerActaPremiacionAsync(codEdicion);

    public Task<InformeFinancieroDto> ObtenerInformeFinancieroAsync() =>
        _repo.ObtenerInformeFinancieroAsync();
}
