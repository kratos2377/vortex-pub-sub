defmodule Hypernova do
  import Plug.Conn

  @type json :: String.t() | number | boolean | nil | [json] | %{String.t() => json}

  alias VortexPubSub.GameLogicController
  use Plug.Router


  plug(VortexPubSub.Hypernova.Cors)
  plug(:dispatch)

  options _ do
    send_resp(conn, 200, "")
  end


  forward("/api/v1/game", to: GameLogicController)

  get _ do
    send_resp(conn, 404, "not found")
  end

  post _ do
    send_resp(conn, 404, "not found")
  end
end
