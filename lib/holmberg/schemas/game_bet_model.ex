defmodule Holmberg.Schemas.GameBetModel do

  use Ecto.Schema
  import Ecto.Changeset


  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    user_id: Ecto.UUID.t(),
    game_id: Ecto.UUID.t(),
    user_id_betting_on: Ecto.UUID.t(),
    session_id: String.t(),
    game_name: String.t(),
    bet_amount: float(),
    created_at: DateTime.t(),
    updated_at: DateTime.t(),
    status: String.t()
  }
 @timestamps_opts [type: :utc_datetime_usec]
 @primary_key {:id, :binary_id, []}
  schema "game_bets" do
    field :user_id, :binary_id
    field :game_id, :binary_id
    field :user_id_betting_on, :binary_id
    field :session_id, :string
    field :game_name, :string
    field :bet_amount, :float
    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
    field :status, :string
  end

  def edit_changeset(user , attrs) do
    user
    |> cast(attrs, [
      :id,
      :status
    ])
    |> validate_required([:id, :status])
    |> unique_constraint(:id)
  end



end
