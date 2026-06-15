using Dapper;
using FestCine.API.DTOs;

namespace FestCine.API.Data;

public class TarifasRepository
{
    private readonly IDbConnectionFactory _db;

    public TarifasRepository(IDbConnectionFactory db) => _db = db;

    public async Task<IEnumerable<TarifaDto>> ObtenerActivas()
    {
        const string sql = "SELECT * FROM vw_TarifasActivas ORDER BY Precio";

        using var conn = _db.CreateConnection();
        return await conn.QueryAsync<TarifaDto>(sql);
    }
}
