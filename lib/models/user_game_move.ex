defmodule Vortex.Model.UserGameMove do

      defstruct id: nil,
                user_id: nil,
                game_id: nil,
                version: nil,
                move_type: nil,
                user_move: nil,
                socket_id: nil

    @type state :: %__MODULE__{
    id: UUID.t(),
    user_id: String.t(),
    game_id: String.t(),
    version: Integer.t(),
    move_type: String.t(),
    user_move: String.t(),
    socket_id: String.t()
    }


end
