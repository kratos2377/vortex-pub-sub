defmodule VortexPubSub do
  use Application
  import Supervisor.Spec
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # supervisor children
    children = [
      #{Registry, keys: :unique, name: VortexPubSub.Pulsar.ChessRegistry},
      #   Pulsar.UserSupervisor,
      {Phoenix.PubSub, name: VortexPubSub.PubSub},
      {Task.Supervisor, name: VortexPubSub.UserSocketSupervisor},
      Pulsar.GameSupervisorApplication,
      {VortexPubSub.Presence, []},
      worker(Mongo, [[name: :mongo, url: "mongodb://admin:adminpassword@localhost/user_game_events_db?authSource=admin", pool_size: 5]]),
     # {VortexPubSub.MongoRepo , []},
     VortexPubSub.PostgresRepo,
     VortexPubSub.Redix,
      VortexPubSub.Endpoint,

      %{
        id: VortexPubSub.KafkaConsumer,
        start: {VortexPubSub.KafkaConsumer, :start, []}
      },

      {Registry, keys: :unique, name: VortexPubSub.Registry},
      {Registry, keys: :unique, name: VortexPubSub.UserRegistry}

    ]

    #:ets.new(:games_table, [:public, :named_table])
    opts = [strategy: :one_for_one, name: VortexPubSub.Supervisor]
    case Supervisor.start_link(children, opts) do
      {:ok , pid} -> IO.puts("Application Started")
      {:ok , pid}
      error -> error


    end
  end

  # defp dispatch do
  #   [
  #     {:_,
  #      [
  #        {"/socket/websocket", VortexPubSub.Cygnus.UserSocket, [
  #         websocket: true,
  #         longpoll: false
  #         ]},
  #        {:_, Plug.Cowboy.Handler, {Hypernova, []}}
  #      ]}
  #   ]
  # end


end
