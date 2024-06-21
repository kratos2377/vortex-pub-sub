defmodule VortexPubSub do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # supervisor children
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Hypernova,
        options: [
          port: String.to_integer(System.get_env("PORT") || "4001"),
          dispatch: dispatch(),
          protocol_options: [idle_timeout: :infinity]
        ]
      )
    ]

    opts = [strategy: :one_for_one, name: VortexSupervison]
    Supervisor.start_link(children, opts)
  end

  defp dispatch do
    [
      {:_,
       [
         {"/socket", Hypernova.SocketHandler, []},
         {:_, Plug.Cowboy.Handler, {Hypernova, []}}
       ]}
    ]
  end
end
