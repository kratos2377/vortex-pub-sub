defmodule VortexPubSub.Cygnus.UserSocket do
  use Phoenix.Socket
  alias Phoenix.Token

  def connect(%{"token" => token}, socket) do
    case Token.verify(socket, "user_connection", token: 1_209_600) do
      {:ok, user_id} -> {:ok , assign(socket, :user_id, user_id)}
      {:error, _reason} -> :error
    end
  end

  def connect(%{}, _socket), do: :error

  def id(_socket), do: nil


end
