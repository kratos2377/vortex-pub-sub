defmodule Holmberg.Queries.GameBet do
  import Ecto.Query, warn: false

  alias Holmberg.Schemas.GameBetModel
  alias VortexPubSub.PostgresRepo

  def get_game_bet_for_user(user_id , game_id , session_id) do
    from(u in GameBetModel,
    where: u.user_id == ^user_id and u.game_id == ^game_id and u.session_id ==  ^session_id
    ) |> PostgresRepo.one()
  end

end
