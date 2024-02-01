namespace MessageBus;

using System;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Azure.Messaging.ServiceBus;



public interface IMessageBus
{
    public IMessageBus SubscribeTo(string? subscription = null);

    public Task SendMessageAsync(Message message);
    public IMessageBus RegisterMessageType<T>(Func<Message, Task> handler) where T: Message;

    public Task StartProcessingAsync();
}


public sealed class MessageBus : IMessageBus
{
    private readonly ServiceBusClient _client;
    private readonly ServiceBusSender _sender;
    private readonly ILogger _logger;
    private string _queueOrTopic;
    
    private readonly List<ServiceBusProcessor> _processors = [];

    private record MessageTypeHandler(Type MessageType, Func<Message, Task> Handler);
    private readonly Dictionary<string, MessageTypeHandler> _messageTypes = new Dictionary<string, MessageTypeHandler>();

    
    public Task SendMessageAsync(Message message)
    {
        if (message is null)
        {
            throw new ArgumentNullException(nameof(message));
        }

        var messageAsString = JsonSerializer.Serialize(message, message.GetType());

        var serviceBusMessage = new ServiceBusMessage(messageAsString);
        serviceBusMessage.ApplicationProperties.Add("MessageType", message.GetType().Name);

        _logger.LogInformation("Sending message to service bus {message}", serviceBusMessage);

        return _sender.SendMessageAsync(serviceBusMessage);
    }

    public IMessageBus RegisterMessageType<T>(Func<Message, Task> handler) where T: Message
    {
        if (_messageTypes.ContainsKey(typeof(T).Name))
        {
            throw new ApplicationException("Message type already registered");
        }

        _messageTypes.Add(typeof(T).Name, new MessageTypeHandler(typeof(T), handler));

        return this;
    }

    private async Task MessageHandler(ProcessMessageEventArgs args)
    {
        if (string.IsNullOrEmpty(args.Message.ApplicationProperties["MessageType"]?.ToString()))
        {
            return;
        }

        if (!_messageTypes.ContainsKey(args.Message.ApplicationProperties["MessageType"].ToString()!))
        {
            return;
        }

        var messageTypeHandler = _messageTypes[args.Message.ApplicationProperties["MessageType"].ToString()!];
        var messageType = messageTypeHandler.MessageType;
        var handler = messageTypeHandler.Handler;

        var message = JsonSerializer.Deserialize(args.Message.Body, messageType);

        if (message is null)
        {
            return;
        }

        await handler((Message)message);

        await args.CompleteMessageAsync(args.Message);
    }

    private Task MessageErrorHandler(ProcessErrorEventArgs args)
    {
        _logger.LogWarning("Error handling message {message}", args.Exception.Message);

        return Task.CompletedTask;
    }

    public IMessageBus SubscribeTo(string? subscription = null)
    {
        ServiceBusProcessor processor;

        if (subscription is null)
            processor = _client.CreateProcessor(_queueOrTopic);
        else
            processor = _client.CreateProcessor(_queueOrTopic, subscription);

        processor.ProcessMessageAsync += MessageHandler;
        processor.ProcessErrorAsync += MessageErrorHandler;

        _processors.Add(processor);

        return this;
    }

    public async Task StartProcessingAsync()
    {
        if (_processors.Count == 0) throw new ApplicationException("No processors registered to receive messages.");

        foreach (var processor in _processors)
        {
            await processor.StartProcessingAsync();
        }
    }


    public async ValueTask DisposeAsync()
    {
        _processors.ForEach(processor => processor.CloseAsync());
        await _client.DisposeAsync();
    }



    public MessageBus(string connectionString, string queueOrTopic, ILogger logger)
    {
        _logger = logger;
        _queueOrTopic = queueOrTopic;

        var clientOptions = new ServiceBusClientOptions()
        {
            TransportType = ServiceBusTransportType.AmqpWebSockets
        };

        _client = new ServiceBusClient(connectionString, clientOptions);
        _sender = _client.CreateSender(queueOrTopic);
    }
}
