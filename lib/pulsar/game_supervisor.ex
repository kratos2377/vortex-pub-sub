defmodule Pulsar.GameSupervisorApplication do

  use Supervisor
  def start_link(_arg) do
    Supervisor.start_link(__MODULE__, _arg)
  end


  @impl true
  def init(_init_arg) do
    children = [

      {Registry, keys: :unique, name: VortexPubSub.Pulsar.ChessRegistry},
      {Registry, keys: :unique, name: VortexPubSub.Pulsar.ScribbleRegistry},
      {Registry, keys: :unique, name: VortexPubSub.Pulsar.PokerRegistry},
      Pulsar.ChessSupervisor,
      Pulsar.ScribbleSupervisor,
      # Pulsar.PokerSupervisor,
    ]

    # Cannot use ets as it does not have distributed sync mechanism
    # Will use mnesia or redis or something else
    # :ets.new(:chess_games_table, [:public, :named_table])
    # :ets.new(:scribble_games_table, [:public, :named_table])
    # :ets.new(:poker_games_table, [:public, :named_table])

    Supervisor.init(children, strategy: :one_for_one)
  end

end
