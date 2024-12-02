defmodule Holmberg.Schemas.UserModel do

  use Ecto.Schema
  import Ecto.Changeset


  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    username: String.t(),
    password: String.t(),
    email: String.t(),
    first_name: String.t(),
    last_name: String.t(),
    verified: boolean(),
    score: integer(),
    created_at: DateTime.t(),
    updated_at: DateTime.t(),
    is_online: boolean()
  }
 @timestamps_opts [type: :utc_datetime_usec]
 @primary_key {:id, :binary_id, []}
  schema "users" do
    field :username, :string
    field :password, :string
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :verified, :boolean
    field :score, :integer
    field :created_at, :utc_datetime_usec
    field :updated_at, :utc_datetime_usec
    field :is_online, :boolean
  end

  def edit_changeset(user , attrs) do
    user
    |> cast(attrs, [
      :id,
      :is_online
    ])
    |> validate_required([:id, :is_online])
    |> unique_constraint(:id)
  end



end
