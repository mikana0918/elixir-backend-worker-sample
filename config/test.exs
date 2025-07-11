import Config

# Configure the backend worker for testing
config :backend_worker,
  rabbitmq_url: System.get_env("RABBITMQ_URL") || "amqp://guest:guest@localhost:5672"

# Configure logger for testing
config :logger,
  level: :warning,
  format: "$time $metadata[$level] $message\n"
