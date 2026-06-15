namespace FestCine.API.DTOs;

public class TarifaDto
{
    public string CodTarifa { get; set; } = string.Empty;
    public string Nombre { get; set; } = string.Empty;
    public decimal Precio { get; set; }
    public string? Descripcion { get; set; }
    public string? CategoriaAsiento { get; set; }
}
