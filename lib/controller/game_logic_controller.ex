defmodule VortexPubSub.GameLogicController do
  import Plug.Conn
  use Plug.Router
  require Logger
  alias Pulsar.ChessSupervisor
  alias Pulsar.ScribbleSupervisor
  alias MaelStorm.ChessServer
  alias MealStorm.ScrribleServer
  alias Holmberg.Mutation.Game, as: GameMutation
  alias VortexPubSub.Constants
  alias JsonResult
  alias VortexPubSub.KafkaProducer
  plug(VortexPubSub.Hypernova.Cors)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["text/*"],
    json_decoder: Jason
  )

  plug(:match)
  plug(:dispatch)


defimpl Jason.Encoder, for: BSON.ObjectId do
  def encode(val, _opts \\ []) do
    BSON.ObjectId.encode!(val)
    |> Jason.encode!()
  end
end

  post "/create_lobby" do
     %{"user_id" => user_id, "username" => username, "game_type" => game_type, "game_name" => game_name} = conn.body_params


   case game_name do
       "chess" -> case GameMutation.create_new_game(conn) do
          {:ok , game_id} ->
            case ChessSupervisor.start_game(game_id , user_id , username) do
              {:ok , _} ->  Logger.info("Spawned Chess game server process named '#{game_id}'.")
              {:error , message} -> Logger.info("Error while spawning ChessProcess for '#{game_id}'. with some error '#{message}'")
            end

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

       "scribble" -> case GameMutation.create_new_game(conn) do
        {:ok , game_id} -> ScribbleSupervisor.start_game(game_id , user_id , username)
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

          case GameMutation.join_lobby(conn , res) do
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

      "scribble" -> case ScribbleServer.game_pid(game_id) do
        pid when is_pid(pid) ->
          res = ScribbleServer.join_lobby(game_id, user_id, username)

          case GameMutation.join_lobby(conn , res) do
            {:ok, _} -> conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              200,
              Jason.encode!(%{result: %{ success: true}})
            )
              _ ->
                _res_leave = ScribbleServer.leave_lobby(game_id, user_id)
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
          IO.puts("Leave Lobby Elixir Result")
          IO.inspect(res)
          case GameMutation.leave_lobby(conn , res) do
            {:ok, _} -> conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              200,
              Jason.encode!(%{result: %{ success: true}})
            )
              _ ->
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

      "scribble" -> case ScribbleServer.game_pid(game_id) do
        pid when is_pid(pid) ->
          res = ScribbleServer.leave_lobby(game_id, user_id)

          case GameMutation.leave_lobby(conn , res) do
            {:ok, _} -> conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              200,
              Jason.encode!(%{result: %{ success: true}})
            )
              _ ->
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
      %{"game_id" => game_id, "game_name" => game_name} = conn.body_params

      case game_name do
        "chess" -> case GameMutation.destroy_lobby_and_game(conn) do
          {:ok , _} -> ChessSupervisor.stop_game(game_id)

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            200,
            Jason.encode!(%{result: %{ success: true}})
          )

            _ -> conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              400,
              Jason.encode!(JsonResult.create_error_struct(Constants.error_while_destroying_lobby()))
            )
        end


        "scribble" -> case GameMutation.destroy_lobby_and_game(conn) do
          {:ok , _} -> ScribbleSupervisor.stop_game(game_id)

          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            200,
            Jason.encode!(%{result: %{ success: true}})
          )

            _ -> conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              400,
              Jason.encode!(JsonResult.create_error_struct(Constants.error_while_destroying_lobby()))
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

  post "/update_player_status" do
    %{"game_id" => game_id, "game_name" => game_name, "user_id" => user_id, "status" => status} = conn.body_params

    case game_name do
      "chess" -> ChessServer.update_player_status(game_id , user_id , status)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true}})
      )

      _ -> conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{result: %{ success: false},  error_message: "some error occured"})
      )

      "scribble" -> ScribbleServer.update_player_status(game_id , user_id , status)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true}})
      )

      _ -> conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{result: %{ success: false},  error_message: "some error occured"})
      )
    end

  end


  post "/start_game" do

    %{"game_id" => game_id, "game_name" => game_name} = conn.body_params

    case game_name do
      "chess" ->
       res =   ChessServer.start_game(game_id)

       case res do
         "success" -> case Mongo.update_one(:mongo, "games", %{id: game_id}, %{ "$set":  %{description: "IN_PROGRESS"} }) do
           {:ok, _} ->

            KafkaProducer.send_message(Constants.kafka_game_topic(), %{message: "start-game", game_id: game_id}, Constants.kafka_game_general_event_key())

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              200,
              Jason.encode!(%{result: %{ success: true}})
            )

            _ -> conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              400,
              Jason.encode!(%{result: %{ success: false},  error_message: Constants.error_while_updating_mongo_entities()})
            )
         end
          "error" -> conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            400,
            Jason.encode!(%{result: %{ success: false},  error_message: Constants.all_players_not_ready()})
          )
       end



      "scribble" ->
        res =   ScribbleServer.start_game(game_id)

        case res do
          "success" -> case Mongo.update_one(:mongo, "games", %{id: game_id}, %{ "$set":  %{description: "IN_PROGRESS"} }) do
            {:ok, _} ->

             KafkaProducer.send_message(Constants.kafka_game_topic(), %{message: "start-game", game_id: game_id}, Constants.kafka_game_general_event_key())

             conn
             |> put_resp_content_type("application/json")
             |> send_resp(
               200,
               Jason.encode!(%{result: %{ success: true}})
             )

             _ -> conn
             |> put_resp_content_type("application/json")
             |> send_resp(
               400,
               Jason.encode!(%{result: %{ success: false},  error_message: Constants.error_while_updating_mongo_entities()})
             )
          end
           "error" -> conn
           |> put_resp_content_type("application/json")
           |> send_resp(
             400,
             Jason.encode!(%{result: %{ success: false},  error_message: Constants.all_players_not_ready()})
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

  post "/get_user_turn_mappings" do

    %{"game_id" => game_id} = conn.body_params
    options = [
      sort: %{"turn_mappings.count_id" => 1},
      limit: 1
    ]
    case Mongo.find_one(:mongo, "user_turns", %{game_id: game_id}, options ) do

      nil -> conn |>  put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true},  user_turns: []})
      )

      user_turns -> conn |>  put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true},  user_turns: user_turns})
      )


      _ ->  conn |>  put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{result: %{ success: false},  error_message: "some error occured"})
      )
    end

  end

  post "/verify_game_status" do
    %{"game_id" => game_id , "game_name" => game_name} = conn.body_params

    case game_name do
      "chess" -> case ChessServer.game_pid(game_id) do
        pid when is_pid(pid) ->   conn |>  put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(%{result: %{ success: true}})
        )

        nil -> conn |>  put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{result: %{ success: false},  error_message: "Invalid Game"})
        )

        end
        _ ->  conn |>  put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{result: %{ success: false},  error_message: "Invalid Game Type"})
        )

        "scribble" -> case ScribbleServer.game_pid(game_id) do
          pid when is_pid(pid) ->   conn |>  put_resp_content_type("application/json")
          |> send_resp(
            200,
            Jason.encode!(%{result: %{ success: true}})
          )

          nil -> conn |>  put_resp_content_type("application/json")
          |> send_resp(
            400,
            Jason.encode!(%{result: %{ success: false},  error_message: "Invalid Game"})
          )

          end
          _ ->  conn |>  put_resp_content_type("application/json")
          |> send_resp(
            400,
            Jason.encode!(%{result: %{ success: false},  error_message: "Invalid Game Type"})
          )
    end
  end

  post "/get_lobby_players" do
    %{"game_id" => game_id, "host_user_id"=> host_user_id} = conn.body_params

    case Mongo.find(:mongo, "users", %{game_id: game_id}) do
       user_cursor ->
        user_list = user_cursor |> Enum.to_list()
        conn |>  put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true},  lobby_users: user_list})
      )
      {:error , _} -> conn |>  put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{result: %{ success: false},  error_message: "No Game or UserMapping found"})
      )
    end
  end

  get "/get_current_state_of_game" do
    %{"game_id" => game_id} = conn.body_params

    case Mongo.find_one(:mongo, "games", %{id: game_id}) do
      game_model ->  conn |>  put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true},  game_state: game_model.chess_state})
      )
      {:error , _} -> conn |>  put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{result: %{ success: false},  error_message: "No Game Mapping found"})
      )
    end
  end

  post "/get_game_details" do
    %{"game_id" => game_id} = conn.body_params

    case Mongo.find_one(:mongo, "games", %{id: game_id}) do
      game_model -> conn |>  put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true},  game: game_model})
      )
      {:error , _} -> conn |>  put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{result: %{ success: false},  error_message: "No Game Mapping found"})
      )
    end
  end


  # post "/stake_in_game" do
  #   %{"game_id" => game_id, "game_name" => game_name, "user_id" => user_id, "username" => username} = conn.body_params



  # end


end
