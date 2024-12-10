defmodule VortexPubSub.MatchmakingController do
  use HTTPoison.Base

  @matchmaking_base_url "http://localhost:8000/"
def start_user_matchmaking(user_id , score , game_type) do

  new_user_ticket_changeset = make_user_ticket_changeset(user_id , score , game_type)

  case HTTPoison.post( @matchmaking_base_url <> "matchmaking/tickets" , new_user_ticket_changeset , %{"Content-Type": "application/json"} ) do
    {:ok , _} -> :ok
    {:error , _} -> :error
  end


end


def make_user_ticket_changeset(user_id , score , game_type) do

  max_score = min(score , 2700)
  min_score = max(0 , score- 900)

  user_ticket_changeset = %{
    MatchParameters: [
      %{
        Type: "game_type",
        Operator: "=",
        Value: game_type
      },
      %{
        Type: "max_limit",
        Operator: "<",
        Value: max_score
      },
      %{
        Type: "min_limit",
        Operator: ">",
        Value: min_score
      }
    ],
    PlayerId: user_id,
    PlayerParamerters: [
        %{
          Type: "score",
          Value: score
        }
    ]
  }

  user_ticket_changeset

end

end
