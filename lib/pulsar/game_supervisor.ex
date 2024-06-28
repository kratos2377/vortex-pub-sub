defmodule Pulsar.GameSupervisor do

  use Supervisor

  def start_link(_arg) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end


  @impl true
  def init(_init_arg) do
    children = [

      {Registry, keys: :unique, name: VortexPubSub.Pulsar.ChessRegistry},
      {Registry, keys: :unique, name: VortexPubSub.Pulsar.ScribbleRegistry},
      {Registry, keys: :unique, name: VortexPubSub.Pulsar.PokerRegistry},
      Pulser.ChessSupervisor,
      Pulser.ScribbleSupervisor,
      Pulser.PokerSupervisor,
    ]

    # Cannot use ets as it does not have distributed sync mechanism
    # Will use mnesia or redis
    # :ets.new(:chess_games_table, [:public, :named_table])
    # :ets.new(:scribble_games_table, [:public, :named_table])
    # :ets.new(:poker_games_table, [:public, :named_table])

    opts = [strategy: :one_for_one, name: Pulsar.GameSupervisor]
    Supervisor.start_link(children, opts)
  end

end
