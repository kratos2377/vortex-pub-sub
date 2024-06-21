defmodule Hypernova do
  import Plug.Conn

  @type json :: String.t() | number | boolean | nil | [json] | %{String.t() => json}

  use Plug.Router

  options _ do
    send_resp(conn, 200, "")
  end

  get _ do
    send_resp(conn, 404, "not found")
  end

  post _ do
    send_resp(conn, 404, "not found")
  end
end
