namespace FestCine.API.DTOs;

public class ProyeccionDto
{
    public string CodProyeccion { get; set; } = string.Empty;
    public string CodPelicula { get; set; } = string.Empty;
    public string Titulo { get; set; } = string.Empty;
    public string CodSala { get; set; } = string.Empty;
    public string NombreSala { get; set; } = string.Empty;
    public string NombreSede { get; set; } = string.Empty;
    public DateTime FechaHoraInicio { get; set; }
    public DateTime FechaHoraFin { get; set; }
    public string? SesionQa { get; set; }
    public int Capacidad { get; set; }
    public int CupoDisponible { get; set; }
}

public class ProgramarProyeccionDto
{
    public string CodProyeccion { get; set; } = string.Empty;
    public string CodPelicula { get; set; } = string.Empty;
    public string CodSala { get; set; } = string.Empty;
    public DateTime FechaHoraInicio { get; set; }
    public string? SesionQa { get; set; }
    public string CodEdicion { get; set; } = string.Empty;
}
