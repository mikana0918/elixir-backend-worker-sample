defmodule BackendWorker.MessageProducer do
  @moduledoc """
  Message Producer module for sending test messages to RabbitMQ queues.
  This module is useful for testing the queue consumer functionality.
  """

  require Logger
  alias BackendWorker.RabbitMQ.Connection

  @exchange_name "work_exchange"
  @routing_key "work.task"

  @doc """
  Publishes a message to the work queue.

  ## Examples

      iex> BackendWorker.MessageProducer.publish_message(%{
      ...>   "task" => "email_notification",
      ...>   "data" => %{"email" => "user@example.com", "subject" => "Welcome!"}
      ...> })
      :ok
  """
  def publish_message(message) when is_map(message) do
    case Jason.encode(message) do
      {:ok, json_payload} ->
        publish_json(json_payload)

      {:error, reason} ->
        Logger.error("Failed to encode message: #{inspect(reason)}")
        {:error, :encoding_failed}
    end
  end

  @doc """
  Publishes a JSON string message to the work queue.
  """
  def publish_json(json_payload) when is_binary(json_payload) do
    case Connection.get_channel() do
      nil ->
        Logger.error("No RabbitMQ connection available")
        {:error, :no_connection}

      channel ->
        case AMQP.Basic.publish(
          channel,
          @exchange_name,
          @routing_key,
          json_payload,
          persistent: true
        ) do
          :ok ->
            Logger.info("Message published successfully")
            :ok

          error ->
            Logger.error("Failed to publish message: #{inspect(error)}")
            error
        end
    end
  end

  @doc """
  Convenience function to send an email notification task.
  """
  def send_email_task(email, subject, body \\ "Default message body") do
    message = %{
      "task" => "email_notification",
      "data" => %{
        "email" => email,
        "subject" => subject,
        "body" => body
      }
    }

    publish_message(message)
  end

  @doc """
  Convenience function to send a data processing task.
  """
  def send_data_processing_task(data_id, processing_type \\ "default") do
    message = %{
      "task" => "data_processing",
      "data" => %{
        "data_id" => data_id,
        "processing_type" => processing_type,
        "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
      }
    }

    publish_message(message)
  end

  @doc """
  Convenience function to send an image resize task.
  """
  def send_image_resize_task(image_url, width, height) do
    message = %{
      "task" => "image_resize",
      "data" => %{
        "image_url" => image_url,
        "width" => width,
        "height" => height
      }
    }

    publish_message(message)
  end

  @doc """
  Sends multiple test messages for demonstration purposes.
  """
  def send_test_messages do
    Logger.info("Sending test messages...")

    # Send email notification
    send_email_task("test@example.com", "Test Email", "This is a test email")

    # Send data processing task
    send_data_processing_task("data_123", "analytics")

    # Send image resize task
    send_image_resize_task("https://example.com/image.jpg", 800, 600)

    # Send a custom message
    publish_message(%{
      "task" => "custom_task",
      "data" => %{
        "custom_field" => "custom_value",
        "priority" => "high"
      }
    })

    Logger.info("Test messages sent successfully")
  end
end
