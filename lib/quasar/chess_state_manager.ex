defmodule Quasar.ChessStateManager do

  @max_players 2
  alias GameState.ChessState
  import Holmberg.Schemas.TurnModel

  def add_new_player(%ChessState{} = chess_state ,user_id, username) do
    new_count_id = Enum.sum([chess_state.player_count_index , 1])
    new_player = %Holmberg.Schemas.TurnModel{count_id: new_count_id, user_id: user_id, username: username}

    updated_players = ([:turn_map] ++ [new_player])
                      |> Enum.sort_by(& &1.count_id)

     %{chess_state | turn_map: updated_players, total_players: Enum.sum([chess_state.total_players , 1]), player_count_index: new_count_id}
  end

  def remove_player(%ChessState{} = chess_state, user_id) do
    case Enum.find_index(:turn_map, &(&1.user_id == user_id)) do
      nil ->
        {:error, :player_not_found}
      _ ->
        updated_players = Enum.reject(:turn_map, &(&1.user_id == user_id))
       %{chess_state | turn_map: updated_players , total_players: Enum.sum([chess_state.total_players, -1])}
    end
  end

  def update_player_status(%ChessState{} = chess_state, user_id , status) do
    new_updated_player_status_map = chess_state.player_ready_status
    new_updated_player_status_map  = Map.update(new_updated_player_status_map , user_id , "not-ready", fn _existing_value -> status end)

    %{chess_state | player_ready_status: new_updated_player_status_map}
  end

end
