defmodule VortexPubSub.PublishMessages do
  use VortexPubSubWeb, :channel
  alias VortexPubSub.KafkaProducer
  alias VortexPubSub.Endpoint
  alias VortexPubSub.Constants
  alias Pulsar.ChessSupervisor
  alias MaelStorm.ChessServer
  alias Holmberg.Mutation.Game, as: GameMutation
  alias Holmberg.Mutation.User, as: UserMutation
  require Logger

  def publish_the_message(key , data) do

    case key do

      "match-found" -> make_game_room_and_publish_data(key , data)

      "friend-request-event" -> send_friend_req_event(key , data)
      _ ->
        Logger.error("Invalid Key")
    end

  end


  defp send_friend_req_event(key , data) do
    IO.inspect("FRIEND REQ DATA EVENTS IS")
    IO.inspect(data)

    user_notif_channel = "user:notifications:" <> data["user_who_we_are_sending_event"]

    start_async_publishing(user_notif_channel , data , key)
  end





  defp make_game_room_and_publish_data(key , data) do
     # Create Game and publish game_details to the users
    # by default we will take user at index 0 as host just for the schema consistency

    sessions_data  = data["CreatedSessions"]
    game_type  = data["GameType"]

    decoded_session_data = Enum.at(sessions_data , 0)
    player_one_id = Enum.at(decoded_session_data["PlayerIds"] , 0 )
    player_two_id = Enum.at(decoded_session_data["PlayerIds"] , 1 )

    topic1 = "user:notifications:" <> player_one_id
    topic2 = "user:notifications:" <> player_two_id

    user_one = UserMutation.get_user_by_id(player_one_id)
    user_two = UserMutation.get_user_by_id(player_two_id)

    player1 = %{ user_id: user_one.id , username: user_one.username  }
    player2 = %{ user_id: user_two.id , username: user_two.username  }



    start_async_publishing(topic1 , %{index: 0} , "match-found")
    start_async_publishing(topic2 , %{index: 1} , "match-found")


    case GameMutation.create_new_match_with_users(game_type , player1 , player2) do
    {:ok, game_id} -> Logger.info("Game Session created for ther users")

    case ChessSupervisor.start_game_of_match_type(game_id , player1 , player2 , game_type == "staked") do
      {:ok , _ , session_id} ->  Logger.info("Spawned Chess game server process named '#{game_id} with session_id=#{session_id}'.")


      start_async_publishing(topic1 , %{index: 0 , opponent_details: player2 , game_id: game_id , game_type: game_type} , "match-found-details")
      start_async_publishing(topic2 , %{index: 1 , opponent_details: player1 , game_id: game_id , game_type: game_type} , "match-found-details")


      {:error , message} -> Logger.info("Error while spawning ChessProcess for '#{game_id}'. with some error '#{message}'")

      start_async_publishing(topic1 , %{} , "match-game-error")
      start_async_publishing(topic2 , %{} , "match-game-error")

    end

    {:error, _} -> Logger.info("Some Issue occured while creating game session for the match")

            start_async_publishing(topic1 , %{} , "match-game-error")
            start_async_publishing(topic2 , %{} , "match-game-error")
    end

  end


  def start_async_publishing(topic , data , key) do
    Endpoint.broadcast!(topic , key , data)
  end
end
