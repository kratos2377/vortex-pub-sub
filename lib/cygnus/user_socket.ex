defmodule VortexPubSub.Cygnus.UserSocket do
  use Phoenix.Socket
  alias Phoenix.Token
  alias VortexPubSub.KafkaProducer

  channel "game:chess:*", VortexPubSub.Cygnus.ChessGameChannel
  transport :websocket, Phoenix.Transports.WebSocket
  def connect(%{"token" => token}, socket) do
    case Token.verify(socket, "user_connection", token: 1_209_600) do
      {:ok, user_id} -> {
       # KafkaProducer.send_message(),
        {:ok , assign(socket, :user_id, user_id)}
      }
      {:error, _reason} -> :error
    end
  end

  def connect(%{}, _socket), do: :error

  def id(_socket), do: nil


end
