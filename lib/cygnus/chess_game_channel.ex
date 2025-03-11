defmodule VortexPubSub.Cygnus.ChessGameChannel do
  use VortexPubSubWeb, :channel
  alias MaelStorm.ChessServer
  alias VortexPubSub.Endpoint
  alias VortexPubSub.Constants
  alias VortexPubSub.KafkaProducer
  alias Pulsar.ChessSupervisor

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

  intercept ["joined-room" , "start-the-replay-match" , "start-the-match" , "game-over-time" , "default-win-because-user-left", "user-left-event",
  "replay-false-event-user", "player-staking-available" , "player-stake-complete", "user-game-bet-event" , "player-did-not-staked-within-time"]
  def handle_out("joined-room", payload, socket) do
    #Add logic to prevent user from joining if the game is in progress
    broadcast!(socket, "new-user-joined", %{user_id: payload.user_id, username: payload.username, game_id: payload.game_id})

    Endpoint.broadcast_from!(self() , "spectate:chess:"<>payload.game_id , "new-user-joined" ,  %{user_id: payload.user_id, username: payload.username, game_id: payload.game_id})

    {:noreply, socket}
  end



  def handle_in("leaved-room", %{"user_id" => user_id, "username" => username, "game_id" => game_id, "player_type" => player_type}, socket) do
    if player_type == "host" do

    broadcast!(socket, "remove-all-users", %{user_id: user_id, username: username, game_id: game_id, player_type: player_type})
    Endpoint.broadcast_from!(self() , "spectate:chess:"<>game_id , "remove-all-users" ,  %{user_id: user_id, username: username, game_id: game_id, player_type: player_type} )
    else
      broadcast!(socket, "user-left-room", %{user_id: user_id, username: username, game_id: game_id, player_type: player_type})
      Endpoint.broadcast_from!(self() , "spectate:chess:"<>game_id , "user-left-room" ,  %{user_id: user_id, username: username, game_id: game_id, player_type: player_type} )
    end

    #KafkaProducer.send_message(Constants.kafka_user_topic(),  %{user_id: user_id, username: username, game_id: game_id, player_type: player_type}, Constants.kafka_user_left_room_event_key())
    {:noreply,socket}

  end

  def handle_in("update-user-status-in-room", %{"user_id" => user_id, "username" => username, "game_id" => game_id, "status" => status} ,socket) do
    broadcast!(socket, "user-status-update", %{user_id: user_id, username: username, game_id: game_id, status: status}  )
    #KafkaProducer.send_message(Constants.kafka_user_topic(),  %{user_id: user_id, username: username, game_id: game_id, status: status}, Constants.kafka_user_status_event_key())

    Endpoint.broadcast_from!(self() , "spectate:chess:"<>game_id , "user-status-update" ,   %{user_id: user_id, username: username, game_id: game_id, status: status} )
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


      Endpoint.broadcast_from!(self() , "spectate:chess:"<>game_id , "game-event" ,   %{user_id: user_id, game_id: game_id, game_event: game_event, event_type: event_type} )
      KafkaProducer.send_message(Constants.kafka_user_game_events_topic(),  user_game_move_event, Constants.kafka_user_game_move_event_key())
      ChessServer.change_player_turn(game_id)

      {:noreply,socket}
  end

  def handle_in("verifying-game-status", %{"user_id" => user_id, "game_id" => game_id} , socket) do
    broadcast!(socket, "verifying-game", %{user_id: user_id , game_id: game_id} )
    #KafkaProducer.send_message(Constants.kafka_user_topic(),  %{user_id: user_id, game_id: game_id}, Constants.kafka_verifying_game_status_event_key())
    Endpoint.broadcast_from!(self() , "spectate:chess:"<>game_id , "verifying-game" ,  %{user_id: user_id , game_id: game_id} )
    {:noreply,socket}
  end

  def handle_in("start-game-event", %{"admin_id" => admin_id, "game_id" => game_id, "game_name" => game_name} , socket) do
    broadcast!(socket, "start-game-for-all", %{admin_id: admin_id , game_id: game_id, game_name: game_name} )
   # KafkaProducer.send_message(Constants.kafka_user_topic(),  %{admin_id: admin_id, game_id: game_id}, Constants.kafka_verifying_game_status_event_key())

      Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id, "start-game-for-all", %{admin_id: admin_id , game_id: game_id, game_name: game_name} )
    {:noreply,socket}
  end


  def handle_in("checkmate-move", %{"color_in_check_mate" => color_in_check_mate , "player_color" => player_color , "winner_username" => winner_username, "winner_user_id" => winner_user_id} , socket) do
    broadcast!(socket, "checkmate", %{color_in_check_mate: color_in_check_mate , player_color: player_color , winner_username:  winner_username, winner_user_id: winner_user_id} )
   # KafkaProducer.send_message(Constants.kafka_user_topic(),  %{admin_id: admin_id, game_id: game_id}, Constants.kafka_verifying_game_status_event_key())


   {:noreply,socket}
  end

  def handle_in("stalemate-move", %{"color_in_stalemate" => color_in_stalemate , "player_one_username" => player_one_username , "player_one_user_id" => player_one_user_id} , socket) do
    broadcast!(socket, "stalemate", %{color_in_stalemate: color_in_stalemate, player_one_username: player_one_username, player_one_user_id: player_one_user_id } )
   # KafkaProducer.send_message(Constants.kafka_user_topic(),  %{admin_id: admin_id, game_id: game_id}, Constants.kafka_verifying_game_status_event_key())

   {:noreply,socket}
  end

  def handle_in("checkmate-accepted", %{"color_in_check_mate" => color_in_check_mate , "winner_username" => winner_username, "winner_user_id" => winner_user_id,
  "loser_username" => loser_username , "loser_user_id" => loser_user_id , "game_id" => game_id} , socket) do
    broadcast!(socket, "game-over", %{color_in_check_mate: color_in_check_mate  , winner_username:  winner_username, winner_user_id: winner_user_id, loser_username: loser_username, loser_user_id: loser_user_id} )

    ChessServer.set_state_to_game_over(game_id , true , winner_user_id)
    Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id , "game-over",   %{color_in_check_mate: color_in_check_mate , winner_username:  winner_username, winner_user_id: winner_user_id, loser_username: loser_username, loser_user_id: loser_user_id , game_id: game_id} )

    # Reset Game Status for replay
    ChessServer.reset_game_state(game_id)

    KafkaProducer.send_message(Constants.kafka_user_score_update_topic() , %{user_id: winner_user_id , game_id: game_id , score: 20})
    KafkaProducer.send_message(Constants.kafka_user_score_update_topic() , %{user_id: loser_user_id , game_id: game_id , score: -10})

   {:noreply,socket}
  end


  def handle_in("stalemate-accepted", %{"color_in_stalemate" => color_in_stalemate , "player_one_username" => player_one_username, "player_one_user_id" => player_one_user_id,
  "player_two_username" => player_two_username , "player_two_user_id" => player_two_user_id , "game_id" => game_id} , socket) do
    broadcast!(socket, "game-over-stalemate", %{color_in_stalemate: color_in_stalemate  , player_one_username:  player_one_username, player_one_user_id: player_one_user_id, player_two_username: player_two_username, player_two_user_id: player_two_user_id} )

    ChessServer.set_state_to_game_over_stalemate(game_id , true)
    Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id , "game-over-stalemate",   %{color_in_stalemate: color_in_stalemate , player_one_username:  player_one_username, player_one_user_id: player_one_user_id, player_two_username: player_two_username, player_two_user_id: player_two_user_id , game_id: game_id} )

    # Reset Game Status for replay
    ChessServer.reset_game_state(game_id)

    KafkaProducer.send_message(Constants.kafka_user_score_update_topic() , %{user_id: player_one_user_id , game_id: game_id , score: 5})
    KafkaProducer.send_message(Constants.kafka_user_score_update_topic() , %{user_id: player_two_user_id , game_id: game_id , score: 5})

   {:noreply,socket}
  end

  def handle_in("error-event", %{"admin_id" => admin_id, "game_id" => game_id, "game_name" => game_name} , socket) do
    #broadcast!(socket, "start-game-for-all", %{admin_id: admin_id , game_id: game_id, game_name: game_name} )
   # KafkaProducer.send_message(Constants.kafka_user_topic(),  %{admin_id: admin_id, game_id: game_id}, Constants.kafka_verifying_game_status_event_key())
    {:noreply,socket}
  end


  def handle_in("replay-false", %{"game_id" => game_id , "user_id" => user_id}, socket) do
    broadcast!(socket, "replay-false-event", %{} )
    Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id , "replay-false-event",   %{} )

    KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: user_id , game_id: game_id}, Constants.kafka_game_general_event_key())
    ChessSupervisor.stop_game(game_id)

    {:noreply,socket}
  end

  def handle_out("start-the-replay-match", payload, socket) do
    broadcast!(socket, "start-the-replay-match-for-users", payload )
    {:noreply,socket}
  end

  def handle_in("replay-req-accepted" , %{"user_id" => user_id , "game_id" => game_id} , socket) do
    broadcast!(socket, "replay-accepted-by-user", %{user_id: user_id} )
    Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id , "replay-accepted-by-user",   %{user_id: user_id} )
    {:noreply,socket}
  end



  def handle_out("start-the-match", payload, socket) do
    broadcast!(socket, "start-the-match-for-users", payload )
    ChessServer.start_game(payload["game_id"])
    _ =   ChessServer.start_interval_update(payload["game_id"])
    {:noreply,socket}
  end

  def handle_out("game-over-time" , payload , socket) do
    broadcast!(socket , "game-over-time-for-users" , payload)
    {:noreply , socket}
  end

  def handle_out("default-win-because-user-left" , payload , socket) do
    broadcast!(socket , "send-user-default-win-because-user-left" , payload)
    {:noreply , socket}
  end

  def handle_out("user-left-event" , payload , socket) do
    broadcast!(socket , "send-user-left-event" , payload)
    {:noreply , socket}
  end

  def handle_out("replay-false-event-user", payload, socket) do
    broadcast!(socket, "replay-false-event", payload )

    ChessSupervisor.stop_game(payload.game_id)

    {:noreply,socket}
  end

  def handle_out("player-staking-available" , payload , socket) do
    broadcast!(socket, "player-staking-available-user", payload )
    {:noreply,socket}
  end



  def handle_out("player-stake-complete" , payload , socket) do
    broadcast!(socket, "player-stake-complete-user", payload )
    {:noreply,socket}
  end

  def handle_out("user-game-bet-event" , payload , socket) do
    broadcast!(socket, "user-game-bet-event-user", payload )
    {:noreply,socket}
  end

  def handle_out("player-did-not-staked-within-time" , payload , socket) do
    broadcast!(socket, "player-did-not-staked-within-time-user", payload )
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
