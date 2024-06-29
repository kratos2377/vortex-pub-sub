defmodule MongoModels.GameModel do

use Ecto.Schema
import Ecto.Changeset

@primary_key {:id}
schema "games" do
  field :id, Ecto.UUID.t()
  field :user_count, :integer
  field :host_id, :string
  field :name, :string
  field :game_type, :string
  field :is_staked, :boolean
  field :current_state, :string
  field :state_index, :integer
  field :description, :string
  field :staked_money_state, :map  # Assuming StakedUsers is a complex type
  field :poker_state, :map         # Assuming PokerState is a complex type

  timestamps()
end

def changeset(game, attrs) do
  game
  |> cast(attrs, [:user_count, :host_id, :name, :game_type, :is_staked,
                  :current_state, :state_index, :description,
                  :staked_money_state, :poker_state])
  |> validate_required([:user_count, :host_id, :name, :game_type, :is_staked,
                        :current_state, :state_index, :description])
end

end
