## Vortex-Pub-Sub
Vortex Pub Sub contains all the game related APIs, it also contains all the WS realtime interface to enable realtime event passing between all 
participants (including all players and spectators).


## Project Demo
[Vortex Project Demo](https://drive.google.com/file/d/1lKqdKbO27KRdyTNZOglrE2yBy8Z1vdj7/view?usp=sharing)

## Project Architecture
[Architecture Design (Lucid Chart)](https://lucid.app/lucidchart/7da583bc-493c-45dc-80b7-34f6002b7646/edit?viewport_loc=-6565%2C-2146%2C8975%2C4355%2C0_0&invitationId=inv_0f90b33d-902f-4d79-b65c-6f4ab7641f46)



## Repo Links

| Codebase              |      Description          |
| :-------------------- | :-----------------------: |
| [Vortex](https://github.com/kratos2377/vortex)    |    Contains Axum APIs for Auth and other services for necessary processing |
| [Vortex-Client](https://github.com/kratos2377/vortex-client)    |  Tauri Client Used to Play/Join Games as Players or specate any games          |
| [Vortex-Mobile](github.com/kratos2377/vortex-mobile)            |      React Native App to scan QR codes and stake in the game and check status of any previous bets       |
| [Vortex-Pub-Sub](https://github.com/kratos2377/vortex-pub-sub)|  Elixir Service to broadcast realtime events to players and spectators    |
| [Vortex-Exchange](https://github.com/kratos2377/vortex-exchange)        |  Smart Contracts made using Anchor framework so that players/spectators can place their bets |
| [Executor-Bots](https://github.com/kratos2377/executor-bots)        |  Bots which consume game result events and settle bets for the players |
| [Vortex-Matchmaker](https://github.com/kratos2377/vortex-matchmaker) | Matchmaking Service which matches any two players with similar ratings |


