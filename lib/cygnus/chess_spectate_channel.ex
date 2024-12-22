defmodule VortexPubSub.Cygnus.ChessSpectateChannel do
  use VortexPubSubWeb, :channel
  require Logger
  alias MaelStorm.ChessServer
  alias VortexPubSub.Presence
  alias VortexPubSub.Constants



  def join("spectate:chess:" <> game_id, _params, socket) do
    case ChessServer.game_pid(game_id) do
      pid when is_pid(pid) ->
        IO.puts("Successfully joined spectate game socket")
        {:ok, socket}

      nil ->
        {:error, %{reason: "Game does not exist"}}

      _ -> IO.puts("Error While joining chess spectate channel")
        {:error, %{reason: "Game does not exist"}}
    end
  end


  @impl true
  def handle_in("new-user-joined" , %{user_id: user_id, username: username, game_id: game_id} , socket) do
    broadcast!(socket , Constats.kafka_user_joined_event_key() , %{user_id: user_id, username: username, game_id: game_id})
    {:noreply,socket}
  end

  def handle_in("remove-all-users" , %{user_id: user_id, username: username, game_id: game_id, player_type: player_type}  , socket) do
    broadcast!(socket , Constats.remove_all_users_key() , %{user_id: user_id, username: username, game_id: game_id, player_type: player_type} )
    {:noreply,socket}
  end

  def handle_in("user-left-room" , %{user_id: user_id, username: username, game_id: game_id, player_type: player_type}  , socket) do
    broadcast!(socket , Constats.kafka_user_left_room_event_key() , %{user_id: user_id, username: username, game_id: game_id, player_type: player_type} )
    {:noreply,socket}
  end


  def handle_in("user-status-update" ,  %{user_id: user_id, username: username, game_id: game_id, status: status}  , socket) do
    broadcast!(socket , Constats.kafka_user_status_event_key() ,  %{user_id: user_id, username: username, game_id: game_id, status: status} )
    {:noreply,socket}
  end


  def handle_in("game-event" ,  %{user_id: user_id, game_id: game_id, game_event: game_event, event_type: event_type}  , socket) do
    broadcast!(socket , Constats.kafka_user_game_move_event_key() ,  %{user_id: user_id, game_id: game_id, game_event: game_event, event_type: event_type} )
    {:noreply,socket}
  end


  def handle_in("verifying-game" , %{user_id: user_id , game_id: game_id}  , socket) do
    broadcast!(socket , Constats.kafka_user_game_move_event_key() , %{user_id: user_id , game_id: game_id} )
    {:noreply,socket}
  end

  def handle_in("start-game-for-all" , %{admin_id: admin_id , game_id: game_id, game_name: game_name} , socket) do
    broadcast!(socket , "start-game-for-all" , %{admin_id: admin_id , game_id: game_id, game_name: game_name} )
    {:noreply,socket}
  end

  def handle_in("game-over" ,  %{color_in_check_mate: color_in_check_mate , player_color: player_color , winner_username:  winner_username, winner_user_id: winner_user_id, loser_username: loser_username, loser_user_id: loser_user_id , game_id: game_id} , socket) do
    broadcast!(socket , "game-over" ,  %{color_in_check_mate: color_in_check_mate , player_color: player_color , winner_username:  winner_username, winner_user_id: winner_user_id, loser_username: loser_username, loser_user_id: loser_user_id , game_id: game_id})
    {:noreply,socket}
  end

  def handle_in("start-the-replay-match", %{}, socket) do
    broadcast!(socket, "start-the-replay-match", %{} )
    {:noreply,socket}
  end

  def handle_in("replay-false-event", %{}, socket) do
    broadcast!(socket, "replay-false-event", %{} )
    {:noreply,socket}
  end

  def handle_in("replay-accepted-by-user", %{user_id: user_id}, socket) do
    broadcast!(socket, "replay-accepted-by-user", %{user_id: user_id} )
    {:noreply,socket}
  end

  def handle_in("start-the-match", %{}, socket) do
    broadcast!(socket, "start-the-match", %{} )
    {:noreply,socket}
  end



end
