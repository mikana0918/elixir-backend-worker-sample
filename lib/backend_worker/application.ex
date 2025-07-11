defmodule BackendWorker.Application do
  @moduledoc """
  The BackendWorker Application.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # RabbitMQ Connection
      BackendWorker.RabbitMQ.Connection,
      # Queue Consumer Worker
      BackendWorker.QueueConsumer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BackendWorker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end