defmodule VortexPubSub.Cygnus.UserNotificationChannel do
    use VortexPubSubWeb, :channel
    require Logger
    alias MaelStorm.ChessServer
    alias VortexPubSub.Presence
    alias VortexPubSub.Constants

    def join("user:notifications:" <> user_id, %{"token" => token , "user_id" => user_id}, socket) do
        #Add Logic to parse token and then join the user socket channel. Send JWT Token in Params and parse it using joken
        signer = Joken.Signer.create("HS256" ,  Application.fetch_env!(:vortex_pub_sub, :joken_signer_key))

        case Joken.verify(token , signer , []) do

            {:ok , claims} -> case claims[:user_id] do
              user_id ->
                Logger.info("Successfully Connected to user notification channel for userId=#{user_id}")
                {:ok , socket}

              _ -> Logger.info("Token userId=#{claims[:user_id]} does not match the userId=#{user_id} trying to connect to socket")
            end
            _ -> Logger.info("Invalid Token issue for userId=#{user_id}")
            :error
        end

    end

    def handle_in("friend-request-event" ,
    %{
        "friend_request_id" => friend_request_id,
        "user_who_send_request_id" => user_who_send_request_id,
        "user_who_send_request_username" => user_who_send_request_username,
        "user_who_we_are_sending_event" => user_who_we_are_sending_event
    }, socket) do
        broadcast!(socket , "friend-request-event" ,  %{
            friend_request_id: friend_request_id,
            user_who_send_request_id: user_who_send_request_id,
            user_who_send_request_username: user_who_send_request_username,
            user_who_we_are_sending_event: user_who_we_are_sending_event
        } )

        {:noreply,socket}
    end

    def handle_in("game-invite-event" ,
    %{
        "user_who_send_request_id" => user_who_send_request_id,
        "user_who_send_request_username" => user_who_send_request_username,
        "user_who_we_are_sending_event" => user_who_we_are_sending_event,
        "game_id" => game_id,
        "game_name" => game_name,
        "game_type" => game_type,
    }, socket) do
        broadcast!(socket , "game-invite-event" ,  %{
            user_who_send_request_id: user_who_send_request_id,
            user_who_send_request_username: user_who_send_request_username,
            user_who_we_are_sending_event: user_who_we_are_sending_event,
            game_id: game_id,
            game_id: game_id,
            game_type: game_type,
        } )
        {:noreply,socket}
    end


    def handle_in("match-found" , %{"index" => index} , socket) do
        broadcast!(socket , "match-found" , %{index: index})
        {:noreply,socket}
    end


    def handle_in("match-found-detail" , %{index: index , opponent_details: player , game_id: game_id} , socket) do
        broadcast!(socket ,"match-found-detail" , %{index: index , opponent_details: player , game_id: game_id})
        {:noreply,socket}
    end

    def handle_in("match-game-error" , %{} , socket) do
        broadcast!(socket , "match-game-error" , %{})
        {:noreply,socket}
    end
end
