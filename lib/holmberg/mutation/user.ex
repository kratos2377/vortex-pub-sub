defmodule Holmberg.Mutation.User do
import Ecto.Query, warn: false

alias Holmberg.Schemas.UserModel
alias VortexPubSub.PostgresRepo

  def set_user_online(user_id , is_online) do
    user_id
    |> get_user_by_id()
    |> set_is_online_changeset(is_online)
    |> PostgresRepo.update()
  end


  def get_user_by_id(user_id) do
    from(u in UserModel,
    where: u.id == ^user_id
    ) |> PostgresRepo.one()
  end



  def set_is_online_changeset(user , is_online) do
    new_user_model = %{
      id: user.id,
      username: user.username,
      password: user.password,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      verified: user.verified,
      score: user.score,
      created_at: user.created_at,
      updated_at: user.updated_at,
      is_online: is_online
    }

    new_user_model
  end

end
