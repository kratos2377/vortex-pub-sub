defmodule VortexPubSub.Cygnus.ChessGameChannel do
  alias MaelStorm.ChessServer
  alias VortexPubSub.Presence
  alias VortexPubSub.KafkaProducer
  alias VortexPubSub.Constants

  def join("game:chess:" <> game_id, _params, socket) do
    case ChessServer.game_pid(game_id) do
      pid when is_pid(pid) ->  {:ok, socket}

      nil ->
        {:error, %{reason: "Game does not exist"}}
    end
  end

  def handle_in("joined-room", %{"user_id" => user_id, "username" => username}, socket) do
    #Add logic to prevent user from joining if the game is in progress
      "game:chess:" <> game_id = socket.topic

    broadcast!(socket, "new-user-joined", %{user_id: user_id, username: username, game_id: game_id})

    #Send Current turn mappings of game to joined user

    KafkaProducer.send_message(Constants.kafka_user_topic(), %{user_id: user_id, username: username, game_id: game_id} ,
      Constants.kafka_user_joined_event_key())

    {:noreply, socket}
  end


  def handle_in("leaved-room", %{"user_id" => user_id, "username" => username, "game_id" => game_id, "player_type" => player_type}, socket) do
    if player_type == "host" do

    broadcast!(socket, "remove-all-users", %{user_id: user_id, username: username, game_id: game_id, player_type: player_type})
    KafkaProducer.send_message(Constants.kafka_game_topic(), %{message: "host-left", game_id: game_id}, Constants.kafka_game_general_event_key())

    else
      broadcast!(socket, "user-left-room", %{user_id: user_id, username: username, game_id: game_id, player_type: player_type})
    end

    KafkaProducer.send_message(Constants.kafka_user_topic(),  %{user_id: user_id, username: username, game_id: game_id, player_type: player_type}, Constants.kafka_user_left_room_event_key())
    {:noreply,socket}

  end

  defp current_player(socket) do
      socket.assigns.current_player
  end

  def terminate(reason, socket) do
    # Add Logic to rearrange the state if user disconnects in arbitary way
    # Handle cleanup or logging when a client leaves
    IO.puts "Client left channel: #{inspect(reason)}"
    :ok
  end
end
