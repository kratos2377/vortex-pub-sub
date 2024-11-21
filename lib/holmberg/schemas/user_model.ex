defmodule Holmberg.Schemas.UserModel do

  use Ecto.Schema
  import Ecto.Changeset

 @timestamps_opts [type: :utc_datetime_usec]
 @primary_key false
  schema "users" do
    field :id, Ecto.UUID
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



end
