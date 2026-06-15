using Dapper;
using FestCine.API.DTOs;

namespace FestCine.API.Data;

public class AsistentesRepository
{
    private readonly IDbConnectionFactory _db;

    public AsistentesRepository(IDbConnectionFactory db) => _db = db;

    public async Task<bool> ExisteAsync(string email)
    {
        using var conn = _db.CreateConnection();

        const string sql = "SELECT COUNT(1) FROM Asistentes WHERE Email = @Email";

        var count = await conn.ExecuteScalarAsync<int>(sql, new { Email = email });
        return count > 0;
    }

    public async Task<AsistentePortalDto?> ObtenerPortalAsync(string email)
    {
        using var conn = _db.CreateConnection();

        const string sqlAsistente = """
            SELECT RTRIM(CodAsistente) AS CodAsistente, Nombres, Apellidos, Email
            FROM Asistentes WHERE Email = @Email
            """;

        var row = await conn.QuerySingleOrDefaultAsync(sqlAsistente, new { Email = email });
        if (row is null) return null;

        string codAsistente = row.CodAsistente;

        const string sqlEntradas = """
            SELECT
                RTRIM(e.CodEntrada) AS CodEntrada, e.FechaCompra, e.PrecioPagado, RTRIM(e.CodigoValidacion) AS CodigoValidacion,
                p.Titulo      AS Pelicula,
                pr.FechaHoraInicio,
                s.NombreSala,
                sd.NombreSede,
                t.Nombre      AS Tarifa,
                RTRIM(a.Fila) AS Fila,
                a.Numero
            FROM Entradas e
            JOIN Tarifas t          ON t.CodTarifa      = e.CodTarifa
            LEFT JOIN Proyecciones pr ON pr.CodProyeccion = e.CodProyeccion
            LEFT JOIN Peliculas p     ON p.CodPelicula    = pr.CodPelicula
            LEFT JOIN Salas s         ON s.CodSala        = pr.CodSala
            LEFT JOIN Sedes sd        ON sd.CodSede       = s.CodSede
            LEFT JOIN Asientos a      ON a.CodAsiento     = e.CodAsiento
            WHERE e.CodAsistente = @CodAsistente
            ORDER BY e.FechaCompra DESC
            """;

        const string sqlAbonos = """
            SELECT
                RTRIM(ca.CodCompraAbono) AS CodCompraAbono, ca.FechaCompra, ca.PrecioPagado, ca.EstadoPago,
                ab.Nombre        AS NombreAbono,
                co.CodigoGenerado AS CodigoAcceso
            FROM ComprasAbonos ca
            JOIN Abonos ab        ON ab.CodAbono        = ca.CodAbono
            JOIN CodigosAcceso co ON co.CodCompraAbono  = ca.CodCompraAbono
            WHERE ca.CodAsistente = @CodAsistente
            ORDER BY ca.FechaCompra DESC
            """;

        var param     = new { CodAsistente = codAsistente };
        var entradas  = (await conn.QueryAsync<EntradaPortalDto>(sqlEntradas, param)).ToList();
        var abonos    = (await conn.QueryAsync<AbonoPortalDto>(sqlAbonos, param)).ToList();

        return new AsistentePortalDto
        {
            CodAsistente  = codAsistente,
            Nombres       = row.Nombres,
            Apellidos     = row.Apellidos,
            Email         = row.Email,
            TotalEntradas = entradas.Count,
            TotalAbonos   = abonos.Count,
            Entradas      = entradas,
            Abonos        = abonos
        };
    }
}
