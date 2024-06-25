defmodule VortexPubSub.Presence do
  use Phoenix.Presence,
    otp_app: :vortex_pub_sub,
    pubsub_server: VortexPubSub.PubSub
end
