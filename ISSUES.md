- [ ] Look if we can paginate get ongoing_games_for_users and make sure all games are unique -> (Its possible A is friends with B,C and both B,C are part of same match or lobby playing the same game)


- [ ] Once Game Is Over the chess state in Redis should be set back to Starting chess state
- [ ] Fix GenServer.whereis() issue. If pid is nil dont use any Genserver call. it will throw unnecessary error