defmodule Holmberg.Schemas.UserTurnMapping do
  use Ecto.Schema
  import Ecto.Changeset
  alias Holmberg.Schemas.TurnModel

  @primary_key false
  schema "user_turns" do
    field(:host_id, :string)
    field(:game_id, :string)
    field(:turn_mappings, :string)
  end


  # def common_validation(attrs) do
  #   attrs
  #   |> validate_future_date(:scheduledFor)
  #   |> validate_not_too_far_into_future_date(:scheduledFor)
  #   |> validate_length(:name, min: 2, max: 60)
  #   |> validate_length(:description, max: 200)
  # end

  # Fix Validation Logic
  @doc false

end
