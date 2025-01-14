defmodule Holmberg.Schemas.TurnModel do
  @derive [Jason.Encoder]  # This allows the struct to be JSON-encoded
  defstruct [:count_id, :user_id, :username]



  @type t:: %__MODULE__{
      count_id: Integer.t(),
      user_id: String.t(),
      username: String.t()
    }


    @behaviour Access

    @impl Access
    def fetch(struct, key) do
      Map.fetch(Map.from_struct(struct), key)
    end

    @impl Access
    def get_and_update(struct, key, fun) do
      {get, update} = fun.(Map.get(struct, key))
      {get, Map.put(struct, key, update)}
    end

    @impl Access
    def pop(struct, key) do
      value = Map.get(struct, key)
      {value, Map.put(struct, key, nil)}
    end
end
