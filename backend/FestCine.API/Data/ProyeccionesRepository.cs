using Dapper;
using FestCine.API.DTOs;
using Microsoft.Data.SqlClient;
using System.Data;

namespace FestCine.API.Data;

public class ProyeccionesRepository
{
    private readonly IDbConnectionFactory _db;

    public ProyeccionesRepository(IDbConnectionFactory db) => _db = db;

    public async Task<IEnumerable<ProyeccionDto>> ObtenerPorPeliculaAsync(string codPelicula)
    {
        const string sql = """
            SELECT * FROM vw_ProyeccionesDisponibles
            WHERE CodPelicula = @CodPelicula AND CupoDisponible >= 0
            ORDER BY FechaHoraInicio
            """;

        using var conn = _db.CreateConnection();
        return await conn.QueryAsync<ProyeccionDto>(sql, new { CodPelicula = codPelicula });
    }

    public async Task ProgramarProyeccionAsync(ProgramarProyeccionDto dto, DateTime fechaHoraFin)
    {
        // INSERT directo: el trigger TR1 actúa INSTEAD OF INSERT y valida conflictos.
        // FechaHoraFin se calcula en el servicio (Inicio + Duracion de la pelicula).
        const string sql = """
            INSERT INTO Proyecciones
                (CodProyeccion, FechaHoraInicio, FechaHoraFin, SesionQa, CodPelicula, CodSala, CodEdicion)
            VALUES
                (@CodProyeccion, @FechaHoraInicio, @FechaHoraFin, @SesionQa, @CodPelicula, @CodSala, @CodEdicion)
            """;

        using var conn = _db.CreateConnection();
        await conn.ExecuteAsync(sql, new
        {
            dto.CodProyeccion,
            dto.FechaHoraInicio,
            FechaHoraFin = fechaHoraFin,
            dto.SesionQa,
            dto.CodPelicula,
            dto.CodSala,
            dto.CodEdicion
        });
    }
}
