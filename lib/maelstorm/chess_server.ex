defmodule MaelStorm.ChessServer do
    use Genserver

    def start_link(game_id) do
      GenServer.start_link(__MODULE__, {game_id}, name: via_tuple(game_id))
    end

    def via_tuple(game_id) do
      {:via, Registry, {VortexPubSub.Pulsar.ChessRegistry, game_id}}
    end


    def game_pid(game_id) do
      game_id
      |> via_tuple()
      |> GenServer.whereis()
    end

    def init({game_id, game_type}) do

    end
end
