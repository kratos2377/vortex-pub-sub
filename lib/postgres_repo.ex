defmodule VortexPubSub.PostgresRepo do
  use Ecto.Repo,
    otp_app: :myapp,
    adapter: Ecto.Adapters.Postgres
end
