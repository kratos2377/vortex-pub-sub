- [ ] If user is disconnected the online status does not change to false
- [ ] Chess Game channel both player and spectate does not have error-event handle_in where as these events are present in client
- [ ] Issue while updating update keys 

    ```
                        18:34:57.212 [error] #PID<0.939.0> running VortexPubSub.Endpoint (connection #PID<0.938.0>, stream id 1) terminated
            Server: localhost:4001 (http)
            Request: POST /api/v1/game/update_player_status
            ** (exit) exited in: GenServer.call({:via, Registry, {VortexPubSub.Pulsar.ChessRegistry, "1cf6d990-282d-4850-ad6b-a72a0e0854c6"}}, {:update_player_status, "f6a8c806-2c11-4eeb-b1cc-393e044a6980", "ready"}, 5000)
                ** (EXIT) an exception was raised:
                    ** (KeyError) key :"f6a8c806-2c11-4eeb-b1cc-393e044a6980" not found
                        (vortex_pub_sub 0.1.0) lib/quasar/chess_state_manager.ex:31: Quasar.ChessStateManager.update_player_status/3
                        (vortex_pub_sub 0.1.0) lib/maelstorm/chess_server.ex:68: MaelStorm.ChessServer.handle_call/3
                        (stdlib 4.3.1.3) gen_server.erl:1149: :gen_server.try_handle_call/4
                        (stdlib 4.3.1.3) gen_server.erl:1178: :gen_server.handle_msg/6
                        (stdlib 4.3.1.3) proc_lib.erl:240: :proc_lib.init_p_do_apply/3


    ```

    #### The new state was reported like this

    ```
            %GameState.ChessState{
        game_id: "1cf6d990-282d-4850-ad6b-a72a0e0854c6",
        turn_map: [
            %Holmberg.Schemas.TurnModel{
            count_id: 1,
            user_id: "8a1f9d34-5086-4994-a89f-923f87824761",
            username: "necromorph23"
            },
            %Holmberg.Schemas.TurnModel{
            count_id: 2,
            user_id: "f6a8c806-2c11-4eeb-b1cc-393e044a6980",
            username: "satorou"
            }
        ],
        turn_count: 0,
        total_players: 2,
        time_left_for_white_player: 900,
        time_left_for_black_player: 900,
        player_count_index: 2,
        player_ready_status: %{
            :"8a1f9d34-5086-4994-a89f-923f87824761" => "ready",
            "f6a8c806-2c11-4eeb-b1cc-393e044a6980" => "not-ready"
        }
        }

    ```

    #### This was the init state

    ```
                %GameState.ChessState{
        game_id: "1cf6d990-282d-4850-ad6b-a72a0e0854c6",
        turn_map: [
            %Holmberg.Schemas.TurnModel{
            count_id: 1,
            user_id: "8a1f9d34-5086-4994-a89f-923f87824761",
            username: "necromorph23"
            }
        ],
        turn_count: 0,
        total_players: 1,
        time_left_for_white_player: 900,
        time_left_for_black_player: 900,
        player_count_index: 1,
        player_ready_status: %{"8a1f9d34-5086-4994-a89f-923f87824761": "not-ready"}
        }

    ```