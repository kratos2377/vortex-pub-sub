defmodule VortexPubSub.Plugs.Authenticate do
  alias MyApp.UserRepo
  import Plug.Conn
  import Phoenix.Controller
  use Joken.Config
  def init(default), do: default

  def call(conn, _opts) do
    signer = Joken.Signer.create("HS256" ,  Application.fetch_env!(:vortex_pub_sub, :joken_signer_key))
    case get_req_header(conn, "Authorization") do
      ["Bearer " <> token] ->
        case Joken.verify(token ,signer , []) do
          {:ok, claims} ->
            assign(conn, :current_user_id, claims["user_id"])

          {:error, _reason} ->
            conn |> put_status(:unauthorized) |> json(%{error: "Invalid token"}) |> halt()
        end

      _ ->
        conn |> put_status(:unauthorized) |> json(%{error: "Missing token"}) |> halt()
    end
  end
end
