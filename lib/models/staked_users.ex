defmodule VortexPubSub.Model.StakedUsers do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :game_id, :binary_id
    field :money_staked, :map
  end

  def changeset(staked_users, attrs) do
    staked_users
    |> cast(attrs, [:game_id, :money_staked])
    |> validate_required([:game_id, :money_staked])
  end
end
