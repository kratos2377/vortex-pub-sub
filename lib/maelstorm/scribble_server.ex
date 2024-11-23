defmodule MaelStorm.ScribbleServer do
  use GenServer
  require Logger
  alias Quasar.ScribbleStateManager
  alias GameState.ScribbleState

  def start_link(%ScribbleState{} = scribble_state) do
    GenServer.start_link(__MODULE__, {scribble_state}, name: via_tuple(scribble_state.game_id))
  end

  def via_tuple(game_id) do
    {:via, Registry, {VortexPubSub.Pulsar.ScribbleRegistry, game_id}}
  end


  def game_pid(game_id) do
    game_id
    |> via_tuple()
    |> GenServer.whereis()
  end




  def join_lobby(game_id , user_id , username) do
      GenServer.call(via_tuple(game_id), {:join_lobby, user_id , username})
  end

  def leave_lobby(game_id, user_id) do
    GenServer.call(via_tuple(game_id), {:leave_lobby, user_id})
  end

  def update_player_status(game_id, user_id , status) do
    GenServer.call(via_tuple(game_id), {:update_player_status, user_id , status} )
  end

  def start_game(game_id) do
    GenServer.call(via_tuple(game_id), {:start_game} )
  end

  def update_canvas_state(game_id , new_canvas_state) do
    GenServer.call(via_tuple(game_id), {:update_canvas_state , new_canvas_state})
  end




  #Server Callbacks

  def init(%ScribbleState{} = scribble_state) do
    Logger.info("Spawned ScribbleGameServer with pid='#{self()}' and game_id='#{scribble_state.game_id}'")
    {:ok , scribble_state}
  end

  def handle_call({:join_lobby, user_id , username}, _from, state) do
    res = ScribbleStateManager.add_new_player(state , user_id , username)

    {:reply , res.player_count_index , res}
  end

  def handle_call({:leave_lobby, user_id }, _from, state) do
    res = ScribbleStateManager.remove_player(state, user_id)

    case res do
      {:error, _} -> {:reply , "error", state}
      _ -> {:reply , "success" , res}
    end
  end

  def handle_call({:update_player_status, user_id, status}, _from , state) do
    res = ScribbleStateManager.update_player_status(state , user_id , status)

    {:reply, "success" , res}
  end

  def handle_call({:start_game}, _from, state) do
    res = ScribbleStateManager.check_game_start_status(state)

    {:reply , res , state}
  end

  def handle_call({:update_canvas_state , new_canvas_state}, _from, state) do
    res = ScribbleStateManager.update_canvas_state(state , new_canvas_state)
    case res do
      {:error, _} -> {:reply , "error", state}
      _ -> {:reply , "success" , res}
    end
  end

end
