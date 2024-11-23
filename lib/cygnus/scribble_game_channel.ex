defmodule VortexPubSub.Cygnus.ScribbleGameChannel do


  def join("game:scribble:" <> game_id , _params , socket) do
    case ScribbleServer.game_pid(game_id) do
      pid when is_pid(pid) ->  {:ok, socket}

      nil ->
        {:error, %{reason: "Game does not exist"}}
    end
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
