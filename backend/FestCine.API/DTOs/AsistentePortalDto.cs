namespace FestCine.API.DTOs;

public class AsistentePortalDto
{
    public string                CodAsistente  { get; set; } = string.Empty;
    public string                Nombres       { get; set; } = string.Empty;
    public string                Apellidos     { get; set; } = string.Empty;
    public string                Email         { get; set; } = string.Empty;
    public int                   TotalEntradas { get; set; }
    public int                   TotalAbonos   { get; set; }
    public List<EntradaPortalDto> Entradas     { get; set; } = new();
    public List<AbonoPortalDto>   Abonos       { get; set; } = new();
}

public class EntradaPortalDto
{
    public string   CodEntrada       { get; set; } = string.Empty;
    public DateTime FechaCompra      { get; set; }
    public decimal  PrecioPagado     { get; set; }
    public string?  CodigoValidacion { get; set; }
    public string?  Pelicula         { get; set; }
    public DateTime? FechaHoraInicio { get; set; }
    public string?  NombreSala       { get; set; }
    public string?  NombreSede       { get; set; }
    public string?  Tarifa           { get; set; }
    public string?  Fila             { get; set; }
    public int?     Numero           { get; set; }
}

public class AbonoPortalDto
{
    public string   CodCompraAbono { get; set; } = string.Empty;
    public DateTime FechaCompra    { get; set; }
    public decimal  PrecioPagado   { get; set; }
    public string   NombreAbono    { get; set; } = string.Empty;
    public string   CodigoAcceso   { get; set; } = string.Empty;
    public string   EstadoPago     { get; set; } = string.Empty;
}

public class ExisteAsistenteDto
{
    public bool Existe { get; set; }
}
