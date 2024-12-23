defmodule VortexPubSub.MatchmakingController do
  require Logger
  use HTTPoison.Base

  @matchmaking_base_url "http://localhost:8000/"
def start_user_matchmaking(user_id , username , score , game_type) do

  new_user_ticket_changeset = make_user_ticket_changeset(user_id , username, score , game_type)
  {:ok , req_body} = Jason.encode(new_user_ticket_changeset)

   case HTTPoison.post( @matchmaking_base_url <> "matchmaking/tickets" , req_body , %{"Content-Type": "application/json"} ) do
    {:ok , response} -> case response.status_code do
      201 -> Logger.info("Status code 201 recieved")
      :ok

      _ ->

        Logger.info("Non 201 status recieved")
        IO.inspect(response)
        :error
    end
    {:error , _} -> :error
  end

end


def delte_user_matchmaking_ticket(user_id) do
  case HTTPoison.delete( @matchmaking_base_url <> "matchmaking/players/" <> user_id <> "/ticket"  , %{"Content-Type": "application/json"} ) do
    {:ok , response} -> case response.status_code do
      200 -> Logger.info("Status code 200 recieved")
      :ok

      _ ->

        Logger.info("Non 200 status recieved")
        IO.inspect(response)
        :error
    end
    {:error , _} -> :error
  end

end

def make_user_ticket_changeset(user_id , username, score , game_type) do

  max_score = min(score , 2700)
  min_score =max(0 , score- 900)

  game_type_num = get_game_type_value(game_type)
  user_ticket_changeset = %{
    MatchParameters: [
      %{
        Type: "score_max_limit",
        Operator: "<",
        Value: max_score
      },
      %{
        Type: "score_min_limit",
        Operator: ">",
        Value: min_score
      },
      %{
        Type: "game_type",
        Operator: "=",
        Value: game_type_num
      }
    ],
    PlayerId: user_id,
    PlayerParameters: [
      %{
        Type: "score_max_limit",
        Value: max_score
      },
      %{
        Type: "score_min_limit",
        Value: min_score
      },
      %{
        Type: "game_type",
        Value: game_type_num
      }
    ]
  }

  user_ticket_changeset

end

def get_game_type_value(game_type) do
  case game_type do
    "staked" -> 1
    "normal" -> 0
    _ ->0
  end
end


end
