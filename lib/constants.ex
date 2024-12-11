defmodule VortexPubSub.Constants do

  #Kafka Topic Constants
  def kafka_game_topic, do: "game"
  def kafka_user_topic, do: "user"
  def kafka_user_game_events_topic, do: "user_game_events"


  #Kafka Key Constants
  def kafka_user_online_event_key, do: "user-online-event"
  def kafka_friend_request_event_key, do: "friend-request-event"
  def kafka_user_joined_event_key, do: "user-joined-room"
  def kafka_user_left_room_event_key, do: "user-left-room"
  def kafka_user_status_event_key, do: "user-status-event"
  def kafka_verifying_game_status_event_key, do: "verifying-game-status"
  def kafka_error_event_key, do: "error-event"
  def kafka_user_game_move_event_key, do: "user-game-move"
  def kafka_game_general_event_key, do: "game-general-event"
  def kafka_game_invite_event_key, do: "game-invite-event"
  def kafka_remove_all_users_key, do: "remove-all-users"

  #Mongo Collections
  def mongo_users_collection_key, do: "users"
  def mongo_games_collection_key, do: "games"
  def mongo_user_turns_collection_key, do: "user_turns"


  #Error Constants
  def game_not_found, do: "Game Not Found"
  def error_while_updating_mongo_entities, do: "Error While Updating Mongo Entities"
  def error_while_joining_lobby, do: "Error while joining lobby."
  def error_while_destroying_lobby, do: "Error while destroying lobby"
  def all_players_not_ready, do: "All Players not ready"
end
