namespace FestCine.API.DTOs;

public class AsientoDto
{
    public string CodAsiento  { get; set; } = string.Empty;
    public string Fila        { get; set; } = string.Empty;
    public int    Numero      { get; set; }
    public string TipoAsiento { get; set; } = string.Empty;
    public string Estado      { get; set; } = string.Empty; // "Libre" | "Ocupado"
}
