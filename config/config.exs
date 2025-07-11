import Config

# Configure the backend worker application
config :backend_worker,
  rabbitmq_url: System.get_env("RABBITMQ_URL") || "amqp://localhost"

# Configure logger
config :logger,
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
