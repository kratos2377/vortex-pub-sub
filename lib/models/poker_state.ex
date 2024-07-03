defmodule VortexPubSub.Model.PokerState do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :game_id, Ecto.UUID
    field :pot_size, :float
    field :current_turn, :string
    embeds_many :user_states, VortexPubSub.Model.Poker
  end

  def changeset(poker_state, attrs) do
    poker_state
    |> cast(attrs, [:game_id, :pot_size, :current_turn])
    |> cast_embed(:user_states)
    |> validate_required([:game_id, :pot_size, :current_turn])
  end
end
