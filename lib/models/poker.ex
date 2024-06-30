defmodule VortexPubSub.Model.Poker do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :money_left, :float
    field :go_all_in, :boolean
    field :turns_left, :integer
  end

  def changeset(poker, attrs) do
    poker
    |> cast(attrs, [:money_left, :go_all_in, :turns_left])
    |> validate_required([:money_left, :go_all_in, :turns_left])
  end
end
