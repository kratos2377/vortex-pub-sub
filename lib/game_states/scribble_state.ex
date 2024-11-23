defmodule GameState.ScribbleState do


  defstruct game_id: "", turn_map: [], turn_count: 0, total_players: 0, canvas_state: "",player_count_index: 0, player_ready_status: %{}

  def new(game_id , user_id, username) do
    new_player = %Holmberg.Schemas.TurnModel{count_id: 1, user_id: user_id, username: username}
    %__MODULE__{game_id: game_id, turn_map: [new_player], turn_count: 0 , total_players: 1, canvas_state: "", player_count_index: 1, player_ready_status: %{user_id: "not-ready"} }
  end


end
