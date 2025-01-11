defmodule VortexPubSub.Cygnus.UserSocket do
  use Phoenix.Socket
  require Logger
  alias Holmberg.Mutation.User, as: UserMutation
  alias VortexPubSub.Endpoint
  alias VortexPubSub.Constants
  alias VortexPubSub.MongoRepo
  alias Pulsar.ChessSupervisor
  use Joken.Config


  defoverridable init: 1

  channel "game:chess:*", VortexPubSub.Cygnus.ChessGameChannel
  channel "user:notifications:*", VortexPubSub.Cygnus.UserNotificationChannel
  channel "spectate:chess:*", VortexPubSub.Cygnus.ChessSpectateChannel

  @impl true
  def connect(%{"token" => token , "user_id" => user_id , "username" => username}, socket , _connect_info) do


      signer = Joken.Signer.create("HS256" ,  Application.fetch_env!(:vortex_pub_sub, :joken_signer_key))
       case Joken.verify(token ,signer , []) do
        {:ok , claims} ->
          # user_connection_event_payload = %{user_id: user_id , username: username}
          case claims["user_id"] do
            user_id ->
              case UserMutation.set_user_online(user_id, true) do
              {:ok , _} -> {:ok , assign(socket, :user_id, user_id)}

              {:error, _} ->:error

              nil ->
                Logger.info("Token userId=#{claims[:user_id]} does not match the userId=#{user_id} trying to connect to socket")
                :error
            end
          end

        _ ->
          IO.puts("Invalid Token for userId=#{user_id}")
          :error
       end
  end

  def connect(_params) do
    :error
  end

  @impl true
  def id(socket) do
     "users_socket:#{socket.assigns.user_id}"
  end



  def on_connect(pid, user_id) do
    # Log user_id connected, increase gauge, etc.
    Logger.info("Starting monitor for user_id: #{user_id}")
    monitor(pid, user_id)
  end

  @impl true
  def init(state) do
    res = {:ok, {_, socket}} = super(state)
    on_connect(self(), socket.assigns.user_id)
    res
  end

  def terminate(reason , state) do
    IO.puts("Socket disconnected. State is")
    IO.inspect(state)
  end

  def on_disconnect(user_id) do

    case Mongo.find_one(:mongo , "users" , %{user_id: user_id}) do
      user_model ->

    KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: user_id , game_id: user_model.game_id}, Constants.kafka_game_general_event_key())
        ChessSupervisor.stop_game(user_model.game_id)
          Endpoint.broadcast!( "game:chess:" <> user_model.game_id , "default-win-because-user-left" , %{user_id_who_left: user_id , user_username_who_left: user_model.username} )
          Endpoint.broadcast!( "spectate:chess:" <> user_model.game_id , "default-win-because-user-left" , %{user_id_who_left: user_id , user_username_who_left: user_model.username} )
      _ -> Logger.info("No Game found for user")
    end

    res = Task.async(fn -> case UserMutation.set_user_online(user_id, false) do
      {:ok , _} -> Logger.info("[SocketDisconnect] Changing User is_online status successful for user_id=#{user_id}")

      {:error, _} -> Logger.info("[SocketDisconnect] Changing User is_online status unsuccessful for user_id=#{user_id}")
    end
     end)
    Task.await(res)
  end

  defp monitor(pid , user_id) do
    Task.Supervisor.start_child(VortexPubSub.UserSocketSupervisor, fn ->
      Process.flag(:trap_exit, true)
      ref = Process.monitor(pid)

      receive do
        {:DOWN, ^ref, :process, _pid, _reason} ->
          on_disconnect(user_id)
      end
    end)
  end

end
