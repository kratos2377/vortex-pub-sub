defmodule VortexPubSub.Cygnus.UserSocket do
  use Phoenix.Socket
  alias Phoenix.Token
  alias VortexPubSub.KafkaProducer
  alias VortexPubSub.Constants

  channel "game:chess:*", VortexPubSub.Cygnus.ChessGameChannel
  transport :websocket, Phoenix.Transports.WebSocket
  transport :longpoll, Phoenix.Transports.LongPoll

  def connect(%{"token" => token, "user_id" => user_id, "username" => username}, socket) do
    case Token.verify(socket, "user_connection", token: 1_209_600) do
      {:ok, user_id} ->
        user_connection_event_payload = %{user_id: user_id , username: username}
       KafkaProducer.send_message(Constants.kafka_user_topic() , user_connection_event_payload, Constants.kafka_user_online_event_key())
        {:ok , assign(socket, :user_id, user_id)}

      {:error, _reason} -> :error
    end
  end

  def connect(_params, _socket), do: :error

  def id(_socket), do: nil


end
