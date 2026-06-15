namespace FestCine.API.DTOs;

public class ComprarMultipleRequestDto
{
    public string       Nombres       { get; set; } = string.Empty;
    public string       Apellidos     { get; set; } = string.Empty;
    public string       Email         { get; set; } = string.Empty;
    public string?      Telefono      { get; set; }
    public string       CodProyeccion { get; set; } = string.Empty;
    public string       CodTarifa     { get; set; } = string.Empty;
    public List<string> CodAsientos   { get; set; } = new();
}

public class ComprarMultipleResponseDto
{
    public string                  CodAsistente    { get; set; } = string.Empty;
    public string                  NombreAsistente { get; set; } = string.Empty;
    public string                  Email           { get; set; } = string.Empty;
    public List<EntradaGeneradaDto> Entradas       { get; set; } = new();
    public decimal                 TotalPagado     { get; set; }
    public decimal                 TotalDescuento  { get; set; }
    public string                  Pelicula        { get; set; } = string.Empty;
    public DateTime                FechaHoraInicio { get; set; }
    public string                  NombreSala      { get; set; } = string.Empty;
    public string                  NombreSede      { get; set; } = string.Empty;
}

public class EntradaGeneradaDto
{
    public string  CodEntrada       { get; set; } = string.Empty;
    public string  CodAsiento       { get; set; } = string.Empty;
    public string  Fila             { get; set; } = string.Empty;
    public int     Numero           { get; set; }
    public string  CodigoValidacion { get; set; } = string.Empty;
    public decimal PrecioPagado     { get; set; }
    public decimal PrecioOriginal   { get; set; }
    public bool    EsPromoAplicada  { get; set; }
}

public class ProyeccionInfoDto
{
    public string   Titulo          { get; set; } = string.Empty;
    public DateTime FechaHoraInicio { get; set; }
    public string   NombreSala      { get; set; } = string.Empty;
    public string   NombreSede      { get; set; } = string.Empty;
}

public class AsistenteSPResultDto
{
    public string CodAsistente { get; set; } = string.Empty;
    public string Nombres      { get; set; } = string.Empty;
    public string Apellidos    { get; set; } = string.Empty;
    public string Email        { get; set; } = string.Empty;
}
