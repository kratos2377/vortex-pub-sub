defmodule VortexPubSub.PostgresRepo do
  use Ecto.Repo,
    otp_app: :vortex_pub_sub,
    adapter: Ecto.Adapters.Postgres
end
