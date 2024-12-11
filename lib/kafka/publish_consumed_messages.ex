defmodule VortexPubSub.PublishMessages do
  use VortexPubSubWeb, :channel
  alias VortexPubSub.Endpoint
  alias VortexPubSub.Constants
  require Logger

  def publish_the_message(key , data) do

    case key do

      _ -> Logger.error("Invalid Key")
    end

  end


  def start_async_publishing(topic , data) do

  end
end
