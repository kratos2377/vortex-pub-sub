defmodule VortexPubSub.Cygnus.UserSocket do
  use Phoenix.Socket
  require Logger
  alias VortexPubSub.KafkaProducer
  alias Holmberg.Mutation.User, as: UserMutation
  use Joken.Config

  defoverridable init: 1

  channel "game:chess:*", VortexPubSub.Cygnus.ChessGameChannel
  channel "user:notifications:*", VortexPubSub.Cygnus.UserNotificationChannel
  channel "game:spectate:chess:*", VortexPubSub.Cygnus.ChessSpectateChannel

  @impl true
  def connect(%{"token" => token , "user_id" => user_id , "username" => _username}, socket) do


      signer = Joken.Signer.create("HS256" ,  Application.fetch_env!(:vortex_pub_sub, :joken_signer_key))
       case Joken.verify(token ,signer , []) do
        {:ok , claims} ->
          # user_connection_event_payload = %{user_id: user_id , username: username}
        case UserMutation.set_user_online(user_id, true) do
          {:ok , _} -> {:ok , assign(socket, :user_id, user_id)}

          {:error, _} ->:error
        end

        _ ->
          IO.puts("Invalid Token")
          :error
       end
  end

  def connect(_params) do
    Logger.info("THIS IS different connect fn")
    :error
  end

  @impl true
  def id(socket) do
     "users_socket:#{socket.assigns.user_id}"
  end



  def on_connect(pid, user_id) do
    # Log user_id connected, increase gauge, etc.
    IO.puts("Starting monitor for user_id: #{user_id}")
    monitor(pid, user_id)
  end

  @impl true
  def init(state) do
    IO.puts("Init state is")
    IO.inspect(state)
    res = {:ok, {_, socket}} = super(state)
    on_connect(self(), socket.assigns.user_id)
    res
  end

  def terminate(reason , state) do
    IO.puts("Socket disconnected. State is")
    IO.inspect(state)
  end

  def on_disconnect(user_id) do
    IO.puts("SOCKET DISCONNECT EVENT FOR USER_ID: #{user_id}")
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
