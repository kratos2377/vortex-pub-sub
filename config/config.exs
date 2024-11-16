import Config


# config :kafka_ex,
# brokers: [
#   {"localhost", 9092},
#   {"localhost", 9093},
#   {"localhost", 9094}
# ],
# consumer_group: "kafka_ex",
# client_id: "kafka_ex",
# sync_timeout: 3000,
# max_restarts: 5,
# max_seconds: 30,
# commit_interval: 5_000,
# commit_threshold: 100,
# auto_offset_reset: :none,
# sleep_for_reconnect: 600,
# use_ssl: false,
# # ssl_options: [
# #   # Fix warnings. More at https://github.com/erlang/otp/issues/5352
# #   verify: :verify_none,
# #   cacertfile: File.cwd!() <> "/ssl/ca-cert",
# #   certfile: File.cwd!() <> "/ssl/cert.pem",
# #   keyfile: File.cwd!() <> "/ssl/key.pem"
# # ],
# snappy_module: :snappyer,
# kafka_version: "0.10.1"
# env_config = Path.expand("#{Mix.env()}.exs", __DIR__)


config :vortex_pub_sub, VortexPubSub.MongoRepo,
  uri: "mongodb://admin:adminpassword@localhost/user_game_events_db?authSource=admin",
  pool_size: 5,
  timeout: 60_000,
  idle_interval: 10_000,
  queue_target: 5_000

config :vortex_pub_sub, VortexPubSub.PostgresRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "dbname_dev",
  hostname: "localhost",
  pool_size: 5

# if File.exists?(env_config) do
#   import_config(env_config)
# end
