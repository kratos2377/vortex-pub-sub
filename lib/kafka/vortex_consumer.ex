defmodule VortexPubSub.KafkaConsumer do
  use KafkaEx.GenConsumer
  require Logger


  def handle_message_set(message_set, state) do
    for %Message{value: message} <- message_set do
      Logger.info(fn -> "message: " <> inspect(message) end)


    end
    {:async_commit, state}
  end
end
