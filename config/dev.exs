import Config

# Configure the backend worker for development
config :backend_worker,
  rabbitmq_url: System.get_env("RABBITMQ_URL") || "amqp://guest:guest@localhost:5672"

# Configure logger for development
config :logger,
  level: :debug,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :mfa]
