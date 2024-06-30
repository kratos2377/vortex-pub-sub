defmodule Holmberg.Mutation.Game do

  alias VortexPubSub.Repo
  alias Holmberg.Schemas.GameModel

  def create_new_game() do
    game_id = Ecto.UUID.generate()
  end


  def create_game_changeset() do

  end

end
