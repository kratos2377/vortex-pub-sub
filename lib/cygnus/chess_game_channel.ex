defmodule VortexPubSub.Cygnus.ChessGameChannel do
  use VortexPubSubWeb, :channel
  alias MaelStorm.ChessServer
  alias VortexPubSub.Presence
  alias VortexPubSub.Endpoint
  alias VortexPubSub.KafkaProducer
  alias VortexPubSub.Constants

  def join("game:chess:" <> game_id, _params, socket) do
    case ChessServer.game_pid(game_id) do
      pid when is_pid(pid) ->
        {:ok, socket}

      nil ->
        {:error, %{reason: "Game does not exist"}}

      _ -> IO.puts("Some other error ")
        {:error, %{reason: "Game does not exist"}}
    end
  end



  def handle_in("joined-room", %{"user_id" => user_id, "username" => username , "game_id" => game_id}, socket) do
    #Add logic to prevent user from joining if the game is in progress

    broadcast!(socket, "new-user-joined", %{user_id: user_id, username: username, game_id: game_id})

    #Send Current turn mappings of game to joined user

    # KafkaProducer.send_message(Constants.kafka_user_topic(), %{user_id: user_id, username: username, game_id: game_id} ,
    #   Constants.kafka_user_joined_event_key())

    Endpoint.broadcast_from!(self() , "game:spectate:chess:"<>game_id , "new-user-joined" ,  %{user_id: user_id, username: username, game_id: game_id})

    {:noreply, socket}
  end


  def handle_in("leaved-room", %{"user_id" => user_id, "username" => username, "game_id" => game_id, "player_type" => player_type}, socket) do
    if player_type == "host" do

    broadcast!(socket, "remove-all-users", %{user_id: user_id, username: username, game_id: game_id, player_type: player_type})
    Endpoint.broadcast_from!(self() , "game:spectate:chess:"<>game_id , "remove-all-users" ,  %{user_id: user_id, username: username, game_id: game_id, player_type: player_type} )
    else
      broadcast!(socket, "user-left-room", %{user_id: user_id, username: username, game_id: game_id, player_type: player_type})
      Endpoint.broadcast_from!(self() , "game:spectate:chess:"<>game_id , "user-left-room" ,  %{user_id: user_id, username: username, game_id: game_id, player_type: player_type} )
    end

    #KafkaProducer.send_message(Constants.kafka_user_topic(),  %{user_id: user_id, username: username, game_id: game_id, player_type: player_type}, Constants.kafka_user_left_room_event_key())
    {:noreply,socket}

  end

  def handle_in("update-user-status-in-room", %{"user_id" => user_id, "username" => username, "game_id" => game_id, "status" => status} ,socket) do
    broadcast!(socket, "user-status-update", %{user_id: user_id, username: username, game_id: game_id, status: status}  )
    #KafkaProducer.send_message(Constants.kafka_user_topic(),  %{user_id: user_id, username: username, game_id: game_id, status: status}, Constants.kafka_user_status_event_key())

    Endpoint.broadcast_from!(self() , "game:spectate:chess:"<>game_id , "user-status-update" ,   %{user_id: user_id, username: username, game_id: game_id, status: status} )
    {:noreply,socket}
  end


  def handle_in("game-event", %{"user_id" => user_id, "game_id" => game_id, "game_event" => game_event, "event_type" => event_type} , socket) do
    broadcast!(socket, "send-user-game-event", %{user_id: user_id, game_id: game_id, game_event: game_event, event_type: event_type}  )
    user_game_move_event =  %{
          game_id: game_id,
          user_id: user_id,
          user_move: game_event,
         move_type: event_type,
      }


      Endpoint.broadcast_from!(self() , "game:spectate:chess:"<>game_id , "game-event" ,   %{user_id: user_id, game_id: game_id, game_event: game_event, event_type: event_type} )
      KafkaProducer.send_message(Constants.kafka_user_game_events_topic(),  user_game_move_event, Constants.kafka_user_game_move_event_key())
    {:noreply,socket}
  end

  def handle_in("verifying-game-status", %{"user_id" => user_id, "game_id" => game_id} , socket) do
    broadcast!(socket, "verifying-game", %{user_id: user_id , game_id: game_id} )
    #KafkaProducer.send_message(Constants.kafka_user_topic(),  %{user_id: user_id, game_id: game_id}, Constants.kafka_verifying_game_status_event_key())
    Endpoint.broadcast_from!(self() , "game:spectate:chess:"<>game_id , "verifying-game" ,  %{user_id: user_id , game_id: game_id} )
    {:noreply,socket}
  end

  def handle_in("start-game-event", %{"admin_id" => admin_id, "game_id" => game_id, "game_name" => game_name} , socket) do
    broadcast!(socket, "start-game-for-all", %{admin_id: admin_id , game_id: game_id, game_name: game_name} )
   # KafkaProducer.send_message(Constants.kafka_user_topic(),  %{admin_id: admin_id, game_id: game_id}, Constants.kafka_verifying_game_status_event_key())

      Endpoint.broadcast_from!(self() , "game:spectate:chess:" <> game_id, "start-game-for-all", %{admin_id: admin_id , game_id: game_id, game_name: game_name} )
    {:noreply,socket}
  end


  def handle_in("checkmate-move", %{"color_in_check_mate" => color_in_check_mate , "player_color" => player_color , "winner_username" => winner_username, "winner_user_id" => winner_user_id} , socket) do
    broadcast!(socket, "checkmate", %{color_in_check_mate: color_in_check_mate , player_color: player_color , winner_username:  winner_username, winner_user_id: winner_user_id} )
   # KafkaProducer.send_message(Constants.kafka_user_topic(),  %{admin_id: admin_id, game_id: game_id}, Constants.kafka_verifying_game_status_event_key())


   {:noreply,socket}
  end



  def handle_in("checkmate-accepted", %{"color_in_check_mate" => color_in_check_mate , "winner_username" => winner_username, "winner_user_id" => winner_user_id,
  "loser_username" => loser_username , "loser_user_id" => loser_user_id , "game_id" => game_id} , socket) do
    broadcast!(socket, "game-over", %{color_in_check_mate: color_in_check_mate  , winner_username:  winner_username, winner_user_id: winner_user_id, loser_username: loser_username, loser_user_id: loser_user_id} )


    Endpoint.broadcast_from!(self() , "game:spectate:chess:" <> game_id , "game-over",   %{color_in_check_mate: color_in_check_mate , winner_username:  winner_username, winner_user_id: winner_user_id, loser_username: loser_username, loser_user_id: loser_user_id , game_id: game_id} )

    # Reset Game Status for replay
    ChessServer.reset_game_state(game_id)

   {:noreply,socket}
  end

  def handle_in("error-event", %{"admin_id" => admin_id, "game_id" => game_id, "game_name" => game_name} , socket) do
    #broadcast!(socket, "start-game-for-all", %{admin_id: admin_id , game_id: game_id, game_name: game_name} )
   # KafkaProducer.send_message(Constants.kafka_user_topic(),  %{admin_id: admin_id, game_id: game_id}, Constants.kafka_verifying_game_status_event_key())
    {:noreply,socket}
  end


  def handle_in("replay-false", %{"game_id" => game_id}, socket) do
    broadcast!(socket, "replay-false-event", %{} )
    Endpoint.broadcast_from!(self() , "game:spectate:chess:" <> game_id , "replay-false-event",   %{} )
  end

  def handle_in("start-the-replay-match", %{}, socket) do
    broadcast!(socket, "start-the-replay-match", %{} )
  end

  def handle_in("replay-req-accepted" , %{"user_id" => user_id , "game_id" => game_id} , socket) do
    broadcast!(socket, "replay-accepted-by-user", %{user_id: user_id} )
    Endpoint.broadcast_from!(self() , "game:spectate:chess:" <> game_id , "replay-accepted-by-user",   %{user_id: user_id} )
  end


  def handle_in("start-the-match", %{}, socket) do
    broadcast!(socket, "start-the-match", %{} )
  end


  #Add stalemate events

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
