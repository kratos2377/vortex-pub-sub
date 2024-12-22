defmodule Quasar.ChessStateManager do

  @max_players 2
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
     %{chess_state | turn_map: sorted_players, total_players: Enum.sum([chess_state.total_players , 1]), player_count_index: new_count_id, player_ready_status: status_map}
  end

  def remove_player(%ChessState{} = chess_state, user_id) do
    case Enum.find_index(chess_state.turn_map, &(&1.user_id == user_id)) do
      nil ->
        {:error, :player_not_found}
      _ ->
        {_ , status_map} = Map.pop(chess_state.player_ready_status , user_id)
        updated_players = Enum.reject(chess_state.turn_map, &(&1.user_id == user_id))
       %{chess_state | turn_map: updated_players , total_players: Enum.sum([chess_state.total_players, -1]), player_ready_status: status_map}
    end
  end

  def update_player_status(%ChessState{} = chess_state, user_id , status) do
    existing_map = chess_state.player_ready_status
    new_updated_player_status_map  = %{existing_map | "#{user_id}": status}

    %{chess_state | player_ready_status: new_updated_player_status_map}
  end

  def check_game_start_status(%ChessState{} = chess_state) do
    has_not_ready = Enum.any?(chess_state.player_ready_status, fn {_key, value} -> value == "not-ready" end)

  if has_not_ready do
    "error"
  else
    "success"
  end
  end

  def reset_game_status(%ChessState{} = chess_state) do
    new_status_map = Map.new(chess_state.player_ready_status , fn {key, _value} -> {key, "not-ready"} end)
    %{chess_state | player_ready_status: new_status_map , time_left_for_white_player: 900, time_left_for_black_player: 900}
  end

end
