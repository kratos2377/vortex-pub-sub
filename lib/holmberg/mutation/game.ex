defmodule Holmberg.Mutation.Game do
  import Plug.Conn
  alias VortexPubSub.MongoRepo
  alias Holmberg.Schemas.GameModel
  alias Holmberg.Schemas.UserGameRelation
  alias Holmberg.Schemas.UserTurnMapping
  alias Holmberg.Schemas.TurnModel
  alias VortexPubSub.Constants
  alias VortexPubSub.Utils.GenerateKeyNames
  alias VortexPubSub.KafkaProducer
  alias VortexPubSub.Redix

  def create_new_game(conn) do
    game_id = Ecto.UUID.generate()
    game_state_key = GenerateKeyNames.get_chess_state_key(game_id)
    params = conn.body_params
    game_changeset = create_game_changeset(game_id, params["user_id"], params["game_type"] , params["game_name"])
    user_game_relation_changeset = create_user_game_relation_changeset(game_id, params["user_id"], params["username"], "host")
    user_turn_mapping_changeset = create_user_turn_mapping_changeset(params["user_id"], game_id, params["user_id"], params["username"], 1)

    case Mongo.insert_one(:mongo , "games", game_changeset) do
      {:ok, _} -> case Mongo.insert_one(:mongo, "users" , user_game_relation_changeset) do
        {:ok , _} -> case Mongo.insert_one(:mongo, "user_turns" , user_turn_mapping_changeset) do
          {:ok , _} -> case Redix.command(["SET", game_state_key, Constants.chess_starting_state()]) do

           { :ok , _ } -> {:ok , game_id}

            _ ->
              KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
              {:error, "Error Occured while adding chess state to redis"}
          end
          {:error, error_message} ->
            KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
            {:error , error_message}

          _ ->
            KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
            {:error, "Error Occured while Persisting User Turn Mapping Model"}
        end
        {:error, error_message} ->
          KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
          {:error , error_message}

        _ ->
          KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
          {:error, "Error Occured while Persisting User Model"}
      end

      {:error, error_message} ->
        KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
        {:error , error_message}

      _ ->

        KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
        {:error, "Error Occured while Persisting Game Model"}
    end
  end

  def create_new_match_with_users(game_type , player1 , player2) do
    game_id = Ecto.UUID.generate()
    game_state_key = GenerateKeyNames.get_chess_state_key(game_id)
    #Only Chess is supported as of now
    game_changeset = create_match_game_changeset(game_id,  "chess" , game_type )
    match_user_changeset_first = create_user_match_relation_changeset(game_id, player1.user_id, player1.username)
    match_user_changeset_second = create_user_match_relation_changeset(game_id, player2.user_id, player2.username)
    user_turn_mapping_changeset = create_match_turns_mapping_changeset(game_id, player1 , player2)

    case Mongo.insert_one(:mongo , "games", game_changeset) do
      {:ok, _} ->  case Mongo.insert_many(:mongo, "users" , [match_user_changeset_first , match_user_changeset_second]) do
        {:ok , _} -> case Mongo.insert_one(:mongo, "user_turns" , user_turn_mapping_changeset) do
          {:ok , _} -> case Redix.command(["SET", game_state_key, Constants.chess_starting_state()]) do

           { :ok , _ } -> {:ok , game_id}

            _ ->
              KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
              {:error, "Error Occured while adding chess state to redis"}
          end
          {:error, error_message} ->
            KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
            {:error , error_message}

          _ ->
            KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
            {:error, "Error Occured while Persisting User Turn Mapping Model"}
        end
        {:error, error_message} ->
          KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
          {:error , error_message}

        _ ->
          KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
          {:error, "Error Occured while Persisting User Model"}
      end

      {:error, error_message} ->
        KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
        {:error , error_message}

      _ ->

        KafkaProducer.send_message(Constants.kafka_user_game_deletion_topic(), %{user_id: "random-user-id" , game_id: game_id}, Constants.kafka_game_general_event_key())
        {:error, "Error Occured while Persisting Game Model"}
    end
  end



  def join_lobby(conn , res) do
    params = conn.body_params

    case Mongo.update_one(:mongo, "user_turns" , %{id: params["game_id"]} , %{ "$push": %{ turn_mappings: %{
              count_id: res,
              user_id: params["user_id"],
              username: params["username"],
          },
      } }) do

        {:ok , _} ->
          user_join_changeset = create_user_game_relation_changeset(params["game_id"] , params["user_id"], params["username"], "player")

          case Mongo.insert_one(:mongo, "users", user_join_changeset) do
            {:ok, _} ->
              game_count_inc_doc = %{"$inc": %{user_count: 1}}
              case Mongo.update_one(:mongo, "games" , %{id: params["game_id"]}, game_count_inc_doc) do
                {:ok , _} -> {:ok, :lobby_joined}
                _ -> {:error , :error_while_joining_lobby}

            end
              _ -> {:error , :error_while_joining_lobby}
          end

        _ -> {:error , Constants.error_while_updating_mongo_entities()}

      end
  end

  def leave_lobby(conn , res) do
    params = conn.body_params

    case Mongo.update_one(:mongo, "user_turns" , %{id: params["game_id"]} , %{ "$pull": %{ turn_mappings: %{
              user_id: params["user_id"],
          },
      } }) do

        {:ok , _} ->
            case Mongo.delete_one(:mongo, "users", %{user_id: params["user_id"]} ) do
              {:ok, _} ->
                game_count_dec_doc = %{"$inc": %{user_count: -1}}
                case Mongo.update_one(:mongo, "games" , %{id: params["game_id"]}, game_count_dec_doc) do
                  {:ok , _} -> {:ok, :left_lobby}
                  _ -> {:error , :error_while_joining_lobby}

              end
                _ -> {:error , :error_while_joining_lobby}
            end


        _ -> {:error , Constants.error_while_updating_mongo_entities()}

      end
  end

  def destroy_lobby_and_game(conn) do
    params = conn.body_params
    case Mongo.delete_one(:mongo, "games", %{id: params["game_id"]} ) do
      {:ok, _} -> case Mongo.delete_many(:mongo , "users" , %{game_id: params["game_id"]}) do
        {:ok , _} -> case Mongo.delete_one(:mongo, "user_turns", %{game_id: params["game_id"]}) do
          {:ok, _} -> {:ok , :lobby_and_game_entities_deleted}
          _ -> {:error, :error_while_destroying_lobby}
        end
        _ -> {:error, :error_while_destroying_lobby}
      end
        _ -> {:error, :error_while_destroying_lobby}
    end

  end


  def update_player_status(game_id , game_name , user_id , status) do
    case Mongo.update_one(:mongo , "users" , %{game_id: game_id , user_id: user_id} , %{ "$set":  %{player_status: status} }) do
      {:ok , _} -> :ok
      _ -> :error
    end
  end


  defp create_game_changeset(game_id, host_id, game_type, game_name) do

    game_model = %{
      id: game_id,
      user_count: 1,
      host_id: host_id,
      name: game_name,
      game_type: game_type,
      is_staked:  game_type == "staked",
      state_index: 0,
      description: "LOBBY",
      is_match: false,
      chess_state: "",
      staked_money_state: "",
      poker_state: "",
      scribble_state: "",
      created_at: DateTime.now!("Etc/UTC"),
      updated_at: DateTime.now!("Etc/UTC")
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

# Matched Players Match
  defp create_match_game_changeset(game_id, game_name, game_type) do
    game_model = %{
      id: game_id,
      user_count: 2,
      host_id: nil,
      name: game_name,
      game_type: game_type,
      is_staked:  game_type == "staked",
      state_index: 0,
      is_match: true,
      description: "LOBBY",
      chess_state: "",
      staked_money_state: "",
      poker_state: "",
      scribble_state: "",
      created_at: DateTime.now!("Etc/UTC"),
      updated_at: DateTime.now!("Etc/UTC")
    }
    game_model
  end



  defp create_user_match_relation_changeset(game_id , user_id, username) do
    user_game_relation_model = %{
      user_id: user_id,
      username: username,
      game_id: game_id,
      player_type: "player",
      player_status: "not-ready"
    }

    user_game_relation_model
  end


  defp create_match_turns_mapping_changeset(game_id, player1 , player2) do
    turn_mapping_model = %{
      game_id: game_id,
      host_id: nil,
      turn_mappings: [
        %{
          count_id: 1,
          user_id: player1.user_id,
          username: player1.username
        },

        %{
          count_id: 2,
          user_id:  player2.user_id,
          username: player2.username
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
