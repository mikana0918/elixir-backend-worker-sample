defmodule BackendWorker.QueueConsumer do
  @moduledoc """
  Queue Consumer GenServer that consumes messages from RabbitMQ queues.
  """

  use GenServer
  require Logger

  alias BackendWorker.RabbitMQ.Connection

  @queue_name "work_queue"
  @exchange_name "work_exchange"
  @routing_key "work.task"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    send(self(), :setup_queue)
    {:ok, %{channel: nil, consumer_tag: nil}}
  end

  @impl true
  def handle_info(:setup_queue, state) do
    case setup_queue_and_consume() do
      {:ok, channel, consumer_tag} ->
        Logger.info("Queue consumer started successfully")
        {:noreply, %{state | channel: channel, consumer_tag: consumer_tag}}

      {:error, reason} ->
        Logger.error("Failed to setup queue: #{inspect(reason)}")
        # Retry after 5 seconds
        Process.send_after(self(), :setup_queue, 5_000)
        {:noreply, state}
    end
  end

  @impl true
  def handle_info({:basic_consume_ok, %{consumer_tag: consumer_tag}}, state) do
    Logger.info("Consumer registered with tag: #{consumer_tag}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:basic_cancel, %{consumer_tag: consumer_tag}}, state) do
    Logger.warning("Consumer cancelled with tag: #{consumer_tag}")
    {:noreply, %{state | consumer_tag: nil}}
  end

  @impl true
  def handle_info({:basic_cancel_ok, %{consumer_tag: consumer_tag}}, state) do
    Logger.info("Consumer cancellation confirmed for tag: #{consumer_tag}")
    {:noreply, state}
  end

  @impl true
  def handle_info({:basic_deliver, payload, meta}, state) do
    %{delivery_tag: tag, redelivered: redelivered} = meta

    Logger.info("Received message: #{payload}")
    Logger.debug("Message metadata: #{inspect(meta)}")

    case process_message(payload, meta) do
      :ok ->
        # Acknowledge the message
        AMQP.Basic.ack(state.channel, tag)
        Logger.info("Message processed successfully")

      {:error, reason} ->
        Logger.error("Failed to process message: #{inspect(reason)}")

        if redelivered do
          # If message was already redelivered, reject it and don't requeue
          AMQP.Basic.reject(state.channel, tag, requeue: false)
          Logger.warning("Message rejected after redelivery")
        else
          # Reject and requeue for retry
          AMQP.Basic.reject(state.channel, tag, requeue: true)
          Logger.info("Message rejected and requeued for retry")
        end
    end

    {:noreply, state}
  end

  defp setup_queue_and_consume do
    with {:ok, channel} <- get_channel(),
         :ok <- declare_exchange_and_queue(channel),
         {:ok, consumer_tag} <- start_consuming(channel) do
      {:ok, channel, consumer_tag}
    else
      error -> error
    end
  end

  defp get_channel do
    case Connection.get_channel() do
      nil -> {:error, :no_connection}
      channel -> {:ok, channel}
    end
  end

  defp declare_exchange_and_queue(channel) do
    with :ok <- AMQP.Exchange.declare(channel, @exchange_name, :direct, durable: true),
         {:ok, _queue_info} <- AMQP.Queue.declare(channel, @queue_name, durable: true),
         :ok <- AMQP.Queue.bind(channel, @queue_name, @exchange_name, routing_key: @routing_key) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp start_consuming(channel) do
    # Set QoS to process one message at a time
    :ok = AMQP.Basic.qos(channel, prefetch_count: 1)

    case AMQP.Basic.consume(channel, @queue_name, nil, no_ack: false) do
      {:ok, consumer_tag} -> {:ok, consumer_tag}
      error -> error
    end
  end

  defp process_message(payload, _meta) do
    try do
      # Parse JSON payload
      case Jason.decode(payload) do
        {:ok, %{"task" => task, "data" => data}} ->
          execute_task(task, data)

        {:ok, invalid_payload} ->
          Logger.warning("Invalid message format: #{inspect(invalid_payload)}")
          {:error, :invalid_format}

        {:error, reason} ->
          Logger.error("Failed to parse JSON: #{inspect(reason)}")
          {:error, :json_parse_error}
      end
    rescue
      exception ->
        Logger.error("Exception while processing message: #{inspect(exception)}")
        {:error, :processing_exception}
    end
  end

  defp execute_task("email_notification", data) do
    Logger.info("Processing email notification task with data: #{inspect(data)}")

    # Simulate email sending
    Process.sleep(1000)

    case Map.get(data, "email") do
      nil ->
        {:error, :missing_email}
      email ->
        Logger.info("Email sent to: #{email}")
        :ok
    end
  end

  defp execute_task("data_processing", data) do
    Logger.info("Processing data processing task with data: #{inspect(data)}")

    # Simulate data processing
    Process.sleep(2000)

    Logger.info("Data processing completed for: #{inspect(data)}")
    :ok
  end

  defp execute_task("image_resize", data) do
    Logger.info("Processing image resize task with data: #{inspect(data)}")

    # Simulate image processing
    Process.sleep(3000)

    case Map.get(data, "image_url") do
      nil ->
        {:error, :missing_image_url}
      image_url ->
        Logger.info("Image resized: #{image_url}")
        :ok
    end
  end

  defp execute_task(unknown_task, data) do
    Logger.warning("Unknown task type: #{unknown_task} with data: #{inspect(data)}")
    {:error, :unknown_task}
  end
end
