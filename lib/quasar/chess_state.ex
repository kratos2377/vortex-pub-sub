defmodule Quasar.ChessState do

  import Holmberg.Schemas.TurnModel

  @max_players 2
  defstruct game_id: "", turn_map: [], turn_count: 0, total_players: 0, time_left_for_white_player: 0, time_left_for_black_player: 0, player_count_index: 0


  def new(game_id , user_id, username) do
    new_player = %Holmberg.Schemas.TurnModel{count_id: 1, user_id: user_id, username: username}
    %__MODULE__{game_id: game_id, turn_map: [new_player], turn_count: 0 , total_players: 1, time_left_for_white_player: 900, time_left_for_black_player: 900, player_count_index: 1 }
  end


  def add_new_player(user_id, username) do
    new_count_id = :player_count_index + 1;
    new_player = %Holmberg.Schemas.TurnModel{count_id: new_count_id, user_id: user_id, username: username}

    updated_players = (:turn_map ++ [new_player])
                      |> Enum.sort_by(& &1.count_id)

    {:ok , %{turn_map: updated_players, total_players: :total_players + 1, player_count_index: new_count_id}}
  end

  def remove_player(user_id) do
    case Enum.find_index(:turn_map, &(&1.user_id == user_id)) do
      nil ->
        {:error, :player_not_found}
      _ ->
        updated_players = Enum.reject(:turn_map, &(&1.user_id == user_id))
        {:ok,  %{turn_map: updated_players , total_players: :total_players - 1}}
    end
  end


end
