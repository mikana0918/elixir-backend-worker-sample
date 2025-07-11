import Config

# Configure the backend worker for production
config :backend_worker,
  rabbitmq_url: System.get_env("RABBITMQ_URL") || "amqp://localhost"

# Configure logger for production
config :logger,
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
