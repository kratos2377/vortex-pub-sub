defmodule GameState.ChessState do

  import Holmberg.Schemas.TurnModel


  defstruct game_id: "", turn_map: [], turn_count: 0, total_players: 0, time_left_for_white_player: 0, time_left_for_black_player: 0, player_count_index: 0, current_turn: "", status: "", player_ready_status: %{}


  def new(game_id , user_id, username) do
    new_player = %Holmberg.Schemas.TurnModel{count_id: 1, user_id: user_id, username: username}
    %__MODULE__{game_id: game_id, turn_map: [new_player], turn_count: 0 , total_players: 1, time_left_for_white_player: 900, time_left_for_black_player: 900, player_count_index: 1, current_turn: "white",  status: "LOBBY" , player_ready_status: %{"#{user_id}": "not-ready"} }
  end


  def new_state_of_match_type(game_id , player1, player2) do
    new_player1 = %Holmberg.Schemas.TurnModel{count_id: 1, user_id: player1["PlayerId"], username: player1["PlayerUsername"]}
    new_player2 = %Holmberg.Schemas.TurnModel{count_id: 2, user_id: player2["PlayerId"], username: player2["PlayerUsername"]}
    %__MODULE__{game_id: game_id, turn_map: [new_player1 , new_player2], turn_count: 0 , total_players: 2, time_left_for_white_player: 900, time_left_for_black_player: 900, player_count_index: 2, current_turn: "white", status: "LOBBY", player_ready_status: %{"#{player1["PlayerId"]}": "not-ready", "#{player2["PlayerId"]}": "not-ready"} }
  end

end
