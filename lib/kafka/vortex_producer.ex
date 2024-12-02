defmodule VortexPubSub.KafkaProducer do
  alias KafkaEx.Protocol.Produce.Message
  alias KafkaEx.Protocol.Produce.Request
  require Logger
  def send_message(topic, %{} = msg , key \\ nil) do
    payload = Jason.encode!(msg)
    case KafkaEx.produce(%Request{topic: topic, partition: 0, required_acks: 1, messages: [%Message{value: payload, key: key}]}) do
      :ok -> Logger.info("Published message on topic: '#{topic}'")
      {:ok , _} -> Logger.info("Published message on topic='#{topic}'")
      _ -> Logger.info("Error while publishing message on kafka topic='#{topic}'")
    end
  end


end
