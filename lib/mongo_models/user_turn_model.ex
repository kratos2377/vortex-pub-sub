defmodule MongoModels.UserTurnModel do
  use Ecto.Schema
  import Ecto.Changeset
  use MongoModels.TurnModel

  @primary_key {:game_id, :string, []}
  schema "user_turns" do
    field(:host_id, :string)
    field(:game_id, :string)
    field(:turn_mappings, MongoModels.TurnModel)
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
  def insert_changeset(user_turn, attrs) do
    user_turn
    |> cast(attrs, [:host_id, :game_id, :turn_mappings])
  end
end
