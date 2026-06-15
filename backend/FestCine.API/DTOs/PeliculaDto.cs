namespace FestCine.API.DTOs;

public class PeliculaDto
{
    public string CodPelicula { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public int AnioProduccion { get; set; }
    public int Duracion { get; set; }
    public string PaisOrigen { get; set; } = string.Empty;
    public string Formato { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public string CodClasificacion { get; set; } = string.Empty;
    public int EdadMinima { get; set; }
    public string? Generos { get; set; }
}
