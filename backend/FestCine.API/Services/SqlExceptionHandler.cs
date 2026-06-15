using Microsoft.Data.SqlClient;

namespace FestCine.API.Services;

// Centraliza la traducción de errores de SQL Server a mensajes de usuario.
// Los RAISERROR con severity 16 del servidor llegan como SqlException con Number < 50000.
public static class SqlExceptionHandler
{
    public static string ObtenerMensajeAmigable(SqlException ex)
    {
        // El mensaje de RAISERROR viaja en ex.Message directamente
        return ex.Message;
    }
}
