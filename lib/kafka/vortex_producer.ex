defmodule VortexPubSub.KafkaProducer do
  alias KafkaEx.Protocol.Produce.Message
  alias KafkaEx.Protocol.Produce.Request

  def send_message(topic, %{} = msg , key \\ nil) do
    payload = Jason.encode!(msg)
    KafkaEx.produce(%Request{topic: topic, partition: 0, required_acks: 1, messages: [%Message{value: payload, key: key}]})
  end


end
