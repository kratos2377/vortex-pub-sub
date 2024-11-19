defmodule VortexPubSub do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # supervisor children
    children = [
      {Registry, keys: :unique, name: VortexPubSub.Registry},
      {Registry, keys: :unique, name: VortexPubSub.UserRegistry},
   #   Pulsar.UserSupervisor,
      Pulsar.GameSupervisorApplication,
      {Phoenix.PubSub, name: VortexPubSub.PubSub},
      {VortexPubSub.Presence, []},
      worker(Mongo, [[name: :mongo, url: "mongodb://admin:adminpassword@localhost/user_game_events_db?authSource=admin", pool_size: 5]]),
     # {VortexPubSub.MongoRepo , []},
     VortexPubSub.PostgresRepo,
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Hypernova,
        options: [
          port: String.to_integer("4000"),
          dispatch: dispatch(),
          protocol_options: [idle_timeout: :infinity]
        ]
      )
    ]

    opts = [strategy: :one_for_one, name: VortexPubSub.Supervisor]
    case Supervisor.start_link(children, opts) do
      {:ok , pid} -> IO.puts("Application Started")
      {:ok , pid}
      error -> error


    end
  end

  defp dispatch do
    [
      {:_,
       [
         {"/socket", VortexPubSub.Cygnus.UserSocket, [
          websocket: true,
          longpoll: true
          ]},
         {:_, Plug.Cowboy.Handler, {Hypernova, []}}
       ]}
    ]
  end


end
