defmodule Holmberg.Mutation.Game do
  import Plug.Conn
  alias VortexPubSub.Repo
  alias Holmberg.Schemas.GameModel
  alias Holmberg.Schemas.UserGameRelation
  alias Holmberg.Schemas.UserTurnMapping
  alias Holmberg.Schemas.TurnModel

  def create_new_game(conn) do
    game_id = Ecto.UUID.generate()
    params = conn.body_params
    game_changeset = create_game_changeset(game_id, params["user_id"], params["game_type"] , params["game_name"])
    user_game_relation_changeset = create_user_game_relation_changeset(game_id, params["user_id"], params["username"], "host")
    user_turn_mapping_changeset = create_user_turn_mapping_changeset(params["user_id"], game_id, params["user_id"], params["username"], 1)

    case Mongo.insert_one(:mongo , "games", game_changeset) do
      {:ok, _} -> case Mongo.insert_one(:mongo, "users" , user_game_relation_changeset) do
        {:ok , _} -> case Mongo.insert_one(:mongo, "user_turns" , user_turn_mapping_changeset) do
          {:ok , _} -> {:ok , game_id}
          {:error, error_message} ->   {:error , error_message}

          _ -> {:error, "Error Occured while Persisting User Turn Mapping Model"}
        end
        {:error, error_message} ->   {:error , error_message}

        _ -> {:error, "Error Occured while Persisting User Model"}
      end

      {:error, error_message} ->   {:error , error_message}

      _ -> {:error, "Error Occured while Persisting Game Model"}
    end
  end



  def join_lobby(conn) do

  end


  defp create_game_changeset(game_id, host_id, game_name, game_type) do
    game_model = %{
      id: game_id,
      user_count: 1,
      host_id: host_id,
      name: game_name,
      game_type: game_name,
      is_staked:  game_type == "staked",
      state_index: 0,
      description: "LOBBY",
      chess_state: "",
      staked_money_state: "",
      poker_state: "",
      scribble_state: "",
    }
    game_model
  end

  defp create_user_game_relation_changeset(game_id , user_id, username, player_type) do
    user_game_relation_model = %{
      user_id: user_id,
      username: username,
      game_id: game_id,
      player_type: player_type,
      player_status: "not-ready"
    }

    user_game_relation_model
  end

  defp create_user_turn_mapping_changeset(host_id, game_id, user_id, username, user_count_id) do
    turn_mapping_model = %{
      game_id: game_id,
      host_id: host_id,
      turn_mappings: [
        %{
          count_id: user_count_id,
          user_id: user_id,
          username: username
        }
      ]
    }

    turn_mapping_model
  end


    defp handle_transaction_error(failed_operation, failed_value) do
      error_message = "Error in #{failed_operation}: #{inspect(failed_value)}"
      {:error, :game_manager_error, error_message}
    end
end
