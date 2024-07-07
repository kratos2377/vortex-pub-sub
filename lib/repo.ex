defmodule VortexPubSub.Repo do
  use Mongo.Repo, otp_app: :vortex_pub_sub, topology: :mongo
end
