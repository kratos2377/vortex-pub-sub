defmodule VortexPubSub.PublishMessages do
  use VortexPubSubWeb, :channel
  alias VortexPubSub.Endpoint
  alias VortexPubSub.Constants
  require Logger

  def publish_the_message(key , data) do

    case key do

      Constants.kafka_game_invite_event_key() ->
        topic = "user:notifications:" <> data.user_who_we_are_sending_event
        start_async_publishing(topic , data , key)

      Constants.kafka_friend_request_event_key() ->

        topic = "user:notifications:"<>data.user_who_we_are_sending_event
        start_async_publishing(topic , data , key)


      _ -> Logger.error("Invalid Key")
    end

  end


  def start_async_publishing(topic , data , key) do
    Endpoint.brodcast(topic , key , data)
  end
end
