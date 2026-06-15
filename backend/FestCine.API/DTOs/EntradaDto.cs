namespace FestCine.API.DTOs;

public class ComprarEntradaRequestDto
{
    public string CodAsistente { get; set; } = string.Empty;
    public string CodProyeccion { get; set; } = string.Empty;
    public string CodTarifa { get; set; } = string.Empty;
}

public class ComprarEntradaResponseDto
{
    public string  CodEntrada       { get; set; } = string.Empty;
    public decimal PrecioPagado     { get; set; }
    public decimal PrecioOriginal   { get; set; }
    public bool    EsPromoAplicada  { get; set; }
    public string  CodigoValidacion { get; set; } = string.Empty;
    public string  Mensaje          { get; set; } = string.Empty;
}
