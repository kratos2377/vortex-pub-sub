defmodule VortexPubSub.KafkaConsumer do


  require Logger


  def handle_messages(messages) do
    for %{key: key, value: value} = message <- messages do
      IO.inspect message
      IO.puts "#{key}: #{value}"
    end
    :ok # Important!
  end

end
