defmodule GameState.ChessState do

  import Holmberg.Schemas.TurnModel
  @derive [Jason.Encoder]


  defstruct game_id: "", turn_map: [], turn_count: 0, total_players: 0, time_left_for_white_player: 0, time_left_for_black_player: 0, player_count_index: 0, current_turn: "", status: "", player_ready_status: %{}, is_staked: false, session_id: "", player_staked_status: %{}, staking_player_time: 122


  def new(game_id , user_id, username , is_staked) do
    new_player = %Holmberg.Schemas.TurnModel{count_id: 1, user_id: user_id, username: username}

    %__MODULE__{game_id: game_id, turn_map: [new_player], turn_count: 0 , total_players: 1, time_left_for_white_player: 900, time_left_for_black_player: 900, player_count_index: 1, current_turn: "white",  status: "LOBBY" , player_ready_status: %{"#{user_id}": "not-ready"}, is_staked: is_staked , session_id: Nanoid.generate(), player_staked_status: %{"#{user_id}": "not-staked"} , staking_player_time: 122 }
  end


  def new_state_of_match_type(game_id , player1, player2 , is_staked) do
    new_player1 = %Holmberg.Schemas.TurnModel{count_id: 1, user_id: player1.user_id, username: player1.username}
    new_player2 = %Holmberg.Schemas.TurnModel{count_id: 2, user_id: player2.user_id, username: player2.username}
    %__MODULE__{game_id: game_id, turn_map: [new_player1 , new_player2], turn_count: 0 , total_players: 2, time_left_for_white_player: 900, time_left_for_black_player: 900, player_count_index: 2, current_turn: "white", status: "LOBBY", player_ready_status: %{"#{player1.user_id}": "not-ready", "#{player2.user_id}": "not-ready"} , is_staked: is_staked , session_id: Nanoid.generate(), player_ready_status: %{"#{player1.user_id}": "not-staked", "#{player2.user_id}": "not-staked"} , staking_player_time: 122  }
  end

end
