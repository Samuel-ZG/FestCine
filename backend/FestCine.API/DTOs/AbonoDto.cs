namespace FestCine.API.DTOs;

public class VenderAbonoRequestDto
{
    public string CodAsistente { get; set; } = string.Empty;
    public string CodAbono { get; set; } = string.Empty;
    public string MetodoPago { get; set; } = string.Empty;
}

public class VenderAbonoResponseDto
{
    public string CodCompraAbono { get; set; } = string.Empty;
    public string CodigoAcceso { get; set; } = string.Empty;
    public decimal MontoPagado { get; set; }
    public string Mensaje { get; set; } = string.Empty;
}
