defmodule VortexPubSub.PublishMessages do
  use VortexPubSubWeb, :channel
  alias VortexPubSub.Endpoint
  alias VortexPubSub.Constants
  alias Pulsar.ChessSupervisor
  alias MaelStorm.ChessServer
  alias Holmberg.Mutation.Game, as: GameMutation
  require Logger

  def publish_the_message(key , data) do

    case key do

     "game-invite-event" ->
        topic = "user:notifications:" <> data.user_who_we_are_sending_event
        start_async_publishing(topic , data , key)

      "friend-request-event" ->

        topic = "user:notifications:"<>data.user_who_we_are_sending_event
        start_async_publishing(topic , data , key)

      "match-found" -> make_game_room_and_publish_data(key , data)
      _ ->
        Logger.error("Invalid Key")
    end

  end


  def start_async_publishing(topic , data , key) do
    Endpoint.brodcast(topic , key , data)
  end


  defp make_game_room_and_publish_data(key , data) do
     # Create Game and publish game_details to the users
    # by default we will take user at index 0 as host just for the schema consistency

    IO.puts("Match data is")
    IO.inspect(data)

    player1  = Enum.payload(data , 0)
    player2  = Enum.payload(data , 1)

    IO.inspect(player1)
    IO.inspect(player2)


    topic1 = "user:notifications:" <> player1["PlayerId"]
    topic2 = "user:notifications:" <> player2["PlayerId"]

    IO.puts("User Topics is")
    IO.puts(topic1)
    IO.puts(topic2)

    start_async_publishing(topic1 , %{index: 0} , "match-found")
    start_async_publishing(topic2 , %{index: 1} , "match-found")


    case GameMutation.create_new_match_with_users(data["GameType"] , player1 , player2) do
    {:ok, game_id} -> Logger.info("Game Session created for ther users")

    start_async_publishing(topic1 , %{index: 0 , opponent_details: player2 , game_id: game_id} , "match-details")
    start_async_publishing(topic2 , %{index: 1 , opponent_details: player1 , game_id: game_id} , "match-details")


      {:error, _} -> Logger.info("Some Issue occured while creating game session for the match")
    end

  end
end
