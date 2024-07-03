defmodule MaelStorm.ChessServer do
    use GenServer

    alias Quasar.ChessState


    def start_link(%ChessState{} = chess_state) do
      GenServer.start_link(__MODULE__, {chess_state}, name: via_tuple(chess_state.game_id))
    end

    def via_tuple(game_id) do
      {:via, Registry, {VortexPubSub.Pulsar.ChessRegistry, game_id}}
    end


    def game_pid(game_id) do
      game_id
      |> via_tuple()
      |> GenServer.whereis()
    end

    def init() do

    end
end
