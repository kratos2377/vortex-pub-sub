defmodule Vortex.Model.UserGameEvent do

  alias Vortex.Utils.UUID
  alias Vortex.Model.UserGameMove
  defstruct id: nil,
            version: nil,
            name: nil,
            description: nil,
            user_game_move: nil

  @type state :: %__MODULE__{
    id: UUID.t(),
    version: Integer.t(),
    name: String.t(),
    description: String.t(),
    user_game_move: UserGameMove.t(),
  }
end
