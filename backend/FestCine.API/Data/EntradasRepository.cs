using Dapper;
using FestCine.API.DTOs;
using System.Data;

namespace FestCine.API.Data;

public class EntradasRepository
{
    private readonly IDbConnectionFactory _db;

    public EntradasRepository(IDbConnectionFactory db) => _db = db;

    public async Task<ComprarEntradaResponseDto> ComprarEntradaAsync(ComprarEntradaRequestDto request)
    {
        using var conn = _db.CreateConnection();
        return await conn.QuerySingleAsync<ComprarEntradaResponseDto>(
            "sp_ComprarEntrada",
            new { request.CodAsistente, request.CodProyeccion, request.CodTarifa },
            commandType: CommandType.StoredProcedure);
    }

    public async Task<ComprarMultipleResponseDto> ComprarMultipleAsync(ComprarMultipleRequestDto request)
    {
        var listaAsientos = string.Join(",", request.CodAsientos);

        using var conn  = _db.CreateConnection();
        using var multi = await conn.QueryMultipleAsync(
            "sp_ComprarEntradasMultiples",
            new
            {
                request.Nombres,
                request.Apellidos,
                request.Email,
                request.Telefono,
                request.CodProyeccion,
                request.CodTarifa,
                ListaAsientos = listaAsientos
            },
            commandType: CommandType.StoredProcedure);

        var entradas  = (await multi.ReadAsync<EntradaGeneradaDto>()).ToList();
        entradas.ForEach(e => {
            e.CodEntrada       = e.CodEntrada.Trim();
            e.CodAsiento       = e.CodAsiento.Trim();
            e.Fila             = e.Fila.Trim();
            e.CodigoValidacion = e.CodigoValidacion.Trim();
        });
        var asistente = await multi.ReadSingleAsync<AsistenteSPResultDto>();
        asistente.CodAsistente = asistente.CodAsistente.Trim();

        // Obtener info de la proyección para el comprobante
        const string sqlProy = """
            SELECT p.Titulo, pr.FechaHoraInicio, s.NombreSala, sd.NombreSede
            FROM Proyecciones pr
            JOIN Peliculas p ON p.CodPelicula = pr.CodPelicula
            JOIN Salas s     ON s.CodSala     = pr.CodSala
            JOIN Sedes sd    ON sd.CodSede    = s.CodSede
            WHERE pr.CodProyeccion = @CodProyeccion
            """;
        var proy = await conn.QuerySingleOrDefaultAsync<ProyeccionInfoDto>(
            sqlProy, new { request.CodProyeccion });

        return new ComprarMultipleResponseDto
        {
            CodAsistente    = asistente.CodAsistente,
            NombreAsistente = $"{asistente.Nombres} {asistente.Apellidos}",
            Email           = asistente.Email,
            Entradas        = entradas,
            TotalPagado     = entradas.Sum(e => e.PrecioPagado),
            TotalDescuento  = entradas.Sum(e => e.PrecioOriginal - e.PrecioPagado),
            Pelicula        = proy?.Titulo        ?? "",
            FechaHoraInicio = proy?.FechaHoraInicio ?? DateTime.MinValue,
            NombreSala      = proy?.NombreSala    ?? "",
            NombreSede      = proy?.NombreSede    ?? ""
        };
    }
}
