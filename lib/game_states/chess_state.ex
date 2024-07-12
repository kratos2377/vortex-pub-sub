defmodule GameState.ChessState do

  import Holmberg.Schemas.TurnModel


  defstruct game_id: "", turn_map: [], turn_count: 0, total_players: 0, time_left_for_white_player: 0, time_left_for_black_player: 0, player_count_index: 0


  def new(game_id , user_id, username) do
    new_player = %Holmberg.Schemas.TurnModel{count_id: 1, user_id: user_id, username: username}
    %__MODULE__{game_id: game_id, turn_map: [new_player], turn_count: 0 , total_players: 1, time_left_for_white_player: 900, time_left_for_black_player: 900, player_count_index: 1 }
  end


end
