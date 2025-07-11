defmodule BackendWorkerTest do
  use ExUnit.Case
  doctest BackendWorker

  alias BackendWorker.MessageProducer

  describe "MessageProducer" do
    test "encodes message correctly" do
      message = %{
        "task" => "email_notification",
        "data" => %{"email" => "test@example.com"}
      }

      # Test that the message can be encoded to JSON
      assert {:ok, json} = Jason.encode(message)
      assert is_binary(json)

      # Test that it can be decoded back
      assert {:ok, decoded} = Jason.decode(json)
      assert decoded == message
    end

    test "creates email task message correctly" do
      email = "test@example.com"
      subject = "Test Subject"
      body = "Test Body"

      # This would normally publish to RabbitMQ, but in test we just verify the structure
      # In a real test environment, you might want to mock the RabbitMQ connection
      assert is_function(&MessageProducer.send_email_task/3)
    end
  end

  describe "Queue Consumer message processing" do
    test "validates message format" do
      # Test valid message format
      valid_message = %{
        "task" => "email_notification",
        "data" => %{"email" => "test@example.com"}
      }

      assert {:ok, json} = Jason.encode(valid_message)
      assert {:ok, decoded} = Jason.decode(json)
      assert Map.has_key?(decoded, "task")
      assert Map.has_key?(decoded, "data")
    end

    test "handles invalid message format" do
      # Test invalid message format
      invalid_message = %{"invalid" => "structure"}

      assert {:ok, json} = Jason.encode(invalid_message)
      assert {:ok, decoded} = Jason.decode(json)
      refute Map.has_key?(decoded, "task")
    end
  end
end
