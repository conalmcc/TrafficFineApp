namespace Vehicles.Services;

using MessageBus;
using Messages;


public class DetectVehicleEnteringZone
{
    private readonly IMessageBus _messageBus;
    private readonly ILogger<DetectVehicleEnteringZone> _logger;

    public DetectVehicleEnteringZone(IMessageBus messageBus, ILogger<DetectVehicleEnteringZone> logger)
    {
        _messageBus = messageBus;
        _logger = logger;
    }

    public async Task RecordEntry(string licensePlate, string zone)
    {
        _logger.LogInformation("Recording entry for {licensePlate} in {zone}", licensePlate, zone);

        await _messageBus.SendMessageAsync(new VehicleEnteredZone() { EntryTime = DateTime.Now, LicensePlate = licensePlate, Zone = zone }); 
    }
}
