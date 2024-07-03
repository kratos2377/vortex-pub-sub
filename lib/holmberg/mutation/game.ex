defmodule Holmberg.Mutation.Game do
  import Plug.Conn
  alias VortexPubSub.Repo
  alias Holmberg.Schemas.GameModel
  alias Holmberg.Schemas.UserGameRelation
  alias Holmberg.Schemas.UserTurnMapping
  alias Holmberg.Schemas.TurnModel
  alias Holmberg.Manager.GameManager

  def create_new_game(conn) do
    game_id = Ecto.UUID.generate()
    params = conn.body_params
    game_changeset = create_game_changeset(game_id, params["user_id"], params["game_type"] , params["game_name"])
    user_game_relation_changeset = create_user_game_relation_changeset(game_id, params["user_id"], params["username"], "host")
    user_turn_mapping_changeset = create_user_turn_mapping_changeset(params["user_id"], game_id, params["user_id"], params["username"], 1)
    case Repo.transaction(GameManager.create_lobby_multi_changeset(game_changeset, user_game_relation_changeset , user_turn_mapping_changeset)) do
      {:ok, _} -> conn |> put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true} , game_id: game_id})
      )

      {:error, _ , error_message} ->   conn |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{result: %{ success: false} , error_message: error_message})
      )

      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          500,
          Jason.encode!(%{result: %{ success: false} , error_message: "Error! Server not available. Try later"})
        )
    end
  end


  defp create_game_changeset(game_id, host_id, game_name, game_type) do
    game_model = %GameModel{
      id: game_id,
      user_count: 1,
      host_id: host_id,
      name: game_name,
      game_type: game_name,
      is_staked:  ^game_type = "staked",
      state_index: 0,
      description: "LOBBY",
      chess_state: "",
      staked_money_state: nil,
      poker_state: nil,
      scribble_state: nil,
    } |> GameModel.changeset

    game_model
  end

  defp create_user_game_relation_changeset(game_id , user_id, username, player_type) do
    user_game_relation_model = %UserGameRelation{
      user_id: user_id,
      username: username,
      game_id: game_id,
      player_type: player_type,
      player_status: "not-ready"
    } |> UserGameRelation.changeset

    user_game_relation_model
  end

  defp create_user_turn_mapping_changeset(host_id, game_id, user_id, username, user_count_id) do
    game_model = %UserTurnMapping{
      game_id: game_id,
      host_id: host_id,
      turn_mappings: [
        %TurnModel{
          count_id: user_count_id,
          user_id: user_id,
          username: username
        }
      ]
    } |> UserTurnMapping.changeset

    game_model
  end


    defp handle_transaction_error(failed_operation, failed_value) do
      error_message = "Error in #{failed_operation}: #{inspect(failed_value)}"
      {:error, :game_manager_error, error_message}
    end
end
