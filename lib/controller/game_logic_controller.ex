defmodule VortexPubSub.GameLogicController do
  import Plug.Conn
  use Plug.Router

  alias Pulsar.ChessSupervisor
  alias MaelStorm.ChessServer
  alias Holmberg.Mutation.Game, as: GameMutation
  alias VortexPubSub.Constants
  alias JsonResult
  plug(VortexPubSub.Hypernova.Cors)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)

  post "/create_lobby" do
     %{"user_id" => user_id, "username" => username, "game_type" => game_type, "game_name" => game_name} = conn.body_params


   case game_name do
       "chess" -> case GameMutation.create_new_game(conn) do
          {:ok , game_id} -> ChessSupervisor.start_game(game_id , user_id , username)
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            200,
            Jason.encode!(%{result: %{ success: true} , game_id: "#{game_id}"})
          )
          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              400,
              Jason.encode!(%{result: %{ success: false}, error_message: message})
            )

       end
        _ ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            400,
            Jason.encode!(%{result: %{ success: false},  error_message: "some error occured"})
          )

     end

  end

  post "/join_lobby" do

    %{"user_id" => user_id, "username" => username, "game_id" => game_id, "game_name" => game_name} = conn.body_params


    case game_name do
      "chess" -> case ChessServer.game_pid(game_id) do
        pid when is_pid(pid) ->
          res = ChessServer.join_lobby(game_id, user_id, username)

          case GameMutation.join_lobby(game_id , res) do
            {:ok, _} -> conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              200,
              Jason.encode!(%{result: %{ success: true}})
            )
              _ ->
                _res_leave = ChessServer.leave_lobby(game_id, user_id)
                conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(JsonResult.create_error_struct(Constants.error_while_joining_lobby()))
        )
          end
        nil ->
          conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{result: %{ success: false},  error_message: Constants.game_not_found()})
        )
      end
        _ -> conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{result: %{ success: false},  error_message: "some error occured"})
        )
    end

  end

  post "/leave_lobby" do
    %{"user_id" => user_id, "username" => username, "game_id" => game_id, "game_name" => game_name} = conn.body_params

    case game_name do
      "chess" -> case ChessServer.game_pid(game_id) do
        pid when is_pid(pid) ->
          res = ChessServer.leave_lobby(game_id, user_id)

          case GameMutation.leave_lobby(game_id , res) do
            {:ok, _} -> conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              200,
              Jason.encode!(%{result: %{ success: true}})
            )
              _ ->
                _res_leave = ChessServer.leave_lobby(game_id, user_id)
                conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(JsonResult.create_error_struct(Constants.error_while_joining_lobby()))
        )
          end
        nil ->
          conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{result: %{ success: false},  error_message: Constants.game_not_found()})
        )
      end
        _ -> conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{result: %{ success: false},  error_message: "some error occured"})
        )
    end

  end

  post "/destroy_lobby_and_game" do

  end

  post "/update_player_status" do

  end


  post "/start_game" do

  end

  post "/get_user_turn_mappings" do

  end

  post "/verify_game_status" do

  end

  post "/get_lobby_players" do

  end

  get "/get_current_state_of_game" do

  end

  post "/get_game_details" do

  end


end
