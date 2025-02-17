defmodule VortexPubSub.GameLogicController do
  import Plug.Conn
  use Plug.Router
  require Logger
  use VortexPubSubWeb, :channel
  alias VortexPubSub.Endpoint
  alias Pulsar.ChessSupervisor
  alias Pulsar.ScribbleSupervisor
  alias MaelStorm.ChessServer
  alias Holmberg.Mutation.Game, as: GameMutation
  alias Holmberg.Queries.GameBet, as: GameBetQuery
  alias VortexPubSub.MatchmakingController
  alias VortexPubSub.Constants
  alias JsonResult
  alias VortexPubSub.KafkaProducer
  alias VortexPubSub.Utils.GenerateKeyNames

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
            case ChessSupervisor.start_game(game_id , user_id , username , game_type == "staked") do
              {:ok , _} ->  Logger.info("Spawned Chess game server process named '#{game_id}'.")

              conn
              |> put_resp_content_type("application/json")
              |> send_resp(
                200,
                Jason.encode!(%{result: %{ success: true} , game_id: "#{game_id}"})
              )


              {:error , message} -> Logger.info("Error while spawning ChessProcess for '#{game_id}'. with some error '#{message}'")

              conn
              |> put_resp_content_type("application/json")
              |> send_resp(
                400,
                Jason.encode!(%{result: %{ success: false}, error_message: "Error while spawning game session"})
              )
            end


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
         case ChessServer.join_lobby(game_id, user_id, username) do
          :lobby_full -> conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            400,
            Jason.encode!(%{result: %{ success: false},  error_message: "Lobby is full"})
          )



            res -> case GameMutation.join_lobby(conn , res) do

              {:ok, _} ->

              Endpoint.broadcast!("game:chess:"<> game_id , "joined-room" , %{user_id: user_id , username: username , game_id: game_id})

                conn
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

            _ ->
              ChessSupervisor.stop_game(game_id)

           KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())


              conn
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
    %{"game_id" => game_id, "game_name" => game_name, "user_id" => user_id, "status" => status , "is_replay" => is_replay , "is_match" => is_match} = conn.body_params

    case game_name do
      "chess" -> case GameMutation.update_player_status(  game_id, game_name  , user_id , status) do
        :ok->  case ChessServer.update_player_status(game_id , user_id , status) do

          {:ok , res} ->

            has_not_ready = Enum.any?(res.player_ready_status, fn {_key, value} -> value == "not-ready" end)

            if !has_not_ready && is_match do
              Endpoint.broadcast!( "game:chess:" <> game_id , "start-the-match" , %{game_id: game_id})
            end

            conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            200,
            Jason.encode!(%{result: %{ success: true}})
          )


            _ ->  conn
            |> put_resp_content_type("application/json")
            |> send_resp(
              400,
              Jason.encode!(%{result: %{ success: false},  error_message: "some error occured"})
            )
        end

        _ -> conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{result: %{ success: false},  error_message: "some error occured"})
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
    game_state_key = GenerateKeyNames.get_chess_state_key(game_id)
    case Mongo.find_one(:mongo, "games", %{id: game_id}) do
      game_model -> case Redix.command(["GET" , game_state_key]) do
        { :ok , state } ->
          conn |>  put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true},  game: game_model , chess_state: state })
      )
          _ -> conn |>  put_resp_content_type("application/json")
          |> send_resp(
            400,
            Jason.encode!(%{result: %{ success: false},  error_message: "Error while fetching game state from redis"})
          )
      end
      {:error , _} -> conn |>  put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{result: %{ success: false},  error_message: "No Game Mapping found"})
      )
    end
  end


  post "/send_game_invite_event" do
    %{ "game_type" => game_type, "game_id" => game_id , "game_name" => game_name,
  "user_receiving_id" => user_receiving_id ,  "user_sending_id" => user_sending_id,
   "user_sending_username" => user_sending_username } = conn.body_params

    user_invite_event = %{
      user_who_send_request_id: user_sending_id,
      user_who_send_request_username: user_sending_username,
      user_who_we_are_sending_event: user_receiving_id,
      game_id: game_id,
      game_name: game_name,
      game_type: game_type,

    }

    IO.puts("Publishing game invite from here")

    Endpoint.broadcast!("user:notifications:"<> user_receiving_id , Constants.kafka_game_invite_event_key() , user_invite_event)
    conn |>  put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true}})
      )


  end


  post "/remove_game_models" do
    %{"game_id" => game_id , "host_user_id" => host_user_id, "game_name" => game_name ,
    "user_id" => user_id } = conn.body_params
    case Mongo.find_one(:mongo , "users" , %{user_id: user_id}) do
      user_model -> case Mongo.delete(:mongo , "users" , %{user_id: user_id} ) do

      {:ok , _} -> case user_model.player_type do
        "host" -> case Mongo.delete(:mongo , "games" , %{host_id: host_user_id, id: game_id , name: game_name}) do
          {:ok , _} ->  conn |>  put_resp_content_type("application/json")
          |> send_resp(
            200,
            Jason.encode!(%{result: %{ success: true}, message: "All game and user models removed"})
          )

          _ -> conn |>  put_resp_content_type("application/json")
          |> send_resp(
            400,
            Jason.encode!(%{result: %{ success: false}, message: "Error while deleting user module in mongo"})
          )
        end

        _ ->  conn |>  put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(%{result: %{ success: true}, message: "User model removed"})
        )
      end
        {:error , _} ->  conn |>  put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{result: %{ success: false}, message: "Error while deleting models in mongo"})
        )

      end
        {:error , _} ->   conn |>  put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{result: %{ success: false}, message: "Error while deleting module in mongo"})
        )
    end
  end

  post "/create_ticket_and_find_match" do
      %{"user_id" => user_id, "username" => username,"score" => score , "game_type" => game_type} = conn.body_params

      case MatchmakingController.start_user_matchmaking(user_id , username, score , game_type) do
        :ok -> conn |>  put_resp_content_type("application/json")
        |> send_resp(
          200,
          Jason.encode!(%{result: %{ success: true},  message: "Raised Matchmaking Ticket"})
        )
        :error -> conn |> send_resp(
          400,
          Jason.encode!(%{result: %{ success: false},  error_message: "Error While Raising Matchmaking Ticket"})
        )
      end
  end


  post "/delete_user_matchmaking_ticket" do
    %{"user_id" => user_id} = conn.body_params

    case MatchmakingController.delte_user_matchmaking_ticket(user_id) do
      :ok -> conn |>  put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true},  message: "Deleted Matchmaking Ticket"})
      )
      :error -> conn |> send_resp(
        400,
        Jason.encode!(%{result: %{ success: false},  error_message: "Error While Deleting Matchmaking Ticket"})
      )
    end
  end

  post "/replay_game" do
    %{"user_id" => user_id , "game_id" => game_id , "status" => status} = conn.body_params

    case ChessServer.update_player_status(game_id , user_id , status) do
      {:ok , res} ->

        has_not_ready = Enum.any?(res.player_ready_status, fn {_key, value} -> value == "not-ready" end)

        if !has_not_ready do

          if res.is_staked do
            ChessServer.stake_interval_check(game_id)
            conn |>  put_resp_content_type("application/json")
            |> send_resp(
              200,
              Jason.encode!(%{result: %{ success: true},  message: "Applied for replay successfully"})
            )
          else
            case ChessServer.start_game(game_id) do
              "success" -> case Mongo.update_one(:mongo, "games", %{id: game_id}, %{ "$set":  %{description: "IN_PROGRESS"} }) do
                {:ok, _} ->


                 if res.is_staked do
                   KafkaProducer.send_message(Constants.kafka_create_new_game_record() , %{game_id: res.game_id ,session_id: res.session_id} , "create_new_game_record")
                 end
                 KafkaProducer.send_message(Constants.kafka_game_topic(), %{message: "start-game", game_id: game_id}, Constants.kafka_game_general_event_key())

                 conn
                 |> put_resp_content_type("application/json")
                 |> send_resp(
                   200,
                   Jason.encode!(%{result: %{ success: true}})
                 )

                 Endpoint.broadcast!("game:chess:"<> game_id , "start-the-replay-match" , %{})
                 Endpoint.broadcast!("spectate:chess:"<> game_id , "start-the-replay-match" , %{})

                 _ ->

                   Endpoint.broadcast_from!(self() , "game:chess:" <> game_id , "replay-false-event-user",   %{game_id: game_id} )
                   Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id , "replay-false-event",   %{} )
                   KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
                   ChessSupervisor.stop_game(game_id)
              end
               "error" ->
                 Endpoint.broadcast_from!(self() , "game:chess:" <> game_id , "replay-false-event-user",   %{game_id: game_id} )
                 Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id , "replay-false-event",   %{} )
                 KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
                 ChessSupervisor.stop_game(game_id)
       end
          end


        end

        conn |>  put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true},  message: "Applied for replay successfully"})
      )

      _ ->  conn |>   put_resp_content_type("application/json") |> send_resp(
        400,
        Jason.encode!(%{result: %{ success: false},  error_message: "Error while setting status"})
      )
    end
  end


  post "/publish_user_stake" do
    #Use this to publish kafka event to update and send socket events
    %{"user_username_who_is_betting" => user_username_who_is_betting,  "user_who_is_betting" => user_who_is_betting , "user_betting_on" => user_betting_on , "game_id" => game_id, "bet_type" => bet_type , "amount" => amount , "session_id" => session_id,
    "event_type"=> event_type} = conn.body_params


    # This API should generate stake events for channels and Kafka event for cerotis and return 201

    user_bet_event = %{
      user_id_who_is_betting: user_who_is_betting,
      user_id: user_betting_on,
      game_id: game_id,
      bet_type: bet_type ,
      amount: amount,
      session_id: session_id,
      event_type: event_type,
      is_player: false
    }


    Endpoint.broadcast_from!(self() , "game:chess:" <> game_id , "user-game-bet-event",   %{"user_username_who_is_betting" => user_username_who_is_betting,  "user_betting_on" => user_betting_on , "game_id" => game_id, "bet_type" => bet_type , "amount" => amount} )
    Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id , "user-game-bet-event",  %{"user_username_who_is_betting" => user_username_who_is_betting,  "user_betting_on" => user_betting_on , "game_id" => game_id, "bet_type" => bet_type , "amount" => amount} )

    KafkaProducer.send_message(Constants.kafka_create_user_bet_topic(),  user_bet_event, "game-bet")


    conn |> put_resp_content_type("application/json") |> send_resp(
      201,
      Jason.encode!(%{result: %{ success: true},  message: "Succesfully staked"})
    )




  end

  # This is used for player stake only. Since player can stake only once the event_type will always be create
  post "/update_player_stake" do


    %{"username" => username ,"user_id" => user_id ,  "game_id" => game_id, "bet_type" => bet_type , "amount" => amount , "session_id" => session_id , "wallet_key" => wallet_key,
    "is_replay" => is_replay} = conn.body_params


    case ChessServer.update_player_stake(game_id , user_id) do




        :ok ->

          #Generate event for game and spectate channel
          # Generate Kafka Event for Cerotis MS

          user_bet_event = %{
            user_id_who_is_betting: user_id,
            user_id: user_id,
            game_id: game_id,
            bet_type: bet_type ,
            amount: amount,
            session_id: session_id,
            wallet_key: wallet_key,
            event_type: "CREATE",
            is_player: true
          }

          Endpoint.broadcast_from!(self() , "game:chess:" <> game_id , "user-game-bet-event",   %{"username" => username,  "user_id" => user_id , "game_id" => game_id, "bet_type" => bet_type , "amount" => amount} )
          Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id , "user-game-bet-event",  %{"username" => username,  "user_id" => user_id , "game_id" => game_id, "bet_type" => bet_type , "amount" => amount} )

          KafkaProducer.send_message(Constants.kafka_create_user_bet_topic(),  user_bet_event, "game-bet")


          has_everyone_staked = Enum.any?(res.player_ready_status, fn {_key, value} -> value == "not-staked" end)

          if !has_everyone_staked do

            Endpoint.broadcast!("game:chess:"<> game_id , "player-stake-complete" , %{})
            Endpoint.broadcast!("spectate:chess:"<> game_id , "player-stake-complete" , %{})


            case ChessServer.start_game(game_id) do
              "success" -> case Mongo.update_one(:mongo, "games", %{id: game_id}, %{ "$set":  %{description: "IN_PROGRESS"} }) do
                {:ok, _} ->

                 KafkaProducer.send_message(Constants.kafka_create_new_game_record() , %{game_id: res.game_id ,session_id: res.session_id} , "create_new_game_record")
                 KafkaProducer.send_message(Constants.kafka_game_topic(), %{message: "start-game", game_id: game_id}, Constants.kafka_game_general_event_key())

                 conn
                 |> put_resp_content_type("application/json")
                 |> send_resp(
                   200,
                   Jason.encode!(%{result: %{ success: true} , message: "Succesfully staked"})
                 )

                 Endpoint.broadcast!("game:chess:"<> game_id , "start-the-replay-match" , %{})
                 Endpoint.broadcast!("spectate:chess:"<> game_id , "start-the-replay-match" , %{})

                 _ ->

                   Endpoint.broadcast_from!(self() , "game:chess:" <> game_id , "replay-false-event-user",   %{game_id: game_id} )
                   Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id , "replay-false-event",   %{} )
                   KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
                   ChessSupervisor.stop_game(game_id)
              end
               "error" ->
                 Endpoint.broadcast_from!(self() , "game:chess:" <> game_id , "replay-false-event-user",   %{game_id: game_id} )
                 Endpoint.broadcast_from!(self() , "spectate:chess:" <> game_id , "replay-false-event",   %{} )
                 KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
                 ChessSupervisor.stop_game(game_id)
          end

            conn |> put_resp_content_type("application/json") |> send_resp(
              201,
              Jason.encode!(%{result: %{ success: true},  message: "Succesfully staked"})
            )

          else

            conn |> put_resp_content_type("application/json") |> send_resp(
              201,
              Jason.encode!(%{result: %{ success: true},  message: "Succesfully staked"})
            )

          end






        _ ->
          conn |> put_resp_content_type("application/json") |> send_resp(
            400,
            Jason.encode!(%{result: %{ success: false},  error_message: "Error While Placing User Bet"})
          )

    end

  end


  post "/check_stake_status" do
    %{"user_who_is_betting" => user_who_is_betting , "user_betting_on" => user_betting_on , "game_id" => game_id, "bet_type" => bet_type} = conn.body_params


    case ChessServer.check_if_bettor_is_player( game_id , user_who_is_betting) do

    {:ok , session_id} ->

      conn |> put_resp_content_type("application/json") |> send_resp(
        200,
        Jason.encode!(%{result: %{ success: true},  session_id: session_id})
      )

    :no ->

      case Mongo.find_one(:mongo , "users", %{user_id: user_betting_on, game_id: game_id }) do

        nil ->
          conn |> put_resp_content_type("application/json") |> send_resp(
            400,
            Jason.encode!(%{result: %{ success: false},  error_message: "Invalid Game or Player. Cannot Place Bet"})
          )


        user_model -> case ChessServer.check_if_stake_is_possible(game_id) do
          {:ok , session_id}->

            #can add redis support to fast up queries
            case GameBetQuery.get_game_bet_for_user(user_who_is_betting , game_id , session_id) do
              nil ->  conn |> put_resp_content_type("application/json") |> send_resp(
                200,
                Jason.encode!(%{result: %{ success: true},  type: "CREATE" , session_id: session_id})
              )

              game_bet_model ->
                IO.inspect("Recieved game bet model for user")
                IO.inspect(game_bet_model)

                if game_bet_model.user_id_betting_on == user_betting_on do

                  conn |> put_resp_content_type("application/json") |> send_resp(
                200,
                Jason.encode!(%{result: %{ success: true},  type: "UPDATE" , session_id: session_id})
              )

                else

                  conn |> put_resp_content_type("application/json") |> send_resp(
                400,
                Jason.encode!(%{result: %{ success: false},  error_message: "Cannot Bet on another player for this session"})
              )

                end

            end

            :timeout ->

              conn |> put_resp_content_type("application/json") |> send_resp(
                400,
                Jason.encode!(%{result: %{ success: false},  error_message: "Total 5 mins have passed since game started. Cannot Place bet anymore"})
              )

            :notstaked ->
              conn |> put_resp_content_type("application/json") |> send_resp(
                400,
                Jason.encode!(%{result: %{ success: false},  error_message: "Game is of not staked type"})
              )



            _ ->

              conn |> put_resp_content_type("application/json") |> send_resp(
                400,
                Jason.encode!(%{result: %{ success: false},  error_message: "Game is not IN-PROGRESS yet"})
              )
        end

    end

    end

  end


  # Test APIS wont be used in production
  post "/generate_make_new_bet_event" do

    %{"user_id" => user_id , "session_id" => session_id , "game_id" => game_id, "amount" => amount , "wallet_key" => wallet_key} = conn.body_params


    user_bet_event = %{
      user_id_who_is_betting: user_id,
      user_id: user_id,
      game_id: game_id,
      bet_type: "win" ,
      amount: amount,
      session_id: session_id,
      wallet_key: wallet_key,
      event_type: "CREATE",
      is_player: true
    }

    KafkaProducer.send_message(Constants.kafka_create_user_bet_topic() , user_bet_event, "game-bet-event")



    conn |> put_resp_content_type("application/json") |> send_resp(
      201,
      Jason.encode!(%{result: %{ success: true},  message: "Succesfully Published"})
    )


  end

  post "/generate_game_over_event" do

    %{"winner_id" => winner_id , "session_id" => session_id , "game_id" => game_id, "is_game_valid" => is_game_valid} = conn.body_params

    KafkaProducer.send_message(Constants.kafka_user_game_over_topic() , %{game_id: game_id , session_id: session_id , winner_id: winner_id , is_game_valid: is_game_valid} , "game-over-event")



    conn |> put_resp_content_type("application/json") |> send_resp(
      201,
      Jason.encode!(%{result: %{ success: true},  message: "Succesfully Published"})
    )


  end

  post "/generate_game_bet_events" do

    %{"winner_id" => winner_id , "session_id" => session_id , "game_id" => game_id, "is_game_valid" => is_game_valid} = conn.body_params

    KafkaProducer.send_message("generate_game_bet_events" , %{game_id: game_id , session_id: session_id , winner_id: winner_id , is_game_valid: is_game_valid} , "game-over-event")



    conn |> put_resp_content_type("application/json") |> send_resp(
      201,
      Jason.encode!(%{result: %{ success: true},  message: "Succesfully Published"})
    )


  end


end
