namespace Vehicles.Utils;

using MessageBus;
using MessageHandlers;
using Messages;

public static class MessageBusExtensions
{
    public static async Task<WebApplication> ConfigureMessageBus(this WebApplication app)
    {
        IMessageBus messageBus = app.Services.GetRequiredService<IMessageBus>().SubscribeTo();

        var handler = app.Services.GetRequiredService<VehicleEnteredZoneHandler>();
        messageBus.RegisterMessageType<VehicleEnteredZone>( m => handler.HandleEvent(m) );

        await messageBus.StartProcessingAsync();

        return app;
    }
}
