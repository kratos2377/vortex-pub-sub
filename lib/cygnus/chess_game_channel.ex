defmodule VortexPubSub.Cygnus.ChessGameChannel do
  alias MaelStorm.ChessServer
  alias VortexPubSub.Presence

  def join("game:chess:" <> game_id, _params, socket) do

  end

  defp current_player(socket) do

  end
end
