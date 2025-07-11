defmodule BackendWorker.RabbitMQ.Connection do
  @moduledoc """
  RabbitMQ Connection GenServer that manages the connection to RabbitMQ.
  """

  use GenServer
  require Logger

  @reconnect_interval 5_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def get_connection do
    GenServer.call(__MODULE__, :get_connection)
  end

  def get_channel do
    GenServer.call(__MODULE__, :get_channel)
  end

  @impl true
  def init(_opts) do
    send(self(), :connect)
    {:ok, %{connection: nil, channel: nil}}
  end

  @impl true
  def handle_call(:get_connection, _from, %{connection: connection} = state) do
    {:reply, connection, state}
  end

  @impl true
  def handle_call(:get_channel, _from, %{channel: channel} = state) do
    {:reply, channel, state}
  end

  @impl true
  def handle_info(:connect, state) do
    case connect() do
      {:ok, connection, channel} ->
        Logger.info("Connected to RabbitMQ")
        Process.monitor(connection.pid)
        {:noreply, %{state | connection: connection, channel: channel}}

      {:error, reason} ->
        Logger.error("Failed to connect to RabbitMQ: #{inspect(reason)}")
        schedule_reconnect()
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, reason}, state) do
    Logger.error("RabbitMQ connection lost: #{inspect(reason)}")
    schedule_reconnect()
    {:noreply, %{state | connection: nil, channel: nil}}
  end

  defp connect do
    rabbitmq_url = Application.get_env(:backend_worker, :rabbitmq_url, "amqp://localhost")

    with {:ok, connection} <- AMQP.Connection.open(rabbitmq_url),
         {:ok, channel} <- AMQP.Channel.open(connection) do
      {:ok, connection, channel}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp schedule_reconnect do
    Process.send_after(self(), :connect, @reconnect_interval)
  end
end
