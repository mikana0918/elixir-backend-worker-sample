# Elixir Backend Worker with RabbitMQ

A robust Elixir application that demonstrates how to implement a queue consumer worker using RabbitMQ. This project provides a complete example of consuming messages from RabbitMQ queues with proper error handling, message acknowledgment, and supervision.

## Features

- **RabbitMQ Integration**: Uses the AMQP library for reliable message queue operations
- **Fault Tolerance**: Automatic reconnection and supervision tree for resilience
- **Message Processing**: Supports multiple task types with JSON payloads
- **Error Handling**: Proper message acknowledgment, rejection, and requeuing
- **Configurable**: Environment-specific configuration support
- **Testing Support**: Includes message producer for testing queue functionality

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Application   │───▶│   Supervisor     │───▶│  Queue Consumer │
│                 │    │                  │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌──────────────────┐
                       │ RabbitMQ         │
                       │ Connection       │
                       └──────────────────┘
```

## Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- RabbitMQ server running locally or accessible via network

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd elixir-backend-worker-sample
```

2. Install dependencies:
```bash
mix deps.get
```

3. Start RabbitMQ (if running locally):
```bash
# Using Docker
docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management

# Or using system package manager
sudo systemctl start rabbitmq-server
```

## Configuration

The application can be configured via environment variables:

- `RABBITMQ_URL`: RabbitMQ connection URL (default: `amqp://localhost`)

### Environment-specific Configuration

- **Development**: [`config/dev.exs`](config/dev.exs) - Debug logging enabled
- **Production**: [`config/prod.exs`](config/prod.exs) - Info level logging
- **Test**: [`config/test.exs`](config/test.exs) - Warning level logging

## Usage

### Starting the Application

```bash
# Development mode
mix run --no-halt

# Or using IEx for interactive development
iex -S mix
```

### Sending Messages

The application includes a message producer for testing:

```elixir
# Send an email notification task
BackendWorker.MessageProducer.send_email_task(
  "user@example.com", 
  "Welcome!", 
  "Thank you for signing up"
)

# Send a data processing task
BackendWorker.MessageProducer.send_data_processing_task("data_123", "analytics")

# Send an image resize task
BackendWorker.MessageProducer.send_image_resize_task(
  "https://example.com/image.jpg", 
  800, 
  600
)

# Send multiple test messages
BackendWorker.MessageProducer.send_test_messages()
```

### Message Format

Messages should be JSON objects with the following structure:

```json
{
  "task": "task_type",
  "data": {
    "key": "value"
  }
}
```

### Supported Task Types

1. **email_notification**
   ```json
   {
     "task": "email_notification",
     "data": {
       "email": "user@example.com",
       "subject": "Subject",
       "body": "Message body"
     }
   }
   ```

2. **data_processing**
   ```json
   {
     "task": "data_processing",
     "data": {
       "data_id": "123",
       "processing_type": "analytics"
     }
   }
   ```

3. **image_resize**
   ```json
   {
     "task": "image_resize",
     "data": {
       "image_url": "https://example.com/image.jpg",
       "width": 800,
       "height": 600
     }
   }
   ```

## Queue Configuration

- **Exchange**: `work_exchange` (direct)
- **Queue**: `work_queue` (durable)
- **Routing Key**: `work.task`
- **QoS**: Prefetch count of 1 (processes one message at a time)

## Error Handling

The consumer implements robust error handling:

- **Successful Processing**: Messages are acknowledged (`ack`)
- **Processing Errors**: Messages are rejected and requeued for retry
- **Redelivery Failures**: Messages that fail after redelivery are rejected without requeuing
- **Connection Issues**: Automatic reconnection with exponential backoff

## Monitoring

The application provides comprehensive logging:

```
2024-01-12 10:30:15.123 [info] Connected to RabbitMQ
2024-01-12 10:30:15.456 [info] Queue consumer started successfully
2024-01-12 10:30:20.789 [info] Received message: {"task":"email_notification","data":{"email":"user@example.com"}}
2024-01-12 10:30:21.012 [info] Processing email notification task with data: %{"email" => "user@example.com"}
2024-01-12 10:30:22.345 [info] Email sent to: user@example.com
2024-01-12 10:30:22.678 [info] Message processed successfully
```

## Development

### Running Tests

```bash
mix test
```

### Code Formatting

```bash
mix format
```

### Static Analysis

```bash
mix credo
```

## Production Deployment

1. Set environment variables:
```bash
export RABBITMQ_URL="amqp://user:password@rabbitmq-server:5672"
export MIX_ENV=prod
```

2. Build release:
```bash
mix deps.get --only prod
mix compile
mix release
```

3. Run the release:
```bash
_build/prod/rel/backend_worker/bin/backend_worker start
```

## Docker Support

Create a `Dockerfile`:

```dockerfile
FROM elixir:1.14-alpine

WORKDIR /app

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY . .
RUN mix compile

CMD ["mix", "run", "--no-halt"]
```

Build and run:

```bash
docker build -t backend-worker .
docker run -e RABBITMQ_URL=amqp://rabbitmq:5672 backend-worker
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

This project is licensed under the MIT License.