defmodule MaelStorm.ChessServer do
    use GenServer
    require Logger
    alias Quasar.ChessStateManager
    alias GameState.ChessState
    alias VortexPubSub.Endpoint


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

    def start_game(game_id) do
      GenServer.call(via_tuple(game_id), {:start_game} )
    end

    def reset_game_state(game_id) do
      GenServer.call(via_tuple(game_id), {:reset_game_state})
    end


    def start_interval_update(game_id) do
      GenServer.call(via_tuple(game_id), {:start_interval_update})
    end

    @spec summary(any()) :: any()
    def summary(game_id) do
      GenServer.call(via_tuple(game_id), {:get_summary})
    end

    def change_player_turn(game_id) do
      GenServer.call(via_tuple(game_id), {:change_player_turn})
    end


    def get_players_data(game_id) do
      GenServer.call(via_tuple(game_id), {:get_players_data})
    end

    def set_state_to_game_over(game_id) do
        GenServer.call(via_tuple(game_id), {:set_state_to_game_over})
    end

    def check_if_stake_is_possible(game_id) do
      GenServer.call(via_tuple(game_id), {:check_if_stake_is_possible})
    end


    #Server Callbacks

    def init({chess_state}) do
      #Logger.info("Spawned ChessGameServer with pid='#{self()}' and game_id='#{chess_state.game_id}'")
      {:ok , chess_state}
    end

    def handle_call({:join_lobby, user_id , username}, _from, state) do
      case ChessStateManager.add_new_player(state , user_id , username) do
        :error -> {:reply , :lobby_full , state}

        res -> {:reply , res.player_count_index , res}
      end


    end


    def handle_call({:get_summary}, _from, state) do
        {:reply , state , state}
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

      {:reply, {:ok , res} , res}
    end

    def handle_call({:start_game}, _from, state) do
      res = ChessStateManager.check_game_start_status(state)

      case res.status do
        "LOBBY" -> {:reply , "error" , state}
          "IN-PROGRESS" ->
            schedule_interval_update()
            {:reply , "success" , res}
            _ -> {:reply , "error" , state}
      end
    end



    def handle_call({:reset_game_state}, _from, state) do

      res = ChessStateManager.reset_game_status(state)
      {:reply , :ok , res }

    end


    def handle_call({:change_player_turn}, _from, state) do
      res = ChessStateManager.change_turn(state)
      {:reply , :ok , res}
    end


    def handle_call({:get_players_data}, _from, state) do
      res = ChessStateManager.get_players_data(state)
      {:reply , res , state}
    end

    def handle_call({:set_state_to_game_over} , _from , state) do
      res = ChessStateManager.set_state_to_game_over(state)
      {:noreply ,  res}
    end

    def handle_call({:check_if_stake_is_possible} , _from , state) do
      case state.status do
        "IN-PROGRESS" ->

          total_time = 1800 - (res.time_left_for_black_player + res.time_left_for_white_player)

          if total_time > 300 do
            {:reply , :timeout , state}
        else
          case res.is_staked do
            true -> {:reply , {:ok , res.session_id} , state}
            _ -> {:reply , :notstaked , state}
          end
        end
          _ -> {:reply , :no , state}
      end
    end


    def handle_call({:start_interval_update} , _from, state) do

        case state.status do
          "IN-PROGRESS" ->
            res = ChessStateManager.update_players_time(state)
          case res.current_turn do
            "white" -> case res.time_left_for_white_player do
              0 ->
                game_finished("white" , state)
                {:noreply , res}
                _ -> schedule_interval_update()
                {:noreply, res}
            end

            "black" ->  case res.time_left_for_black_player do
              0 ->
                game_finished("black" , state)
                {:noreply ,  res}
                _ -> schedule_interval_update()
                {:noreply , res}
            end
          end

          _ -> Logger.info("Game has either been stopped or in lobby state for gameId=#{state.game_id}")
        end

     end


    def handle_info(:start_interval_update, state) do

      case state.status do
        "IN-PROGRESS" ->
          res = ChessStateManager.update_players_time(state)
        case res.current_turn do
          "white" -> case res.time_left_for_white_player do
            0 ->
              game_finished("white" , state)
              {:noreply  , res}
              _ -> schedule_interval_update()
              {:noreply, res}
          end

          "black" ->  case res.time_left_for_black_player do
            0 ->
              game_finished("black" , state)
              {:noreply , res}
              _ -> schedule_interval_update()
              {:noreply , res}
          end
        end

        _ -> Logger.info("Game has either been stopped or in lobby state for gameId=#{state.game_id}")
      end

    end


    def game_finished(player_color , state) do

        case player_color do
          "white" ->

              white_player = Enum.at(state.turn_map , 0)
              Endpoint.broadcast!("game:chess:"<> state.game_id , "game-over-time" , white_player)
              Endpoint.broadcast!("spectate:chess:"<> state.game_id , "game-over-time" , white_player)

            "black" ->

              black_player = Enum.at(state.turn_map , 1)
              Endpoint.broadcast!("game:chess:"<> state.game_id , "game-over-time" , black_player)
              Endpoint.broadcast!("spectate:chess:"<> state.game_id , "game-over-time" , black_player)
        end

    end

    def schedule_interval_update() do
      Process.send_after(self(), :start_interval_update, 1_000)
    end


    def terminate(reason, _game) do
      :ok
    end


    def terminate(reason, game) do
      :ok
    end

    def terminate(_reason, _game) do
      :ok
    end
end
