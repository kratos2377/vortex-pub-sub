defmodule MaelStorm.ChessServer do
    use GenServer
    require Logger
    alias Quasar.ChessStateManager
    alias GameState.ChessState


    def start_link(%ChessState{} = chess_state) do
      GenServer.start_link(__MODULE__, {chess_state}, name: via_tuple(chess_state.game_id))
    end

    def via_tuple(game_id) do
      {:via, Registry, {VortexPubSub.Pulsar.ChessRegistry, game_id}}
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




    #Server Callbacks

    def init(%ChessState{} = chess_state) do
      Logger.info("Spawned ChessGameServer with pid='#{self()}' and game_id='#{chess_state.game_id}'")
      {:ok , chess_state}
    end

    def handle_call({:join_lobby, user_id , username}, _from, state) do
      res = ChessStateManager.add_new_player(state , user_id , username)

      {:reply , res.player_count_index , res}
    end

    def handle_call({:leave_lobby, user_id }, _from, state) do
      res = ChessStateManager.remove_player(state, user_id)

      case res do
        {:error, _} -> {:reply , "error", state}
        _ -> {:reply , "success" , res}
      end
    end

    def handle_call({:update_player_status, user_id, status}, _from , state) do
      res = ChessStateManager.update_player_status(state , user_id , status)

      {:reply, "success" , res}
    end

end
