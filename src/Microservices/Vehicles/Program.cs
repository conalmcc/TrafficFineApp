using System;
using Microsoft.AspNetCore.Mvc;
using Serilog;
using Serilog.Context;
using Azure.Identity;
using System.Threading.Tasks.Dataflow;
using Microsoft.ApplicationInsights.AspNetCore.Extensions;
using System.Configuration;
using Azure.Messaging.ServiceBus;
using Vehicles;
using MessageBus;
using Messages;
using Vehicles.MessageHandlers;
using Azure;
using Vehicles.Utils;


var builder = WebApplication.CreateBuilder(args);


if (builder.Environment.IsProduction())
{
    // Load secrets from Azure Key Vault
    var keyVaultName = builder.Configuration["KeyVaultName"];
    builder.Configuration.AddAzureKeyVault( 
        new Uri($"https://{keyVaultName}.vault.azure.net/"),
        new DefaultAzureCredential());
    
    string APP_INSIGHTS = builder.Configuration["ApplicationInsights:ConnectionString"] ?? "";

    // Assign App Insights connection string to environment variable which App Insights configuration will utilise
    // Ideally we wouldn't need to do this, but Key Vault doesn't allow underscores in the secret name
    Environment.SetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING", APP_INSIGHTS);

    builder.Services.AddApplicationInsightsTelemetry();
}


// Add Serilog
builder.Host.UseSerilog((hostingContext, loggerConfiguration) =>
    loggerConfiguration.ReadFrom.Configuration(hostingContext.Configuration));

var sbConnectionString = builder.Configuration.GetValue<string>("ServiceBus:ConnectionString") ?? string.Empty;

builder.Services.AddSingleton<IMessageBus>(
                x => new MessageBus.MessageBus(
                    sbConnectionString, 
                    "fines-queue", x.GetRequiredService<ILogger<MessageBus.MessageBus>>()));

builder.Services.AddSingleton<VehicleEnteredZoneHandler>();


// Add services to the container.  
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseSerilogRequestLogging();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}
else
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

await app.ConfigureMessageBus();




var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

app.MapGet("/weatherforecast", (string? city, [FromServices] ILoggerFactory loggerFactory, IConfiguration configuration) =>
{
    LogContext.PushProperty("Endpoint", "GetWeatherForecast");

    var logger = loggerFactory.CreateLogger("WeatherForecast");
    logger.LogInformation("Looking up weather for {city}", city);

    var forecast = Enumerable.Range(1, 5).Select(index =>
        new WeatherForecast
        (
            DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
            Random.Shared.Next(-20, 55),
            summaries[Random.Shared.Next(summaries.Length)]
        ))
        .ToArray();

    logger.LogInformation("Weather forecast generated");

    return forecast;
})
.WithName("GetWeatherForecast")
.WithOpenApi();


app.MapGet("/vehicles/{licensePlate}", async (string licensePlate, [FromServices] IMessageBus messageBus) =>
{
    await messageBus.SendMessageAsync(new VehicleEnteredZone() { EntryTime = DateTime.Now, LicensePlate = licensePlate, Zone = "Zone1" });

    return "Sent message to service bus";
})
.WithName("EnterVehicle")
.WithOpenApi();


app.Run();

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
