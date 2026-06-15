namespace FestCine.API.DTOs;

public class RankingPeliculaDto
{
    public int Posicion { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public int TotalProyecciones { get; set; }
    public int TotalAsistentes { get; set; }
    public int CapacidadTotal { get; set; }
    public decimal PctOcupacion { get; set; }
}

public class ActaPremiacionDto
{
    public string Categoria { get; set; } = string.Empty;
    public string Premio { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public decimal? PromedioVotacion { get; set; }
    public int? TotalVotos { get; set; }
    public int EdicionAnio { get; set; }
}

public class InformeFinancieroPorTipoVentaDto
{
    public string  TipoVenta      { get; set; } = string.Empty;
    public int     CantidadVendida { get; set; }
    public decimal MontoBruto      { get; set; }
    public decimal DescuentoTotal  { get; set; }
    public decimal TotalRecaudado  { get; set; }
}

public class InformeFinancieroPorTarifaDto
{
    public string  Concepto         { get; set; } = string.Empty;
    public string  TipoVenta        { get; set; } = string.Empty;
    public bool    EsPromoAplicada  { get; set; }
    public int     CantidadVendida  { get; set; }
    public decimal MontoOriginal    { get; set; }
    public decimal DescuentoAplicado { get; set; }
    public decimal TotalRecaudado   { get; set; }
}

public class InformeFinancieroDto
{
    public List<InformeFinancieroPorTipoVentaDto> PorTipoVenta { get; set; } = new();
    public List<InformeFinancieroPorTarifaDto>     PorTarifa    { get; set; } = new();
}
