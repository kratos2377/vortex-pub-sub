defmodule Quasar.ScribbleStateManager do

  @max_players 8
  alias GameState.ScribbleState
  import Holmberg.Schemas.TurnModel

  def add_new_player(%ScribbleState{} = scribble_state ,user_id, username) do
    new_count_id = Enum.sum([scribble_state.player_count_index , 1])
    new_player = %Holmberg.Schemas.TurnModel{count_id: new_count_id, user_id: user_id, username: username}

    updated_players = Enum.concat(chess_state.turn_map ,[new_player])
    sorted_players = Enum.sort(updated_players , &(&1.count_id <= &2.count_id))
    status_map = Map.update(scribble_state.player_ready_status , user_id , "not-ready", fn _existing_value -> "not-ready" end)
     %{scribble_state | turn_map: sorted_players, total_players: Enum.sum([scribble_state.total_players , 1]), player_count_index: new_count_id, player_ready_status: status_map}
  end

  def remove_player(%ScribbleState{} = scribble_state, user_id) do
    case Enum.find_index(scribble_state.turn_map, &(&1.user_id == user_id)) do
      nil ->
        {:error, :player_not_found}
      _ ->
        {_ , status_map} = Map.pop(scribble_state.player_ready_status , user_id)
        updated_players = Enum.reject(scribble_state.turn_map, &(&1.user_id == user_id))
       %{scribble_state | turn_map: updated_players , total_players: Enum.sum([scribble_state.total_players, -1]), player_ready_status: status_map}
    end
  end

  def update_player_status(%ScribbleState{} = scribble_state, user_id , status) do
    new_updated_player_status_map = scribble_state.player_ready_status
    new_updated_player_status_map  = Map.update(new_updated_player_status_map , user_id , "not-ready", fn _existing_value -> status end)

    %{scribble_state | player_ready_status: new_updated_player_status_map}
  end

  def check_game_start_status(%ScribbleState{} = scribble_state) do
    has_not_ready = Enum.any?(scribble_state.player_ready_status, fn {_key, value} -> value == "not-ready" end)

  if has_not_ready do
    "error"
  else
    "success"
  end
  end

  def update_canvas_state(%ScribbleState{} = scribble_state, new_state) do
    %{scribble_state | canvas_state: new_state}
  end

  def generate_word_for_current_round(%ScribbleState{} = scribble_state , new_state) do

  end

end
