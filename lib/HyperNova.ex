defmodule Hypernova do
  import Plug.Conn

  @type json :: String.t() | number | boolean | nil | [json] | %{String.t() => json}

  alias VortexPubSub.GameLogicController
  use Plug.Router


  plug(VortexPubSub.Hypernova.Cors)
  plug(:match)
  plug(:dispatch)

  options _ do
    send_resp(conn, 200, "")
  end


  # pipeline :protected do
  #   plug VortexPubSub.Plugs.Authenticate
  # end

  forward("/api/v1/game", to: GameLogicController)
  #might remove this middleware
#  scope "/" do
#   pipe_through [:protected]
#   forward("/api/v1/game", to: GameLogicController)
#  end

  get "/health" do
    send_resp(conn , 200 , "Health Check Pass")
  end

  get _ do
    send_resp(conn, 404, "not found")
  end



  post _ do
    send_resp(conn, 404, "not found")
  end
end
