defmodule VortexPubSub.KafkaConsumer do

  @behaviour :brod_group_subscriber_v2
  require Logger

  alias VortexPubSub.PublishMessages

  def start() do
    group_config = [
      offset_commit_policy: :commit_to_kafka_v2,
      offset_commit_interval_seconds: 5,
      rejoin_delay_seconds: 2,
      reconnect_cool_down_seconds: 10
    ]

    config = %{
      client: :kafka_client,
      group_id: "vortex",
      topics: ["user" , "game" , "user-matchmaking"],
      cb_module: __MODULE__,
      group_config: group_config,
      consumer_config: [begin_offset: :earliest]
    }

    :brod.start_link_group_subscriber_v2(config)
  end


  @impl :brod_group_subscriber_v2
  def init(_arg, _arg2) do
    {:ok, []}
  end

  def handle_message(message, state) do
    case message do
      {:kafka_message_set , topic , partition , _ , payload} ->
        case Enum.at(payload , 0) do
          {:kafka_message , _ , key , data , _ , _ , _} ->
            case Jason.decode(data) do

              {:ok , json_data} ->
                res = Task.async(fn -> PublishMessages.publish_the_message(key, json_data) end)
                Task.await(res)
                _ ->
                  Logger.error("Error while parsing json data")
            end

          _ -> IO.puts("Invalid Kafka data message")
        end

      _ -> Logger.warn("Invalid Message")
    end
    {:ok, :commit, []}
  end

end
