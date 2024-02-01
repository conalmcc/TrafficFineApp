namespace Messages;

using MessageBus;

public class VehicleEnteredZone: Message
{
    public string LicensePlate { get; set; } = string.Empty;
    public string Zone { get; set; } = string.Empty;
    public DateTime EntryTime { get; set; } = DateTime.Now;
}
