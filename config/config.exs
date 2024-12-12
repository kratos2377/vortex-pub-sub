import Config

database_url =
  System.get_env("DATABASE_URL") ||
    "postgres://postgres:secret@localhost:5432/vortex"

config :kafka_ex, log_level: :debug,
brokers: [
  {"localhost", 9092}
],
consumer_group: "vortex",
client_id: "kafka_ex",
max_restarts: 5,
max_seconds: 30,
commit_interval: 5_000,
commit_threshold: 100,
auto_offset_reset: :none,
sleep_for_reconnect: 600,
use_ssl: false


config :vortex_pub_sub, VortexPubSub.MongoRepo,
  uri: "mongodb://admin:adminpassword@localhost/user_game_events_db?authSource=admin",
  pool_size: 5,
  timeout: 60_000,
  idle_interval: 10_000,
  queue_target: 5_000

config :vortex_pub_sub, VortexPubSub.PostgresRepo, url: database_url

config :brod,
  clients: [
    kafka_client: [
      endpoints: [localhost: 9092]
    ]
  ]

config :vortex_pub_sub, VortexPubSub.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {0, 0, 0, 0}, port: 4001, protocol_options: [
    idle_timeout: 5_000
  ]],
  debug_errors: true,
  secret_key_base: "new-jwt-secret-token",
  # code_reloader: true,
  check_origin: false,
  pubsub: [name: VortexPubSub.PubSub],
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    # esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]},
    # tailwind: {Tailwind, :install_and_run, [:default, ~w(--watch)]}

    # npx: [
    #    "tailwindcss",
    #    "--input=css/app.css",
    #    "--output=../priv/static/assets/app.css",
    #    "--postcss",
    #    "--watch",
    #    cd: Path.expand("../assets", __DIR__)
    #  ]
  ]

# if File.exists?(env_config) do
#   import_config(env_config)
# end

config :vortex_pub_sub,
joken_signer_key: "new-jwt-secret-token"
