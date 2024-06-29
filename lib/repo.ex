defmodule VortexPubSub.Repo do
  use Ecto.Repo, otp_app: :vortex_pub_sub, adapter: Mongo.Ecto
end
