defmodule Holmberg.Mutation.User do
import Ecto.Query, warn: false

alias Holmberg.Schemas.UserModel
alias VortexPubSub.PostgresRepo

  def set_user_online(user_id , is_online) do
    user_id
    |> get_user_by_id()
    |> UserModel.edit_changeset(%{is_online: true})
    |> PostgresRepo.update()
  end


  def get_user_by_id(user_id) do
    from(u in UserModel,
    where: u.id == ^user_id
    ) |> PostgresRepo.one()
  end



  # def set_is_online_changeset(user , is_online) do


  #   new_user_model

  #   IO.inspect("NEW MODEL IS")
  #   IO.inspect(new_user_model)
  # end

end
