using FestCine.API.Data;
using FestCine.API.DTOs;
using FestCine.API.Services;
using Microsoft.AspNetCore.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

// ── Servicios ──────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();

// Cadena de conexión disponible vía DI
builder.Services.AddSingleton<IDbConnectionFactory>(
    new DbConnectionFactory(
        builder.Configuration.GetConnectionString("FestCineDb")!));

// Data Access
builder.Services.AddScoped<PeliculasRepository>();
builder.Services.AddScoped<ProyeccionesRepository>();
builder.Services.AddScoped<TarifasRepository>();
builder.Services.AddScoped<EntradasRepository>();
builder.Services.AddScoped<AbonosRepository>();
builder.Services.AddScoped<ReportesRepository>();
builder.Services.AddScoped<AsientosRepository>();
builder.Services.AddScoped<AsistentesRepository>();

// Services
builder.Services.AddScoped<PeliculasService>();
builder.Services.AddScoped<ProyeccionesService>();
builder.Services.AddScoped<TarifasService>();
builder.Services.AddScoped<EntradasService>();
builder.Services.AddScoped<AbonosService>();
builder.Services.AddScoped<ReportesService>();
builder.Services.AddScoped<AsientosService>();
builder.Services.AddScoped<AsistentesService>();

// CORS permisivo para el frontend local (ajustar en producción)
builder.Services.AddCors(options =>
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader()));

var app = builder.Build();

// Manejador global: cualquier excepción no capturada devuelve JSON (no HTML)
// y mantiene los headers CORS ya escritos por el middleware
app.UseExceptionHandler(errApp => errApp.Run(async ctx =>
{
    var feature = ctx.Features.Get<IExceptionHandlerFeature>();
    var msg = feature?.Error?.Message ?? "Error interno del servidor.";
    ctx.Response.StatusCode  = 500;
    ctx.Response.ContentType = "application/json";
    await ctx.Response.WriteAsJsonAsync(ApiResponse<object>.Fail(msg));
}));

app.UseCors();
app.MapControllers();
app.Run();
