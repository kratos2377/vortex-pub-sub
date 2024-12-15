defmodule VortexPubSub.MatchmakingController do
  require Logger
  use HTTPoison.Base

  @matchmaking_base_url "http://localhost:8000/"
def start_user_matchmaking(user_id , score , game_type) do

  new_user_ticket_changeset = make_user_ticket_changeset(user_id , score , game_type)
  {:ok , req_body} = Jason.encode(new_user_ticket_changeset)

  IO.puts("Req body is")
  IO.inspect(req_body)

  case HTTPoison.post( @matchmaking_base_url <> "matchmaking/tickets" , req_body , %{"Content-Type": "application/json"} ) do
    {:ok , response} -> case response.status_code do
      201 -> Logger.info("Status code 201 recieved")
      :ok

      _ ->
        Logger.info("Non 200 status recieved")
        :error
    end
    {:error , _} -> :error
  end


end


def make_user_ticket_changeset(user_id , score , game_type) do

  max_score = min(score , 2700)
  min_score =max(0 , score- 900)

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
