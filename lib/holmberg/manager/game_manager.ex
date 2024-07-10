defmodule Holmberg.Manager.GameManager do
  alias Ecto.Multi

  def create_lobby_multi_changeset(game_changeset, user_game_relation_changeset, user_turn_mapping_changeset) do
        Multi.new()
        |> Multi.insert(:games, game_changeset)
        |> Multi.insert(:users, user_game_relation_changeset)
        |> Multi.insert(:users_turns, user_turn_mapping_changeset)
  end


  def join_lobby_multi_changeset() do

  end

end
