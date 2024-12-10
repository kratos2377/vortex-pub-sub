defmodule VortexPubSub.Cygnus.ScribbleGameChannel do


  def join("game:scribble:" <> game_id , _params , socket) do
    case ScribbleServer.game_pid(game_id) do
      pid when is_pid(pid) ->  {:ok, socket}

      nil ->
        {:error, %{reason: "Game does not exist"}}
    end
  end


  # def handle_in("game_event", %{"user_id" => user_id , "game_event" => game_event , "game_id" => game_id , "event_type" => event_type} , socket) do
  #   broadcast!(socket , "update-canvas-state" , %{drawOptions: game_event})
  #   {:noreply , socket}
  # end

  # def handle_in("undo" , %{"canvas_state" => canvas_state } , socket) do
  #   broadcast!(socket , "undo-canvas" , %{canvas_state: canvas_state})
  #   {:noreply , socket}
  # end


  # def handle_in("word_guess" , %{"user_id" => user_id , "username" => username , "word" => word , "game_id" => game_id}) do

  # end

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
