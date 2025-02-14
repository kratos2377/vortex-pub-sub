defmodule VortexPubSub.Utils.GenerateKeyNames do


    def get_chess_state_key(game_id) do
      "ChessState_#{game_id}"
    end

end
