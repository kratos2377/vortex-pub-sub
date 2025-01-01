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

  intercept ["new-user-joined" ,"start-game-for-all" ,  "remove-all-users" , "user-left-room" , "user-status-update" , "game-event" ,
  "verifying-game" , "game-over", "start-the-replay-match" , "replay-false-event" , "replay-accepted-by-user" , "start-the-match", "game-over-time"]

  def handle_out("new-user-joined" , payload , socket) do
    broadcast!(socket , Constants.kafka_user_joined_event_key() , payload)
    {:noreply,socket}
  end

  def handle_out("remove-all-users" , payload  , socket) do
    broadcast!(socket , "remove-all-users-for-spectators"  , payload )
    {:noreply,socket}
  end

  def handle_out("user-left-room" , payload  , socket) do
    broadcast!(socket , "some-user-left" , payload )
    {:noreply,socket}
  end


  def handle_out("user-status-update" ,  payload , socket) do
    broadcast!(socket , Constants.kafka_user_status_event_key() ,  payload)
    {:noreply,socket}
  end


  def handle_out("game-event" ,  payload  , socket) do
    IO.puts("New user game move event recieved")
    broadcast!(socket , Constants.kafka_user_game_move_event_key() ,  payload )
    {:noreply,socket}
  end


  def handle_out("verifying-game" , payload  , socket) do
    broadcast!(socket ,  "verifying-game-for-spectators" , payload )
    {:noreply,socket}
  end

  def handle_out("start-game-for-all" , payload , socket) do
    IO.puts("New start game for all event recieved")
    broadcast!(socket , "start-game-for-spectators" , payload )
    {:noreply,socket}
  end

  def handle_out("game-over" ,  payload , socket) do
    IO.puts("Broadcasting new game over event")
    broadcast!(socket , "game-over-for-spectators" ,  payload)
    {:noreply,socket}
  end

  def handle_out("start-the-replay-match", payload, socket) do
    broadcast!(socket, "start-the-replay-match-for-spectators", payload )
    {:noreply,socket}
  end

  def handle_out("replay-false-event", payload, socket) do
    broadcast!(socket, "replay-false-event-for-spectators", payload )
    {:noreply,socket}
  end

  def handle_out("replay-accepted-by-user", payload, socket) do
    broadcast!(socket, "replay-accepted-by-user-for-spectators", payload )
    {:noreply,socket}
  end

  def handle_out("start-the-match", payload, socket) do
    broadcast!(socket, "start-the-match-for-spectators", payload )
    {:noreply,socket}
  end

  def handle_out("game-over-time", payload, socket) do
    broadcast!(socket, "game-over-time-for-spectators", payload )
    {:noreply,socket}
  end



end
