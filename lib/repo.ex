defmodule VortexPubSub.MongoRepo do
  use Mongo.MongoRepo, otp_app: :vortex_pub_sub, topology: :mongo
end
