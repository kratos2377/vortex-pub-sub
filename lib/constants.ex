defmodule VortexPubSub.Constants do

  #Kafka Topic Constants
  def kafka_game_topic, do: "game"
  def kafka_user_topic, do: "user"


  #Error Constants
  def game_not_found, do: "Game Not Found"
  def error_while_updating_mongo_entities, do: "Error While Updating Mongo Entities"
  def error_while_joining_lobby, do: "Error while joining lobby."
  def error_while_destroying_lobby, do: "Error while destroying lobby"
  def all_players_not_ready, do: "All Players not ready"
end
