defmodule VortexPubSub.Cygnus.ChessSpectateChannel do
  use VortexPubSubWeb, :channel
  alias MaelStorm.ChessServer
  alias VortexPubSub.Presence
  alias VortexPubSub.Constants



  def join("game:spectate:chess:" <> game_id, _params, socket) do
    case ChessServer.game_pid(game_id) do
      pid when is_pid(pid) ->
        {:ok, socket}

      nil ->
        {:error, %{reason: "Game does not exist"}}

      _ -> IO.puts("Error While joining chess spectate channel")
        {:error, %{reason: "Game does not exist"}}
    end
  end


  def handle_in("new-user-joined" , %{user_id: user_id, username: username, game_id: game_id} , socket) do
    broadcast!(socket , Constats.kafka_user_joined_event_key() , %{user_id: user_id, username: username, game_id: game_id})
  end

  def handle_in("remove-all-users" , %{user_id: user_id, username: username, game_id: game_id, player_type: player_type}  , socket) do
    broadcast!(socket , Constats.remove_all_users_key() , %{user_id: user_id, username: username, game_id: game_id, player_type: player_type} )
  end

  def handle_in("user-left-room" , %{user_id: user_id, username: username, game_id: game_id, player_type: player_type}  , socket) do
    broadcast!(socket , Constats.kafka_user_left_room_event_key() , %{user_id: user_id, username: username, game_id: game_id, player_type: player_type} )
  end


  def handle_in("user-status-update" ,  %{user_id: user_id, username: username, game_id: game_id, status: status}  , socket) do
    broadcast!(socket , Constats.kafka_user_status_event_key() ,  %{user_id: user_id, username: username, game_id: game_id, status: status} )
  end


  def handle_in("game-event" ,  %{user_id: user_id, game_id: game_id, game_event: game_event, event_type: event_type}  , socket) do
    broadcast!(socket , Constats.kafka_user_game_move_event_key() ,  %{user_id: user_id, game_id: game_id, game_event: game_event, event_type: event_type} )
  end


  def handle_in("verifying-game" , %{user_id: user_id , game_id: game_id}  , socket) do
    broadcast!(socket , Constats.kafka_user_game_move_event_key() , %{user_id: user_id , game_id: game_id} )
  end

  def handle_in("start-game-for-all" , %{admin_id: admin_id , game_id: game_id, game_name: game_name} , socket) do
    broadcast!(socket , "start-game-for-all" , %{admin_id: admin_id , game_id: game_id, game_name: game_name} )
  end

  def handle_in("game-over" ,  %{color_in_check_mate: color_in_check_mate , player_color: player_color , winner_username:  winner_username, winner_user_id: winner_user_id, loser_username: loser_username, loser_user_id: loser_user_id , game_id: game_id} , socket) do
    broadcast!(socket , "game-over" ,  %{color_in_check_mate: color_in_check_mate , player_color: player_color , winner_username:  winner_username, winner_user_id: winner_user_id, loser_username: loser_username, loser_user_id: loser_user_id , game_id: game_id})
  end

end
