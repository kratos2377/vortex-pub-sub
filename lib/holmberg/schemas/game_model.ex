defmodule Holmberg.Schemas.GameModel do

use Ecto.Schema
import Ecto.Changeset

  alias VortexPubSub.Model.StakedUsers
  alias VortexPubSub.Model.PokerState

 #Make scribble and chess states and change them from string to their
 # respective states

@primary_key {:id}
schema "games" do
  field :id, Ecto.UUID.t()
  field :user_count, :integer
  field :host_id, :string
  field :name, :string
  field :game_type, :string
  field :is_staked, :boolean
  field :state_index, :integer
  field :description, :string
  field :chess_state, :string
  field :staked_money_state, StakedUsers   # Assuming StakedUsers is a complex type
  field :poker_state, PokerState         # Assuming PokerState is a complex type
  field :scribble_state, :string         # Assuming ScribbleState is a complex type

  timestamps()
end

def changeset(game, attrs) do
  game
  |> cast(attrs, [:user_count, :host_id, :name, :game_type, :is_staked,
                  :chess_state, :state_index, :description,
                  :staked_money_state, :poker_state, :scribble_state])
  |> validate_required([:user_count, :host_id, :name, :game_type, :is_staked,
                        :chess_state, :state_index, :description])
end

end
