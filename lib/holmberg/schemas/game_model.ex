defmodule Holmberg.Schemas.GameModel do

  use Ecto.Schema
  import Ecto.Changeset
  alias VortexPubSub.Model.StakedUsers
  alias VortexPubSub.Model.PokerState

 #Make scribble and chess states and change them from string to their
 # respective states
 @primary_key false
  schema "games" do
    field :id, Ecto.UUID
    field :user_count, :integer
    field :host_id, :string
    field :name, :string
    field :game_type, :string
    field :is_staked, :boolean
    field :state_index, :integer
    field :is_match, :boolean
    field :description, :string
    field :chess_state, :string
    field :staked_money_state, :string   # Assuming StakedUsers is a complex type
    field :poker_state, :string         # Assuming PokerState is a complex type
    field :scribble_state, :string         # Assuming ScribbleState is a complex type
    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
  end



end
