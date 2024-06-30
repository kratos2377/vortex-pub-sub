defmodule Quasar.ChessState do

  use Holmberg.Schemas.TurnModel

  @max_players 2
  defstruct [:game_id, :turn_map, :turn_count, :total_players, :time_left_for_white_player, :time_left_for_black_player, :player_count_index]


  def new(game_id , user_id, username) do
    new_player = %Holmberg.Schemas.TurnModel{count_id: 1, user_id: user_id, username: username}
    %__MODULE__{game_id: game_id, turn_map: [new_player], turn_count: 0 , total_players: 1, time_left_for_white_player: 900, time_left_for_black_player: 900, player_count_index: 1 }
  end


  def add_new_player(user_id, username) do
    new_count_id = state.player_count_index + 1;
    new_player = %Holmberg.Schemas.TurnModel{count_id: new_count_id, user_id: user_id, username: username}

    updated_players = (state.turn_map ++ [new_player])
                      |> Enum.sort_by(& &1.count_id)

    %{state | turn_map: updated_players, total_players: state.total_players + 1, player_count_index: new_count_id}
  end

  def remove_player(user_id, username) do
    case Enum.find_index(state.turn_map, &(&1.user_id == user_id)) do
      nil ->
        {:error, :player_not_found}
      _ ->
        updated_players = Enum.reject(state.turn_map, &(&1.user_id == user_id))
        {:ok, %{state | turn_map: updated_players , total_players: state.total_players - 1}}
    end
  end


end
