using Dapper;
using FestCine.API.DTOs;

namespace FestCine.API.Data;

public class AsientosRepository
{
    private readonly IDbConnectionFactory _db;

    public AsientosRepository(IDbConnectionFactory db) => _db = db;

    public async Task<IEnumerable<AsientoDto>> ObtenerPorProyeccionAsync(string codProyeccion)
    {
        const string sql = """
            SELECT RTRIM(CodAsiento) AS CodAsiento, RTRIM(Fila) AS Fila, Numero, TipoAsiento, Estado
            FROM vw_AsientosPorProyeccion
            WHERE CodProyeccion = @CodProyeccion
            ORDER BY Fila, Numero
            """;
        using var conn = _db.CreateConnection();
        return await conn.QueryAsync<AsientoDto>(sql, new { CodProyeccion = codProyeccion });
    }
}
