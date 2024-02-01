namespace Vehicles.MessageHandlers;

using Messages;
using MessageBus;


public class VehicleEnteredZoneHandler
{
    private readonly ILogger<VehicleEnteredZoneHandler> _logger;

    public VehicleEnteredZoneHandler(ILogger<VehicleEnteredZoneHandler> logger)
    {
        _logger = logger;
    }
    
    public async Task HandleEvent(Message message)
    {
        var vehicleEnteredZoneMessage = message as VehicleEnteredZone;
        _logger.LogInformation("Vehicle {licensePlate} entered zone {zone} at {entryTime}", vehicleEnteredZoneMessage.LicensePlate, vehicleEnteredZoneMessage.Zone, vehicleEnteredZoneMessage.EntryTime);
    }
}
