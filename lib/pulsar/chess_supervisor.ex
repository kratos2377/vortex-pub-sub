defmodule Pulsar.ChessSupervisor do
  use DynamicSupervisor
  require Logger
  alias GameState.ChessState
  alias MaelStorm.ChessServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end



  def start_game(game_id , user_id, username) do
    chess_init_state = ChessState.new(game_id , user_id , username)
    #Logger.info("For game_id='#{game_id}', chess_state_is='#{chess_init_state}'")
    IO.puts("Chess state is")
    IO.inspect(chess_init_state)
    child_spec = %{
      id: ChessServer,
      start: {ChessServer, :start_link, [chess_init_state]},
      restart: :transient
    }
    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:ok , chess_game_pid} ->  Logger.info("Spawned Chess game server process named '#{game_id}'.")
        IO.inspect(chess_game_pid)
        {:ok ,chess_game_pid }
      {:error , message} ->
        Logger.info("Error while spawning ChessProcess for '#{game_id}'. Error is as follows")
        IO.inspect(message)
          {:error , "some error occurred while spawning child"}
      {:ok , chess_game_pid , _ } ->
         Logger.info("Spawned Chess game server process named '#{game_id}' with pid '#{chess_game_pid}' with additional info.")
         {:ok ,chess_game_pid }
      :ignore ->
        Logger.info("No child added to PID for some reason")
        {:error , "child ignored"}
    end
  end


  def start_game_of_match_type(game_id , player1, player2) do
    chess_init_state = ChessState.new_state_of_match_type(game_id , player1 , player2)
    #Logger.info("For game_id='#{game_id}', chess_state_is='#{chess_init_state}'")
    IO.puts("Chess state is")
    IO.inspect(chess_init_state)
    child_spec = %{
      id: ChessServer,
      start: {ChessServer, :start_link, [chess_init_state]},
      restart: :transient
    }
    case DynamicSupervisor.start_child(__MODULE__, child_spec) do
      {:ok , chess_game_pid} ->  Logger.info("Spawned Chess game server process named '#{game_id}'.")
        IO.inspect(chess_game_pid)
        {:ok ,chess_game_pid }
      {:error , message} ->
        Logger.info("Error while spawning ChessProcess for '#{game_id}'. Error is as follows")
        IO.inspect(message)
          {:error , "some error occurred while spawning child"}
      {:ok , chess_game_pid , _ } ->
         Logger.info("Spawned Chess game server process named '#{game_id}' with pid '#{chess_game_pid}' with additional info.")
         {:ok ,chess_game_pid }
      :ignore ->
        Logger.info("No child added to PID for some reason")
        {:error , "child ignored"}
    end
  end


  def stop_game(game_id) do
    #:ets.delete(:games_table, game_id)
    case ChessServer.game_pid(game_id) do
      pid when is_pid(pid) -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      nil ->
        Logger.info("GAME Process not found")
        {:error , :not_found}
    end

  end
end
