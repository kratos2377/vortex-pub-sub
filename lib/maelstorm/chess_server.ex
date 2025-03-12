defmodule MaelStorm.ChessServer do
    use GenServer
    require Logger
    alias Quasar.ChessStateManager
    alias GameState.ChessState
    alias VortexPubSub.Endpoint
    alias VortexPubSub.Constants
    alias VortexPubSub.KafkaProducer
    alias Pulsar.ChessSupervisor

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

    def get_game_data(game_id) do
      GenServer.call(via_tuple(game_id), {:get_game_data})
    end

    def set_state_to_game_over(game_id , is_valid , winner_id) do
        GenServer.call(via_tuple(game_id), {:set_state_to_game_over , is_valid , winner_id , game_id})
    end

    def set_state_to_game_over_stalemate(game_id , is_valid) do
      GenServer.call(via_tuple(game_id), {:set_state_to_game_over_stalemate , is_valid , game_id})
  end

    def check_if_stake_is_possible(game_id) do
      GenServer.call(via_tuple(game_id), {:check_if_stake_is_possible})
    end

    def check_if_bettor_is_player(game_id , user_id) do
      GenServer.call(via_tuple(game_id), {:check_if_bettor_is_player , user_id})
    end


    def update_player_stake(game_id , user_id) do
      GenServer.call(via_tuple(game_id), {:update_player_stake , user_id})
    end


    def stake_interval_check(game_id) do
      GenServer.call(via_tuple(game_id), {:stake_interval_check})
    end

    def is_in_game_over_state(game_id) do
      GenServer.call(via_tuple(game_id), {:is_in_game_over_state})
    end


    #Server Callbacks

    def init({chess_state}) do
      #Logger.info("Spawned ChessGameServer with pid='#{self()}' and game_id='#{chess_state.game_id}'")
      {:ok , chess_state}
    end

    def handle_call({:is_in_game_over_state} , _from , state) do
      case state.status do
        "GAME-OVER" -> {:reply , :yes , state}

          _ -> {:reply , :no , state}
      end
    end

    def handle_call({:join_lobby, user_id , username}, _from, state) do
      res = ChessStateManager.add_new_player(state , user_id , username)
      {:reply , res.player_count_index , res}
    end


    def handle_call({:get_game_data}, _from, state) do
      {:reply , state , state}
    end

    def handle_call({:get_summary}, _from, state) do

        new_map = Map.drop(state, [:game_timer_ref, :stake_timer_ref])
        {:reply , new_map , state}
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

            game_timer_ref = schedule_interval_update()

            if state.is_staked do
              KafkaProducer.send_message(Constants.kafka_create_new_game_record() , %{game_id: state.game_id , session_id: state.session_id} , "new_game_record")
              stake_timer_ref = start_stake_interval_timer()
              {:reply , "success" , %{res | game_timer_ref: game_timer_ref , stake_timer_ref: stake_timer_ref}}
            else
              {:reply , "success" , %{res | game_timer_ref: game_timer_ref}}
            end

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

    def handle_call({:set_state_to_game_over , is_valid , winner_id , game_id} , _from , state) do
      res = ChessStateManager.set_state_to_game_over(state)
      if res.is_staked do
          KafkaProducer.send_message(Constants.kafka_user_game_over_topic() , %{game_id: game_id , session_id: res.session_id , winner_id: winner_id , is_game_valid: is_valid} , "game-over-event")
      end
      {:reply ,  res , res}
    end

    def handle_call({:set_state_to_game_over_stalemate , is_valid , game_id} , _from , state) do
      res = ChessStateManager.set_state_to_game_over(state)
      if res.is_staked do
          KafkaProducer.send_message(Constants.kafka_user_game_over_topic() , %{game_id: game_id , session_id: res.session_id , winner_id: "" , is_game_valid: is_valid} , "game-over-event")
      end
      {:reply ,  res , res}
    end


    def handle_call({:check_if_bettor_is_player , user_id} , _from , state) do

      res = Map.has_key?(state.player_staked_status , String.to_atom(user_id))

      if res do
        {:reply , {:ok , state.session_id} , state}
      else
        {:reply , :no  , state}
      end

    end

    def handle_call({:update_player_stake , user_id} , _from , state) do

      res = ChessStateManager.update_player_staked_status(state , user_id , "staked")
      {:reply , {:ok , res} ,  res}



    end

    def handle_call({:check_if_stake_is_possible} , _from , state) do
      case state.status do
        "IN-PROGRESS" ->

          total_time = 1800 - (state.time_left_for_black_player + state.time_left_for_white_player)

          if total_time > 300 do
            {:reply , :timeout , state}
        else
          case state.is_staked do
            true -> {:reply , {:ok , state.session_id} , state}
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
                _ ->
                  game_timer_ref = schedule_interval_update()
                {:noreply, %{res | game_timer_ref: game_timer_ref }}
            end

            "black" ->  case res.time_left_for_black_player do
              0 ->
                game_finished("black" , state)
                {:noreply ,  res}
                _ ->

                  game_timer_ref = schedule_interval_update()
                  {:noreply, %{res | game_timer_ref: game_timer_ref }}
            end
          end

          _ -> Logger.info("Game has either been stopped or in lobby state for gameId=#{state.game_id}")
          {:noreply , state}
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
              _ ->
                game_timer_ref = schedule_interval_update()
                {:noreply, %{res | game_timer_ref: game_timer_ref }}
          end

          "black" ->  case res.time_left_for_black_player do
            0 ->
              game_finished("black" , state)
              {:noreply , res}
              _ ->

                game_timer_ref = schedule_interval_update()
                {:noreply, %{res | game_timer_ref: game_timer_ref }}
          end
        end

        _ -> Logger.info("Game has either been stopped or in lobby state for gameId=#{state.game_id}")
        {:noreply , state}
      end

    end


    def game_finished(player_color , state) do

        case player_color do
          "white" ->

              white_player = Enum.at(state.turn_map , 0)
              black_player = Enum.at(state.turn_map , 1)
              Endpoint.broadcast!("game:chess:"<> state.game_id , "game-over-time" , %{winner_username: black_player.username , winner_user_id: black_player.user_id,
                loser_username: white_player.username , loser_user_id: white_player.user_id})
              Endpoint.broadcast!("spectate:chess:"<> state.game_id , "game-over-time" , %{winner_username: black_player.username , winner_user_id: black_player.user_id,
              loser_username: white_player.username , loser_user_id: white_player.user_id})

              MaelStorm.ChessServer.set_state_to_game_over(state.game_id , false , black_player.user_id)
              ChessSupervisor.stop_game(state.game_id )

            "black" ->
              white_player = Enum.at(state.turn_map , 0)
              black_player = Enum.at(state.turn_map , 1)
              Endpoint.broadcast!("game:chess:"<> state.game_id , "game-over-time" , %{winner_username: white_player.username , winner_user_id: white_player.user_id,
              loser_username: black_player.username , loser_user_id: black_player.user_id})
              Endpoint.broadcast!("spectate:chess:"<> state.game_id , "game-over-time" , %{winner_username: white_player.username , winner_user_id: white_player.user_id,
              loser_username: black_player.username , loser_user_id: black_player.user_id})
              MaelStorm.ChessServer.set_state_to_game_over(state.game_id , false , white_player.user_id)
              ChessSupervisor.stop_game(state.game_id )

        end

    end

    def handle_call({:stake_interval_check} , _from, state) do

      if state.is_staked do

        if state.staking_player_time == 182 do
          Endpoint.broadcast!("game:chess:"<> state.game_id , "player-staking-available" , %{})
          Endpoint.broadcast!("spectate:chess:"<> state.game_id , "player-staking-available" , %{})
         res =  ChessStateManager.update_staking_time(state)
         lobby_stake_timer_ref = start_stake_check_interval_update()
          {:reply, "success" ,  %{res | lobby_stake_timer_ref: lobby_stake_timer_ref}}
        else
          has_everyone_staked = Enum.any?(state.player_staked_status, fn {_key, value} -> value == "not-staked" end)


          if !has_everyone_staked do

            Endpoint.broadcast!("game:chess:"<> state.game_id , "player-stake-complete" , %{})
            Endpoint.broadcast!("spectate:chess:"<> state.game_id , "player-stake-complete" , %{})

            {:reply, "success",  state}

          else

            if state.staking_player_time == 0 do

              Endpoint.broadcast!("game:chess:"<> state.game_id , "player-did-not-staked-within-time" , %{})
              Endpoint.broadcast!("spectate:chess:"<> state.game_id , "player-did-not-staked-within-time" , %{})
              {:reply, "success",  state}

            else
              res =  ChessStateManager.update_staking_time(state)
              lobby_stake_timer_ref = start_stake_check_interval_update()
              {:reply, "success" ,  %{res | lobby_stake_timer_ref: lobby_stake_timer_ref}}
            end


          end

        end
      end

   end


  def handle_info(:stake_interval_check, state) do

    if state.is_staked do

      if state.staking_player_time == 182 do
        Endpoint.broadcast!("game:chess:"<> state.game_id , "player-staking-available" , %{})
        Endpoint.broadcast!("spectate:chess:"<> state.game_id , "player-staking-available" , %{})
        res =  ChessStateManager.update_staking_time(state)
        lobby_stake_timer_ref = start_stake_check_interval_update()
        {:noreply, %{res | lobby_stake_timer_ref: lobby_stake_timer_ref}}

      else
        has_everyone_staked = Enum.any?(state.player_staked_status, fn {_key, value} -> value == "not-staked" end)


        if !has_everyone_staked do

          Endpoint.broadcast!("game:chess:"<> state.game_id , "player-stake-complete" , %{})
          Endpoint.broadcast!("spectate:chess:"<> state.game_id , "player-stake-complete" , %{})
          {:noreply, state}
        else

          if state.staking_player_time == 0 do

            Endpoint.broadcast!("game:chess:"<> state.game_id , "player-did-not-staked-within-time" , %{})
            Endpoint.broadcast!("spectate:chess:"<> state.game_id , "player-did-not-staked-within-time" , %{})
            KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: state.game_id}, Constants.kafka_game_general_event_key())
            ChessSupervisor.stop_game(state.game_id)
            {:noreply, state}
          else

            res =  ChessStateManager.update_staking_time(state)
            lobby_stake_timer_ref = start_stake_check_interval_update()
            {:noreply, %{res | lobby_stake_timer_ref: lobby_stake_timer_ref}}
          end

        end

      end
    end

  end



  def handle_call({:stake_interval_timer} , _from, state) do

    case state.status do
      "IN-PROGRESS" ->
        if state.is_staked do
          total_time = 1800 - (state.time_left_for_black_player + state.time_left_for_white_player)

          if total_time > 300 do
              KafkaProducer.send_message(Constants.kafka_stake_time_over() , %{game_id: state.game_id , session_id: state.session_id} , "stake_time_over")

              {:noreply, state}
         else
          stake_timer_ref = start_stake_interval_timer()
            {:noreply, %{state | stake_timer_ref: stake_timer_ref}}
          end



        else
          {:noreply, state}
        end

        _ ->  {:noreply, state}
    end

 end


def handle_info(:stake_interval_timer, state) do

  case state.status do
    "IN-PROGRESS" ->
      if state.is_staked do
        total_time = 1800 - (state.time_left_for_black_player + state.time_left_for_white_player)

        if total_time > 300 do
            KafkaProducer.send_message(Constants.kafka_stake_time_over() , %{game_id: state.game_id , session_id: state.session_id} , "stake_time_over")
            {:noreply, state}
          else
          stake_timer_ref = start_stake_interval_timer()
            {:noreply, %{state | stake_timer_ref: stake_timer_ref}}
        end


      else
        {:noreply, state}
      end

      _ ->  {:noreply, state}
  end


end

    def schedule_interval_update() do
      Process.send_after(self(), :start_interval_update, 1_000)
    end


    def start_stake_check_interval_update() do
      Process.send_after(self(), :stake_interval_check, 1_000)
    end

    def start_stake_interval_timer() do
      Process.send_after(self(), :stake_interval_timer, 1_000)
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
