defmodule VortexPubSub.Router do
  use Plug.Router
  plug(:match)
  plug(:dispatch)
  # Import Hypernova routes under the root path
  forward "/", to: Hypernova

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
