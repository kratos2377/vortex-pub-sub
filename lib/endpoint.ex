defmodule VortexPubSub.Endpoint do
  use Phoenix.Endpoint, otp_app: :vortex_pub_sub

  @session_options [
    store: :cookie,
    key: "_vortex_key_v1",
    signing_salt: "1a9OALgV62"
  ]

  socket "/socket", VortexPubSub.Cygnus.UserSocket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]



  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug VortexPubSub.Router
end
