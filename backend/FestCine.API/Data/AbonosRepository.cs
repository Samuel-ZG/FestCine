using Dapper;
using FestCine.API.DTOs;
using System.Data;

namespace FestCine.API.Data;

public class AbonosRepository
{
    private readonly IDbConnectionFactory _db;

    public AbonosRepository(IDbConnectionFactory db) => _db = db;

    public async Task<VenderAbonoResponseDto> VenderAbonoAsync(VenderAbonoRequestDto request)
    {
        using var conn = _db.CreateConnection();

        var result = await conn.QuerySingleAsync<VenderAbonoResponseDto>(
            "sp_VenderAbono",
            new
            {
                request.CodAsistente,
                request.CodAbono,
                request.MetodoPago
            },
            commandType: CommandType.StoredProcedure);

        return result;
    }
}
