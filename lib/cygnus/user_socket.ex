defmodule VortexPubSub.Cygnus.UserSocket do
  use Phoenix.Socket
  require Logger
  alias VortexPubSub.KafkaProducer
  alias VortexPubSub.Constants
  alias Holmberg.Mutation.User, as: UserMutation

  channel "game:chess:*", VortexPubSub.Cygnus.ChessGameChannel
  transport :websocket, Phoenix.Transports.WebSocket
  #transport :longpoll, Phoenix.Transports.LongPoll

  @impl true
  def connect(%{"token" => token , "user_id" => user_id , "username" => username}, socket) do

        user_connection_event_payload = %{user_id: user_id , username: username}
        case UserMutation.set_user_online(user_id, true) do
          {:ok , _} ->
            #Since We are updating the user connection from here there is no need to send additional kafka event
            #KafkaProducer.send_message(Constants.kafka_user_topic() , user_connection_event_payload, Constants.kafka_user_online_event_key())
            {:ok , assign(socket, :user_id, user_id)}

          {:error, _} ->
            Logger.info("SOME ERROR WHILE CONNECTING TO WS SERVER")
            #IO.inspect(reason)
            :error
        end





  end

  def connect(_params) do
    Logger.info("THIS IS different connect fn")
    :error
  end

  @impl true
  def id(socket), do: nil

  # def init(opts , _args) do
  #   opts
  # end

  # @impl true
  # def init(request, _state) do
  #   IO.puts("INIT NEW SOCKET")
  #   IO.inspect(request)


  #   params = URI.decode_query(request[:qs])
  #   state = %{
  #     user_id: params["user_id"],
  #     username: params["username"]
  #   }

  #   {:cowboy_websocket, request, state}
  # end


end
