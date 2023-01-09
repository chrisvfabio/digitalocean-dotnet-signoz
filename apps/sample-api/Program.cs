using OpenTelemetry.Trace;
using Microsoft.Extensions.DependencyInjection;
using OpenTelemetry.Resources;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddHealthChecks();

builder.Services.AddOpenTelemetryTracing(b => b
    .SetResourceBuilder(ResourceBuilder.CreateDefault()
        .AddService("sample-app"))
    .AddAspNetCoreInstrumentation()
    .AddConsoleExporter()
    .AddOtlpExporter(o =>
    {
        o.Endpoint = new Uri("https://signoz-otel.upwork-32321074.proj.chrisvfab.io");
    })
);

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseAuthorization();

app.MapHealthChecks("/healthz");
app.MapControllers();

app.Run();
