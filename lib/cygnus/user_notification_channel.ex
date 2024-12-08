defmodule VortexPubSub.Cygnus.UserNotificationChannel do
    use VortexPubSubWeb, :channel
    alias MaelStorm.ChessServer
    alias VortexPubSub.Presence
    alias VortexPubSub.Constants

    def join("user:" <> user_id, _params, socket) do
        #Add Logic to parse token and then join the user socket channel. Send JWT Token in Params and parse it using joken
        {:ok , socket}
    end

    def handle_in("friend-request-event" ,
    %{
        "friend_request_id" => friend_request_id,
        "user_who_send_request_id" => user_who_send_request_id,
        "user_who_send_request_username" => user_who_send_request_username,
        "user_who_we_are_sending_event" => user_who_we_are_sending_event
    }, socket) do
        broadcast!(socket , "friend-request-event" ,  %{
            "friend_request_id" => friend_request_id,
            "user_who_send_request_id" => user_who_send_request_id,
            "user_who_send_request_username" => user_who_send_request_username,
            "user_who_we_are_sending_event" => user_who_we_are_sending_event
        } )
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
            "user_who_send_request_id" => user_who_send_request_id,
            "user_who_send_request_username" => user_who_send_request_username,
            "user_who_we_are_sending_event" => user_who_we_are_sending_event,
            "game_id" => game_id,
            "game_id" => game_id,
            "game_type" => game_type,
        } )
    end
end
