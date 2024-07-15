defmodule Pulsar.ChessSupervisor do
  use DynamicSupervisor
  alias GameState.ChessState
  alias MaelStorm.ChessServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end



  def start_game(game_id , user_id, username) do
    chess_init_state = ChessState.new(game_id , user_id , username)
    child_spec = %{
      id: ChessServer,
      start: {ChessServer, :start_link, [chess_init_state]},
      restart: :transient
    }
    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end


  def stop_game(game_id) do
    child_gen_id = ChessServer.game_pid(game_id)
    DynamicSupervisor.terminate_child(__MODULE__, child_gen_id)
  end
end
