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
    opts = [strategy: :one_for_one, name: Pulsar.GameSupervisor]
    Supervisor.start_link(children, opts)
  end

end
