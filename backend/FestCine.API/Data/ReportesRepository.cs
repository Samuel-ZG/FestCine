using Dapper;
using FestCine.API.DTOs;

namespace FestCine.API.Data;

public class ReportesRepository
{
    private readonly IDbConnectionFactory _db;

    public ReportesRepository(IDbConnectionFactory db) => _db = db;

    public async Task<IEnumerable<RankingPeliculaDto>> ObtenerRankingAsync(string codEdicion)
    {
        const string sql = """
            SELECT
                RANK() OVER (ORDER BY r.TotalAsistentes DESC, r.PctOcupacion DESC) AS Posicion,
                r.Titulo,
                r.TotalProyecciones,
                r.TotalAsistentes,
                r.CapacidadTotal,
                r.PctOcupacion
            FROM vw_RankingPeliculas r
            WHERE r.CodEdicion = @CodEdicion
            ORDER BY Posicion
            """;

        using var conn = _db.CreateConnection();
        return await conn.QueryAsync<RankingPeliculaDto>(sql, new { CodEdicion = codEdicion });
    }

    public async Task<IEnumerable<ActaPremiacionDto>> ObtenerActaPremiacionAsync(string codEdicion)
    {
        const string sql = """
            SELECT * FROM vw_ActaPremiacion
            WHERE CodEdicion = @CodEdicion
            ORDER BY Categoria, Premio
            """;

        using var conn = _db.CreateConnection();
        return await conn.QueryAsync<ActaPremiacionDto>(sql, new { CodEdicion = codEdicion });
    }

    public async Task<InformeFinancieroDto> ObtenerInformeFinancieroAsync()
    {
        const string sql = """
            SELECT * FROM vw_InformeFinancieroPorTipoVenta ORDER BY TipoVenta;
            SELECT * FROM vw_InformeFinancieroPorTarifa ORDER BY TipoVenta, Concepto;
            """;

        using var conn  = _db.CreateConnection();
        using var multi = await conn.QueryMultipleAsync(sql);

        return new InformeFinancieroDto
        {
            PorTipoVenta = (await multi.ReadAsync<InformeFinancieroPorTipoVentaDto>()).ToList(),
            PorTarifa    = (await multi.ReadAsync<InformeFinancieroPorTarifaDto>()).ToList(),
        };
    }
}
