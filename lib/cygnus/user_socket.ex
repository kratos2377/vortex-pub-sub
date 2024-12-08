defmodule VortexPubSub.Cygnus.UserSocket do
  use Phoenix.Socket
  require Logger
  alias VortexPubSub.KafkaProducer
  alias VortexPubSub.Constants
  alias Holmberg.Mutation.User, as: UserMutation

  channel "game:chess:*", VortexPubSub.Cygnus.ChessGameChannel
  channel "user:*", VortexPubSub.Cygnus.UserNotificationChannel
  channel "game:spectate:chess:*", VortexPubSub.Cygnus.ChessSpectateChannel
  transport :websocket, Phoenix.Transports.WebSocket
  @impl true
  def connect(%{"token" => token , "user_id" => user_id , "username" => username}, socket) do

        user_connection_event_payload = %{user_id: user_id , username: username}
        case UserMutation.set_user_online(user_id, true) do
          {:ok , _} -> {:ok , assign(socket, :user_id, user_id)}

          {:error, _} ->:error
        end





  end

  def connect(_params) do
    Logger.info("THIS IS different connect fn")
    :error
  end

  @impl true
  def id(socket), do: "users_socket:#{socket.assigns.user_id}"



end
