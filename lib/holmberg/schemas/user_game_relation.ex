defmodule Holmberg.Schemas.UserGameRelation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "users" do
    field(:user_id, Ecto.UUID)
    field(:username, :string)
    field(:game_id, :string)
    field(:player_type, :string)
    field(:player_status, :string)
  end


  # def common_validation(attrs) do
  #   attrs
  #   |> validate_future_date(:scheduledFor)
  #   |> validate_not_too_far_into_future_date(:scheduledFor)
  #   |> validate_length(:name, min: 2, max: 60)
  #   |> validate_length(:description, max: 200)
  # end


end
