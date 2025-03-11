defmodule Quasar.ChessStateManager do

  @max_players 2
  alias GameState.ChessState
  alias GameState.ChessState
  import Holmberg.Schemas.TurnModel

  def add_new_player(%ChessState{} = chess_state ,user_id, username) do

    if chess_state.total_players == 2 do
      :error
    end

    new_count_id = Enum.sum([chess_state.player_count_index , 1])
    new_player = %Holmberg.Schemas.TurnModel{count_id: new_count_id, user_id: user_id, username: username}

    updated_players = Enum.concat(chess_state.turn_map ,[new_player])

    sorted_players = Enum.sort(updated_players , &(&1.count_id <= &2.count_id))
    status_map = Map.put(chess_state.player_ready_status , String.to_atom(user_id) , "not-ready")
    staked_map = Map.put(chess_state.player_staked_status , String.to_atom(user_id) , "not-staked")
     %{chess_state | turn_map: sorted_players, total_players: Enum.sum([chess_state.total_players , 1]), player_count_index: new_count_id, player_ready_status: status_map, player_staked_status: staked_map}
  end

  def remove_player(%ChessState{} = chess_state, user_id) do
    case Enum.find_index(chess_state.turn_map, &(&1.user_id == user_id)) do
      nil ->
        {:error, :player_not_found}
      _ ->
        {_ , status_map} = Map.pop(chess_state.player_ready_status , user_id)
        {_ , staked_map} = Map.pop(chess_state.player_staked_status , user_id)
        updated_players = Enum.reject(chess_state.turn_map, &(&1.user_id == user_id))
       %{chess_state | turn_map: updated_players , total_players: Enum.sum([chess_state.total_players, -1]), player_ready_status: status_map, player_staked_status: staked_map}
    end
  end

  def update_player_status(%ChessState{} = chess_state, user_id , status) do
    existing_map = chess_state.player_ready_status
    new_updated_player_status_map  = Map.update(existing_map , String.to_atom(user_id) , "ready", fn _existing_value -> status end)

    %{chess_state | player_ready_status: new_updated_player_status_map}
  end


  def update_player_staked_status(%ChessState{} = chess_state, user_id , status) do
    existing_map = chess_state.player_staked_status

    new_updated_player_staked_map  =  Map.update(existing_map , String.to_atom(user_id) , "staked", fn _existing_value -> status end)

    %{chess_state | player_staked_status: new_updated_player_staked_map}
  end

  def check_game_start_status(%ChessState{} = chess_state) do

    if chess_state.total_players < 2 do
      chess_state

    else
      has_not_ready = Enum.any?(chess_state.player_ready_status, fn {_key, value} -> value == "not-ready" end)

      if has_not_ready do
        IO.puts("NOT ALL PLAYERS READY")
        chess_state
      else
        case chess_state.is_staked do
          true ->

            has_everyone_staked = Enum.any?(chess_state.player_staked_status, fn {_key, value} -> value == "not-staked" end)

            if has_everyone_staked do
              IO.puts("NOT ALL PLAYERS STAKED")
              chess_state
            else

            %{chess_state |  time_left_for_white_player: 901, time_left_for_black_player: 901 , current_turn: "white" , status: "IN-PROGRESS"}

            end


            _ -> %{chess_state |  time_left_for_white_player: 901, time_left_for_black_player: 901 , current_turn: "white" , status: "IN-PROGRESS"}
        end
      end
    end


  end

  def reset_game_status(%ChessState{} = chess_state) do
    new_status_map = Map.new(chess_state.player_ready_status , fn {key, _value} -> {key, "not-ready"} end)
    new_staked_map = Map.new(chess_state.player_staked_status , fn {key, _value} -> {key, "not-staked"} end)
    %{chess_state | player_ready_status: new_status_map , time_left_for_white_player: 901, time_left_for_black_player: 901 , current_turn: "white" , status: "GAME-OVER" , session_id: Nanoid.generate() , player_staked_status: new_staked_map , staking_player_time: 182}
  end


  def update_players_time(%ChessState{} = chess_state) do

    case chess_state.current_turn do
      "white" ->  %{chess_state | time_left_for_white_player: max(0 , chess_state.time_left_for_white_player - 1)}
      "black" -> %{chess_state | time_left_for_black_player: max(0 , chess_state.time_left_for_black_player - 1)}
    end

  end

  def update_staking_time(%ChessState{} = chess_state) do
     %{chess_state | staking_player_time: max(0 , chess_state.staking_player_time - 1)}
  end

  def change_turn(%ChessState{} = chess_state) do
    case chess_state.current_turn do
      "white" -> %{chess_state | current_turn: "black"}
      "black" -> %{chess_state | current_turn: "white"}
    end
  end

  def get_players_data(%ChessState{} = chess_state) do
    chess_state.turn_map
  end

  def set_state_to_game_over(%ChessState{} = chess_state) do
    %{chess_state | status: "GAME-OVER"}
  end


end
