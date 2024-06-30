defmodule Holmberg.Schemas.TurnModel do
  @derive [Jason.Encoder]  # This allows the struct to be JSON-encoded
  defstruct [:count_id, :user_id, :username]

  @type t:: %__MODULE__{
      count_id: Integer.t(),
      user_id: String.t(),
      username: String.t()
    }
end
