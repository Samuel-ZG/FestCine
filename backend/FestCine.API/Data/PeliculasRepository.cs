using Dapper;
using FestCine.API.DTOs;

namespace FestCine.API.Data;

public class PeliculasRepository
{
    private readonly IDbConnectionFactory _db;

    public PeliculasRepository(IDbConnectionFactory db) => _db = db;

    public async Task<IEnumerable<PeliculaDto>> ObtenerCarteleraAsync()
    {
        const string sql = "SELECT * FROM vw_PeliculasCartelera ORDER BY Titulo";

        using var conn = _db.CreateConnection();
        return await conn.QueryAsync<PeliculaDto>(sql);
    }

    public async Task<int> ObtenerDuracionAsync(string codPelicula)
    {
        const string sql = "SELECT Duracion FROM Peliculas WHERE CodPelicula = @CodPelicula";

        using var conn = _db.CreateConnection();
        return await conn.QuerySingleAsync<int>(sql, new { CodPelicula = codPelicula });
    }
}
