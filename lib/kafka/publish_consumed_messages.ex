defmodule VortexPubSub.PublishMessages do
  use VortexPubSubWeb, :channel
  alias VortexPubSub.Endpoint
  alias VortexPubSub.Constants
  require Logger

  def publish_the_message(key , data) do

    case key do

     "game-invite-event" ->
        topic = "user:notifications:" <> data.user_who_we_are_sending_event
        start_async_publishing(topic , data , key)

      "friend-request-event" ->

        topic = "user:notifications:"<>data.user_who_we_are_sending_event
        start_async_publishing(topic , data , key)


      _ ->
        IO.inspect("Invalid Key data recieved")
        IO.inspect(data)
        Logger.error("Invalid Key")
    end

  end


  def start_async_publishing(topic , data , key) do
    Endpoint.brodcast(topic , key , data)
  end
end
