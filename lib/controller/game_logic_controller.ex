defmodule VortexPubSub.GameLogicController do
  import Plug.Conn
  use Plug.Router


  plug(VortexPubSub.Hypernova.Cors)
  plug(:dispatch)

  post "/create_lobby" do

  end

  post "/join_lobby" do

  end

  post "/leave_lobby" do

  end

  post "/destroy_lobby_and_game" do

  end

  post "/update_player_status" do

  end


  post "/start_game" do

  end

  post "/get_user_turn_mappings" do

  end

  post "/verify_game_status" do

  end

  post "/get_lobby_players" do

  end

  get "/get_current_state_of_game" do

  end

  post "/get_game_details" do

  end


end
